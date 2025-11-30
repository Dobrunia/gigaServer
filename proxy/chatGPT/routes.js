const { extractApiKey, proxyToOpenAI } = require('./utils');
const { handleOpenAIError, validationError } = require('./errorHandler');

function setupRoutes(app) {
  // Main chat completions endpoint
  app.post('/v1/chat/completions', async (req, res) => {
    try {
      // Extract API key
      const apiKey = extractApiKey(req);

      if (!apiKey) {
        return res
          .status(401)
          .json(
            validationError('Missing API key. Please provide Authorization: Bearer <key> header')
          );
      }

      // Validate request body
      if (!req.body || !req.body.messages) {
        return res.status(400).json(validationError('Missing required parameter: messages'));
      }

      // Check if streaming is requested
      const isStreaming = req.body.stream === true;

      // Proxy to OpenAI
      await proxyToOpenAI(apiKey, req.body, req, res, isStreaming);
    } catch (error) {
      const isStreaming = req.body?.stream === true;
      handleOpenAIError(error, isStreaming, res);
    }
  });

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  // Root endpoint - server info
  app.get('/', (req, res) => {
    res.json({
      name: 'ChatGPT Proxy Server',
      version: '1.0.0',
      endpoints: {
        'POST /v1/chat/completions': 'Chat completions (OpenAI-compatible)',
        'GET /health': 'Health check',
        'GET /': 'Server information',
      },
      usage: {
        example:
          'curl -X POST http://localhost:3000/v1/chat/completions \\\n  -H "Authorization: Bearer sk-your-key" \\\n  -H "Content-Type: application/json" \\\n  -d \'{"model": "gpt-4", "messages": [{"role": "user", "content": "Hello"}]}\'',
      },
    });
  });
}

module.exports = setupRoutes;
