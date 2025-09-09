#!/usr/bin/env bash
# Generate minimal secrets into ./secrets (local). Overwrites existing files with caution.
set -euo pipefail

SECRETS_DIR="$(cd "$(dirname "$0")/.." && pwd)/secrets"
mkdir -p "$SECRETS_DIR"

echo "Generating secrets in $SECRETS_DIR"

# n8n db password
if [ -f "$SECRETS_DIR/n8n_db_password" ]; then
  echo "n8n_db_password already exists — skipping"
else
  head -c 24 /dev/urandom | base64 | tr -d '\n' > "$SECRETS_DIR/n8n_db_password"
  echo "created n8n_db_password"
fi

# n8n encryption key
if [ -f "$SECRETS_DIR/n8n_encryption_key" ]; then
  echo "n8n_encryption_key already exists — skipping"
else
  head -c 32 /dev/urandom | base64 | tr -d '\n' > "$SECRETS_DIR/n8n_encryption_key"
  echo "created n8n_encryption_key"
fi

# pgvector password
if [ -f "$SECRETS_DIR/pgvector_password" ]; then
  echo "pgvector_password already exists — skipping"
else
  head -c 24 /dev/urandom | base64 | tr -d '\n' > "$SECRETS_DIR/pgvector_password"
  echo "created pgvector_password"
fi

# oauth2-proxy secrets (client secret and cookie secret)
if [ -f "$SECRETS_DIR/OAUTH2_PROXY_CLIENT_SECRET" ]; then
  echo "OAUTH2_PROXY_CLIENT_SECRET exists — skipping"
else
  head -c 32 /dev/urandom | base64 | tr -d '\n' > "$SECRETS_DIR/OAUTH2_PROXY_CLIENT_SECRET"
  echo "created OAUTH2_PROXY_CLIENT_SECRET"
fi

if [ -f "$SECRETS_DIR/OAUTH2_PROXY_COOKIE_SECRET" ]; then
  echo "OAUTH2_PROXY_COOKIE_SECRET exists — skipping"
else
  # oauth2-proxy expects 16/24/32 bytes base64
  head -c 24 /dev/urandom | base64 | tr -d '\n' > "$SECRETS_DIR/OAUTH2_PROXY_COOKIE_SECRET"
  echo "created OAUTH2_PROXY_COOKIE_SECRET"
fi

# traefik basic auth - create htpasswd entry if htpasswd available
if [ -f "$SECRETS_DIR/traefik_basicauth" ]; then
  echo "traefik_basicauth exists — skipping"
else
  if command -v htpasswd >/dev/null 2>&1; then
    read -p "Enter username for Traefik basic auth: " TF_USER
    htpasswd -B -c "$SECRETS_DIR/traefik_basicauth" "$TF_USER"
    echo "created traefik_basicauth with user $TF_USER"
  else
    echo "htpasswd not found — writing placeholder to $SECRETS_DIR/traefik_basicauth" 
    echo "# Replace with htpasswd content: user:bcrypt_hash" > "$SECRETS_DIR/traefik_basicauth"
  fi
fi

echo "Secrets generation complete. Review $SECRETS_DIR and commit only templates, not secrets."
