# Архитектура проекта и план реализации

Назначение: краткое, практичное описание целевой архитектуры Sattva AI (n8n + LightRAG) и список конкретных задач с приоритетами для реализации этой архитектуры. Файл используется как эталон для сравнения с `TASK_JOURNAL.md`.

## Короткий обзор архитектуры

- Edge / reverse proxy: Traefik — маршрутизация, SSL (Let's Encrypt), HTTP→HTTPS.

- Бэкенд сервисы (Docker Compose):
  - PostgreSQL (+ pgvector) — основной хранилище данных и векторная база для LightRAG

  - Redis — очередь/кэш для n8n

  - n8n — workflow-движок (интеграции)

  - LightRAG сервис (контейнер) — обработка запросов RAG (Retriever + Reader)

  - Ollama (опционально) — локальный LLM runtime (контейнер)

- Frontend: React 18 + Vite + TypeScript + Tailwind CSS — админ/панель мониторинга

- Тесты и CI:
  - Unit/Integration: Vitest + @testing-library/react

  - E2E: Playwright (GitHub Actions runner)

  - CI: GitHub Actions — build, unit tests, e2e smoke

- Логирование и мониторинг: Log aggregation (опционально), простой файл логов + health endpoints

- Секреты: хранить вне репозитория (stack/.env, secrets/ с правильными правами)

## Компоненты и контракты (вход/выход)

- Traefik: принимает HTTPS, перенаправляет на соответствующий сервис по hostname.

- n8n: REST API + вебхуки; ожидает подключение к PostgreSQL и Redis.

- LightRAG: REST API: POST /query { prompt } → { answers, sources }.

- Frontend: статический сайт (build → dist) — сервируется через Traefik или простой static server в CI.

## Ненулевые предположения

- Развёртывание ориентировано на Docker Compose в /opt/N8N (prod) и на dev через docker compose override.

- Домен/сертификаты настраиваются через Traefik ACME.

- CI использует Ubuntu GitHub Actions runner.

## План работ (разбит по приоритетам и задачам)

Каждая задача имеет ID, краткое описание и критерий готовности.

### Высокий приоритет

- TASK-001: Убедиться, что базовый стек запускается локально и в CI
  - Действия: проверить `stack/docker-compose.yml`, запустить `bash scripts/20_bootstrap_stack.sh` на тестовом хосте

  - Критерий: все контейнеры в статусе "healthy"; доступ к n8n и LightRAG

- TASK-002: Настроить CI (GitHub Actions): build, unit tests, e2e smoke
  - Действия: workflow `ci.yml` с job-ами: install, build, test, e2e

  - Критерий: успешный run в PR

- TASK-003: Надёжный static server для E2E в CI
  - Действия: добавить `scripts/simple-serve.js`, заменить `http-server` в package.json, настроить playwright webServer

  - Критерий: Playwright тесты проходят на runner

### Средний приоритет

- TASK-004: Восстановление и унификация стилей frontend (Tailwind)
  - Действия: правки компонентов, правки `tailwind.config.cjs`

  - Критерий: корректный билд и визуально приемлемая панель

- TASK-005: Покрытие unit/integration тестами основных UI-компонентов
  - Действия: добавить `LogsPane`, `DetailsPanel`, API mock tests

  - Критерий: >= 80% стабильных тестов локально и в CI

- TASK-006: Исправить и централизовать тестовые декларации (setup-tests.d.ts)
  - Действия: добавить d.ts для глобов и настроить vitest.config.ts

  - Критерий: tsc без ошибок в тестах

### Низкий приоритет / опционально

- TASK-007: Добавить мониторинг и логирование (Log Analytics или ELK)

- TASK-008: Промежуточные smoketests на staging (вне CI)

- TASK-009: Автоматизация .env generation (template.env → .env) в setup скриптах

## Зависимости между задачами

- TASK-003 (static server для E2E) зависит от TASK-002 (CI) и от успешной сборки frontend (TASK-004).

- TASK-005 (тесты) требует чтобы TASK-006 был выполнен (чтобы тесты видели глобы и типы).

## Риски и edge-cases

- Локальная среда (Windows) может блокировать bind() для Node (EACCES). Решение: запуск E2E на CI runner или в WSL/контейнере.

- Commit/индексация node_modules — риск большого веса репозитория. Решение: .gitignore + `git rm --cached` + CI restore через `npm ci`.

- Secret leakage — никогда не хранить .env в репо.

## Acceptance criteria / Quality gates

- Build: `npm run build` проходит в CI

- Typecheck: `tsc --noEmit` — без ошибок

- Unit tests: `npm test` (vitest) — проходящий набор тестов (задокументированное покрытие)

- E2E: Playwright smoke — минимальный сценарий (open index, авторизация, базовый flow)

## Как использовать этот файл и сводить с `TASK_JOURNAL.md`

- `ARCHITECTURE_AND_ROADMAP.md` — эталонный список задач и критериев.

- `TASK_JOURNAL.md` — фактические записи о проделанной работе.

- Процесс сверки: по завершении итерации берём список TASK-00x и ищем соответствующие записи в `TASK_JOURNAL.md`. Если критерий готовности для задачи выполнен — отмечаем Done.

## Предложенные следующие шаги (практично)

1. Закоммитить `TASK_JOURNAL.md` и `ARCHITECTURE_AND_ROADMAP.md` в текущую ветку.

2. Пушнуть ветку и создать PR в `main` — дождаться CI run и проверить job `e2e`.

3. Если CI упадёт по причинам локального bind/ports — временно поместить E2E в блок `if: github.event_name == 'push'` и тестировать на форк/runner.

---

Файл создан автоматически. Если нужно — сразу закоммичу и запушу изменения, а также создам PR и/или обновлю существующий PR для ветки `feature/ci-e2e-simple-serve`.

<!-- TEST-COMMIT: allow hooks to run -->
