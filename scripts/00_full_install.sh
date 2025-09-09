#!/usr/bin/env bash
set -euo pipefail

# Full install helper: runs 10_prereqs.sh -> 20_bootstrap_stack.sh -> 30_deploy_lightrag.sh
# Usage (recommended):
# DOMAIN_NAME='example.com' ACME_EMAIL='me@example.com' bash scripts/00_full_install.sh
# Optional: PRUNE=true to run `docker system prune -a --volumes --force` before installing (dangerous)

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOGDIR="/var/log/n8n_install"
LOGFILE="$LOGDIR/install-$TIMESTAMP.log"

mkdir -p "$LOGDIR"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== Full install started: $TIMESTAMP ==="

# helpers
die(){ echo "ERROR: $*" >&2; echo "See $LOGFILE" >&2; exit 1; }
info(){ echo "[INFO] $*"; }

# ensure running from project root (script lives in scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# required env
: "${DOMAIN_NAME:?Please set DOMAIN_NAME env var (e.g. DOMAIN_NAME=example.com)}"
: "${ACME_EMAIL:?Please set ACME_EMAIL env var (e.g. ACME_EMAIL=you@example.com)}"

info "Project root: $PROJECT_ROOT"
info "Logging to: $LOGFILE"

# Optional destructive prune
if [ "${PRUNE:-false}" = "true" ]; then
  info "PRUNE=true -> performing full docker system prune (containers/images/volumes)"
  docker system prune -a --volumes --force || die "docker prune failed"
fi

# Backup secrets if present
if [ -d "$PROJECT_ROOT/secrets" ]; then
  BACKUP_DIR="$PROJECT_ROOT/secrets.bak.$TIMESTAMP"
  info "Backing up secrets -> $BACKUP_DIR"
  cp -a "$PROJECT_ROOT/secrets" "$BACKUP_DIR" || die "failed to backup secrets"
else
  info "No secrets dir found, skipping backup"
fi

# 1) prerequisites
if [ -x "$PROJECT_ROOT/scripts/10_prereqs.sh" ] || [ -f "$PROJECT_ROOT/scripts/10_prereqs.sh" ]; then
  info "Running prerequisites"
  bash "$PROJECT_ROOT/scripts/10_prereqs.sh" || die "10_prereqs.sh failed"
else
  die "scripts/10_prereqs.sh not found"
fi

# 2) bootstrap stack (pass DOMAIN_NAME & ACME_EMAIL)
if [ -x "$PROJECT_ROOT/scripts/20_bootstrap_stack.sh" ] || [ -f "$PROJECT_ROOT/scripts/20_bootstrap_stack.sh" ]; then
  info "Bootstrapping stack (DOMAIN_NAME=$DOMAIN_NAME ACME_EMAIL=$ACME_EMAIL)"
  DOMAIN_NAME="$DOMAIN_NAME" ACME_EMAIL="$ACME_EMAIL" bash "$PROJECT_ROOT/scripts/20_bootstrap_stack.sh" || die "20_bootstrap_stack.sh failed"
else
  die "scripts/20_bootstrap_stack.sh not found"
fi

# 3) deploy LightRAG
if [ -x "$PROJECT_ROOT/scripts/30_deploy_lightrag.sh" ] || [ -f "$PROJECT_ROOT/scripts/30_deploy_lightrag.sh" ]; then
  info "Deploying LightRAG"
  bash "$PROJECT_ROOT/scripts/30_deploy_lightrag.sh" || die "30_deploy_lightrag.sh failed"
else
  die "scripts/30_deploy_lightrag.sh not found"
fi

# 4) smoke tests (best-effort)
if [ -x "$PROJECT_ROOT/tests/smoke/test_start_header.sh" ] || [ -f "$PROJECT_ROOT/tests/smoke/test_start_header.sh" ]; then
  info "Running smoke tests"
  bash "$PROJECT_ROOT/tests/smoke/test_start_header.sh" || info "smoke tests returned non-zero"
else
  info "No smoke tests found, skipping"
fi

info "Full install finished. Tail of log:"
tail -n 200 "$LOGFILE" || true

echo "=== Finished: $TIMESTAMP ==="

echo "Log saved to: $LOGFILE"

exit 0
