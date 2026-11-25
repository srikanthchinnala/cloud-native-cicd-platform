const express = require('express');
const client = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || 'dev';
const COLOR = process.env.DEPLOY_COLOR || 'local';

// ---- Prometheus metrics ----
const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequests = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status'],
  registers: [register],
});

const httpDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request latency in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2],
  registers: [register],
});

app.use((req, res, next) => {
  const end = httpDuration.startTimer();
  res.on('finish', () => {
    const route = req.route ? req.route.path : req.path;
    const labels = { method: req.method, route, status: res.statusCode };
    httpRequests.inc(labels);
    end(labels);
  });
  next();
});

// ---- Routes ----
app.get('/', (req, res) => {
  res.send(`<!doctype html>
<html><head><title>Cloud-Native Demo</title>
<style>body{font-family:system-ui;margin:4rem;background:#0f172a;color:#e2e8f0}
.badge{display:inline-block;padding:.3rem .8rem;border-radius:999px;background:${COLOR === 'green' ? '#16a34a' : '#2563eb'}}</style>
</head><body>
<h1>Cloud-Native CI/CD Platform</h1>
<p>Version: <strong>${VERSION}</strong></p>
<p>Active slot: <span class="badge">${COLOR}</span></p>
</body></html>`);
});

app.get('/api/info', (req, res) => {
  res.json({ version: VERSION, color: COLOR, hostname: require('os').hostname() });
});

// Liveness and readiness probes for Kubernetes
app.get('/healthz', (req, res) => res.status(200).json({ status: 'ok' }));
app.get('/readyz', (req, res) => res.status(200).json({ status: 'ready' }));

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

if (require.main === module) {
  app.listen(PORT, () => console.log(`App ${VERSION} (${COLOR}) listening on ${PORT}`));
}

module.exports = app;
