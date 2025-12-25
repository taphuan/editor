import express from 'express';
import http2 from 'http2';
import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import compression from 'compression';
import pty from 'node-pty';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ============================================================================
// LOGGING CONFIGURATION
// ============================================================================
// Set DEBUG_LOGGING to true to enable all debug console output
// When false (default), only startup messages and critical errors are logged
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

// Parse command line arguments
const args = process.argv.slice(2);
const useHttp = args.includes('--http') || args.includes('-h');
const PORT = process.env.PORT || 3000;

const app = express();

// Enable compression for better performance
app.use(compression({
  level: 6,
  threshold: 1024,
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  }
}));

// Serve static files with HTTP/2 optimizations
app.use(express.static('public', {
  maxAge: '1d',
  etag: true,
  lastModified: true,
  setHeaders: (res, filePath) => {
    // Aggressive caching for static assets
    if (filePath.endsWith('.js') || filePath.endsWith('.css')) {
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    }
    // HTTP/2 optimizations
    res.setHeader('Link', '</styles.css>; rel=preload; as=style, </app.js>; rel=preload; as=script');
  }
}));


// Store active terminal sessions
const terminalSessions = new Map();

// Terminal endpoint - HTTP/2 Server-Sent Events
app.get('/api/terminal/:sessionId', (req, res) => {
  const { sessionId } = req.params;
  
  // Set headers for SSE over HTTP/2
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no'); // Disable buffering for faster rendering
  res.setHeader('Access-Control-Allow-Origin', '*'); // CORS for development
  
  // Send initial connection message
  res.write(`data: ${JSON.stringify({ type: 'connected' })}\n\n`);
  
  // Create new terminal session if doesn't exist
  if (!terminalSessions.has(sessionId)) {
    debugLog(`Creating new terminal session: ${sessionId}`);
    const shell = process.platform === 'win32' ? 'powershell.exe' : process.env.SHELL || 'bash';
    const shellArgs = process.platform === 'win32' ? ['-NoLogo'] : [];
    
    const ptyProcess = pty.spawn(shell, shellArgs, {
      name: 'xterm-256color',
      cols: 80,
      rows: 24,
      cwd: process.cwd(),
      env: { ...process.env, TERM: 'xterm-256color', COLORTERM: 'truecolor' }
    });

    // Handle terminal output - optimized for low latency
    ptyProcess.onData((data) => {
      debugLog(`Terminal output (${sessionId}):`, data.substring(0, 50));
      if (res && !res.destroyed) {
        try {
          const message = `data: ${JSON.stringify({ type: 'output', data })}\n\n`;
          res.write(message);
          // Aggressive flushing for low latency
          if (res.flush && typeof res.flush === 'function') {
            res.flush();
          } else if (res.stream && typeof res.stream.flush === 'function') {
            // HTTP/2 stream flush
            res.stream.flush();
          }
        } catch (err) {
          debugError('Error writing to SSE stream:', err);
        }
      } else {
        // Response is destroyed, try to update it
        const session = terminalSessions.get(sessionId);
        if (session && session.res && !session.res.destroyed) {
          try {
            const message = `data: ${JSON.stringify({ type: 'output', data })}\n\n`;
            session.res.write(message);
            // Flush updated stream
            if (session.res.flush && typeof session.res.flush === 'function') {
              session.res.flush();
            } else if (session.res.stream && typeof session.res.stream.flush === 'function') {
              session.res.stream.flush();
            }
          } catch (err) {
            debugError('Error writing to updated SSE stream:', err);
          }
        }
      }
    });

    ptyProcess.onExit(({ exitCode, signal }) => {
      if (res && !res.destroyed) {
        res.write(`data: ${JSON.stringify({ type: 'exit', exitCode, signal })}\n\n`);
        res.end();
      }
      terminalSessions.delete(sessionId);
      debugLog(`Terminal session ended: ${sessionId}`);
    });

    terminalSessions.set(sessionId, { pty: ptyProcess, res });
    debugLog(`Terminal session created: ${sessionId}`);
    
    // Force shell to output prompt by sending a newline after a short delay
    setTimeout(() => {
      if (ptyProcess && !ptyProcess.killed) {
        // Send a newline to trigger shell prompt
        ptyProcess.write('\r\n');
      }
    }, 100);
  } else {
    // Update response reference for existing session
    const session = terminalSessions.get(sessionId);
    if (session) {
      session.res = res;
      debugLog(`Updated response for existing session: ${sessionId}`);
    }
  }

  const session = terminalSessions.get(sessionId);
  
  // Handle client disconnect
  req.on('close', () => {
    debugLog(`Client disconnected from session: ${sessionId}`);
    // Don't kill the session on disconnect, allow reconnection
    // Only update the response reference
    if (session) {
      session.res = null;
    }
  });
  
  req.on('error', (err) => {
    debugError(`Error on SSE connection for session ${sessionId}:`, err);
  });
});

