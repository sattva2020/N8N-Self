# Sattva AI — n8n + LightRAG stack

Разворачивается в `/opt/N8N` и включает:
- Traefik (HTTPS + Let’s Encrypt)
- PostgreSQL для n8n
- Redis
- n8n
- Ollama
- pgvector (PostgreSQL с расширением `vector` для LightRAG)
- Деплой LightRAG (через docker compose override) + Traefik + Basic‑Auth

## Быстрый старт (Ubuntu 24.04)
```bash
sudo mkdir -p /opt/N8N
sudo chown -R $USER:$USER /opt/N8N
cd /opt/N8N

# распакуй архив сюда (появятся папки: stack, scripts, pgvector_init, LightRAG_conf)
bash scripts/10_prereqs.sh

# создаст stack/.env, секреты без \n, поднимет базовый стек
bash scripts/20_bootstrap_stack.sh

# клонирует/обновит LightRAG, соберёт .env, положит override, запустит
bash scripts/30_deploy_lightrag.sh
```

После запуска:
- Swagger LightRAG: `https://rag.$DOMAIN_NAME/docs` (защищено Basic‑Auth)
- n8n: `https://n8n.$DOMAIN_NAME`
- Traefik dashboard: `https://traefik.$DOMAIN_NAME` (без auth — при необходимости добавьте)

**DNS:** Создайте A-записи `rag.$DOMAIN_NAME`, `n8n.$DOMAIN_NAME`, `traefik.$DOMAIN_NAME` на публичный IP сервера.

## Порты и DNS (пару заметок для новичков)

- Порты, которые должны быть доступны извне для корректной работы и ACME http challenge:
	- 80/tcp — HTTP (обязателен для Let's Encrypt HTTP challenge)
	- 443/tcp — HTTPS (Traefik)

- Внутренние порты контейнеров (обычно не нужно открывать на хосте):
	- Traefik dashboard: 8080 (внутри контейнера)
	- n8n: 5678 (exposed для Traefik)
	- LightRAG: 9621 (как помечено в override)

- DNS: перед запуском убедитесь, что A-записи `rag.$DOMAIN_NAME`, `n8n.$DOMAIN_NAME` и `traefik.$DOMAIN_NAME` указывают на публичный IP вашего сервера. Let's Encrypt проверяет HTTP (порт 80), поэтому DNS должен уже быть распространён.

Если вы тестируете локально (без публичного домена), используйте WSL2/Docker Desktop или настройте `stack/docker-compose.override.yml` (dev) — пример есть в репозитории.

## Ollama (LLM runtime)

По умолчанию в `stack/docker-compose.yml` сервис `ollama` закомментирован — это ускоряет старт и уменьшает использование диска/ресурсов. Чтобы вернуть Ollama, откройте `stack/docker-compose.yml` и раскомментируйте секцию `ollama`, затем перезапустите стек:

```bash
cd stack
docker compose up -d ollama
```

Если вы не используете Ollama (например, планируете внешний LLM), оставьте сервис закомментированным.

## Подключение к удалённому серверу (SSH)

Если вы будете подключаться к удалённому серверу для деплоя или тестирования, удобнее всего использовать WSL или OpenSSH в PowerShell. Пример доступа к серверу, где проект размещён в `/opt/N8N`:

WSL / Linux (рекомендуется для корректных прав на ключ):

```bash
# сделайте права ключа корректными (только для владельца)
chmod 600 /mnt/c/Users/Admin/.ssh/id_rsa_n8n

# подключение и выполнение скрипта деплоя и smoke-test
ssh -i /mnt/c/Users/Admin/.ssh/id_rsa_n8n -o StrictHostKeyChecking=no root@37.53.91.144 \
	"cd /opt/N8N || exit 2; bash scripts/30_deploy_lightrag.sh || exit 3; bash tests/smoke/test_start_header.sh || true"
```

PowerShell (Windows OpenSSH client):

```powershell
# при необходимости откорректируйте права через WSL или используйте icacls в PowerShell
# ssh -i "C:\Users\Admin\.ssh\id_rsa_n8n" -o StrictHostKeyChecking=no root@37.53.91.144 "cd /opt/N8N && bash scripts/30_deploy_lightrag.sh"
```

Примечания:
- Если SSH жалуется на "UNPROTECTED PRIVATE KEY FILE" — выполните `chmod 600` в WSL на путь к ключу, или откорректируйте права файла в Windows; после этого ключ будет загружаться корректно.
- Не отправляйте приватный ключ или пароль в чат. Используйте ключ локально и подключайтесь напрямую.

Пример успешного запуска (Git Bash / WSL):

```bash
chmod 600 /c/Users/Admin/.ssh/id_rsa_n8n
ssh -i /c/Users/Admin/.ssh/id_rsa_n8n -o StrictHostKeyChecking=no root@37.53.91.144 "cd /opt/N8N && bash scripts/10_prereqs.sh"
```

## Что учтено
- Фиксированные сети Docker: `stack_proxy`/`stack_backend`
- Секреты пишутся без перевода строки (`\n`) → нет ошибки `InvalidPassword`
- Все YAML/ENV — UTF‑8/ASCII (без «умных» кавычек)
- Traefik‑роуты и Basic‑Auth в override LightRAG
# N8N-Self
