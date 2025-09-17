#!/usr/bin/env bash
set -euo pipefail

# Helper: generate detect-secrets baseline if detect-secrets is installed.
if command -v detect-secrets >/dev/null 2>&1; then
  echo "Running detect-secrets to generate .secrets.baseline"
  detect-secrets scan > .secrets.baseline
  echo "Wrote .secrets.baseline. Review and commit to repository (or keep private)."
else
  echo "detect-secrets not found. Install with: pip install detect-secrets"
  echo "Then run: ./scripts/generate-detect-secrets-baseline.sh"
  exit 0
fi
