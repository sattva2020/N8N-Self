#!/usr/bin/env node
const http = require('http')
const fs = require('fs')
const path = require('path')

const argv = require('minimist')(process.argv.slice(2))
const port = argv.port || argv.p || 5175
// Default to 0.0.0.0 which works well in CI and avoids some Windows/WSL bind restrictions.
// Allow overriding with --host if needed (e.g., --host 127.0.0.1).
const host = argv.host || '0.0.0.0'
const root = path.resolve(__dirname, '..', 'dist')

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
}

const server = http.createServer((req, res) => {
  try {
    let urlPath = decodeURIComponent(new URL(req.url, `http://${req.headers.host}`).pathname)
    if (urlPath === '/') urlPath = '/index.html'
    const filePath = path.join(root, urlPath)
    if (!filePath.startsWith(root)) {
      res.statusCode = 403
      res.end('Forbidden')
      return
    }
    fs.stat(filePath, (err, stats) => {
      if (err || !stats.isFile()) {
        res.statusCode = 404
        res.end('Not found')
        return
      }
      const ext = path.extname(filePath)
      res.setHeader('Content-Type', mime[ext] || 'application/octet-stream')
      const stream = fs.createReadStream(filePath)
      stream.pipe(res)
    })
  } catch (e) {
    res.statusCode = 500
    res.end('Server error')
  }
})

function startServer(listenHost) {
  server.listen(port, listenHost, () => {
    console.log(`Serving ${root} at http://${listenHost}:${port}/`)
  })
}

let triedFallback = false

startServer(host)
server.on('error', (err) => {
  if (err && err.code === 'EACCES') {
    if (!triedFallback && host !== '0.0.0.0') {
      // Try a single fallback; avoid infinite retry loops.
      triedFallback = true
      const fallback = '0.0.0.0'
      console.warn(`Permission denied binding to ${host}:${port}, retrying on ${fallback}`)
      startServer(fallback)
      return
    }
    console.error(`Permission denied binding to port ${port} (host tried: ${host}${triedFallback ? ', fallback attempted' : ''}).`)
    console.error('If this persists locally, try: run PowerShell as Administrator, or start the server with --host 0.0.0.0')
    process.exit(1)
  } else {
    console.error('Server error', err)
    process.exit(1)
  }
})
