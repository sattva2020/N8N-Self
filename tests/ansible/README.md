# Ansible smoke for N8N stack

Quick start:

1) Edit `inventory.ini` and set your host (Ubuntu 24).
2) Ensure you have SSH access (key-based preferred).
3) Install required collections:

```bash
ansible-galaxy collection install -r tests/ansible/collections/requirements.yml
```

1) From repo root, run:

```bash
ansible-playbook -i tests/ansible/inventory.ini tests/ansible/playbooks/smoke.yml
```

Deploy dashboard (infra)

You can deploy the dashboard infra (infra/docker-compose.dashboard.yml) and run a basic availability check using the helper playbook:

```bash
# from repo root - replace example domain with your test domain
ansible-playbook -i tests/ansible/inventory.ini tests/ansible/playbooks/deploy_dashboard.yml -e domain_name=dashboard.example.test
```

Notes:

- This playbook installs Docker (if missing), syncs `stack/` and `secrets/`, renders `stack/.env`, and runs `docker compose`.
- It then waits for Traefik and n8n endpoints to respond over HTTPS.
- For production, maintain secrets on the server. Local `secrets/` sync is optional and can be removed.

Windows tips:

- Use WSL or Git Bash for Ansible commands; native Ansible on Windows isn’t supported — run from a Linux shell.

## CI / Registry (дополнение)

- Workflow: `.github/workflows/ci-build-postgres-pgvector.yml` — собирает и пушит образ в registry (по умолчанию `ghcr.io`).
- Рекомендуемый способ: использовать `GITHUB_TOKEN` (предоставляется автоматически в Actions) — в workflow установлено `permissions: packages: write`.
- Если вы хотите пушить в другой registry, добавьте в `Settings → Secrets`:
  - `REGISTRY_URL` — URL registry (например `registry.example.com`)
  - `REGISTRY_USERNAME` — имя для логина
  - `REGISTRY_PASSWORD` — пароль или token

 
### Локальный push (только если CI недоступен)
 
1. Создайте PAT (classic or fine‑grained) с правом `write:packages` (и `read:packages` при необходимости).
2. На контроллере WSL выполните:

```bash
export GHCR_USER="<your-gh-user>"
export GHCR_PAT="<paste-your-pat-here>"

echo "$GHCR_PAT" | docker login ghcr.io -u "$GHCR_USER" --password-stdin

docker tag local/postgres-pgvector:15 ghcr.io/${GHCR_USER}/postgres-pgvector:15
docker push ghcr.io/${GHCR_USER}/postgres-pgvector:15

# Очистить секреты
unset GHCR_PAT
unset GHCR_USER
```

 
### Обновление prod (myvm)
 
- После того как образ запушен, обновите `/opt/n8n/infra/supabase/.env.supabase`:
  - `POSTGRES_PGVECTOR_IMAGE=ghcr.io/<ORG>/postgres-pgvector:15`
- Затем на `myvm` выполнить:

```bash
cd /opt/n8n/infra/supabase
cp .env.supabase .env.supabase.bak
docker compose pull supabase-db || true
docker compose up -d --no-deps --force-recreate supabase-db
```

 
### Ansible Vault
 
- `tests/ansible/group_vars/all.yml` находится в Ansible Vault формате.
- Для неинтерактивного запуска используйте `--vault-password-file` или интегрируйте пароль в CI через Secrets.

 
### Non-interactive rsync/ssh
 
- Для `synchronize`/`rsync` используйте `--private-key` в `ansible-playbook` или настройте `~/.ssh/config` с нужным `IdentityFile`.

---

Если нужно, могу добавить шаблон GitHub Actions secret setup snippet или Ansible command examples в README.
