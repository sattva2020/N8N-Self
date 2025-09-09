#!/usr/bin/env bash
# Usage: ./import_realm.sh
# Requires: curl, jq
set -euo pipefail
HOST=${1:-http://localhost:8081}
ADMIN_USER=${2:-admin}
ADMIN_PASS=${3:-admin}
REALM_JSON="/work/realm-dashboard.json"

echo "Waiting for Keycloak at $HOST..."
until curl -sS "$HOST/" >/dev/null 2>&1; do sleep 1; done

TOKEN=$(curl -sS -X POST "$HOST/realms/master/protocol/openid-connect/token" \
  -d "username=$ADMIN_USER" \
  -d "password=$ADMIN_PASS" \
  -d 'grant_type=password' \
  -d 'client_id=admin-cli' | jq -r .access_token)

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Failed to get admin token" >&2
  exit 2
fi

echo "Posting realm..."
curl -sS -X POST "$HOST/admin/realms" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary @infra/keycloak/realm-dashboard.json

echo "Done."
