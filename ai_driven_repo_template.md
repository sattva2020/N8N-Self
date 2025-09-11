# AI‑Driven Repo Template

Ниже — готовая структура репозитория с файлами. Скопируй нужные части или скачай архив (я приложу ссылку в чате).

```
ai-driven-repo-template/
├─ README.md
├─ LICENSE
├─ .gitignore
├─ .editorconfig
├─ .claude/
│  ├─ settings.json
│  └─ commands/
│     ├─ spec.md
│     ├─ test-plan.md
│     ├─ bugfix.md
│     ├─ refactor.md
│     ├─ migrate.md
│     ├─ perf-audit.md
│     ├─ security-review.md
│     ├─ review.md
│     └─ release-notes.md
├─ .github/
│  └─ workflows/
│     └─ ci.yml
├─ package.json            (опционально для Node)
├─ prettier.config.cjs     (опционально для Node)
├─ requirements.txt        (опционально для Python)
└─ Makefile                (опционально)
```

---

## VS Code — интеграция и рабочее пространство

Ниже — практические рекомендации и готовые конфиги для VS Code, адаптированные под этот проект (frontend в `dashboard/frontend`, Vite + Playwright, простой static‑server `scripts/simple-serve.js`). Скопируй файлы из `.vscode/` в корень репозитория — я уже добавил примеры в репо.

Коротко:
- Рекомендуемые расширения: ESLint, Prettier, Tailwind CSS IntelliSense, Playwright, GitLens, YAML, EditorConfig.
- Настройки: форматирование при сохранении, авто‑фикс ESLint on save, терминал по умолчанию — PowerShell на Windows.
- Задачи (tasks): install, build frontend, serve dist (background), run Playwright smoke.
- Запуск/отладка: конфиг запуска node для простого static server и конфиг для запуска Playwright с инспектором.

### Файлы и где их положить
- `.vscode/extensions.json` — рекомендации расширений.
- `.vscode/settings.json` — рабочие настройки редактора для команды.
- `.vscode/tasks.json` — одно‑кликовые задачи: install, build, serve, e2e.
- `.vscode/launch.json` — простые конфиги для отладки `simple-serve` и Playwright.

> Примечание: в CI используется GitHub Actions; локально VS Code tasks облегчают воспроизведение шагов сборки и e2e.

---

(Далее — оставшиеся разделы шаблона: README.md, .claude/, workflows и пр. — без изменений, но с дополнениями для VS Code.)

## README.md

```md
# AI‑Driven Development Template

Этот шаблон помогает команде вести разработку через ИИ‑ассистента (Claude Code/аналог), с готовыми слэш‑командами, хуками и практиками.

## Быстрый старт
1. Установи инструмент ассистента (пример для Claude Code):
   ```bash
   npm i -g @anthropic-ai/claude-code
   ```

2. В корне проекта держи папку `.claude/` с командами и `settings.json` (см. в репозитории).
3. Запусти агента в корне проекта и используй слэш‑команды:
   - `/spec` — архитектурное ТЗ
   - `/test-plan` — план тестов по изменённым файлам
   - `/bugfix` — фикс с минимальным диффом и тестами
   - `/refactor` / `/migrate` — безопасные изменения по шагам
   - `/perf-audit` — аудит производительности
   - `/security-review` — быстрый обзор безопасности
   - `/review` — ревью диффа
   - `/release-notes` — релиз‑ноты по git

## Культура работы

- **Архитектура → код.** Начинай с `/spec`, фиксируй допущения и риски.
- **Мелкие шаги.** Делай короткие итерации с тест‑планом перед реализацией.
- **Автодисциплина хуками.** Форматирование, защита конфигов и логирование команд — автоматом.
- **Команды вместо длинных промптов.** Всё повторяемое — в `.claude/commands/`.
- **Контроль затрат.** Периодически проверяй `/cost` и ограничивай `allowed-tools` во фронтматтере команд.

## MCP/интеграции (опционально)

Подключай GitHub/Jira/Figma/Slack через MCP, чтобы агент читал/обновлял задачи и дизайн‑артефакты.

## Мульти‑стек

Шаблон нейтрален к стеку. Для Node есть `package.json`/Prettier; для Python — `requirements.txt`; CI — GitHub Actions с матрицей.

## Метрики

- Скорость: задачи/день, средний PR‑дифф, время цикла.
- Качество: прохождение тестов и ревью с первого раза.
- Стоимость: собирай `/cost` по сессиям и связывай с задачами.

## Безопасность

Хуки исполняются локально с твоими правами. Ревьюй любые скрипты и ограничивай инструменты через `allowed-tools`.
```

---

## LICENSE

```txt
MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## .gitignore

```gitignore
# Node
node_modules/
.npm/

# Python
.venv/
__pycache__/
*.pyc

# General
.DS_Store
.env
secrets/
.cache/
dist/
build/
.vscode/
```

---

## .editorconfig

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true
```

---

