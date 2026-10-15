import { HttpError } from '../lib/http-error.js';
import { verifyAccessToken } from '../lib/tokens.js';

/** Protects a route. On success `req.userId` is the authenticated user's id. */
export function requireAuth(req, res, next) {
  const [scheme, token] = (req.headers.authorization ?? '').split(' ');

  if (scheme?.toLowerCase() !== 'bearer' || !token) {
    throw new HttpError(401, 'unauthorized', 'Missing access token');
  }

  req.userId = verifyAccessToken(token).userId;
  next();
}
