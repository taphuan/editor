// Initialize Monaco Editor
let editor;
let terminal;
let fitAddon = null; // Make fitAddon accessible globally
let currentFilePath = null;
let terminalSessionId = null;
let eventSource = null;
let sessionReady = false; // Track if terminal session is ready

// ============================================================================
// LOGGING CONFIGURATION
// ============================================================================
// Set DEBUG_LOGGING to true to enable all debug console output
// When false (default), only critical errors are logged
// To enable: Change DEBUG_LOGGING to true below
const DEBUG_LOGGING = false;

// Logging helper functions
const debugLog = (...args) => {
    if (DEBUG_LOGGING) {
        console.log(...args);
    }
};

const debugWarn = (...args) => {
    if (DEBUG_LOGGING) {
        console.warn(...args);
    }
};

const debugError = (...args) => {
    // Critical errors are always logged regardless of DEBUG_LOGGING flag
    console.error(...args);
};

// Generate unique session ID
terminalSessionId = 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);

// Unified terminal resize handler - can be called from anywhere
function handleTerminalResize() {
    if (!fitAddon || !terminal) {
        debugWarn('Cannot resize: fitAddon or terminal not available');
        return;
    }
    
    try {
        // Get the actual container dimensions
        const terminalPanel = document.getElementById('terminalPanel');
        const terminalElement = document.getElementById('terminal');
        
        if (!terminalPanel || !terminalElement) {
            debugWarn('Terminal elements not found');
            return;
        }
        
        // Force a reflow
        terminalPanel.offsetHeight;
        terminalElement.offsetHeight;
        
        // Fit the terminal to its container
        fitAddon.fit();
        
        debugLog('✓ Terminal resized - Panel:', terminalPanel.offsetHeight + 'px, Cols:', terminal.cols, 'Rows:', terminal.rows);
        
        // Notify server of new size (only if terminal has dimensions)
        if (terminalSessionId && typeof terminal.cols !== 'undefined' && typeof terminal.rows !== 'undefined') {
            resizeTerminal();
        }
    } catch (err) {
        console.error('Error in handleTerminalResize:', err);
    }
}

// Wait for xterm.js and FitAddon to be available
function waitForXterm(callback, maxAttempts = 100) {
    // Check both window.Terminal and global Terminal
    const TerminalAvailable = typeof Terminal !== 'undefined' || typeof window.Terminal !== 'undefined';
    const FitAddonAvailable = typeof FitAddon !== 'undefined' || typeof window.FitAddon !== 'undefined';
    
    if (TerminalAvailable && FitAddonAvailable) {
        callback();
    } else if (maxAttempts > 0) {
        setTimeout(() => waitForXterm(callback, maxAttempts - 1), 50);
    } else {
        debugError('Failed to load xterm.js or FitAddon after', maxAttempts * 50, 'ms');
        debugLog('Terminal available:', TerminalAvailable);
        debugLog('FitAddon available:', FitAddonAvailable);
        // Try to initialize anyway if Terminal is available
        if (TerminalAvailable) {
            debugWarn('Initializing terminal without FitAddon');
            callback();
        } else {
            alert('Failed to load terminal library. Please refresh the page.');
        }
    }
}

require.config({ paths: { vs: 'https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs' } });
require(['vs/editor/editor.main'], () => {
    editor = monaco.editor.create(document.getElementById('editor'), {
        value: '// Welcome to HTTP/2 Editor\n// Start coding...\n',
        language: 'javascript',
        theme: 'vs-dark',
        automaticLayout: true,
        minimap: { enabled: true },
        fontSize: 14,
        lineNumbers: 'on',
        scrollBeyondLastLine: false,
        wordWrap: 'on',
        renderWhitespace: 'selection',
        // Performance optimizations
        renderLineHighlight: 'all',
        smoothScrolling: true,
        cursorBlinking: 'smooth',
        cursorSmoothCaretAnimation: true
    });

    // Wait for xterm.js to load before initializing terminal
    waitForXterm(() => {
        // Initialize terminal
        initTerminal();
        
        // Load file explorer
        loadFileExplorer();
        
        // Setup event listeners
        setupEventListeners();
    });
});

