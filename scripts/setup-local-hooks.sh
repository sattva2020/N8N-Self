#!/usr/bin/env bash
set -euo pipefail

# Installs local git hooks. Choose Husky (recommended) or legacy .githooks.
MODE=${1:-husky}
if [ "$MODE" = "husky" ]; then
  if [ ! -d ".husky" ]; then
    echo "Initializing Husky..."
    # create .husky directory if missing; user must have node and npx available
    npx --no-install husky install || true
  fi
  echo "Husky hooks initialized (run 'npx husky install' if missing)."
  echo "To switch to legacy hooks: ./scripts/setup-local-hooks.sh legacy"
  exit 0
fi

if [ "$MODE" = "legacy" ]; then
  if [ ! -d ".githooks" ]; then
    echo ".githooks directory not found. Make sure you run this from the repository root." >&2
    exit 1
  fi
  git config core.hooksPath .githooks
  chmod +x .githooks/pre-commit .githooks/pre-push .githooks/commit-msg || true
  echo "Installed legacy git hooks: core.hooksPath set to .githooks"
  echo "To uninstall: git config --unset core.hooksPath"
  exit 0
fi

echo "Unknown mode: $MODE. Use 'husky' (default) or 'legacy'"
exit 1
