import Fastify, { FastifyRequest, FastifyReply } from 'fastify';
import Docker from 'dockerode';
import dotenv from 'dotenv';
import client from 'prom-client';

dotenv.config();
const fastify = Fastify({ logger: true });
const docker = new Docker({ socketPath: process.env.DOCKER_SOCKET || '/var/run/docker.sock' });

// Prometheus metrics
const register = new client.Registry();
client.collectDefaultMetrics({ register });
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'] as const,
  buckets: [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
});
register.registerMetric(httpRequestDuration);

fastify.addHook('onRequest', async (req, _res) => {
  // attach start time
  (req as any)._start = process.hrtime.bigint();
});

fastify.addHook('onResponse', async (req, reply) => {
  try {
    const start = (req as any)._start as bigint | undefined;
    if (start) {
      const diffNs = Number(process.hrtime.bigint() - start);
      const seconds = diffNs / 1e9;
      const route = (reply as any).context?.config?.url || req.routerPath || req.raw.url || 'unknown';
      httpRequestDuration
        .labels(req.method, route, String(reply.statusCode))
        .observe(seconds);
    }
  } catch (e) {
    fastify.log.debug('metrics error', e);
  }
});

fastify.get('/api/health', async () => ({ ok: true }));

fastify.get('/api/info', async () => ({
  service: 'dashboard-backend',
  version: process.env.npm_package_version || '0.0.0',
  env: process.env.NODE_ENV || 'development',
}));

fastify.get('/api/services', async (request: FastifyRequest, reply: FastifyReply) => {
  try {
    const containers = await docker.listContainers({ all: true });
    const services = containers.map((c: any) => ({
      id: c.Id,
      names: c.Names,
      image: c.Image,
      status: c.Status,
      labels: c.Labels,
    }));
    return reply.send(services);
  } catch (err) {
    fastify.log.error(err);
    return reply.status(500).send({ error: 'docker-unavailable' });
  }
});

// trigger start/stop/restart
fastify.post('/api/services/:id/action', async (request, reply) => {
  const { id } = request.params as any;
  const body = request.body as any;
  const action = body?.action;
  try {
    const container = docker.getContainer(id);
    if (action === 'start') await container.start();
    else if (action === 'stop') await container.stop();
    else if (action === 'restart') await container.restart();
    else return reply.status(400).send({ error: 'invalid-action' });
    return { status: 'accepted' };
  } catch (err) {
    fastify.log.error(err);
    return reply.status(500).send({ error: 'action-failed' });
  }
});

// logs tail
fastify.get('/api/services/:id/logs', async (request, reply) => {
  const { id } = request.params as any;
  const tail = Number((request.query as any)?.tail || 200);
  try {
    const container = docker.getContainer(id);
    const stream = await container.logs({ stdout: true, stderr: true, tail, follow: false });
    const chunks: Buffer[] = [];
    for await (const chunk of stream as any) chunks.push(Buffer.from(chunk));
    const out = Buffer.concat(chunks).toString('utf8');
    reply.type('text/plain').send(out);
  } catch (err) {
    fastify.log.error(err);
    reply.status(500).send('error');
  }
});

// simple SSE for services updates
fastify.get('/api/events', (request, reply) => {
  reply.raw.writeHead(200, {
    Connection: 'keep-alive',
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
  });
  const interval = setInterval(
    async () => {
      const containers = await docker.listContainers({ all: true });
      reply.raw.write(`data: ${JSON.stringify(containers)}\n\n`);
    },
    Number(process.env.POLL_INTERVAL || 15000)
  );
  request.raw.on('close', () => clearInterval(interval));
});

// basic health prober for containers (just wrapper)
fastify.get('/api/health/probe', async () => ({ ok: true, timestamp: Date.now() }));

// Prometheus metrics endpoint
fastify.get('/metrics', async (_req, reply) => {
  reply.type(register.contentType);
  return await register.metrics();
});

const start = async () => {
  try {
    await fastify.listen({ port: Number(process.env.PORT || 3000), host: '0.0.0.0' });
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
