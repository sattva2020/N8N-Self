#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
BASE_DIR="$PWD"

echo "==> Параметры:"
DOMAIN_NAME="${DOMAIN_NAME:-}"
ACME_EMAIL="${ACME_EMAIL:-}"
TZ="${TZ:-Europe/Kyiv}"

# Проверки: docker и docker compose
check_command(){ command -v "$1" >/dev/null 2>&1; }
if ! check_command docker; then
	echo "ERROR: Docker не найден в PATH. Установите Docker и повторите." >&2
	exit 1
fi

# Проверим, что демон Docker работает
if ! docker info >/dev/null 2>&1; then
	echo "ERROR: Docker демoн не отвечает. Убедитесь, что Docker запущен." >&2
	exit 1
fi

COMPOSE_CMD=""
if docker compose version >/dev/null 2>&1; then
	COMPOSE_CMD="docker compose"
elif check_command docker-compose; then
	COMPOSE_CMD="docker-compose"
else
	echo "ERROR: Docker Compose (docker compose или docker-compose) не найден." >&2
	exit 1
fi

if [[ -z "${DOMAIN_NAME}" ]]; then read -rp "DOMAIN_NAME (напр. sattva-ai.top): " DOMAIN_NAME; fi
if [[ -z "${ACME_EMAIL}" ]]; then read -rp "ACME_EMAIL (почта для Let's Encrypt): " ACME_EMAIL; fi

# stack/.env
cat > "$BASE_DIR/stack/.env" <<EOF
DOMAIN_NAME=${DOMAIN_NAME}
ACME_EMAIL=${ACME_EMAIL}
TZ=${TZ}
EOF

umask 077
mkdir -p "$BASE_DIR/secrets"

gen_b64(){ openssl rand -base64 24 | tr -d '\n'; }
gen_hex(){ openssl rand -hex 32 | tr -d '\n'; }

[[ -f "$BASE_DIR/secrets/pgvector_password" ]] || printf "%s" "$(gen_b64)" > "$BASE_DIR/secrets/pgvector_password"
[[ -f "$BASE_DIR/secrets/n8n_db_password"   ]] || printf "%s" "$(gen_b64)" > "$BASE_DIR/secrets/n8n_db_password"
[[ -f "$BASE_DIR/secrets/n8n_encryption_key" ]] || printf "%s" "$(gen_hex)" > "$BASE_DIR/secrets/n8n_encryption_key"
[[ -f "$BASE_DIR/secrets/lightrag_api_key"  ]] || printf "%s" "$(gen_hex)" > "$BASE_DIR/secrets/lightrag_api_key"

echo "==> Basic-Auth для LightRAG"
mkdir -p "$BASE_DIR/LightRAG/secrets"
LR_BASIC_PASS="$(gen_b64)"
htpasswd -nbB admin "${LR_BASIC_PASS}" > "$BASE_DIR/LightRAG/secrets/traefik_basicauth"
cp "$BASE_DIR/LightRAG/secrets/traefik_basicauth" "$BASE_DIR/secrets/traefik_basicauth"

echo "==> Поднимаю базовый стек (Traefik, n8n, Redis, n8n-Postgres, Ollama, pgvector)"
cd "$BASE_DIR/stack"
${COMPOSE_CMD} up -d

echo
echo "==> Готово."
echo "DOMAIN_NAME=${DOMAIN_NAME}"
echo "ACME_EMAIL=${ACME_EMAIL}"
echo "TZ=${TZ}"
echo "LightRAG Basic-Auth: user=admin pass=${LR_BASIC_PASS}"
echo "LightRAG API key: $(cat "$BASE_DIR/secrets/lightrag_api_key")"
echo
echo "Не забудьте создать DNS A-записи: rag.${DOMAIN_NAME}, n8n.${DOMAIN_NAME}, traefik.${DOMAIN_NAME}"
