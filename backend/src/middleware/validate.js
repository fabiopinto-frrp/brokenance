/**
 * Validates `req.body` with a zod schema. On success `req.body` is replaced by the parsed value
 * (trimmed, lowercased, defaults applied). On failure the error handler answers with a 400.
 */
export const validateBody = (schema) => (req, res, next) => {
  req.body = schema.parse(req.body);
  next();
};

/** Same as validateBody, for the URL parameters (`/goals/:id`). */
export const validateParams = (schema) => (req, res, next) => {
  req.params = schema.parse(req.params);
  next();
};

/** Same as validateBody, for the query string (`?type=expense&from=2026-10-01`). */
export const validateQuery = (schema) => (req, res, next) => {
  // In Express 5 `req.query` is a read-only getter, so the parsed value is defined on the
  // request itself. Controllers keep reading `req.query`.
  Object.defineProperty(req, 'query', { value: schema.parse(req.query), enumerable: true });
  next();
};
