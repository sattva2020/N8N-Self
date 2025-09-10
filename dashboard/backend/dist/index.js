'use strict';
var __importDefault =
  (this && this.__importDefault) ||
  function (mod) {
    return mod && mod.__esModule ? mod : { default: mod };
  };
Object.defineProperty(exports, '__esModule', { value: true });
const fastify_1 = __importDefault(require('fastify'));
const dockerode_1 = __importDefault(require('dockerode'));
const dotenv_1 = __importDefault(require('dotenv'));
dotenv_1.default.config();
const fastify = (0, fastify_1.default)({ logger: true });
const docker = new dockerode_1.default({
  socketPath: process.env.DOCKER_SOCKET || '/var/run/docker.sock',
});
fastify.get('/api/health', async () => ({ ok: true }));
fastify.get('/api/services', async (request, reply) => {
  try {
    const containers = await docker.listContainers({ all: true });
    const services = containers.map((c) => ({
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
  const { id } = request.params;
  const body = request.body;
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
  const { id } = request.params;
  const tail = Number(request.query?.tail || 200);
  try {
    const container = docker.getContainer(id);
    const stream = await container.logs({ stdout: true, stderr: true, tail, follow: false });
    const chunks = [];
    for await (const chunk of stream) chunks.push(Buffer.from(chunk));
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
const start = async () => {
  try {
    await fastify.listen({ port: Number(process.env.PORT || 3000), host: '0.0.0.0' });
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};
start();
