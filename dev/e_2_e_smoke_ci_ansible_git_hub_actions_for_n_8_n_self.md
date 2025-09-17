# E2E Smoke CI — Ansible + GitHub Actions

Этот пакет добавляет **сквозной smoke‑чек** инфраструктуры (Traefik → n8n → LightRAG docs под Basic‑Auth) и его запуск из **GitHub Actions**. Подходит для ветки `feat/ansible-smoke-ci` или `main`.

---

## 📁 Структура файлов

```
infra/
  inventory.ini            # пример инвентаря (локальный запуск)
  smoke.yml                # ansible-playbook для e2e-smoke
.github/
  workflows/
    e2e-smoke.yml         # CI job, запускающий smoke по SSH
```

---

## 1) `infra/smoke.yml` — Ansible playbook

```yaml
# infra/smoke.yml
- name: E2E smoke: Traefik / n8n / LightRAG
  hosts: target
  gather_facts: no

  vars:
    domain: "{{ lookup('env','DOMAIN_NAME') | default('', true) }}"
    rag_user: "{{ lookup('env','RAG_BASIC_USER') | default('', true) }}"
    rag_pass: "{{ lookup('env','RAG_BASIC_PASS') | default('', true) }}"

  pre_tasks:
    - name: Validate required variables
      assert:
        that:
          - domain | length > 0
          - rag_user | length > 0
          - rag_pass | length > 0
        fail_msg: "DOMAIN_NAME, RAG_BASIC_USER, RAG_BASIC_PASS must be provided via env"

  tasks:
    - name: Wait Traefik is serving HTTPS (root)
      uri:
        url: "https://traefik.{{ domain }}/"
        method: GET
        status_code: 200
        validate_certs: yes
      register: traefik_https_root
      retries: 30
      delay: 5
      until: traefik_https_root.status == 200

    - name: HTTP -> HTTPS redirect for n8n (port 80)
      uri:
        url: "http://n8n.{{ domain }}/"
        method: GET
        follow_redirects: none
        status_code: 301,302
      register: n8n_http_redir

    - name: n8n homepage over HTTPS
      uri:
        url: "https://n8n.{{ domain }}/"
        method: GET
        validate_certs: yes
        follow_redirects: safe
        status_code: 200,302
      register: n8n_https
      retries: 20
      delay: 5
      until: n8n_https.status in [200, 302]

    - name: LightRAG /docs is available under Basic-Auth
      uri:
        url: "https://rag.{{ domain }}/docs"
        method: GET
        validate_certs: yes
        url_username: "{{ rag_user }}"
        url_password: "{{ rag_pass }}"
        force_basic_auth: yes
        status_code: 200
      register: rag_docs
      retries: 20
      delay: 5
      until: rag_docs.status == 200

    - name: Summary
      debug:
        msg:
          - "Traefik: {{ traefik_https_root.status }}"
          - "n8n HTTP→HTTPS: {{ n8n_http_redir.status }}"
          - "n8n HTTPS: {{ n8n_https.status }}"
          - "LightRAG /docs: {{ rag_docs.status }}"
```

> При желании можно расширить задачами проверки health‑проб контейнеров (`docker ps`) или валидности TLS‑сертов, но для быстрой дым‑проверки этого набора достаточно.

---

## 2) `infra/inventory.ini` — пример инвентаря для локального запуска

```ini
# infra/inventory.ini
[target]
prod ansible_host=YOUR_SERVER_IP ansible_user=root
```

> В CI инвентарь будет генерироваться на лету из секретов.

---

## 3) `.github/workflows/e2e-smoke.yml` — GitHub Actions

