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

Notes:

- This playbook installs Docker (if missing), syncs `stack/` and `secrets/`, renders `stack/.env`, and runs `docker compose`.
- It then waits for Traefik and n8n endpoints to respond over HTTPS.
- For production, maintain secrets on the server. Local `secrets/` sync is optional and can be removed.

Windows tips:

- Use WSL or Git Bash for Ansible commands; native Ansible on Windows isn’t supported — run from a Linux shell.
