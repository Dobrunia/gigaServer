/**
 * Error handling middleware
 */
function errorHandler(err, req, res, next) {
  console.error('Error:', err);
  res.status(500).json({
    error: {
      message: 'Internal server error',
      type: 'server_error',
    },
  });
}

/**
 * Send error response (SSE or JSON)
 */
function sendError(res, errorData, statusCode, isStreaming) {
  if (isStreaming && !res.headersSent) {
    res.setHeader('Content-Type', 'text/event-stream');
    res.write(`data: ${JSON.stringify(errorData)}\n\n`);
    res.end();
  } else {
    res.status(statusCode).json(errorData);
  }
}

/**
 * Handle OpenAI API errors
 */
function handleOpenAIError(error, isStreaming, res) {
  let errorData;
  let statusCode = 500;

  if (error.response) {
    // OpenAI API error
    statusCode = error.response.status;
    errorData = error.response.data || {
      error: { message: 'OpenAI API error', type: 'api_error' },
    };
  } else if (error.request) {
    // Request made but no response
    errorData = {
      error: { message: 'No response from OpenAI API', type: 'network_error' },
    };
  } else {
    // Error setting up request
    errorData = {
      error: { message: error.message, type: 'request_error' },
    };
  }

  sendError(res, errorData, statusCode, isStreaming);
}

/**
 * Validation errors
 */
function validationError(message, type = 'invalid_request_error') {
  return {
    error: {
      message,
      type,
    },
  };
}

module.exports = {
  errorHandler,
  handleOpenAIError,
  validationError,
};
