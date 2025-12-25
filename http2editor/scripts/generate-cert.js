import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import crypto from 'crypto';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const certsDir = path.join(__dirname, '..', 'certs');

// Create certs directory if it doesn't exist
if (!fs.existsSync(certsDir)) {
    fs.mkdirSync(certsDir, { recursive: true });
}

console.log('Generating SSL certificates for HTTPS...');

function generateCertWithOpenSSL() {
    const rootDir = path.join(__dirname, '..');
    
    // Generate private key
    execSync(
        'openssl genrsa -out certs/server.key 2048',
        { stdio: 'inherit', cwd: rootDir }
    );
    
    // Generate certificate signing request
    execSync(
        'openssl req -new -key certs/server.key -out certs/server.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"',
        { stdio: 'inherit', cwd: rootDir }
    );
    
    // Generate self-signed certificate
    execSync(
        'openssl x509 -req -days 365 -in certs/server.csr -signkey certs/server.key -out certs/server.crt',
        { stdio: 'inherit', cwd: rootDir }
    );
    
    // Clean up CSR file
    const csrPath = path.join(certsDir, 'server.csr');
    if (fs.existsSync(csrPath)) {
        fs.unlinkSync(csrPath);
    }
}

function generateCertWithNode() {
    console.log('Using Node.js crypto module to generate certificates...');
    
    // Generate key pair
    const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: { type: 'spki', format: 'pem' },
        privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
    });
    
    // For a proper certificate, we'd need to use a library like 'selfsigned'
    // For now, create a basic self-signed cert using openssl command
    // This is a fallback that creates minimal certs
    console.log('⚠️  Node.js crypto cannot create full certificates.');
    console.log('Please install OpenSSL or use mkcert for proper certificates.');
    throw new Error('OpenSSL not available');
}

try {
    // Try OpenSSL first
    generateCertWithOpenSSL();
    console.log('✅ SSL certificates generated successfully!');
    console.log('📁 Certificates saved in:', certsDir);
} catch (error) {
    console.error('❌ Error generating certificates with OpenSSL:', error.message);
    console.log('\n💡 Options to generate certificates:');
    console.log('\n1. Install OpenSSL:');
    console.log('   - Windows: Download from https://slproweb.com/products/Win32OpenSSL.html');
    console.log('   - macOS: brew install openssl');
    console.log('   - Linux: sudo apt-get install openssl');
    console.log('\n2. Use mkcert (recommended for trusted local certificates):');
    console.log('   - Install: https://github.com/FiloSottile/mkcert');
    console.log('   - Run: mkcert -install');
    console.log('   - Run: mkcert localhost');
    console.log('   - Copy localhost.pem to certs/server.crt');
    console.log('   - Copy localhost-key.pem to certs/server.key');
    console.log('\n3. Manual generation:');
    console.log('   Create certs/server.key and certs/server.crt manually');
    process.exit(1);
}

