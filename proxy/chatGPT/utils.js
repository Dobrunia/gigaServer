const axios = require('axios');

const OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions';

/**
 * Extract API key from Authorization header
 */
function extractApiKey(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return null;
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return null;
  }

  return parts[1];
}

/**
 * Proxy request to OpenAI
 */
async function proxyToOpenAI(apiKey, body, req, res, isStreaming = false) {
  const config = {
    method: 'POST',
    url: OPENAI_API_URL,
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    data: body,
    responseType: isStreaming ? 'stream' : 'json',
  };

  try {
    if (isStreaming) {
      const response = await axios(config);

      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');
      res.setHeader('X-Accel-Buffering', 'no'); // Disable nginx buffering

      response.data.on('data', (chunk) => {
        if (!res.destroyed) {
          res.write(chunk);
        }
      });

      response.data.on('end', () => {
        if (!res.destroyed) {
          res.end();
        }
      });

      response.data.on('error', (error) => {
        console.error('Stream error:', error);
        if (!res.destroyed) {
          res.write(
            `data: ${JSON.stringify({
              error: { message: 'Stream error', type: 'stream_error' },
            })}\n\n`
          );
          res.end();
        }
      });

      // Handle client disconnect
      req.on('close', () => {
        if (response.data && typeof response.data.destroy === 'function') {
          response.data.destroy();
        }
      });
    } else {
      // Handle regular JSON response
      const response = await axios(config);
      res.json(response.data);
    }
  } catch (error) {
    throw error; // Re-throw to be handled by error handler
  }
}

module.exports = {
  extractApiKey,
  proxyToOpenAI,
};
