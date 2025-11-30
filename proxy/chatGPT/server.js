require('dotenv').config();
const express = require('express');
const setupRoutes = require('./routes');
const { errorHandler } = require('./errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

const corsOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map((origin) => origin.trim())
  : ['*'];

app.use(express.json());
app.use((req, res, next) => {
  const origin = req.headers.origin;

  if (corsOrigins.includes('*') || (origin && corsOrigins.includes(origin))) {
    res.header('Access-Control-Allow-Origin', origin || '*');
  }

  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.header('Access-Control-Expose-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  next();
});

if (process.env.LOG_REQUESTS === 'true') {
  app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
    next();
  });
}

setupRoutes(app);

/**
 * Error handling middleware
 */
app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`ChatGPT Proxy Server running on http://localhost:${PORT}`);
//   console.log(`CORS enabled for: ${corsOrigins.join(', ')}`);
//   console.log(`Available endpoints:`);
//   console.log(`  POST http://localhost:${PORT}/v1/chat/completions`);
//   console.log(`  GET  http://localhost:${PORT}/health`);
//   console.log(`  GET  http://localhost:${PORT}/`);
});

module.exports = app;