```yaml
# .github/workflows/e2e-smoke.yml
name: e2e-smoke

on:
  push:
    branches: [ main, feat/ansible-smoke-ci ]
  workflow_dispatch: {}

permissions:
  contents: read

concurrency:
  group: smoke-${{ github.ref }}
  cancel-in-progress: true

jobs:
  smoke:
    runs-on: ubuntu-latest
    timeout-minutes: 20

    steps:
      - uses: actions/checkout@v4

      - name: Install Ansible & OpenSSH client
        run: |
          sudo apt-get update -y
          sudo apt-get install -y ansible openssh-client

      - name: Add SSH key
        env:
          SSH_KEY: ${{ secrets.PROD_SSH_KEY }}
          PROD_HOST: ${{ secrets.PROD_HOST }}
        run: |
          install -m 700 -d ~/.ssh
          echo "$SSH_KEY" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H "$PROD_HOST" >> ~/.ssh/known_hosts

      - name: Write dynamic inventory
        env:
          PROD_HOST: ${{ secrets.PROD_HOST }}
        run: |
          mkdir -p infra
          cat > infra/inventory.ini <<'INI'
          [target]
          prod ansible_host=${PROD_HOST} ansible_user=root
          INI

      - name: Run smoke playbook
        env:
          DOMAIN_NAME: ${{ secrets.DOMAIN_NAME }}
          RAG_BASIC_USER: ${{ secrets.RAG_BASIC_USER }}
          RAG_BASIC_PASS: ${{ secrets.RAG_BASIC_PASS }}
        run: |
          set -o pipefail
          ansible-playbook -i infra/inventory.ini infra/smoke.yml -vv | tee smoke-report.txt

      - name: Upload smoke report
        if: ${{ always() }}
        uses: actions/upload-artifact@v4
        with:
          name: smoke-report
          path: smoke-report.txt
```

---

## 4) Секреты GitHub Actions (Repository → Settings → Secrets and variables → Actions)

| Secret           | Описание                                                                                       |
| ---------------- | ---------------------------------------------------------------------------------------------- |
| `PROD_HOST`      | Публичный IP/домен сервера, куда подключаемся по SSH                                           |
| `PROD_SSH_KEY`   | Приватный ключ **(строго без пароля)** для root/другого пользователя с правами деплоя          |
| `DOMAIN_NAME`    | Базовый домен, используется как `traefik.$DOMAIN_NAME`, `n8n.$DOMAIN_NAME`, `rag.$DOMAIN_NAME` |
| `RAG_BASIC_USER` | Логин для Basic‑Auth на LightRAG                                                               |
| `RAG_BASIC_PASS` | Пароль для Basic‑Auth на LightRAG                                                              |

> **Важно:** ключи и пароли не коммитим. Если когда‑то в репозитории оказывались приватные ключи — поменяйте их и очистите историю (например, `git filter-repo`/BFG) + инвалидируйте старые.

---

## 5) Локальный запуск smoke

```bash
# 1) Настрой ssh‑доступ к серверу (ssh root@YOUR_SERVER_IP)
# 2) Экспортируй переменные окружения
export DOMAIN_NAME=example.com
export RAG_BASIC_USER=demo
export RAG_BASIC_PASS='s3cr3t'

# 3) Запусти playbook
ansible-playbook -i infra/inventory.ini infra/smoke.yml -vv
```

---

## 6) Интеграция с текущим README

Добавьте раздел «E2E Smoke (Ansible)» с:

- командой локального запуска;
- ссылкой на workflow `e2e-smoke.yml`;
- перечнем секретов и ожиданий (какие субдомены должны отвечать);
- примечанием, что старый `tests/smoke/test_start_header.sh` можно оставить как дополнительную check‑команду после деплоя.

Пример вставки в README:

````md
### E2E Smoke (Ansible)
После деплоя можно проверить доступность сервисов:

```bash
export DOMAIN_NAME=example.com
export RAG_BASIC_USER=demo
export RAG_BASIC_PASS='s3cr3t'
ansible-playbook -i infra/inventory.ini infra/smoke.yml -vv
````

В CI см. `.github/workflows/e2e-smoke.yml`. Требуемые секреты: `PROD_HOST`, `PROD_SSH_KEY`, `DOMAIN_NAME`, `RAG_BASIC_USER`, `RAG_BASIC_PASS`.

````

---

## 7) Быстрый git‑патч (опционально)
Содержит два новых файла. Сохраните блок ниже как `smoke.patch` и примените:

```bash
git checkout feat/ansible-smoke-ci
git apply smoke.patch
git add infra/smoke.yml infra/inventory.ini .github/workflows/e2e-smoke.yml
git commit -m "chore: add ansible-based e2e smoke + GH Actions"
git push origin feat/ansible-smoke-ci
````

