const http = require('http');
const path = require('path');
const fs = require('fs');

const root = path.resolve(__dirname, '..', 'dist');
const port = process.env.PORT || 5177;
const host = process.env.HOST || '0.0.0.0';

function getContentType(file) {
  if (file.endsWith('.html')) return 'text/html; charset=utf-8';
  if (file.endsWith('.js')) return 'application/javascript; charset=utf-8';
  if (file.endsWith('.css')) return 'text/css; charset=utf-8';
  if (file.endsWith('.json')) return 'application/json; charset=utf-8';
  if (file.endsWith('.svg')) return 'image/svg+xml';
  if (file.endsWith('.png')) return 'image/png';
  return 'application/octet-stream';
}

// Create and start a server; to avoid stale listeners we create a fresh server per attempt.
function createServerInstance() {
  return http.createServer((req, res) => {
    const requested = decodeURIComponent(req.url.split('?')[0]);
    let filePath = path.join(root, requested);
    if (!filePath.startsWith(root)) {
      res.statusCode = 403;
      res.end('Forbidden');
      return;
    }

    if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
      filePath = path.join(filePath, 'index.html');
    }

    if (!fs.existsSync(filePath)) {
      // fallback to index.html for SPA
      filePath = path.join(root, 'index.html');
    }

    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.statusCode = 500;
        res.end('Server error');
        return;
      }
      res.setHeader('Content-Type', getContentType(filePath));
      res.setHeader('Cache-Control', 'no-store');
      res.end(data);
    });
  });
}

const START_PORT = Number.isFinite(Number(port)) ? parseInt(port, 10) : 5177;
const MAX_PORT_TRIES = 10;
// If STRICT_PORT is set (truthy), fail fast instead of auto-incrementing ports.
const STRICT_PORT = !!(process.env.STRICT_PORT && process.env.STRICT_PORT !== '0');

function tryListen(listenHost, tryPort, attemptsLeft) {
  const server = createServerInstance();
  server.listen(tryPort, listenHost, () => {
    // ensure tmp dir exists and write served port for CI/debugging
    try {
      const tmpDir = path.join(__dirname, '..', 'tmp');
      if (!fs.existsSync(tmpDir)) fs.mkdirSync(tmpDir, { recursive: true });
      fs.writeFileSync(path.join(tmpDir, 'served-port'), String(tryPort), 'utf8');
    } catch (e) {
      // non-fatal
    }
    console.log(`simple-serve: serving ${root} at http://${listenHost}:${tryPort}/`);
  });

  server.once('error', (err) => {
    // If binding to 0.0.0.0 fails on some Windows environments, fall back to localhost
    if (err && err.code === 'EACCES' && listenHost === '0.0.0.0') {
      console.error('simple-serve bind to 0.0.0.0 failed with EACCES, retrying on 127.0.0.1');
      tryListen('127.0.0.1', tryPort, attemptsLeft);
      return;
    }

    // If port is in use or permission denied
    if (err && (err.code === 'EACCES' || err.code === 'EADDRINUSE')) {
      if (STRICT_PORT) {
        console.error(`Port ${tryPort} failed (${err.code}) and STRICT_PORT=true — failing fast.`);
        process.exit(2);
      }
      if (attemptsLeft > 0) {
        console.error(`Port ${tryPort} failed (${err.code}). Trying port ${tryPort + 1} (${attemptsLeft - 1} attempts left)`);
        // close server and retry on next port
        try {
          server.close(() => {
            tryListen(listenHost, tryPort + 1, attemptsLeft - 1);
          });
        } catch (closeErr) {
          // if close fails, still attempt next port
          tryListen(listenHost, tryPort + 1, attemptsLeft - 1);
        }
        return;
      }
    }

    // Detailed error logging to help debugging (print code, full error and stack)
    try {
      console.error('simple-serve error code:', err && err.code);
      console.error('simple-serve error object:', err);
      if (err && err.stack) console.error('simple-serve error stack:\n', err.stack);
    } catch (logErr) {
      console.error('simple-serve encountered an error and failed to log details:', logErr);
    }

    process.exit(1);
  });
}

// Start attempts: try the configured port and up to MAX_PORT_TRIES ports above it.
tryListen(host, START_PORT, MAX_PORT_TRIES);
