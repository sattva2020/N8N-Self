#!/usr/bin/env bash
set -euo pipefail

# Simple renderer: finds .mmd and .dsl files under docs/architecture and posts to Kroki
OUT_DIR="$(pwd)/docs/architecture/out"
mkdir -p "$OUT_DIR"

KROKI_URL="${KROKI_URL:-https://kroki.io}"
STRUCTURIZR_CLI_JAR="${STRUCTURIZR_CLI_JAR:-}"

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
  local out_svg="$OUT_DIR/${base}.svg"
  echo "Rendering $src -> $out_png / $out_svg"
  if ! retry_post "$src" "$KROKI_URL/mermaid/png" "$out_png"; then
    echo "ERROR: rendering $src to PNG failed after retries"
  fi
  if ! retry_post "$src" "$KROKI_URL/mermaid/svg" "$out_svg"; then
    echo "ERROR: rendering $src to SVG failed after retries"
  fi
}

render_structurizr_via_export() {
  local src="$1" # .dsl
  local base=$(basename "$src" .dsl)
  local export_dir="$(pwd)/docs/architecture/.structurizr-export-${base}"
  rm -rf "$export_dir" && mkdir -p "$export_dir"
  echo "Exporting Structurizr DSL $src -> Mermaid into $export_dir"
  # Export all views into Mermaid files
  java -jar "$STRUCTURIZR_CLI_JAR" export -workspace "$src" -format mermaid -output "$export_dir"
  # Render each exported .mmd
  find "$export_dir" -type f -name '*.mmd' | while read -r mf; do
    render_mermaid "$mf"
  done
}

render_structurizr_fallback() {
  local src="$1"
  local base=$(basename "$src" .dsl)
  echo "Structurizr CLI not configured; copying $src into out/ for reference"
  cp "$src" "$OUT_DIR/"
}

# 1) Render all Mermaid sources under docs/architecture
find docs/architecture -type f -name '*.mmd' | while read -r f; do
  render_mermaid "$f" || echo "Warning: render failed for $f"
done

# 2) Structurizr: export to Mermaid if CLI is available, otherwise copy DSL
if [ -n "$STRUCTURIZR_CLI_JAR" ] && [ -f "$STRUCTURIZR_CLI_JAR" ]; then
  find docs/architecture -type f -name '*.dsl' | while read -r f; do
    render_structurizr_via_export "$f" || echo "Warning: structurizr export failed for $f"
  done
else
  find docs/architecture -type f -name '*.dsl' | while read -r f; do
    render_structurizr_fallback "$f"
  done
fi

echo "Done. Outputs in $OUT_DIR"