function initTerminal() {
    // Prevent multiple initializations
    if (terminal) {
        debugWarn('Terminal already initialized, skipping re-initialization');
        return;
    }
    
    // Try both Terminal and window.Terminal
    const TerminalClass = typeof Terminal !== 'undefined' ? Terminal : (typeof window.Terminal !== 'undefined' ? window.Terminal : null);
    
    if (!TerminalClass) {
        console.error('Terminal is not defined. Please ensure xterm.js is loaded.');
        document.getElementById('terminal').innerHTML = '<div style="padding: 20px; color: #ff6b6b;">Failed to load terminal. Please refresh the page.</div>';
        return;
    }
    
    terminal = new TerminalClass({
        cursorBlink: true,
        fontSize: 14,
        fontFamily: 'Consolas, "Courier New", monospace',
        theme: {
            background: '#1e1e1e',
            foreground: '#d4d4d4',
            cursor: '#aeafad',
            selection: '#264f78'
        },
        // Performance optimizations for faster rendering
        allowTransparency: true,
        disableStdin: false,
        rows: 24,
        cols: 80,
        // Optimize rendering performance
        fastScrollModifier: 'alt',
        scrollback: 1000, // Limit scrollback for better performance
        macOptionIsMeta: true,
        // Reduce rendering overhead
        rendererType: 'canvas', // Use canvas renderer for better performance
        rightClickSelectsWord: true,
        // Additional performance optimizations
        convertEol: true, // Convert line endings for better performance
        bellStyle: 'none', // Disable bell sound for better performance
        disableStdin: false // Keep stdin enabled for input
    });

    // Try both FitAddon and window.FitAddon
    const FitAddonClass = typeof FitAddon !== 'undefined' ? FitAddon : (typeof window.FitAddon !== 'undefined' ? window.FitAddon : null);
    
    if (!FitAddonClass) {
        debugWarn('FitAddon is not defined. Terminal will work but resize may not function properly.');
    }
    
    fitAddon = FitAddonClass ? new FitAddonClass.FitAddon() : null;
    if (fitAddon) {
        terminal.loadAddon(fitAddon);
    }
    
    const terminalElement = document.getElementById('terminal');
    
    // Ensure terminal element has proper sizing
    terminalElement.style.width = '100%';
    terminalElement.style.height = '100%';
    
    terminal.open(terminalElement);
    
    // Fit terminal to container and enable word wrap
    if (fitAddon) {
        // Initial fit
        setTimeout(() => {
            if (fitAddon && terminal) {
                try {
                    fitAddon.fit();
                    debugLog('Initial terminal fit - cols:', terminal.cols, 'rows:', terminal.rows);
                } catch (err) {
                    console.error('Error in initial fit:', err);
                }
            }
        }, 50);
        
        // Re-fit after a short delay to ensure container is ready
        setTimeout(() => {
            if (fitAddon && terminal) {
                try {
                    fitAddon.fit();
                    debugLog('Delayed terminal fit - cols:', terminal.cols, 'rows:', terminal.rows);
                    // Only resize if terminal is fully initialized
                    if (terminalSessionId && typeof terminal.cols !== 'undefined' && typeof terminal.rows !== 'undefined') {
                        resizeTerminal();
                    }
                } catch (err) {
                    console.error('Error in delayed fit:', err);
                }
            }
        }, 200);
    }
    
    // Handle window resize with optimized debouncing
    let resizeTimeout;
    window.addEventListener('resize', () => {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(() => {
            if (fitAddon && terminal && typeof terminal.cols !== 'undefined' && typeof terminal.rows !== 'undefined') {
                // Use requestAnimationFrame for smooth resize
                requestAnimationFrame(() => {
                    fitAddon.fit();
                    resizeTerminal();
                });
            }
        }, 50); // Reduced from 100ms for faster response
    });
    
    // Handle terminal panel resize using ResizeObserver
    if (typeof ResizeObserver !== 'undefined') {
        const terminalPanel = document.getElementById('terminalPanel');
        const resizeObserver = new ResizeObserver((entries) => {
            for (const entry of entries) {
                const { width, height } = entry.contentRect;
                debugLog('ResizeObserver: Panel resized to', width + 'x' + height);
                
                // Debounce the resize with requestAnimationFrame for smooth updates
                clearTimeout(window.terminalResizeTimeout);
                window.terminalResizeTimeout = setTimeout(() => {
                    requestAnimationFrame(() => {
                        handleTerminalResize();
                    });
                }, 16); // ~60fps debounce (reduced from 50ms)
            }
        });
        
        if (terminalPanel) {
            resizeObserver.observe(terminalPanel);
            debugLog('ResizeObserver: Observing terminalPanel');
        }
        
        // Also observe the terminal element itself
        resizeObserver.observe(terminalElement);
        debugLog('ResizeObserver: Observing terminalElement');
    }
    
    // Fallback: Listen for CSS resize events (when user drags resize handle)
    const terminalPanel = document.getElementById('terminalPanel');
    if (terminalPanel) {
        let resizeTimer;
        const handleCSSResize = () => {
            clearTimeout(resizeTimer);
            resizeTimer = setTimeout(() => {
                debugLog('CSS resize detected');
                requestAnimationFrame(() => {
                    handleTerminalResize();
                });
            }, 16); // Reduced from 100ms for faster response
        };
        
        // Listen for mouse events on the panel (for CSS resize handle)
        terminalPanel.addEventListener('mouseup', handleCSSResize);
        terminalPanel.addEventListener('mousemove', (e) => {
            if (e.buttons === 1) { // Mouse button is pressed (dragging)
                handleCSSResize();
            }
        });
    }

    // Ensure terminal is writable and ready for input
    terminal.clear();
    terminal.writeln('\x1b[36mTerminal initialized. Connecting to server...\x1b[0m');
    
    // Focus terminal for input
    terminal.focus();
    
    // Optimized input handling - use queue instead of blocking flag
    let inputQueue = [];
    let isProcessingInput = false;
    let lastInputTime = 0;
    const INPUT_DEBOUNCE_MS = 5; // Reduced from 10ms for faster response
    
    const processInputQueue = () => {
        if (isProcessingInput || inputQueue.length === 0) {
            return;
        }
        
        const input = inputQueue.shift();
        isProcessingInput = true;
        
        // Send input without blocking - use fire-and-forget for better responsiveness
        sendTerminalInput(input)
            .catch(() => {
                // Errors are already logged in sendTerminalInput
            })
            .finally(() => {
                isProcessingInput = false;
                // Process next item in queue immediately
                if (inputQueue.length > 0) {
                    // Use requestAnimationFrame for smooth processing
                    requestAnimationFrame(processInputQueue);
                }
            });
    };
    
    // Handle terminal input - ensure it's enabled
    // Only register once to avoid event listener conflicts
    terminal.onData((data) => {
        const now = Date.now();
        
        // Prevent rapid-fire duplicate single-character inputs
        if (now - lastInputTime < INPUT_DEBOUNCE_MS && data.length === 1) {
            return;
        }
        lastInputTime = now;
        
        debugLog('Terminal input received:', JSON.stringify(data));
        
        // Add to queue instead of blocking
        inputQueue.push(data);
        
        // Process queue if not already processing
        if (!isProcessingInput) {
            processInputQueue();
        }
    });
    
    // Handle terminal key events for debugging (disabled to prevent interference)
    // terminal.onKey(({ key, domEvent }) => {
    //     // Log special key combinations for debugging
    //     if (domEvent.ctrlKey || domEvent.metaKey || domEvent.altKey) {
    //         console.log('Special key:', key, 'Ctrl:', domEvent.ctrlKey, 'Meta:', domEvent.metaKey, 'Alt:', domEvent.altKey);
    //     }
    // });
    
    // Make terminal clickable to focus
    terminalElement.addEventListener('click', () => {
        terminal.focus();
    });
    
    // Connect to terminal via HTTP/2 SSE (after terminal is ready)
    setTimeout(() => {
        connectTerminal();
        
        // Test terminal output after connection
        setTimeout(() => {
            if (!sessionReady) {
                terminal.write('\r\n\x1b[33m[Warning: No output received yet. Checking connection...]\x1b[0m\r\n');
            }
        }, 2000);
    }, 100); // Small delay to ensure terminal is fully initialized
}

