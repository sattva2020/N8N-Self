#!/usr/bin/env bash
set -euo pipefail

# Smoke test: проверяет доступность Traefik dashboard /docs LightRAG
BASE_DIR="$(dirname "${BASH_SOURCE[0]}")/../.."
STACK_DIR="$BASE_DIR/stack"

DOMAIN_NAME="${DOMAIN_NAME:-localhost}"

echo "==> Smoke test: проверка Traefik и LightRAG endpoints"

# Проверка Traefik (должен быть проксирован через HTTPS)
echo -n "Checking Traefik dashboard... "
if curl -k --max-time 10 -sS "https://traefik.${DOMAIN_NAME}/" >/dev/null; then
  echo "OK"
else
  echo "FAIL"
  exit 2
fi

# Проверка LightRAG /docs
echo -n "Checking LightRAG /docs... "
if curl -k --max-time 10 -sS "https://rag.${DOMAIN_NAME}/docs" | grep -q "Swagger"; then
  echo "OK"
else
  echo "WARN: /docs не вернул ожидаемый Swagger (возможно, BasicAuth или сервис не поднят)"
fi

echo "Smoke test finished."

exit 0
