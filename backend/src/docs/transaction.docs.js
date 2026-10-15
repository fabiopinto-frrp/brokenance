import { errorResponse } from './responses.js';
import { dateInFuture, json, notFound, protectedErrors, secured, withId } from './helpers.js';
import {
  listTransactionsQuery,
  transactionBodySchema,
  transactionListResponseSchema,
  transactionResponseSchema,
} from '../schemas/transaction.schemas.js';

const notEditable = errorResponse(
  'Automatic transactions (income, subscription charges, adjustments) cannot be changed or deleted',
  'transaction_not_editable',
  'Automatic transactions (income, subscription charges, adjustments) cannot be changed',
);
const transactionNotFound = notFound('transaction', 'transaction_not_found');

export const transactionPaths = {
  '/transactions': {
    get: {
      tags: ['Transactions'],
      summary: 'List transactions (the history of the net worth)',
      description:
        'Every change to the net worth, newest first: what you added by hand (`expense`, `outing`, `leisure`) and what the API added (`income`, `subscription_charge`, `adjustment`). Due income and charges are applied first.',
      ...secured,
      requestParams: { query: listTransactionsQuery },
      responses: {
        200: { description: 'The transactions', content: json(transactionListResponseSchema) },
        400: errorResponse('Invalid filters', 'validation_error', 'Invalid request'),
        ...protectedErrors,
      },
    },
    post: {
      tags: ['Transactions'],
      summary: 'Add an expense, outing or leisure item',
      description: 'The amount is subtracted from the net worth.',
      ...secured,
      requestBody: { required: true, content: json(transactionBodySchema) },
      responses: {
        201: { description: 'Created', content: json(transactionResponseSchema) },
        400: dateInFuture,
        ...protectedErrors,
      },
    },
  },
  '/transactions/{id}': {
    put: {
      tags: ['Transactions'],
      summary: 'Edit an expense, outing or leisure item',
      description: 'Replaces every field. The net worth follows automatically.',
      ...secured,
      ...withId,
      requestBody: { required: true, content: json(transactionBodySchema) },
      responses: {
        200: { description: 'Updated', content: json(transactionResponseSchema) },
        400: dateInFuture,
        ...protectedErrors,
        404: transactionNotFound,
        409: notEditable,
      },
    },
    delete: {
      tags: ['Transactions'],
      summary: 'Delete an expense, outing or leisure item',
      description: 'The money goes back to the net worth.',
      ...secured,
      ...withId,
      responses: {
        204: { description: 'Deleted' },
        ...protectedErrors,
        404: transactionNotFound,
        409: notEditable,
      },
    },
  },
};
