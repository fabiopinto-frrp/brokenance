import {
  errorResponse,
  tooManyRequests,
  unauthorized,
  validationError,
} from './responses.js';
import {
  changePasswordSchema,
  loginSchema,
  meResponseSchema,
  refreshSchema,
  registerSchema,
  sessionResponseSchema,
  tokensResponseSchema,
} from '../schemas/auth.schemas.js';

// OpenAPI description of the auth endpoints. It reuses the zod schemas that validate the
// requests, so the documentation cannot drift from the code. It is collected in
// docs/openapi.js.

const json = (schema) => ({ 'application/json': { schema } });

export const authPaths = {
  '/auth/register': {
    post: {
      tags: ['Auth'],
      summary: 'Create an account',
      description:
        'Creates the user and its profile and logs the user in. The app checks "confirm password" in its form, so the API receives the password once. Can be turned off with `REGISTRATION_ENABLED=false`. Limited to 10 requests per 15 minutes per IP.',
      requestBody: { required: true, content: json(registerSchema) },
      responses: {
        201: { description: 'Account created', content: json(sessionResponseSchema) },
        400: validationError,
        403: errorResponse('Registration is disabled', 'registration_disabled', 'Registration is disabled'),
        409: errorResponse('The username is already taken', 'username_taken', 'This username is already taken'),
        429: tooManyRequests,
      },
    },
  },
  '/auth/login': {
    post: {
      tags: ['Auth'],
      summary: 'Log in',
      description:
        'Returns the user and a new pair of tokens. A wrong password and an unknown username give the same error. Limited to 10 requests per 15 minutes per IP.',
      requestBody: { required: true, content: json(loginSchema) },
      responses: {
        200: { description: 'Logged in', content: json(sessionResponseSchema) },
        400: validationError,
        401: errorResponse(
          'Username or password is incorrect',
          'invalid_credentials',
          'Username or password is incorrect',
        ),
        429: tooManyRequests,
      },
    },
  },
  '/auth/refresh': {
    post: {
      tags: ['Auth'],
      summary: 'Get a new access token (stay logged in)',
      description:
        'Call this when the app starts and when an access token expires. The refresh token is **rotated**: the response contains a new one and the old one stops working. Using an old refresh token again revokes that whole login. If this fails with 401 the session is over and the user must log in again.',
      requestBody: { required: true, content: json(refreshSchema) },
      responses: {
        200: { description: 'New tokens', content: json(tokensResponseSchema) },
        400: validationError,
        401: errorResponse(
          'The refresh token is unknown, expired, already used or revoked. Codes: `invalid_refresh_token`, `refresh_token_expired`.',
          'invalid_refresh_token',
          'Refresh token is invalid, please log in again',
        ),
      },
    },
  },
  '/auth/logout': {
    post: {
      tags: ['Auth'],
      summary: 'Log out',
      description:
        'Revokes the refresh token and every token created from it (this device only). Always succeeds, even if the token is unknown.',
      requestBody: { required: true, content: json(refreshSchema) },
      responses: {
        204: { description: 'Logged out' },
        400: validationError,
      },
    },
  },
  '/auth/me': {
    get: {
      tags: ['Auth'],
      summary: 'Current user',
      description: 'Returns the logged-in user. Useful to check that a session is valid.',
      security: [{ bearerAuth: [] }],
      responses: {
        200: { description: 'The logged-in user', content: json(meResponseSchema) },
        401: unauthorized,
      },
    },
  },
  '/auth/password': {
    put: {
      tags: ['Auth'],
      summary: 'Change password',
      description:
        'Changes the password of the logged-in user. **Every session is revoked**, so other devices are logged out. The response contains a new pair of tokens for this device: store them and drop the old ones. Limited to 10 requests per 15 minutes per IP.',
      security: [{ bearerAuth: [] }],
      requestBody: { required: true, content: json(changePasswordSchema) },
      responses: {
        200: { description: 'Password changed, new tokens for this device', content: json(tokensResponseSchema) },
        400: errorResponse(
          'The body is invalid (`validation_error`) or the current password is wrong (`invalid_current_password`)',
          'invalid_current_password',
          'Current password is incorrect',
        ),
        401: unauthorized,
        429: tooManyRequests,
      },
    },
  },
};
