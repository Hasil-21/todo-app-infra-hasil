require('dotenv').config();
const express = require('express');
const cors = require('cors');
const logger = require('./logger');
const requestLogger = require('./requestLogger');
const { metricsMiddleware, metricsHandler } = require('./metrics');

const authRoutes = require('./routes/auth');
const taskRoutes = require('./routes/tasks');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors({ origin: process.env.CLIENT_ORIGIN || '*' }));
app.use(express.json());

app.get('/health', (req, res) => res.json({status : 'ok'}));
app.use(metricsMiddleware);        
app.get('/metrics', metricsHandler);
app.use('/api', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use(requestLogger);

app.use((err, req, res, next) => {
  (req.log || logger).error({ err }, 'unhandled error');
  res.status(500).json({ error: 'Internal server error' });
});

const server = app.listen(PORT, () => logger.info({ port: PORT }, 'server started')); 

process.on('unhandledRejection', (reason) => logger.error({ err: reason }, 'unhandled rejection'));
process.on('uncaughtException', (err) => { logger.fatal({ err }, 'uncaught exception'); process.exit(1); });

server.keepAliveTimeout = 65000;
server.keepAliveTimeoutBuffer = 66000;

module.exports = app;
