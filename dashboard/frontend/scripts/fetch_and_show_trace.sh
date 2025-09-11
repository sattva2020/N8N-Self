#!/usr/bin/env bash
set -euo pipefail

# Usage: fetch_and_show_trace.sh <URL-or-local-zip>
# If argument is a URL (http/https), downloads to /tmp/playwright_trace.zip
# Then runs: npx playwright show-trace <zip>

ZIP="$1"

if [[ -z "$ZIP" ]]; then
  echo "Usage: $0 <URL-or-local-zip>" >&2
  exit 2
fi

TMPZIP="$PWD/trace_to_show.zip"

if [[ "$ZIP" =~ ^https?:// ]]; then
  echo "Downloading $ZIP -> $TMPZIP"
  if command -v curl >/dev/null 2>&1; then
    curl -fL "$ZIP" -o "$TMPZIP"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$TMPZIP" "$ZIP"
  else
    echo "Neither curl nor wget found. Install one to download artifacts." >&2
    exit 3
  fi
else
  if [[ ! -f "$ZIP" ]]; then
    echo "File not found: $ZIP" >&2
    exit 4
  fi
  cp "$ZIP" "$TMPZIP"
fi

echo "Opening trace with Playwright show-trace: $TMPZIP"
# prefer local node_modules playwright if present
if [[ -x "./node_modules/.bin/playwright" ]]; then
  ./node_modules/.bin/playwright show-trace "$TMPZIP"
else
  npx playwright show-trace "$TMPZIP"
fi
