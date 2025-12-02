require('dotenv').config();
const socks = require('socksv5');

const PORT = process.env.PORT || 1080;
const LOG_CONNECTIONS = process.env.LOG_CONNECTIONS === 'true';

// Parse tokens from environment variables
function parseTokens() {
  const tokens = new Set();
  let tokenIndex = 1;

  while (true) {
    const tokenKey = `TOKEN${tokenIndex}`;
    const token = process.env[tokenKey];

    if (!token) {
      break;
    }

    tokens.add(token.trim());
    tokenIndex++;
  }

  return tokens;
}

const validTokens = parseTokens();

if (validTokens.size === 0) {
  console.error('Error: No tokens configured. Please set TOKEN1, TOKEN2, etc. in .env');
  console.error('Example: TOKEN1=your-secret-token-here');
  process.exit(1);
}

// Authentication handler - токен используется как username, password игнорируется
const auth = socks.auth.UserPassword((username, password, callback) => {
  // Проверяем, что переданный username (токен) есть в списке разрешенных
  if (validTokens.has(username)) {
    if (LOG_CONNECTIONS) {
      console.log(
        `[${new Date().toISOString()}] ✅ Authenticated token: ${username.substring(0, 8)}...`
      );
    }
    callback(true);
  } else {
    // Логируем все попытки доступа для безопасности
    console.warn(
      `[${new Date().toISOString()}] ❌ Unauthorized access attempt from ${
        username ? username.substring(0, 8) + '...' : 'unknown'
      }`
    );
    callback(false);
  }
});

// Create SOCKS5 server
const server = socks.createServer((info, accept, deny) => {
  if (LOG_CONNECTIONS) {
    console.log(
      `[${new Date().toISOString()}] Connection from ${info.srcAddr}:${info.srcPort} to ${
        info.dstAddr
      }:${info.dstPort}`
    );
  }

  // Accept the connection
  const socket = accept(true);

  socket.on('error', (err) => {
    if (LOG_CONNECTIONS) {
      console.error(`[${new Date().toISOString()}] Socket error:`, err.message);
    }
  });

  socket.on('close', () => {
    if (LOG_CONNECTIONS) {
      console.log(
        `[${new Date().toISOString()}] Connection closed: ${info.dstAddr}:${info.dstPort}`
      );
    }
  });
});

// Set authentication handler
server.useAuth(auth);

// Error handling
server.on('error', (err) => {
  console.error(`[${new Date().toISOString()}] Server error:`, err);
});

// Start server
server.listen(PORT, '0.0.0.0', () => {
  console.log(`SOCKS5 Proxy Server running on port ${PORT}`);
  console.log(`Configured tokens: ${validTokens.size}`);
  console.log(`Connection logging: ${LOG_CONNECTIONS ? 'enabled' : 'disabled'}`);
  console.log(`\nTo use this proxy:`);
  console.log(`  Type: SOCKS5`);
  console.log(`  Host: localhost`);
  console.log(`  Port: ${PORT}`);
  console.log(`  Username: <your-token>`);
  console.log(`  Password: <any or empty>`);
  console.log(`\n⚠️  Only authorized tokens can connect. All unauthorized attempts are logged.`);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\nShutting down server...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

process.on('SIGTERM', () => {
  console.log('\nShutting down server...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

module.exports = server;
