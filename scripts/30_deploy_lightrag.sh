#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
BASE_DIR="$PWD"

DOMAIN_NAME="$(grep -E '^DOMAIN_NAME=' stack/.env | cut -d= -f2)"
if [[ -z "${DOMAIN_NAME}" ]]; then echo "DOMAIN_NAME не найден в stack/.env"; exit 1; fi

# Clone/update LightRAG
if [[ -d LightRAG/.git ]]; then
  echo "==> Обновляю LightRAG..."
  (cd LightRAG && git pull --ff-only)
elif [[ -d LightRAG && -n "$(ls -A LightRAG 2>/dev/null)" ]]; then
  echo "Папка LightRAG существует и не пуста, но это не git. Переименовываю и клонирую заново."
  mv LightRAG "LightRAG.bak-$(date +%Y%m%d-%H%M%S)"
  git clone https://github.com/HKUDS/LightRAG.git LightRAG
else
  echo "==> Клонирую LightRAG..."
  git clone https://github.com/HKUDS/LightRAG.git LightRAG
fi

LR_API_KEY="$(cat "$BASE_DIR/secrets/lightrag_api_key")"
PG_PASS="$(tr -d '\n' < "$BASE_DIR/secrets/pgvector_password")"

# Сборка .env напрямую (без sed), чтобы не сломать спецсимволами
cat > "$BASE_DIR/LightRAG/.env" <<EOF
HOST=0.0.0.0
PORT=9621
WEBUI_TITLE=My Graph KB
WEBUI_DESCRIPTION=Simple and Fast Graph Based RAG System

LIGHTRAG_API_KEY=${LR_API_KEY}

LLM_BINDING=ollama
LLM_MODEL=llama3.1:8b-instruct-q8_0
LLM_BINDING_HOST=http://ollama:11434
OLLAMA_LLM_NUM_CTX=32768

EMBEDDING_BINDING=ollama
EMBEDDING_MODEL=nomic-embed-text
EMBEDDING_DIM=768
EMBEDDING_BINDING_HOST=http://ollama:11434
OLLAMA_EMBEDDING_NUM_CTX=8192

LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_DOC_STATUS_STORAGE=PGDocStatusStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=NetworkXStorage

POSTGRES_HOST=pgvector
POSTGRES_PORT=5432
POSTGRES_USER=lightrag
POSTGRES_PASSWORD=${PG_PASS}
POSTGRES_DATABASE=lightrag
POSTGRES_MAX_CONNECTIONS=12
POSTGRES_VECTOR_INDEX_TYPE=HNSW
POSTGRES_HNSW_M=16
POSTGRES_HNSW_EF=200
POSTGRES_IVFFLAT_LISTS=100
EOF

# override для сетей/Traefik/Basic-Auth
cp "$BASE_DIR/LightRAG_conf/docker-compose.override.yml" "$BASE_DIR/LightRAG/docker-compose.override.yml"
sed -i "s/{{DOMAIN_NAME}}/${DOMAIN_NAME}/g" "$BASE_DIR/LightRAG/docker-compose.override.yml"

# гарантируем наличие usersfile
mkdir -p "$BASE_DIR/LightRAG/secrets"
if [[ ! -f "$BASE_DIR/LightRAG/secrets/traefik_basicauth" ]]; then
  cp "$BASE_DIR/secrets/traefik_basicauth" "$BASE_DIR/LightRAG/secrets/traefik_basicauth"
fi

echo "==> Запуск LightRAG"
cd "$BASE_DIR/LightRAG"
docker compose up -d

CID="$(docker compose ps -q lightrag || true)"
if [[ -n "${CID}" ]]; then
  echo "==> Проверка DNS внутри контейнера (pgvector / ollama)"
  docker exec -it "$CID" getent hosts pgvector || true
  docker exec -it "$CID" getent hosts ollama || true
fi

echo
echo "==> Доступ к LightRAG:"
echo "URL: https://rag.${DOMAIN_NAME}/docs"
echo "Basic-Auth usersfile: LightRAG/secrets/traefik_basicauth"