function connectTerminal() {
    // Use EventSource for Server-Sent Events over HTTP/2
    // HTTP/2 provides better multiplexing than WebSockets for this use case
    debugLog('Connecting to terminal session:', terminalSessionId);
    sessionReady = false; // Reset session ready state
    eventSource = new EventSource(`/api/terminal/${terminalSessionId}`);
    
    // Optimized output batching for better performance
    let writeBuffer = '';
    let writeTimer = null;
    const BATCH_DELAY_MS = 8; // Small delay for batching rapid output
    const MAX_BUFFER_SIZE = 4096; // Flush if buffer gets too large
    
    const flushBuffer = () => {
        if (writeBuffer) {
            // Use requestAnimationFrame for smooth rendering
            requestAnimationFrame(() => {
                terminal.write(writeBuffer);
                writeBuffer = '';
            });
        }
        if (writeTimer) {
            clearTimeout(writeTimer);
            writeTimer = null;
        }
    };
    
    const scheduleFlush = () => {
        if (writeTimer) return;
        writeTimer = setTimeout(flushBuffer, BATCH_DELAY_MS);
    };
    
    eventSource.onopen = () => {
        debugLog('Terminal SSE connection opened');
        sessionReady = true;
        terminal.write('\x1b[32m[Terminal connected - waiting for shell...]\x1b[0m\r\n');
    };
    
    eventSource.onmessage = (event) => {
        try {
            const data = JSON.parse(event.data);
            debugLog('Received terminal data:', data.type, data.data ? data.data.substring(0, 50) : '');
            
            if (data.type === 'output') {
                sessionReady = true; // Session is ready when we receive output
                
                // Batch writes for better performance with rapid output
                writeBuffer += data.data;
                
                // Flush immediately if buffer is large (prevents lag with large outputs)
                if (writeBuffer.length >= MAX_BUFFER_SIZE) {
                    flushBuffer();
                } else {
                    // Schedule flush for small outputs (batches rapid small writes)
                    scheduleFlush();
                }
            } else if (data.type === 'connected') {
                debugLog('Terminal session connected');
                sessionReady = true;
                terminal.write('\x1b[33m[Shell starting...]\x1b[0m\r\n');
            } else if (data.type === 'error') {
                flushBuffer(); // Flush any pending output first
                terminal.write('\x1b[31m' + data.data + '\x1b[0m');
            } else if (data.type === 'exit') {
                flushBuffer(); // Flush any pending output first
                terminal.write('\r\n\x1b[33m[Session ended]\x1b[0m\r\n');
                sessionReady = false;
                eventSource.close();
            }
        } catch (e) {
            console.error('Error parsing terminal data:', e, event.data);
            flushBuffer(); // Flush buffer before error message
            terminal.write('\r\n\x1b[31m[Error parsing data]\x1b[0m\r\n');
        }
    };
    
    eventSource.onerror = (error) => {
        flushBuffer();
        console.error('Terminal connection error:', error, 'State:', eventSource.readyState);
        if (eventSource.readyState === EventSource.CONNECTING) {
            terminal.write('\r\n\x1b[33m[Connecting...]\x1b[0m\r\n');
        } else if (eventSource.readyState === EventSource.CLOSED) {
            terminal.write('\r\n\x1b[31m[Connection closed. Reconnecting...]\x1b[0m\r\n');
            sessionReady = false;
            setTimeout(() => {
                connectTerminal();
            }, 1000);
        }
    };
    
    // Flush buffer when page becomes visible (prevents lag when tab is switched back)
    document.addEventListener('visibilitychange', () => {
        if (!document.hidden) {
            flushBuffer();
        }
    });
    
    // Flush buffer on window focus (ensures output is up-to-date)
    window.addEventListener('focus', flushBuffer);
}

