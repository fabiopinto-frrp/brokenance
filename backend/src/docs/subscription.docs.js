import { json, notFound, protectedBodyErrors, protectedErrors, secured, withId } from './helpers.js';
import {
  subscriptionBodySchema,
  subscriptionListResponseSchema,
  subscriptionResponseSchema,
} from '../schemas/subscription.schemas.js';

const subscriptionNotFound = notFound('subscription', 'subscription_not_found');

export const subscriptionPaths = {
  '/subscriptions': {
    get: {
      tags: ['Subscriptions'],
      summary: 'List subscriptions (monthly and yearly)',
      description: 'Active ones first, with the totals per month and per year. Due charges are applied first.',
      ...secured,
      responses: {
        200: { description: 'The subscriptions', content: json(subscriptionListResponseSchema) },
        ...protectedErrors,
      },
    },
    post: {
      tags: ['Subscriptions'],
      summary: 'Add a subscription',
      description:
        'Monthly subscriptions are charged every month on `billingDay`. Yearly ones (`period: yearly`) every year on `billingDay` of `billingMonth`. Each charge is a `subscription_charge` transaction that subtracts from the net worth. If the billing date is today, it is charged right away; if it already passed, the first charge is in the next month (or year).',
      ...secured,
      requestBody: { required: true, content: json(subscriptionBodySchema) },
      responses: {
        201: { description: 'Created', content: json(subscriptionResponseSchema) },
        ...protectedBodyErrors,
      },
    },
  },
  '/subscriptions/{id}': {
    put: {
      tags: ['Subscriptions'],
      summary: 'Edit, pause or resume a subscription',
      description:
        'Replaces every field. A new amount or date applies to future charges only; past charges stay as they were. Resuming never charges the paused periods. Switching between monthly and yearly starts the new schedule from today.',
      ...secured,
      ...withId,
      requestBody: { required: true, content: json(subscriptionBodySchema) },
      responses: {
        200: { description: 'Updated', content: json(subscriptionResponseSchema) },
        ...protectedBodyErrors,
        404: subscriptionNotFound,
      },
    },
    delete: {
      tags: ['Subscriptions'],
      summary: 'Delete a subscription',
      description: 'Stops future charges. Past charges stay in the history.',
      ...secured,
      ...withId,
      responses: {
        204: { description: 'Deleted' },
        ...protectedErrors,
        404: subscriptionNotFound,
      },
    },
  },
};
