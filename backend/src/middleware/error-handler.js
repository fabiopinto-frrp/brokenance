import { ZodError } from 'zod';
import { config } from '../config/index.js';
import { HttpError } from '../lib/http-error.js';

const body = (code, message, details) => ({
  error: { code, message, ...(details ? { details } : {}) },
});

export function notFound(req, res) {
  res.status(404).json(body('not_found', 'Route not found'));
}

// Express recognises error handlers by their four arguments, so `next` must stay.
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  if (err instanceof HttpError) {
    return res.status(err.status).json(body(err.code, err.message));
  }

  if (err instanceof ZodError) {
    return res.status(400).json(body('validation_error', 'Invalid request', err.issues));
  }

  if (err.type === 'entity.parse.failed') {
    return res.status(400).json(body('invalid_json', 'Request body is not valid JSON'));
  }

  if (err.type === 'entity.too.large') {
    return res.status(413).json(body('payload_too_large', 'Request body is too large'));
  }

  console.error(err);
  const message = config.isProduction ? 'Internal server error' : err.message;
  return res.status(500).json(body('internal_error', message));
}