function sendTerminalInput(input) {
    if (!terminalSessionId) {
        console.error('No terminal session ID');
        return Promise.reject(new Error('No session ID'));
    }
    
    return fetch(`/api/terminal/${terminalSessionId}/input`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ input })
    })
    .then(res => {
        if (!res.ok) {
            return res.json().then(err => {
                throw new Error(err.error || 'Failed to send input');
            });
        }
        return res.json();
    })
    .then(data => {
        if (!data.success) {
            debugWarn('Input sent but server returned:', data);
        }
        return data;
    })
    .catch(err => {
        console.error('Error sending terminal input:', err);
        terminal.write('\r\n\x1b[31m[Error: Could not send input. Check console for details.]\x1b[0m\r\n');
        throw err;
    });
}

// Terminal resize function - Version 2.0 (no getOption calls)
function resizeTerminal() {
    // Safety checks - ensure terminal exists and is properly initialized
    if (!terminal) {
        debugWarn('resizeTerminal: terminal is not initialized');
        return;
    }
    
    // Check if terminal has the required properties (cols and rows)
    // NOTE: We use terminal.cols/rows directly, NOT terminal.getOption()
    if (typeof terminal.cols === 'undefined' || typeof terminal.rows === 'undefined') {
        debugWarn('resizeTerminal: terminal dimensions not available yet');
        return;
    }
    
    if (!terminalSessionId) {
        debugWarn('resizeTerminal: terminalSessionId is not set');
        return;
    }
    
    // Get actual terminal dimensions
    let cols, rows;
    try {
        // Use terminal's actual dimensions (set by FitAddon)
        cols = terminal.cols;
        rows = terminal.rows;
        
        // Validate dimensions
        if (!cols || !rows || cols < 10 || rows < 5) {
            debugWarn('resizeTerminal: Invalid dimensions, using defaults', { cols, rows });
            cols = cols || 80;
            rows = rows || 24;
        }
        
        const dimensions = { cols, rows };
        
        debugLog('Resizing terminal session:', dimensions);
        
        fetch(`/api/terminal/${terminalSessionId}/resize`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(dimensions)
        })
        .then(res => {
            if (!res.ok) {
                // If session not found, it might not be created yet - that's okay
                if (res.status === 404) {
                    debugWarn('Terminal session not found yet (may not be created). Will retry when session is ready.');
                    return null;
                }
                return res.json().then(err => {
                    throw new Error(err.error || 'Failed to resize terminal');
                });
            }
            return res.json();
        })
        .then(data => {
            if (data && data.success) {
                debugLog('Terminal resized successfully:', dimensions);
            }
        })
        .catch(err => {
            // Don't log 404 errors as they're expected if session isn't ready yet
            if (!err.message || !err.message.includes('Session not found')) {
                console.error('Error resizing terminal:', err);
            }
        });
    } catch (error) {
        console.error('Error in resizeTerminal:', error);
    }
}

