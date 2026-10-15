import { z } from 'zod';

// Building blocks shared by every module's documentation (*.docs.js).

export const errorSchema = z
  .object({
    error: z.object({
      code: z.string().meta({ description: 'Stable code the app can react to and translate' }),
      message: z.string().meta({ description: 'Human readable message, in English' }),
      details: z.array(z.unknown()).optional().meta({
        description: 'Only for validation errors: the list of invalid fields',
      }),
    }),
  })
  .meta({ id: 'Error', description: 'Every error response has this shape' });

/** Documents an error response with an example `code` and `message`. */
export const errorResponse = (description, code, message) => ({
  description,
  content: {
    'application/json': {
      schema: errorSchema,
      example: { error: { code, message } },
    },
  },
});

export const validationError = errorResponse(
  'The request body is invalid',
  'validation_error',
  'Invalid request',
);

export const tooManyRequests = errorResponse(
  'Too many attempts from this IP address, try again in 15 minutes',
  'too_many_requests',
  'Too many requests, try again later',
);

export const unauthorized = errorResponse(
  'Missing, invalid or expired access token. If the code is `token_expired`, call `POST /auth/refresh` and retry.',
  'token_expired',
  'Access token has expired',
);
