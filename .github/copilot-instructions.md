# Copilot instructions (concise)

Repo: n8n + LightRAG stack with a small dashboard (Fastify backend + React/Vite frontend).

Quick start (local):
- Frontend: `cd dashboard/frontend && npm ci && npm run dev` (build: `npm run build`).
- Backend: `cd dashboard/backend && npm ci && npm run dev` (build: `npm run build`).

Server deploy (quick): `bash scripts/10_prereqs.sh`, `bash scripts/20_bootstrap_stack.sh`, `bash scripts/30_deploy_lightrag.sh` (use `DOMAIN_NAME` & `ACME_EMAIL`).

Key files: `README.md`, `dashboard/README.md`, `stack/docker-compose.yml`, `scripts/20_bootstrap_stack.sh`, `dashboard/frontend/playwright.config.ts`, `dashboard/frontend/scripts/simple-serve.js`.

Playwright (trace + CI debugging) — быстрый чеклист:

- Если CI упал: скачайте артефакт `playwright-report` из run, извлеките `trace.zip`.
- Локальный просмотр: установите Playwright и выполните
	- `npx playwright show-trace runs/.../trace.zip` — откроет viewer с дорожкой и скриншотами.
- Быстрый ручной анализ (если viewer недоступен): распакуйте `trace.zip` и проверьте:
	- `0-trace.stacks` — нативные стеки/краши;
	- `0-trace.network` — сетевые запросы/ответы;
	- `test.trace` и ресурсы — воспроизводимые снимки/HTML/CSS.
- Воспроизведение локально (реплика CI):
	- `cd dashboard/frontend && npm ci && npm run build`
	- `node ./scripts/simple-serve.js` (по умолчанию порт 5175)
	- `npx playwright test --project=chromium --trace=on --reporter=list`
- Частые CI‑проблемы и remediation:
	- "Project(s) 'chromium' not found" — убедитесь, что `dashboard/frontend/playwright.config.ts` содержит `projects: [{ name: 'chromium', use: { browserName: 'chromium' } }]`.
	- Пустой `playwright-report` при upload — убедитесь, что Playwright reporter пишет в `playwright-report` (см. `outputDir`) и что шаг upload смотрит в `dashboard/frontend/playwright-report`.
	- Защитный хук для артефактов: в CI добавьте placeholder файл перед upload (например `echo ok > dashboard/frontend/playwright-report/placeholder.txt`) чтобы upload не падал, если тестов нет.
	- Windows `EACCES` на `0.0.0.0` — `scripts/simple-serve.js` должен иметь fallback на `127.0.0.1` (не удаляйте эту логику).

Если нужно, могу добавить короткий пример bash‑скрипта для автоматического извлечения trace и запуска `npx playwright show-trace` локально.

Project conventions: don't commit `secrets/` or `.env` (scripts expect no trailing newline); LightRAG lives outside this repo (copy overrides to `LightRAG_conf/`).

Common pitfall: `simple-serve.js` may hit `EACCES` on `0.0.0.0` on Windows — keep host fallback to `127.0.0.1`.

If unclear: open a short PR comment describing the change + how you validated (attach `playwright-report` trace zip for E2E failures).
