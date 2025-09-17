# Deployment View

Кратко о развёртывании и сетевой топологии для dev/stage/prod.

## Компоненты

- Traefik (edge, HTTP/S): 80/443, маршрутизация, доступ к dashboard на `traefik.${DOMAIN_NAME}`.
- n8n + Postgres (n8n-postgres)
- Redis (кэш/очереди)
- pgvector (LightRAG)
- Ollama (локальные модели)

Примечание: ранее использовался Caddy для TLS passthrough n8n. Сейчас конфигурация упрощена — TLS терминируется в Traefik (официальный подход n8n).

## Сети/Порты

- Сеть `proxy`: Traefik <-> публичные сервисы (n8n, LightRAG)
- Сеть `backend`: внутренняя связь (n8n, Postgres, Redis, pgvector, Ollama)
- Порты хоста: 80, 443, 8080 (Traefik dashboard)

## Домены

- `traefik.${DOMAIN_NAME}` → Traefik dashboard
- `${SUBDOMAIN}.${DOMAIN_NAME}` → n8n (через Traefik)
- `rag.${DOMAIN_NAME}` → LightRAG (через Traefik, Basic-Auth)

## TLS/ACME

- Traefik использует ACME TLS-ALPN-01 через resolver `mytlschallenge` (единый для всех роутеров).

## Переменные окружения

- `DOMAIN_NAME` — корневой домен.
- `SUBDOMAIN` — поддомен для n8n (по умолчанию `n8n`), итоговый хост: `${SUBDOMAIN}.${DOMAIN_NAME}`.
- `ACME_EMAIL` — почта для Let’s Encrypt.
- `TZ` и `GENERIC_TIMEZONE` — часовой пояс контейнеров (для совместимости некоторые образы ждут обе переменные).

См. `stack/template.env` и генерируемый `stack/.env` (скрипт `scripts/20_bootstrap_stack.sh`).

## Окружения

- dev: self-host, без CDN/WAF; секреты через Docker secrets (`../secrets`).
- stage/prod: те же роли; рекомендуются бэкапы Postgres, мониторинг, ограничение доступа к Traefik dashboard.

## Чеклист развёртывания

1) DNS
	- Укажите A-записи на IP сервера для: `traefik.${DOMAIN_NAME}`, `${SUBDOMAIN}.${DOMAIN_NAME}`, `rag.${DOMAIN_NAME}`.

2) Secrets
	- Подготовьте `secrets/` на сервере (пароли БД, `n8n_encryption_key`, `traefik_basicauth` для LightRAG и пр.).

3) Окружение
	- Заполните `stack/template.env` → `stack/.env` (или запустите `scripts/20_bootstrap_stack.sh` — он сгенерирует `stack/.env` и подскажет недостающие значения).

4) Запуск
	- `docker compose -f stack/docker-compose.yml up -d` (и LightRAG при необходимости).

5) Проверка
	- Зайдите на: `https://traefik.${DOMAIN_NAME}`, `https://${SUBDOMAIN}.${DOMAIN_NAME}`, `https://rag.${DOMAIN_NAME}`.
	- Убедитесь, что сертификаты выпущены (Let’s Encrypt) и healthchecks проходят.

## Примечания

- Файлы: `stack/docker-compose.yml`, `stack/template.env`.
- Miro OAuth: redirect_uri должен использовать публичный хост без контейнерных портов.