function loadFileExplorer() {
    fetch('/api/files')
        .then(res => res.json())
        .then(files => {
            const fileList = document.getElementById('fileList');
            fileList.innerHTML = '';
            files.forEach(file => {
                const li = document.createElement('li');
                li.className = file.type;
                li.textContent = file.name;
                li.onclick = () => {
                    if (file.type === 'file') {
                        loadFile(file.path);
                    }
                };
                fileList.appendChild(li);
            });
        })
        .catch(err => console.error('Error loading files:', err));
}

function loadFile(filePath) {
    fetch(`/api/files/content?path=${encodeURIComponent(filePath)}`)
        .then(res => res.json())
        .then(data => {
            currentFilePath = filePath;
            const language = getLanguageFromPath(filePath);
            editor.setValue(data.content);
            monaco.editor.setModelLanguage(editor.getModel(), language);
            document.title = `HTTP/2 Editor - ${filePath}`;
        })
        .catch(err => {
            console.error('Error loading file:', err);
            alert('Error loading file: ' + err.message);
        });
}

function getLanguageFromPath(path) {
    const ext = path.split('.').pop().toLowerCase();
    const langMap = {
        'js': 'javascript',
        'ts': 'typescript',
        'py': 'python',
        'html': 'html',
        'css': 'css',
        'json': 'json',
        'md': 'markdown',
        'java': 'java',
        'cpp': 'cpp',
        'c': 'c',
        'go': 'go',
        'rs': 'rust',
        'php': 'php',
        'rb': 'ruby'
    };
    return langMap[ext] || 'plaintext';
}

