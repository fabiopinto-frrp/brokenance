import rateLimit from 'express-rate-limit';
import { config } from '../config/index.js';

/** Limits requests per IP address. Responds with the standard JSON error shape. */
export function createRateLimiter({ limit, windowMs = 15 * 60 * 1000 }) {
  return rateLimit({
    windowMs,
    limit,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    skip: () => config.env === 'test',
    handler: (req, res) =>
      res.status(429).json({
        error: { code: 'too_many_requests', message: 'Too many requests, try again later' },
      }),
  });
}