```diff
*** Begin Patch
*** Add File: infra/smoke.yml
+ - name: E2E smoke: Traefik / n8n / LightRAG
+   hosts: target
+   gather_facts: no
+
+   vars:
+     domain: "{{ lookup('env','DOMAIN_NAME') | default('', true) }}"
+     rag_user: "{{ lookup('env','RAG_BASIC_USER') | default('', true) }}"
+     rag_pass: "{{ lookup('env','RAG_BASIC_PASS') | default('', true) }}"
+
+   pre_tasks:
+     - name: Validate required variables
+       assert:
+         that:
+           - domain | length > 0
+           - rag_user | length > 0
+           - rag_pass | length > 0
+         fail_msg: "DOMAIN_NAME, RAG_BASIC_USER, RAG_BASIC_PASS must be provided via env"
+
+   tasks:
+     - name: Wait Traefik is serving HTTPS (root)
+       uri:
+         url: "https://traefik.{{ domain }}/"
+         method: GET
+         status_code: 200
+         validate_certs: yes
+       register: traefik_https_root
+       retries: 30
+       delay: 5
+       until: traefik_https_root.status == 200
+
+     - name: HTTP -> HTTPS redirect for n8n (port 80)
+       uri:
+         url: "http://n8n.{{ domain }}/"
+         method: GET
+         follow_redirects: none
+         status_code: 301,302
+       register: n8n_http_redir
+
+     - name: n8n homepage over HTTPS
+       uri:
+         url: "https://n8n.{{ domain }}/"
+         method: GET
+         validate_certs: yes
+         follow_redirects: safe
+         status_code: 200,302
+       register: n8n_https
+       retries: 20
+       delay: 5
+       until: n8n_https.status in [200, 302]
+
+     - name: LightRAG /docs is available under Basic-Auth
+       uri:
+         url: "https://rag.{{ domain }}/docs"
+         method: GET
+         validate_certs: yes
+         url_username: "{{ rag_user }}"
+         url_password: "{{ rag_pass }}"
+         force_basic_auth: yes
+         status_code: 200
+       register: rag_docs
+       retries: 20
+       delay: 5
+       until: rag_docs.status == 200
+
+     - name: Summary
+       debug:
+         msg:
+           - "Traefik: {{ traefik_https_root.status }}"
+           - "n8n HTTP→HTTPS: {{ n8n_http_redir.status }}"
+           - "n8n HTTPS: {{ n8n_https.status }}"
+           - "LightRAG /docs: {{ rag_docs.status }}"
+
*** End Patch
```

```diff
*** Begin Patch
*** Add File: .github/workflows/e2e-smoke.yml
+name: e2e-smoke
+
+on:
+  push:
+    branches: [ main, feat/ansible-smoke-ci ]
+  workflow_dispatch: {}
+
+permissions:
+  contents: read
+
+concurrency:
+  group: smoke-${{ github.ref }}
+  cancel-in-progress: true
+
+jobs:
+  smoke:
+    runs-on: ubuntu-latest
+    timeout-minutes: 20
+
+    steps:
+      - uses: actions/checkout@v4
+
+      - name: Install Ansible & OpenSSH client
+        run: |
+          sudo apt-get update -y
+          sudo apt-get install -y ansible openssh-client
+
+      - name: Add SSH key
+        env:
+          SSH_KEY: ${{ secrets.PROD_SSH_KEY }}
+          PROD_HOST: ${{ secrets.PROD_HOST }}
+        run: |
+          install -m 700 -d ~/.ssh
+          echo "$SSH_KEY" > ~/.ssh/id_rsa
+          chmod 600 ~/.ssh/id_rsa
+          ssh-keyscan -H "$PROD_HOST" >> ~/.ssh/known_hosts
+
+      - name: Write dynamic inventory
+        env:
+          PROD_HOST: ${{ secrets.PROD_HOST }}
+        run: |
+          mkdir -p infra
+          cat > infra/inventory.ini <<'INI'
+          [target]
+          prod ansible_host=${PROD_HOST} ansible_user=root
+          INI
+
+      - name: Run smoke playbook
+        env:
+          DOMAIN_NAME: ${{ secrets.DOMAIN_NAME }}
+          RAG_BASIC_USER: ${{ secrets.RAG_BASIC_USER }}
+          RAG_BASIC_PASS: ${{ secrets.RAG_BASIC_PASS }}
+        run: |
+          set -o pipefail
+          ansible-playbook -i infra/inventory.ini infra/smoke.yml -vv | tee smoke-report.txt
+
+      - name: Upload smoke report
+        if: ${{ always() }}
+        uses: actions/upload-artifact@v4
+        with:
+          name: smoke-report
+          path: smoke-report.txt
+
*** End Patch
```