// Terminal input endpoint
app.post('/api/terminal/:sessionId/input', express.json(), (req, res) => {
  const { sessionId } = req.params;
  const { input } = req.body;
  
  if (!input) {
    return res.status(400).json({ error: 'Input is required' });
  }
  
  const session = terminalSessions.get(sessionId);
  if (session && session.pty) {
    try {
      session.pty.write(input);
      debugLog(`Input sent to session ${sessionId}:`, JSON.stringify(input));
      res.json({ success: true });
    } catch (err) {
      debugError(`Error writing to pty for session ${sessionId}:`, err);
      res.status(500).json({ error: 'Failed to write to terminal' });
    }
  } else {
    debugWarn(`Session not found: ${sessionId}`);
    res.status(404).json({ error: 'Session not found. Please refresh the page.' });
  }
});

// Resize terminal endpoint
app.post('/api/terminal/:sessionId/resize', express.json(), (req, res) => {
  const { sessionId } = req.params;
  const { cols, rows } = req.body;
  
  const session = terminalSessions.get(sessionId);
  if (session && session.pty) {
    session.pty.resize(cols, rows);
    res.json({ success: true });
  } else {
    res.status(404).json({ error: 'Session not found' });
  }
});

// File operations API
app.get('/api/files', (req, res) => {
  const dir = req.query.path || '.';
  try {
    const files = fs.readdirSync(dir, { withFileTypes: true }).map(dirent => ({
      name: dirent.name,
      type: dirent.isDirectory() ? 'directory' : 'file',
      path: path.join(dir, dirent.name)
    }));
    res.json(files);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/files/content', (req, res) => {
  const filePath = req.query.path;
  if (!filePath) {
    return res.status(400).json({ error: 'Path required' });
  }
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    res.json({ content });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/files/save', express.json(), (req, res) => {
  const { path: filePath, content } = req.body;
  if (!filePath || content === undefined) {
    return res.status(400).json({ error: 'Path and content required' });
  }
  try {
    fs.writeFileSync(filePath, content, 'utf8');
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create server based on mode
let server;

if (useHttp) {
  // HTTP mode - simple HTTP/1.1 server
  console.log('🌐 Running in HTTP mode (no HTTPS)');
  server = http.createServer(app);
  
  server.listen(PORT, () => {
    console.log(`🚀 HTTP Editor Server running on http://localhost:${PORT}`);
    console.log(`📝 Editor: http://localhost:${PORT}`);
    console.log(`⚡ Terminal optimized for fast rendering`);
    console.log(`⚠️  Note: Running without HTTPS (development only)`);
  });
} else {
  // HTTPS mode - HTTP/2 secure server
  const keyPath = path.join(__dirname, 'certs', 'server.key');
  const certPath = path.join(__dirname, 'certs', 'server.crt');

  if (!fs.existsSync(keyPath) || !fs.existsSync(certPath)) {
    console.error('❌ SSL certificates not found!');
    console.log('📝 Please generate certificates first:');
    console.log('   npm run generate-cert');
    console.log('\n💡 Or run in HTTP mode: npm start -- --http');
    console.log('   Or manually create certs/server.key and certs/server.crt');
    process.exit(1);
  }

  let options;
  try {
    options = {
      key: fs.readFileSync(keyPath),
      cert: fs.readFileSync(certPath),
      allowHTTP1: true // Allow HTTP/1.1 fallback
    };
  } catch (error) {
    console.error('❌ Error loading SSL certificates:', error.message);
    process.exit(1);
  }

  // Create HTTP/2 secure server with Express
  server = http2.createSecureServer(options, (req, res) => {
    // Handle HTTP/2 push for critical resources
    if (req.url === '/' && res.stream) {
      try {
        const stylesPath = path.join(__dirname, 'public', 'styles.css');
        const appJsPath = path.join(__dirname, 'public', 'app.js');
        
        if (fs.existsSync(stylesPath)) {
          res.stream.pushStream({ ':path': '/styles.css' }, (err, pushStream) => {
            if (!err) {
              pushStream.respond({ 'content-type': 'text/css' });
              pushStream.end(fs.readFileSync(stylesPath));
            }
          });
        }
        
        if (fs.existsSync(appJsPath)) {
          res.stream.pushStream({ ':path': '/app.js' }, (err, pushStream) => {
            if (!err) {
              pushStream.respond({ 'content-type': 'application/javascript' });
              pushStream.end(fs.readFileSync(appJsPath));
            }
          });
        }
      } catch (err) {
        // Push failed, continue normally
      }
    }
    
    // Delegate to Express
    app(req, res);
  });

  server.listen(PORT, () => {
    console.log(`🚀 HTTP/2 Editor Server running on https://localhost:${PORT}`);
    console.log(`📝 Editor: https://localhost:${PORT}`);
    console.log(`🔒 Using HTTP/2 with HTTPS`);
    console.log(`⚡ Terminal optimized for fast rendering`);
  });
}

server.on('error', (err) => {
  console.error('❌ Server error:', err.message);
});

