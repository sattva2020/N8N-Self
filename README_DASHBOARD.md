Dashboard scaffold

This folder contains a minimal scaffold for a project dashboard.

Components:
- Keycloak (dev) on port 8081
- oauth2-proxy on port 4180
- dashboard-backend (Fastify, uses dockerode)
- dashboard-frontend (React + Vite)

How to run (dev):
1. Edit `infra/docker-compose.dashboard.yml` and set DOMAIN_NAME and secrets in environment.
2. Build backend and frontend images:
   cd infra && docker compose -f docker-compose.dashboard.yml up --build

Notes:
- oauth2-proxy needs client secret and cookie secret set properly.
- Keycloak realm/client should be configured; see docs in repo for example realm JSON.
