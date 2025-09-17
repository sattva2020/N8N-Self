#!/bin/sh
# Simple healthcheck: attempt HTTP GET to localhost:5678 and return 0 on <400
set -e

# Wait a tiny bit if needed
HOST=127.0.0.1
PORT=5678
URL="http://${HOST}:${PORT}/"

# Use node if available, else attempt wget/curl, else fail
if command -v node >/dev/null 2>&1; then
  node -e 'require("http").get("http://127.0.0.1:5678/", res => { process.exit(res.statusCode < 400 ? 0 : 1) }).on("error", () => process.exit(1))'
  exit $?
fi

if command -v curl >/dev/null 2>&1; then
  curl -f -sS "$URL" >/dev/null
  exit $?
fi

if command -v wget >/dev/null 2>&1; then
  wget -qO- "$URL" >/dev/null
  exit $?
fi

# If none available, exit 1
exit 1
