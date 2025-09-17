# Creating n8n Credentials (Postgres + Miro) — UI guide

This guide shows step-by-step how to create the Postgres and Miro credentials in the n8n UI. Replace the placeholder screenshots with your own captures (or use the screenshots in the repo if available).

## Overview
- File: `docs/architecture/integrations/credentials-ui.md`
- Screenshots: put images into `docs/architecture/integrations/images/` with the names used below.

---

## 1) Open Credentials
1. Login to your n8n instance.
2. From the left menu choose **Personal** → **Credentials** (or top menu Credentials).

![credentials-list](images/01-credentials-list.png)

## 2) Add Postgres credential
1. Click **Add** / **New Credential** (or **Add first credential**).
2. In the dialog choose **Postgres** as credential type.

![add-credential](images/02-add-credential.png)

3. Fill the Connection fields:
   - Host — e.g. `localhost` or your DB host
   - Database — e.g. `postgres` or `myproject_db`
   - User — database user (e.g. `n8n_user`)
   - Password — user password
   - Port — usually `5432`
   - Maximum Number of Connections — start with `5-20`
   - Ignore SSL Issues — leave off for prod

![postgres-form](images/03-postgres-form.png)

4. (Optional) On the **Details** tab add a description like `Project DB for Miro mapping`.
5. Click **Save**.

## 3) Add Miro credential (HTTP Header Auth)
1. Click **Add** → choose **HTTP Header Auth** (or Generic API key depending on UI).
2. In the header fields enter:
   - Name: `Authorization`
   - Value: `Bearer <YOUR_MIRO_TOKEN>`

![miro-credential](images/04-miro-credential.png)

3. Optionally add details/description and save.

## 4) Use credentials in workflow
- Open the workflow `Miro Sync - n8n` and open the Postgres node(s).
- Select the Postgres credential you created from the credential dropdown.
- Open each HTTP Request node for Miro and, if needed, select the HTTP header credential or set header manually using expression `Bearer {{$credentials["Miro Credential"].value}}`.

## 5) Test
- In the Postgres node click **Execute Node** to test DB connection.
- In the HTTP Request node (CreateMiro) click **Execute Node** to test Miro call (remember to use a safe test payload).

## Screenshots and naming
Place screenshots in `docs/architecture/integrations/images/` with these names:
- `01-credentials-list.png` — credentials landing page
- `02-add-credential.png` — add new credential dialog
- `03-postgres-form.png` — filled Postgres form
- `04-miro-credential.png` — filled Miro header auth

---

## Security notes
- Do NOT commit images that contain real tokens or passwords. Redact or blur sensitive fields before committing.
- Prefer storing tokens in n8n credentials UI rather than environment variables in plain text.

---

If you want, I can: 
- insert your provided screenshots into the guide (you uploaded one earlier), or
- produce ready-to-import screenshots by spinning a local n8n instance and capturing them.

What do you prefer?