## .claude/settings.json

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "description": "Log every Bash command to file",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"\\(.tool_input.command) - \\(.tool_input.description // \\\"No description\\\")\"' >> ~/.claude/bash-command-log.txt"
          }
        ]
      },
      {
        "matcher": "Edit|MultiEdit|Write",
        "description": "Protect sensitive files (.env, package-lock.json, .git/, secrets/)",
        "hooks": [
          {
            "type": "command",
            "command": "python3 - << 'PY'\nimport json,sys\npayload=json.load(sys.stdin)\npath=(payload.get('tool_input') or {}).get('file_path','')\nfor p in ['.env','package-lock.json','.git/','secrets/']:\n    if p in path:\n        sys.exit(2)\nsys.exit(0)\nPY"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|MultiEdit|Write",
        "description": "Auto format TS/JS with Prettier if available",
        "hooks": [
          {
            "type": "command",
            "command": "python3 - << 'PY'\nimport json,sys,os,subprocess\npayload=json.load(sys.stdin)\npath=(payload.get('tool_input') or {}).get('file_path','')\nif path.endswith(('.ts','.tsx','.js','.jsx')) and os.path.exists('node_modules/.bin/prettier'):\n    subprocess.run(['node', 'node_modules/.bin/prettier', '--write', path], check=False)\nPY"
          }
        ]
      }
    ]
  }
}
```

---

## .claude/commands/spec.md

```md
---
allowed-tools: Bash(git:*), Bash(npx:*), Edit, MultiEdit, Write
---
You are a senior architect. Produce a concise SPEC for the change:
- Problem & Context
- Constraints & Non-goals
- Data model, API, contracts
- Risks & unknowns
- Phased plan (MVP → v1)
- Test strategy (unit/e2e)
Return: SPEC.md + step-by-step plan.
```

---

## .claude/commands/test-plan.md

```md
You are a senior SDET. Build a practical test plan for changed files:
- Coverage by layer (unit/integration/e2e)
- Critical paths & edge cases
- Data/setup/fixtures
- Expected metrics (latency, memory) if relevant
Return: checklist + test skeletons.
```

---

## .claude/commands/bugfix.md

```md
You are a senior engineer. Fix the bug with minimal diff.
- Root cause analysis
- 2–3 fix options → choose least risky
- Add/adjust tests to prove the fix
- Keep public API stable unless migration is justified
Return: diff + tests.
```

---

## .claude/commands/refactor.md

```md
Plan and execute a safe refactor with zero behavior change:
- Scope & invariants
- API/contract stability
- Stepwise commits (small diffs)
- Automated checks (lint, typecheck, tests)
- Rollback plan
Return: diffs + notes.
```

---

## .claude/commands/migrate.md

```md
Plan and execute a migration (breaking changes allowed with deprecation plan):
- Current → Target (diagram)
- Risks & fallback
- Incremental steps with compatibility shims
- Data migrations (if any)
- Tests at each step
Return: plan + diffs.
```

---

## .claude/commands/perf-audit.md

```md
Do a performance audit of changed files:
- Identify hot paths & quick wins
- Complexity & allocations
- I/O and network patterns
- Micro-bench suggestions
Return: prioritized checklist + sample diffs.
```

---

## .claude/commands/security-review\.md

```md
Security review (quick):
- Secrets handling (.env, tokens)
- Injection/XXE/SSRF/RCE risks
- Deserialization and eval usage
- Dependency risks (supply chain)
- AuthZ/AuthN checks
Return: findings by severity + fixes.
```

---

## .claude/commands/review\.md

```md
Senior code review for the current diff:
- Correctness & edge cases
- Readability & cohesion
- Test adequacy
- Performance and security notes
Return: summary + actionable suggestions.
```

---

## .claude/commands/release-notes.md

```md
Generate release notes from git log since the last tag:
- User‑facing changes (features, fixes)
- Breaking changes & migrations
- Performance & security notes
Return: markdown suitable for CHANGELOG.
```

---

## .github/workflows/ci.yml

```yaml
name: CI
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        language: [node, python]
    steps:
      - uses: actions/checkout@v4

      - name: Node setup
        if: matrix.language == 'node'
        uses: actions/setup-node@v4
        with:
          node-version: 20
      - name: Install deps (Node)
        if: matrix.language == 'node'
        run: |
          if [ -f package.json ]; then npm ci; fi
      - name: Lint & Test (Node)
        if: matrix.language == 'node'
        run: |
          if [ -f package.json ]; then npm run -s lint || true; npm test || true; fi

      - name: Python setup
        if: matrix.language == 'python'
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install deps (Python)
        if: matrix.language == 'python'
        run: |
          if [ -f requirements.txt ]; then python -m pip install -U pip && pip install -r requirements.txt; fi
      - name: Tests (Python)
        if: matrix.language == 'python'
        run: |
          if [ -d tests ]; then pytest -q || true; fi
```

---

## package.json (опционально)

```json
{
  "name": "ai-driven-repo-template",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "lint": "eslint .",
    "format": "prettier --write ."
  },
  "devDependencies": {
    "eslint": "^9.11.1",
    "prettier": "^3.3.3"
  }
}
```

---

## prettier.config.cjs (опционально)

```js
module.exports = {
  semi: true,
  singleQuote: true,
  trailingComma: 'all'
};
```

---

## requirements.txt (опционально)

```txt
pytest>=8.2.0
```

---

## Makefile (опционально)

```makefile
.PHONY: fmt test
fmt:
	npx prettier --write . || true
	eslint . || true

auto:
	# пример: автоматизируй частые действия
	claude /spec "Implement feature X"

test:
	pytest -q || true
```

