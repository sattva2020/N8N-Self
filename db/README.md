# DB migrations (skeleton)

Цель: зафиксировать схему и индексы приложения. Пока без инструмента миграций.

Как применять локально (psql):

1. Экспортируйте переменные окружения подключения к Postgres.
   - Для n8n: хост `n8n-postgres`, БД `n8n`, пользователь `n8n`.
2. Примените SQL:

```sh
# Linux/macOS
psql "host=localhost user=n8n dbname=n8n" -f db/migrations/001_init.sql

# Windows PowerShell
psql "host=localhost user=n8n dbname=n8n" -f db/migrations/001_init.sql
```

Замечания:

- Для production используйте управляемый инструмент миграций (Flyway/Liquibase/Prisma/Knex) и CI шаг.
- Сначала обновляйте `template.env`/секреты, затем применяйте миграции.
