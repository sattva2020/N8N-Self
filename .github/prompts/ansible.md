# Ansible prompt for this repository

Цель:

Краткие правила при работе с Ansible в этом репо:

1. Запуск и окружение
  ```bash
  source /home/sattva/.ansible-venv-wsl/bin/activate
  /home/sattva/.ansible-venv-wsl/bin/ansible-playbook -i tests/ansible/inventory.ini tests/ansible/playbooks/smoke.yml --check --diff -u root -vvvv
  ```

2. SSH и синхронизация
  - `private_key: /home/sattva/.ssh/id_rsa_n8n`
  - `use_ssh_args: true`
  - `_ssh_args: '-i /home/sattva/.ssh/id_rsa_n8n -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'`

3. Проверки и CI

4. Безопасность

5. Шаблон задачи (PR/issue prompt)

Пример быстрого промпта для PR-написания (русский):

"Добавил поддержку контроллерной синхронизации в `tests/ansible/playbooks/smoke.yml`.
"

Если нужно, могу добавить примеры `ansible.cfg`, шаблон inventory для локальной разработки и snippets для common tasks.
