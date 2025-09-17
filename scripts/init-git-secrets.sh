#!/usr/bin/env bash
set -euo pipefail

# Initialize git-secrets (if installed) and add common patterns
if command -v git-secrets >/dev/null 2>&1; then
  git secrets --install || true
  git secrets --register-aws || true
  echo "git-secrets installed and AWS patterns added"
else
  echo "git-secrets not found. Install it: https://github.com/awslabs/git-secrets"
fi

# Alternatively, detect-secrets: show command to run locally
if command -v detect-secrets >/dev/null 2>&1; then
  echo "detect-secrets is available. Run 'detect-secrets scan > .secrets.baseline' to create baseline."
else
  echo "detect-secrets is not installed. To use it, install via pip: pip install detect-secrets"
fi
