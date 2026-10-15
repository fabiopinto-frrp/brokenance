import { errorResponse } from './responses.js';
import { json, protectedErrors, secured } from './helpers.js';
import { dashboardQuery, dashboardResponseSchema } from '../schemas/dashboard.schemas.js';

export const dashboardPaths = {
  '/dashboard/summary': {
    get: {
      tags: ['Dashboard'],
      summary: 'Everything the dashboard shows, in one request',
      description:
        'Net worth, this month (income, spending per category, what is left), the last months for the charts, savings target progress, goals and subscriptions. Due income and charges are applied first. Months follow the user time zone.',
      ...secured,
      requestParams: { query: dashboardQuery },
      responses: {
        200: { description: 'The summary', content: json(dashboardResponseSchema) },
        400: errorResponse('Invalid `months`', 'validation_error', 'Invalid request'),
        ...protectedErrors,
      },
    },
  },
};
