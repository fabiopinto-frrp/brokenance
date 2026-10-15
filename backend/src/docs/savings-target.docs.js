import { dateInFuture, json, notFound, protectedErrors, secured, withId } from './helpers.js';
import {
  savingsTargetBodySchema,
  savingsTargetListResponseSchema,
  savingsTargetResponseSchema,
} from '../schemas/savings-target.schemas.js';

const targetNotFound = notFound('savings target', 'savings_target_not_found');

export const savingsTargetPaths = {
  '/savings-targets': {
    get: {
      tags: ['Savings targets'],
      summary: 'List monthly savings targets (Poupança)',
      description: 'The current target and the history. Targets never change the net worth.',
      ...secured,
      responses: {
        200: { description: 'The targets', content: json(savingsTargetListResponseSchema) },
        ...protectedErrors,
      },
    },
    post: {
      tags: ['Savings targets'],
      summary: 'Set a new monthly savings target',
      description: 'It becomes the current target. The previous one stays as history.',
      ...secured,
      requestBody: { required: true, content: json(savingsTargetBodySchema) },
      responses: {
        201: { description: 'Created', content: json(savingsTargetResponseSchema) },
        400: dateInFuture,
        ...protectedErrors,
      },
    },
  },
  '/savings-targets/{id}': {
    put: {
      tags: ['Savings targets'],
      summary: 'Edit a savings target',
      description: 'Editing an old row only changes the history. Without `effectiveDate` the row keeps its date.',
      ...secured,
      ...withId,
      requestBody: { required: true, content: json(savingsTargetBodySchema) },
      responses: {
        200: { description: 'Updated', content: json(savingsTargetResponseSchema) },
        400: dateInFuture,
        ...protectedErrors,
        404: targetNotFound,
      },
    },
    delete: {
      tags: ['Savings targets'],
      summary: 'Delete a savings target',
      description: 'Deleting the current target makes the previous one current again.',
      ...secured,
      ...withId,
      responses: {
        204: { description: 'Deleted' },
        ...protectedErrors,
        404: targetNotFound,
      },
    },
  },
};
