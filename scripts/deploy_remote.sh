#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/deploy_remote.sh user@host [--key /path/to/key] [--remote-path /some/path]
# Environment:
#  REMOTE_PATH - optional remote path override

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <user@host> [--key /path/to/key] [--remote-path /some/path]"
  exit 1
fi

TARGET="$1"
shift
SSH_KEY=""
REMOTE_PATH="/opt/lightRAG"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --key) SSH_KEY="$2"; shift 2; ;;
    --remote-path) REMOTE_PATH="$2"; shift 2; ;;
    *) echo "Unknown arg $1"; exit 1; ;;
  esac
done

if [ -n "$SSH_KEY" ]; then
  SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no"
else
  SSH_OPTS="-o StrictHostKeyChecking=no"
fi

HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP_TAR="/tmp/lightrag_deploy_$(date +%s).tar.gz"

echo "Packing repository..."
(cd "$HERE" && tar -czf "$TMP_TAR" \
  --exclude='./.git' \
  --exclude='./secrets' \
  --exclude='./node_modules' \
  --exclude='**/node_modules' \
  --exclude='**/playwright-report*' \
  --exclude='**/test-results' \
  --exclude='**/tmp' \
  --exclude='**/*.log' \
  --exclude='./runs' \
  --exclude='./sattva-stack.zip' \
  --exclude='./N8N.zip' \
  .)

echo "Copying archive to remote $TARGET:$REMOTE_PATH"
scp $SSH_OPTS "$TMP_TAR" "$TARGET:/tmp/" 

echo "Connecting to remote to prepare directories and extract"
ARCHIVE_NAME="$(basename "$TMP_TAR")"
ssh $SSH_OPTS "$TARGET" bash -lc "set -euo pipefail; \
  sudo mkdir -p '$REMOTE_PATH'; \
  sudo tar --no-same-owner -xzf '/tmp/$ARCHIVE_NAME' -C '$REMOTE_PATH'; \
  sudo chown -R \"\$(whoami):\$(whoami)\" '$REMOTE_PATH'"

echo "On remote: create docker networks if missing"
ssh $SSH_OPTS "$TARGET" bash -lc "docker network inspect proxy >/dev/null 2>&1 || docker network create --driver bridge proxy || true; docker network inspect backend >/dev/null 2>&1 || docker network create --driver bridge backend || true"

echo "On remote: ensure secrets dir exists — you must manually place secret files in $REMOTE_PATH/secrets or use scp to copy them"
ssh $SSH_OPTS "$TARGET" bash -lc "ls -la $REMOTE_PATH/secrets || true"

echo "Starting stack compose on remote (traefik + stack)"
ssh $SSH_OPTS "$TARGET" bash -lc "cd $REMOTE_PATH && docker compose -f stack/docker-compose.yml up -d"

echo "Starting optional infra compose (dashboard/keycloak) if present"
ssh $SSH_OPTS "$TARGET" bash -lc "cd $REMOTE_PATH && if [ -f infra/docker-compose.dashboard.yml ]; then docker compose -f infra/docker-compose.dashboard.yml up -d --build; else echo 'infra/docker-compose.dashboard.yml not found, skipping'; fi"

echo "Deploy finished. Check logs: ssh $TARGET 'docker compose -f $REMOTE_PATH/stack/docker-compose.yml logs -f traefik'"
