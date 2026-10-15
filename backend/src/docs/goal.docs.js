import { errorResponse } from './responses.js';
import { json, notFound, protectedBodyErrors, protectedErrors, secured, withId } from './helpers.js';
import {
  contributionBodySchema,
  goalBodySchema,
  goalListResponseSchema,
  goalResponseSchema,
} from '../schemas/goal.schemas.js';

const goalNotFound = notFound('goal', 'goal_not_found');

export const goalPaths = {
  '/goals': {
    get: {
      tags: ['Goals'],
      summary: 'List goals (Objetivos)',
      description: 'Each goal comes with its progress. Goals never change the net worth.',
      ...secured,
      responses: {
        200: { description: 'The goals', content: json(goalListResponseSchema) },
        ...protectedErrors,
      },
    },
    post: {
      tags: ['Goals'],
      summary: 'Add a goal',
      ...secured,
      requestBody: { required: true, content: json(goalBodySchema) },
      responses: {
        201: { description: 'Created', content: json(goalResponseSchema) },
        ...protectedBodyErrors,
      },
    },
  },
  '/goals/{id}': {
    put: {
      tags: ['Goals'],
      summary: 'Edit a goal',
      description: 'Replaces every field, including the exact saved amount.',
      ...secured,
      ...withId,
      requestBody: { required: true, content: json(goalBodySchema) },
      responses: {
        200: { description: 'Updated', content: json(goalResponseSchema) },
        ...protectedBodyErrors,
        404: goalNotFound,
      },
    },
    delete: {
      tags: ['Goals'],
      summary: 'Delete a goal',
      ...secured,
      ...withId,
      responses: {
        204: { description: 'Deleted' },
        ...protectedErrors,
        404: goalNotFound,
      },
    },
  },
  '/goals/{id}/contributions': {
    post: {
      tags: ['Goals'],
      summary: 'Quick "+ add to goal"',
      description: 'Adds an amount to the saved amount.',
      ...secured,
      ...withId,
      requestBody: { required: true, content: json(contributionBodySchema) },
      responses: {
        200: { description: 'The goal with the new saved amount', content: json(goalResponseSchema) },
        400: errorResponse(
          'The body is invalid (`validation_error`) or the saved amount would pass the maximum (`amount_too_large`)',
          'amount_too_large',
          'The saved amount would be too large',
        ),
        ...protectedErrors,
        404: goalNotFound,
      },
    },
  },
};
