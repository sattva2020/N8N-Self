
# Miro sync (n8n) — example

This folder contains a minimal n8n workflow to sync a JSON list of services into a Miro board as sticky notes.

## Files

- `miro-n8n.json` — importable n8n workflow. The workflow exposes a POST webhook at `/webhook/miro-sync` which accepts JSON:

```json
{
  "services": [
    {"id":"svc1","name":"API","description":"Main API","owner":"team-a","url":"https://api"}
  ]
}
```

## Environment variables required (in n8n or OS env)

- `MIRO_TOKEN` — personal access token for Miro with widget:write scopes.
- `MIRO_BOARD_ID` — target board id.

## Postgres mapping (n8n)

- This workflow uses a Postgres table `miro_mapping(service_id TEXT PRIMARY KEY, widget_id TEXT)` to store mapping from your service id to the created Miro widget id.
- Configure a Postgres credential in n8n (Credentials → Create → Postgres) with host, port, database, user and password. The n8n Postgres nodes in the workflow reference that credential when running.
- Alternatively, run the SQL manually to create the table before first run:

```sql
CREATE TABLE IF NOT EXISTS miro_mapping (
  id SERIAL PRIMARY KEY,
  service_id TEXT UNIQUE NOT NULL,
  widget_id TEXT
);
```

Notes:
- Use n8n's built-in Postgres credential UI instead of environment variables for security.
- For high-throughput syncs consider adding an UPSERT/transaction or a single SQL upsert instead of separate SELECT/INSERT/UPDATE steps.

## Import steps

1. In n8n, go to Workflows → Import and choose `miro-n8n.json`.
2. Set environment variables in n8n (or edit the HTTP Request node to inject token directly for testing).
3. Activate the workflow (or test via the webhook's test URL). Send a POST as shown above.

## n8n credentials template

You can import credentials into n8n using a credentials JSON. A small template is provided at `docs/architecture/integrations/n8n-credentials-template.json` (do NOT commit real secrets; replace placeholders locally before import). Steps:

1. In n8n, go to Credentials → Import and paste the JSON content from the template (or upload the file).
2. Replace placeholders: `{{MIRO_TOKEN}}`, `{{PG_HOST}}`, `{{PG_PORT}}`, `{{PG_DATABASE}}`, `{{PG_USER}}`, `{{PG_PASSWORD}}`.
3. Alternatively, create credentials manually via Credentials → New Credential and choose the appropriate type (Postgres, HTTP Header Auth).

Security note: prefer storing secrets via the n8n credential UI. Never commit real passwords or tokens into the repo.

For a step-by-step UI guide with screenshots see `docs/architecture/integrations/credentials-ui.md`.

## Notes & improvements

- This example creates a sticky note per service at coordinates (0,0). For production, add layout logic (grid placement) and idempotency (store created widget ids to update instead of recreate).
- Respect rate limits; add throttling or batch processing if syncing many services.