function saveFile() {
    if (!currentFilePath) {
        const fileName = prompt('Enter file name:');
        if (!fileName) return;
        currentFilePath = fileName;
    }
    
    const content = editor.getValue();
    fetch('/api/files/save', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ path: currentFilePath, content })
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            alert('File saved successfully!');
            loadFileExplorer();
        }
    })
    .catch(err => {
        console.error('Error saving file:', err);
        alert('Error saving file: ' + err.message);
    });
}

function setupEventListeners() {
    document.getElementById('saveBtn').addEventListener('click', saveFile);
    document.getElementById('refreshFiles').addEventListener('click', loadFileExplorer);
    document.getElementById('clearTerminal').addEventListener('click', () => {
        if (terminal) {
            terminal.clear();
        }
    });
    
    // Terminal toggle button - maximize/restore
    const toggleTerminalBtn = document.getElementById('toggleTerminal');
    const terminalPanel = document.getElementById('terminalPanel');
    
    if (toggleTerminalBtn && terminalPanel) {
        let isMaximized = false;
        let savedHeight = '400px';
        
        // Save initial height
        const computedStyle = window.getComputedStyle(terminalPanel);
        savedHeight = computedStyle.height;
        
        toggleTerminalBtn.addEventListener('click', (e) => {
            e.stopPropagation(); // Prevent triggering header drag
            e.preventDefault();
            
            debugLog('Toggle button clicked, isMaximized:', isMaximized);
            debugLog('Current height:', terminalPanel.style.height || window.getComputedStyle(terminalPanel).height);
            
            if (isMaximized) {
                // Restore to saved height
                debugLog('Restoring to:', savedHeight);
                terminalPanel.style.height = savedHeight;
                terminalPanel.style.maxHeight = '90vh';
                toggleTerminalBtn.textContent = '⛶';
                toggleTerminalBtn.title = 'Maximize terminal';
                isMaximized = false;
            } else {
                // Save current height before maximizing
                savedHeight = terminalPanel.style.height || window.getComputedStyle(terminalPanel).height;
                debugLog('Saving height:', savedHeight, 'Maximizing to 85vh');
                // Maximize
                terminalPanel.style.height = '85vh';
                terminalPanel.style.maxHeight = '85vh';
                toggleTerminalBtn.textContent = '⛶';
                toggleTerminalBtn.title = 'Restore terminal size';
                isMaximized = true;
            }
            
            debugLog('New height:', terminalPanel.style.height);
            
            // Force a reflow and trigger resize
            terminalPanel.offsetHeight; // Force reflow
            setTimeout(() => {
                debugLog('Toggle: Fitting terminal, height:', terminalPanel.offsetHeight);
                handleTerminalResize();
            }, 150);
        });
        
        // Also listen for manual resize via CSS resize handle
        if (typeof ResizeObserver !== 'undefined') {
            const resizeObserver = new ResizeObserver((entries) => {
                for (const entry of entries) {
                    const newHeight = entry.contentRect.height;
                    debugLog('Terminal panel resized via CSS resize handle:', newHeight + 'px');
                    if (fitAddon && terminal && typeof terminal.cols !== 'undefined' && typeof terminal.rows !== 'undefined') {
                        fitAddon.fit();
                        resizeTerminal();
                    }
                }
            });
            resizeObserver.observe(terminalPanel);
        }
        
        // Also add a direct resize event listener as backup
        let resizeTimeout;
        const handleResize = () => {
            clearTimeout(resizeTimeout);
            resizeTimeout = setTimeout(() => {
                const currentHeight = terminalPanel.offsetHeight;
                debugLog('Terminal panel resize detected:', currentHeight + 'px');
                if (fitAddon && terminal && typeof terminal.cols !== 'undefined' && typeof terminal.rows !== 'undefined') {
                    requestAnimationFrame(() => {
                        fitAddon.fit();
                        resizeTerminal();
                    });
                }
            }, 16); // Reduced from 50ms for faster response
        };
        
        // Listen for CSS resize events (when user drags the resize handle)
        terminalPanel.addEventListener('mouseup', handleResize);
        terminalPanel.addEventListener('mousemove', (e) => {
            if (e.buttons === 1) { // Mouse button is pressed
                handleResize();
            }
        });
    }
    
    // Make terminal header draggable for resizing
    const terminalHeader = document.querySelector('.terminal-header');
    if (terminalHeader && terminalPanel) {
        let isResizing = false;
        let startY = 0;
        let startHeight = 0;
        
        terminalHeader.addEventListener('mousedown', (e) => {
            // Don't resize when clicking buttons or their children
            if (e.target.tagName === 'BUTTON' || e.target.closest('button')) {
                return;
            }
            
            isResizing = true;
            startY = e.clientY;
            startHeight = terminalPanel.offsetHeight;
            terminalPanel.classList.add('resized');
            document.body.style.cursor = 'ns-resize';
            document.body.style.userSelect = 'none';
            e.preventDefault();
            e.stopPropagation();
        });
        
        const handleMouseMove = (e) => {
            if (!isResizing) return;
            
            const deltaY = startY - e.clientY; // Inverted because we're dragging up
            const newHeight = Math.max(150, Math.min(window.innerHeight * 0.9, startHeight + deltaY));
            debugLog('Resizing terminal:', newHeight + 'px');
            terminalPanel.style.height = newHeight + 'px';
            terminalPanel.style.maxHeight = newHeight + 'px';
            
            // Force a reflow
            terminalPanel.offsetHeight;
            
            // Update terminal size in real-time with requestAnimationFrame
            if (fitAddon && terminal && typeof terminal.cols !== 'undefined' && typeof terminal.rows !== 'undefined') {
                requestAnimationFrame(() => {
                    fitAddon.fit();
                    resizeTerminal();
                });
            }
        };
        
        const handleMouseUp = () => {
            if (isResizing) {
                isResizing = false;
                document.body.style.cursor = '';
                document.body.style.userSelect = '';
            }
        };
        
        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);
        document.addEventListener('mouseleave', handleMouseUp); // Handle mouse leaving window
    }
    
    document.getElementById('themeSelect').addEventListener('change', (e) => {
        monaco.editor.setTheme(e.target.value);
    });
    document.getElementById('newFileBtn').addEventListener('click', () => {
        currentFilePath = null;
        editor.setValue('');
        monaco.editor.setModelLanguage(editor.getModel(), 'plaintext');
        document.title = 'HTTP/2 Editor';
    });
}

