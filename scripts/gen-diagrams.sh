#!/usr/bin/env bash
set -euo pipefail

# Simple renderer: finds .mmd and .dsl files under docs/architecture and posts to Kroki
OUT_DIR="$(pwd)/docs/architecture/out"
mkdir -p "$OUT_DIR"

KROKI_URL="${KROKI_URL:-https://kroki.io}"

echo "Rendering diagrams to $OUT_DIR using Kroki at $KROKI_URL"

retry_post() {
  local src="$1"; shift
  local url="$1"; shift
  local out="$1"; shift

  local attempt=1
  local max=5
  local sleep_secs=1
  while [ $attempt -le $max ]; do
    if curl -sS -X POST -H "Content-Type: text/plain" --data-binary @"$src" "$url" -o "$out"; then
      return 0
    fi
    echo "Attempt $attempt failed for $src -> retrying in ${sleep_secs}s..."
    sleep $sleep_secs
    attempt=$((attempt+1))
    sleep_secs=$((sleep_secs * 2))
  done
  return 1
}

render_mermaid() {
  local src="$1"
  local base=$(basename "$src" .mmd)
  local out_png="$OUT_DIR/${base}.png"
  echo "Rendering $src -> $out_png"
  if ! retry_post "$src" "$KROKI_URL/mermaid/png" "$out_png"; then
    echo "ERROR: rendering $src failed after retries"
    return 1
  fi
}

render_structurizr() {
  local src="$1"
  local base=$(basename "$src" .dsl)
  local out_png="$OUT_DIR/${base}.png"
  echo "Note: Structurizr DSL rendering via Kroki is not supported; saving source to out for reference: $src -> $OUT_DIR/"
  cp "$src" "$OUT_DIR/"
}


find docs/architecture -type f -name '*.mmd' | while read -r f; do
  render_mermaid "$f" || echo "Warning: render failed for $f"
done

find docs/architecture -type f -name '*.dsl' | while read -r f; do
  render_structurizr "$f"
done

echo "Done. Outputs in $OUT_DIR"