---

## 8) Что можно улучшить позже

- Проверка `docker ps` и health‑checks контейнеров.
- Локальный self‑hosted Runner в приватной сети.
- Добавить Slack/Telegram уведомление при фейле.
- Опциональная проверка срока действия TLS‑сертов Traefik (через `openssl s_client` из Ansible `shell`).



---

## 9) Pull Request — текст (готов к вставке)

**Title**:

```
ci(smoke): add Ansible-based E2E smoke checks and GitHub Actions workflow
```

**Description**:

```
This PR introduces a fast E2E smoke check to validate the stack after deploy:
- Traefik serves HTTPS on https://traefik.$DOMAIN_NAME/
- n8n is reachable (HTTP→HTTPS redirect + HTTPS 200/302)
- LightRAG /docs responds with HTTP 200 under Basic-Auth

It adds an Ansible playbook (infra/smoke.yml) and a GitHub Actions workflow (.github/workflows/e2e-smoke.yml). The workflow uses repository secrets to connect over SSH and run the checks remotely. A textual report is uploaded as a build artifact.
```

**Changes**:

- `infra/smoke.yml`: Idempotent smoke playbook with retries and TLS validation.
- `.github/workflows/e2e-smoke.yml`: CI job with SSH bootstrap, dynamic inventory, artifact upload.
- Docs: instructions for local run, secrets list, and README insertion sample.

**How it works**:

- Triggers on push to `main` and `feat/ansible-smoke-ci`, or manually via `workflow_dispatch`.
- Creates SSH known\_hosts, writes inventory from `PROD_HOST`, exports env for Ansible.
- Runs `ansible-playbook` and uploads `smoke-report.txt` as artifact.

**Required secrets**:

- `PROD_HOST`, `PROD_SSH_KEY`, `DOMAIN_NAME`, `RAG_BASIC_USER`, `RAG_BASIC_PASS`.

**Local test**:

```
export DOMAIN_NAME=example.com
export RAG_BASIC_USER=demo
export RAG_BASIC_PASS='s3cr3t'
ansible-playbook -i infra/inventory.ini infra/smoke.yml -vv
```

**Observability**:

- Artifact: `smoke-report` (contains `smoke-report.txt`).
- Non‑zero exit stops pipeline.

**Security notes**:

- Never commit private keys; rotate any previously exposed keys.
- All credentials are read from repo secrets; Basic‑Auth for LightRAG enforced.

**Risks & mitigations**:

- ACME/DNS propagation or network jitter → retries in Ansible tasks.
- Flaky checks → conservative timeouts, minimal scope, no sleeps, only state‑based waits.
- SSH failure → early fail with clear logs; artifact aids debugging.

**Rollback plan**:

- Disable workflow in repo settings and revert this PR.
- If secrets suspected compromised, rotate `PROD_SSH_KEY` and Basic‑Auth creds.

**Checklist**:

-

---

## 10) Быстро создать PR через GitHub CLI (опционально)

С таким телом PR можно сразу из консоли:

