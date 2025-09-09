# Remote deployment helper

Предназначено для упаковки репозитория, копирования на удалённый сервер и запуска docker compose.

Подготовка (локально):

- Сгенерировать секреты:

```bash
./scripts/generate_secrets.sh
```

- Настроить `infra/.env` и `stack/.env` (DOMAIN_NAME, ACME_EMAIL, TZ и т.д.).

Копирование и запуск на удалённом сервере:

```bash
# копирование и запуск
./scripts/deploy_remote.sh user@remote.host --key /path/to/key --remote-path /opt/lightRAG
```

После копирования — вручную разместите секреты в `/opt/lightRAG/secrets` на удалённом сервере (traefik_basicauth, n8n_db_password и т.д.).

Проверки:

- Traefik dashboard: https://traefik.${DOMAIN_NAME}
- Keycloak (oauth2-proxy hostname): https://auth.${DOMAIN_NAME}
- Dashboard: https://dashboard.${DOMAIN_NAME}

Если нужно автоматизировать загрузку секретов — используйте scp для копирования файлов в `/opt/lightRAG/secrets`.
