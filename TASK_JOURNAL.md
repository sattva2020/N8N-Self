# Журнал задач (Task Journal)

Назначение: вести хронологию выполненных и текущих задач по проекту, с указанием статуса, изменённых файлов, веток/коммитов и заметок (проверки/CI).

Формат записи (одна запись = один пункт):
- Дата: YYYY-MM-DD
- Задача: краткое описание
- Статус: Done / In progress / Blocked / Deferred
- Файлы/изменения: ключевые пути файлов, созданных/отредактированных
- Ветка/Коммит: имя ветки и/или SHA коммита (если есть)
- Проверки: краткие результаты (tsc, vitest, CI)
- Заметки: дополнительные детали (проблемы, next steps)

---

## Записи

- Дата: 2025-09-10
  - Задача: Исправить Tailwind utility (max-h) и привести стили компонентов в порядок
  - Статус: Done
  - Файлы/изменения: `dashboard/frontend/src/index.css`, `dashboard/frontend/src/components/TopBar.tsx`, `dashboard/frontend/src/components/ServicesTable.tsx`, `dashboard/frontend/tailwind.config.cjs`
  - Ветка/Коммит: `feature/ci-e2e-simple-serve` (локальные правки)
  - Проверки: `tsc --noEmit` — без ошибок; Vite build — успешен после правки стилей
  - Заметки: использована синтаксис-утилита `max-h-[50%]` вместо `max-h-1/2`.

- Дата: 2025-09-10
  - Задача: Добавить/исправить unit/integration тесты (LogsPane, DetailsPanel, API mocks)
  - Статус: Done
  - Файлы/изменения: `dashboard/frontend/src/components/LogsPane.test.tsx`, `dashboard/frontend/src/components/DetailsPanel.test.tsx`, `dashboard/frontend/src/api.test.ts`, `dashboard/frontend/src/setup-tests.d.ts`
  - Ветка/Коммит: `feature/ci-e2e-simple-serve`
  - Проверки: локальные unit тесты/глобы настроены; Vitest конфиг обновлён
  - Заметки: использованы `vi` моки и `@testing-library/react` для рендеринга.

- Дата: 2025-09-10
  - Задача: Подготовить E2E (Playwright) и надёжный статический сервер для CI
  - Статус: Done (CI-targeted)
  - Файлы/изменения: `dashboard/frontend/scripts/simple-serve.js`, `dashboard/frontend/package.json` (скрипт `serve-dist`), `dashboard/frontend/playwright.*.config` (temp/ts/js)
  - Ветка/Коммит: `feature/ci-e2e-simple-serve`
  - Проверки: локальный запуск сервера в этой Windows-сессии — блокируется EACCES при bind(); CI workflow запланирован для запуска на GitHub Actions
  - Заметки: для E2E рекомендую запускать на CI runner (github actions), т.к. локальная среда блокирует сокеты.

- Дата: 2025-09-10
  - Задача: Обновить GitHub Actions workflow — добавить job `e2e` с запуском Playwright
  - Статус: Done
  - Файлы/изменения: `.github/workflows/ci.yml` (обновлён, добавлен job `e2e`)
  - Ветка/Коммит: `feature/ci-e2e-simple-serve`
  - Проверки: ожидается запуск в CI после push/PR
  - Заметки: workflow стартует сервер (npm run serve-dist) в фоне и ждёт готовности перед `npx playwright test`.

- Дата: 2025-09-10
  - Задача: Исключить `dashboard/frontend/node_modules` из индекса Git и добавить `.gitignore`
  - Статус: Done
  - Файлы/изменения: `/.gitignore` (добавлен), выполнена команда `git rm --cached -r dashboard/frontend/node_modules` и коммит "chore: ignore frontend node_modules and clean index"
  - Ветка/Коммит: `feature/ci-e2e-simple-serve`
  - Проверки: `git status` — node_modules удалены из индекса
  - Заметки: патч сохранён в `patches/ci-e2e-simple-serve.patch`.

---

## Как пользоваться
- Для добавления новой записи: просто добавьте блок в этот файл, соблюдая формат. Желательно указывать ветку/коммит и краткие результаты проверок.
- Пример команды для фиксации после добавления записи:

```powershell
# на Windows PowerShell
git add TASK_JOURNAL.md
git commit -m "docs: update TASK_JOURNAL — <short note>"
git push origin feature/ci-e2e-simple-serve
```

## Предложения по автоматизации
- Можно добавить pre-commit hook, который добавляет строку в журнал при выполнении особых скриптов (например, после `npm run build` или `npm test`).
- Также можно держать `TASK_JOURNAL.md` в корне и ссылаться на него в PR template.

---

Файл создан автоматически инструментом работы над репозиторием. Если хотите — могу сразу закоммитить и запушить изменения в текущую ветку.  