```bash
git checkout feat/ansible-smoke-ci
# Убедись, что файлы добавлены и запушены (см. раздел патча выше)

# Создать PR на base=main
cat > /tmp/pr-body.md <<'MD'
ci(smoke): add Ansible-based E2E smoke checks and GitHub Actions workflow

### Context
Adds infra/smoke.yml (Ansible smoke) and .github/workflows/e2e-smoke.yml (CI).
Validates Traefik, n8n, LightRAG/docs (Basic-Auth) after deploy.

### Secrets
PROD_HOST, PROD_SSH_KEY, DOMAIN_NAME, RAG_BASIC_USER, RAG_BASIC_PASS

### How to test
- Local: run `ansible-playbook -i infra/inventory.ini infra/smoke.yml -vv`
- CI: trigger workflow_dispatch and check `smoke-report` artifact

### Risks & Rollback
Retries for network/ACME; rotate secrets and revert if needed.
MD

gh pr create \
  --base main \
  --head feat/ansible-smoke-ci \
  --title "ci(smoke): add Ansible-based E2E smoke checks and GitHub Actions workflow" \
  --body-file /tmp/pr-body.md
```



---

## 11) README — секция + мини‑бейдж статуса

Ниже блоки, которые можно вставить в `README.md`.

### Бейдж GitHub Actions (workflow: e2e-smoke)

```md
<!-- Основной бейдж для ветки main -->
[![e2e-smoke](https://github.com/sattva2020/N8N-Self/actions/workflows/e2e-smoke.yml/badge.svg?branch=main)](https://github.com/sattva2020/N8N-Self/actions/workflows/e2e-smoke.yml)

<!-- (опционально) бейдж для feature-ветки -->
[![e2e-smoke (feat/ansible-smoke-ci)](https://github.com/sattva2020/N8N-Self/actions/workflows/e2e-smoke.yml/badge.svg?branch=feat/ansible-smoke-ci)](https://github.com/sattva2020/N8N-Self/actions/workflows/e2e-smoke.yml)
```

> Если форк/организация другие — замените `sattva2020/N8N-Self` на свои `owner/repo`.

---

### Раздел: E2E Smoke (Ansible)

````md
## E2E Smoke (Ansible)
Быстрая дым‑проверка доступности ключевых сервисов после деплоя:
- **Traefik** — HTTPS доступность `https://traefik.$DOMAIN_NAME/`
- **n8n** — редирект HTTP→HTTPS и отклик домашней страницы
- **LightRAG** — доступность `/docs` под Basic‑Auth (200)

### Требования
1. Настроены DNS `A/AAAA` записи для `traefik.$DOMAIN_NAME`, `n8n.$DOMAIN_NAME`, `rag.$DOMAIN_NAME`.
2. Выпущены/автоматически выпускаются TLS‑сертификаты (Traefik + ACME).
3. В репозитории заданы Secrets: `PROD_HOST`, `PROD_SSH_KEY`, `DOMAIN_NAME`, `RAG_BASIC_USER`, `RAG_BASIC_PASS`.

### Запуск локально
```bash
export DOMAIN_NAME=example.com
export RAG_BASIC_USER=demo
export RAG_BASIC_PASS='s3cr3t'
ansible-playbook -i infra/inventory.ini infra/smoke.yml -vv
````

### Запуск из GitHub Actions

- Перейдите в **Actions → e2e-smoke → Run workflow** (или сделайте push в `main`).
- Отчёт будет приложен артефактом **smoke-report** (файл `smoke-report.txt`).

### Переменные и секреты

- `PROD_HOST` — адрес SSH‑хоста
- `PROD_SSH_KEY` — приватный SSH‑ключ (без пароля)
- `DOMAIN_NAME` — базовый домен (например `example.com`)
- `RAG_BASIC_USER` / `RAG_BASIC_PASS` — креды Basic‑Auth для `rag.$DOMAIN_NAME`

### Траблшутинг

- **ACME/сертификат**: подождите 1–2 мин, проверьте логи Traefik и DNS‑записи.
- **401 на /docs**: убедитесь в корректности `RAG_BASIC_USER/PASS` и в том, что Basic‑Auth включён.
- **301/302 на n8n**: редирект ожидаем; важен итоговый 200/302 по HTTPS.
- **SSH ошибки**: перепроверьте `PROD_HOST`, ключ, права пользователя и доступ по 22 порту.

```
```
