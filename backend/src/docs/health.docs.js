import { z } from 'zod';

const json = (schema) => ({ 'application/json': { schema } });

export const healthPaths = {
  '/health': {
    get: {
      tags: ['Health'],
      summary: 'Is the API running?',
      description: 'Does not touch the database.',
      responses: {
        200: {
          description: 'The API is up',
          content: json(z.object({ status: z.literal('ok') })),
        },
      },
    },
  },
  '/health/ready': {
    get: {
      tags: ['Health'],
      summary: 'Is the API ready? (checks the database)',
      responses: {
        200: {
          description: 'The API and the database are up',
          content: json(z.object({ status: z.literal('ok'), database: z.literal('up') })),
        },
        503: {
          description: 'The database cannot be reached',
          content: json(z.object({ status: z.literal('unavailable'), database: z.literal('down') })),
        },
      },
    },
  },
};
