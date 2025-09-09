#!/usr/bin/env bash
# start the stack and deploy LightRAG
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE/stack"
# start core stack
docker compose pull || true
docker compose up -d
# deploy LightRAG (if present)
if [ -d "$HERE/LightRAG" ]; then
  echo "Deploying LightRAG..."
  (cd "$HERE/LightRAG" && docker compose pull || true && docker compose up -d)
fi

echo "Stack started."
