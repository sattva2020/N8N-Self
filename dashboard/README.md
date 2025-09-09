Dashboard (Fastify backend + React frontend)

Quick start (development)

1. Backend

```bash
cd dashboard/backend
npm install
npm run dev
```

2. Frontend

```bash
cd dashboard/frontend
npm install
npm run dev
```

Build for production

```bash
cd dashboard/backend
npm run build
cd ../frontend
npm run build
```

The backend exposes several endpoints under /api (health, services, logs, events).
