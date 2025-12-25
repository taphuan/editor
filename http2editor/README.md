# HTTP/2 Editor

An online code editor with integrated terminal support, optimized for HTTP/2 performance.

## Features

- 🚀 **HTTP/2 Support**: Built on HTTP/2 for faster, multiplexed connections
- 📝 **Monaco Editor**: Full-featured code editor with syntax highlighting
- 💻 **Terminal Integration**: Real-time terminal using Server-Sent Events over HTTP/2
- ⚡ **Performance Optimized**: Compression, caching, and HTTP/2 push optimizations
- 🔒 **HTTPS**: Secure connections with SSL/TLS

## Installation

### Prerequisites
- Node.js 18+ (ES modules support)
- OpenSSL (for certificate generation) or mkcert
- Windows: Visual Studio Build Tools (for node-pty native module)

### Steps

1. Install dependencies:
```bash
npm install
```

**Note for Windows users**: If `node-pty` fails to install, you may need:
- Visual Studio Build Tools: https://visualstudio.microsoft.com/downloads/
- Or use: `npm install --build-from-source node-pty`

2. Generate SSL certificates:
```bash
npm run generate-cert
```

Or manually create certificates in the `certs/` directory:
- `server.key` - Private key
- `server.crt` - Certificate

For trusted local certificates, use `mkcert`:
```bash
mkcert -install
mkcert localhost
# Copy files to certs/ directory
```

## Usage

### HTTPS Mode (Default - HTTP/2)
Start the server with HTTPS:
```bash
npm start
```

Or run in development mode with auto-reload:
```bash
npm run dev
```

Open your browser and navigate to:
```
https://localhost:8443
```

**Note**: You'll need to accept the self-signed certificate warning in your browser.

### HTTP Mode (Development - No Certificates Required)
Start the server in HTTP mode (no HTTPS):
```bash
npm run start:http
```

Or run in development mode:
```bash
npm run dev:http
```

Open your browser and navigate to:
```
http://localhost:8080
```

You can also use the `--http` flag directly:
```bash
node server.js --http
```

## Architecture

### HTTP/2 Optimizations

1. **Server-Sent Events (SSE)**: Terminal uses SSE over HTTP/2 instead of WebSockets for better multiplexing
2. **Compression**: Gzip compression for text-based content
3. **Caching**: Aggressive caching headers for static assets
4. **HTTP/2 Push**: Ready for HTTP/2 server push (can be enabled)
5. **Connection Multiplexing**: Multiple requests over single connection

### Terminal Performance

- **Buffering Disabled**: `X-Accel-Buffering: no` header for immediate output
- **Event Streaming**: Low-latency terminal updates via SSE
- **Efficient Rendering**: Optimized xterm.js configuration

## API Endpoints

- `GET /api/terminal/:sessionId` - SSE stream for terminal output
- `POST /api/terminal/:sessionId/input` - Send input to terminal
- `POST /api/terminal/:sessionId/resize` - Resize terminal
- `GET /api/files` - List files in directory
- `GET /api/files/content?path=...` - Get file content
- `POST /api/files/save` - Save file

## Browser Support

- Chrome/Edge: Full HTTP/2 support
- Firefox: Full HTTP/2 support
- Safari: Full HTTP/2 support

## Security Notes

- Self-signed certificates are used for development
- For production, use proper SSL certificates from a trusted CA
- Consider adding authentication and authorization

## License

MIT

