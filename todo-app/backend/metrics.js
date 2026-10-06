const client = require('prom-client');

// Node.js runtime metrics: event loop lag, heap, GC, CPU, open handles
client.collectDefaultMetrics();

const httpDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
});

function metricsMiddleware(req, res, next) {
  if (req.path === '/metrics') return next();   // don't measure scrapes
  const end = httpDuration.startTimer();
  res.on('finish', () => {
    // req.route only exists after routing, so read it here, not above
    const route = req.route ? (req.baseUrl || '') + req.route.path : 'unmatched';
    end({ method: req.method, route, status_code: res.statusCode });
  });
  next();
}

async function metricsHandler(req, res) {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
}

module.exports = { metricsMiddleware, metricsHandler };