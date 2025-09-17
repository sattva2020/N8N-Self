
# Structurizr integration

This document explains how to push `workspace.dsl` to Structurizr (SaaS) and local options.

## 1) Quick: Structurizr CLI (recommended for automation)

Install (requires Java):

- Download the CLI from Structurizr site or use Docker image `structurizr/cli`.

Using Docker (example):

```bash
docker run --rm -v $(pwd)/docs/architecture:/workspace structurizr/cli push -workspace /workspace/workspace.dsl -url https://api.structurizr.com -apiKey $STRUCTURIZR_KEY -apiSecret $STRUCTURIZR_SECRET
```

Using the binary (local):

```bash
# assuming `structurizr-cli.jar` and a simple config
java -jar structurizr-cli.jar push -workspace docs/architecture/workspace.dsl -url https://api.structurizr.com -apiKey $STRUCTURIZR_KEY -apiSecret $STRUCTURIZR_SECRET
```

## 2) GitHub Actions example (safe placeholder)

Add secrets `STRUCTURIZR_KEY` and `STRUCTURIZR_SECRET` in repository settings.

```yaml
- name: Push to Structurizr
  if: github.ref == 'refs/heads/main'
  run: |
    docker run --rm -v ${{ github.workspace }}/docs/architecture:/workspace structurizr/cli push -workspace /workspace/workspace.dsl -url https://api.structurizr.com -apiKey $STRUCTURIZR_KEY -apiSecret $STRUCTURIZR_SECRET
  env:
    STRUCTURIZR_KEY: ${{ secrets.STRUCTURIZR_KEY }}
    STRUCTURIZR_SECRET: ${{ secrets.STRUCTURIZR_SECRET }}
```

## 3) Local preview / offline

Structurizr Desktop / Enterprise support offline previews but for most CI flows pushing to SaaS is easiest.

## Notes & recommendations

- Keep `workspace.dsl` in `docs/architecture/` and include short documentation blocks for any components you want on the Structurizr site.
- Use branch protection and require review before pushing to main if Structurizr sync is enabled.
- Consider using Structurizr workspaces per-environment (staging / prod) if you need separate views.
