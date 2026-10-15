import { idParams } from '../schemas/common.schemas.js';
import { errorResponse, unauthorized, validationError } from './responses.js';

// Small helpers to keep the *.docs.js files short.

export const json = (schema) => ({ 'application/json': { schema } });

export const secured = { security: [{ bearerAuth: [] }] };

/** Error responses every protected endpoint can return. */
export const protectedErrors = { 401: unauthorized };

/** Error responses of a protected endpoint that receives a body. */
export const protectedBodyErrors = { 400: validationError, 401: unauthorized };

export const notFound = (what, code) =>
  errorResponse(`The ${what} does not exist or belongs to another user`, code, `${what[0].toUpperCase()}${what.slice(1)} not found`);

export const dateInFuture = errorResponse(
  'The body is invalid (`validation_error`) or the date is after today (`date_in_future`)',
  'date_in_future',
  'The date cannot be in the future',
);

/** Documents the `:id` path parameter. Paths use the OpenAPI form: '/goals/{id}'. */
export const withId = { requestParams: { path: idParams } };
