import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import { config } from '../config/index.js';
import { HttpError } from './http-error.js';

const ISSUER = 'brokenance';
const ALGORITHM = 'HS256';

/** Short-lived JWT sent in the `Authorization: Bearer` header. */
export function signAccessToken(userId) {
  const token = jwt.sign({}, config.jwt.accessSecret, {
    algorithm: ALGORITHM,
    issuer: ISSUER,
    subject: userId,
    expiresIn: config.jwt.accessTtl,
  });
  const { exp } = jwt.decode(token);
  return { token, expiresAt: new Date(exp * 1000) };
}

export function verifyAccessToken(token) {
  try {
    const payload = jwt.verify(token, config.jwt.accessSecret, {
      algorithms: [ALGORITHM],
      issuer: ISSUER,
    });
    return { userId: payload.sub };
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw new HttpError(401, 'token_expired', 'Access token has expired');
    }
    throw new HttpError(401, 'invalid_token', 'Access token is invalid');
  }
}

/** Long-lived, random and opaque. Only its hash is stored in the database. */
export const generateRefreshToken = () => crypto.randomBytes(48).toString('base64url');

// The token is 384 bits of randomness, so a fast hash is enough (no need for argon2 here).
export const hashToken = (token) => crypto.createHash('sha256').update(token).digest('hex');
