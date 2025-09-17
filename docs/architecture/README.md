
# Architecture-as-code examples and CI helpers

This folder contains examples and conventions for storing diagrams-as-code.

## Files

- `workspace.dsl` — Structurizr DSL (C4) minimal example.
- `er.mmd` — Mermaid ER example.
- `sequence.mmd` — Mermaid sequence example.

## Rendering locally via Kroki (quick)

Windows (PowerShell):

```powershell
# Render ER to PNG using public kroki
Invoke-RestMethod -Method Post -Uri "https://kroki.io/mermaid/png" -InFile "er.mmd" -OutFile "er.png"
```

Unix (bash):

```bash
curl -sX POST -H "Content-Type: text/plain" --data-binary @er.mmd https://kroki.io/mermaid/png > er.png
```

## Structurizr (CLI/SaaS)

- Use `structurizr-cli` to push `workspace.dsl` to Structurizr (requires API key/secret) or render locally with the CLI.
- See the Structurizr CLI docs: [Structurizr CLI](https://structurizr.com/help/cli)

## CI notes

- Recommend using `KROKI_URL` secret if you host a private Kroki instance.
- Small diagrams are safe on public `kroki.io`; for larger diagrams self-hosting Kroki is recommended.

## Conventions

- Keep diagrams in `docs/architecture/`.
- Rendered outputs go to `docs/architecture/out/` (generated; don't commit render artifacts unless desired).
