# Security Baseline

Минимальные правила безопасности для проекта.

## Секреты и конфигурация

- Используйте `stack/template.env` → `.env` и Docker secrets в `secrets/` (не коммитить).
- Не размещайте redirect_uri с контейнерными портами; для n8n используйте `https://n8n.${DOMAIN_NAME}`.
- Traefik dashboard доступен только по VPN/белому списку IP. Уберите публичный 8080 в проде.

## TLS и домены

- Traefik: HTTP → HTTPS редирект, ACME http-01, отдельный роутер для dashboard.
- Caddy: самостоятельный ACME для `n8n.${DOMAIN_NAME}` через TLS passthrough.

## Права и доступы

- Минимизируйте volume‑mount прав и привилегии контейнеров; docker.sock только для нужных сервисов.
- Регулярные обновления образов (`:latest` допустим в dev, закрепляйте теги в prod).

## Threat modeling

- Подготовьте DFD/STRIDE в `docs/security/` (Threat Dragon). Критичные векторы: компрометация секретов, MITM на миссконфигурированных доменах, доступ к Traefik dashboard, SSRF из нод n8n.

## Инциденты

- Документируйте способ отзыва токенов (Miro/OAuth), ротацию ключей и восстановление из бэкапов Postgres.
