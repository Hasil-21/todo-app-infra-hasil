const crypto = require('crypto');
const logger = require('./logger');

// Paths that are called constantly by machines. Add your real health path.
const SKIP_PATHS = new Set(['/metrics', '/health', '/healthz']);

function requestLogger(req, res, next) {
  if (SKIP_PATHS.has(req.path)) return next();

  const start = process.hrtime.bigint();
  const requestId = req.headers['x-request-id'] || crypto.randomUUID();

  req.id = requestId;
  res.setHeader('X-Request-Id', requestId);
  req.log = logger.child({ request_id: requestId });

  res.on('finish', () => {
    const durationMs = Math.round(Number(process.hrtime.bigint() - start) / 1e6);
    const route = req.route ? (req.baseUrl || '') + req.route.path : 'unmatched';
    const level = res.statusCode >= 500 ? 'error' : res.statusCode >= 400 ? 'warn' : 'info';

    req.log[level](
      {
        method: req.method,
        route,
        status: res.statusCode,
        duration_ms: durationMs,
        amzn_trace_id: req.headers['x-amzn-trace-id'],
      },
      'request completed'
    );
  });

  next();
}

module.exports = requestLogger;