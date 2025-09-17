#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/_rendered"
mkdir -p "$OUT"

render() {
  local type="$1"; shift
  local src="$1"; shift
  local base=$(basename "$src")
  local name="${base%.*}"
  # PNG
  curl -fsSL -H "Content-Type: text/plain" \
    --data-binary @"$src" \
    "https://kroki.io/${type}/png" > "$OUT/${name}.png"
  # SVG
  curl -fsSL -H "Content-Type: text/plain" \
    --data-binary @"$src" \
    "https://kroki.io/${type}/svg" > "$OUT/${name}.svg"
  echo "Rendered $src → $OUT/${name}.{png,svg}"
}

# ER
render mermaid "$ROOT/er.mmd"
# Flows
render mermaid "$ROOT/flows/barcode-seq.mmd"
render mermaid "$ROOT/flows/ocr-seq.mmd"

# Примечание: C4 (Structurizr) рендерьте в Structurizr (Lite/Cloud) → экспортируйте PNG/SVG.
