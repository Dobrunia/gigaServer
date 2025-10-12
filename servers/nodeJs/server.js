const express = require('express');
const app = express();
const PORT = 59887;

// Middleware to capture raw body
app.use(express.raw({ type: '*/*' }));

// CORS middleware
app.use((req, res, next) => {
  // Set CORS headers
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
  res.header(
    'Access-Control-Allow-Headers',
    'x-test,ngrok-skip-browser-warning,Content-Type,Accept,Access-Control-Allow-Headers'
  );

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  next();
});

// Route /result4/ - returns JSON with required properties
app.all('/result4/', (req, res) => {
  // Get x-test header value
  const xTestValue = req.headers['x-test'] || '';

  // Get request body value (raw body as string)
  let bodyValue = '';
  if (req.body) {
    if (Buffer.isBuffer(req.body)) {
      bodyValue = req.body.toString('utf8');
    } else if (typeof req.body === 'string') {
      bodyValue = req.body;
    }
  }

  // Create response object
  const response = {
    message: 'dbe14467-cf9f-4f6d-844e-35d284ae4d2d',
    'x-result': xTestValue,
    'x-body': bodyValue,
  };

  // Set Content-Type header
  res.setHeader('Content-Type', 'application/json');

  // Send JSON response
  res.json(response);
});

// Route /login - returns login
app.get('/login', (req, res) => {
  res.send('dbe14467-cf9f-4f6d-844e-35d284ae4d2d');
});

// Route /hour - returns current hour in Moscow time (HH format)
app.get('/hour', (req, res) => {
  // Get current time in Moscow timezone
  const now = new Date();
  const moscowTime = new Date(now.toLocaleString('en-US', { timeZone: 'Europe/Moscow' }));
  const hour = moscowTime.getHours().toString().padStart(2, '0');

  res.send(hour);
});

// Health check route
app.get('/', (req, res) => {
  res.json({
    message: `CORS Server running on port ${PORT}`,
    routes: ['/result4/', '/login', '/hour'],
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`CORS enabled for all origins`);
  console.log(`Available routes:`);
  console.log(`  GET/POST/PUT/DELETE http://localhost:${PORT}/result4/`);
  console.log(`  GET http://localhost:${PORT}/login`);
  console.log(`  GET http://localhost:${PORT}/hour`);
});

module.exports = app;
