# Setup Guide

## Quick Start

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Generate SSL Certificates**
   ```bash
   npm run generate-cert
   ```
   
   If OpenSSL is not available, you can use `mkcert`:
   ```bash
   # Install mkcert (one-time)
   # Windows: choco install mkcert
   # macOS: brew install mkcert
   # Linux: See https://github.com/FiloSottile/mkcert
   
   mkcert -install
   mkcert localhost
   # Copy localhost.pem to certs/server.crt
   # Copy localhost-key.pem to certs/server.key
   ```

3. **Start the Server**
   ```bash
   npm start
   ```

4. **Open in Browser**
   Navigate to: `https://localhost:8443`
   
   **Note**: Accept the self-signed certificate warning in your browser.

## Performance Optimizations

### HTTP/2 Features
- **Multiplexing**: Multiple requests over single connection
- **Server Push**: Critical resources pushed proactively
- **Header Compression**: Reduced overhead
- **Server-Sent Events**: Terminal streaming over HTTP/2

### Terminal Optimizations
- **Batched Writes**: Small writes are batched for better performance
- **Canvas Renderer**: Uses canvas for faster rendering
- **Limited Scrollback**: Reduced memory usage
- **No Buffering**: Immediate output with `X-Accel-Buffering: no`

### Caching Strategy
- Static assets: 1 year cache with immutable flag
- Dynamic content: No cache
- Terminal stream: No cache (SSE)

## Troubleshooting

### Certificate Issues
- Ensure `certs/server.key` and `certs/server.crt` exist
- Check file permissions
- Regenerate certificates if expired

### Terminal Not Working
- Check browser console for errors
- Verify HTTP/2 connection (check Network tab)
- Ensure `node-pty` is installed correctly

### Performance Issues
- Check browser DevTools Network tab for HTTP/2
- Verify compression is enabled
- Monitor terminal output rate

## Development

Run with auto-reload:
```bash
npm run dev
```

## Production Considerations

1. **Use Proper SSL Certificates**: Replace self-signed certs with CA-signed certificates
2. **Add Authentication**: Implement user authentication
3. **Rate Limiting**: Add rate limiting for API endpoints
4. **Security Headers**: Add security headers (CSP, HSTS, etc.)
5. **Monitoring**: Add logging and monitoring
6. **Resource Limits**: Set terminal session limits

