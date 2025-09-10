const http = require('http')
const path = require('path')
const fs = require('fs')

const root = path.resolve(__dirname, '..', 'dist')
const port = process.env.PORT || 5175
const host = process.env.HOST || '0.0.0.0'

function getContentType(file) {
  if (file.endsWith('.html')) return 'text/html; charset=utf-8'
  if (file.endsWith('.js')) return 'application/javascript; charset=utf-8'
  if (file.endsWith('.css')) return 'text/css; charset=utf-8'
  if (file.endsWith('.json')) return 'application/json; charset=utf-8'
  if (file.endsWith('.svg')) return 'image/svg+xml'
  if (file.endsWith('.png')) return 'image/png'
  return 'application/octet-stream'
}

const server = http.createServer((req, res) => {
  const requested = decodeURIComponent(req.url.split('?')[0])
  let filePath = path.join(root, requested)
  if (!filePath.startsWith(root)) {
    res.statusCode = 403
    res.end('Forbidden')
    return
  }

  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
    filePath = path.join(filePath, 'index.html')
  }

  if (!fs.existsSync(filePath)) {
    // fallback to index.html for SPA
    filePath = path.join(root, 'index.html')
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.statusCode = 500
      res.end('Server error')
      return
    }
    res.setHeader('Content-Type', getContentType(filePath))
    res.setHeader('Cache-Control', 'no-store')
    res.end(data)
  })
})

server.listen(port, host, () => {
  console.log(`simple-serve: serving ${root} at http://${host}:${port}/`)
})

server.on('error', (err) => {
  console.error('simple-serve error:', err && err.code ? err.code : err)
  process.exit(1)
})
