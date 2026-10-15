import { json, protectedBodyErrors, protectedErrors, secured } from './helpers.js';
import { profileResponseSchema, setNetWorthSchema, updateProfileSchema } from '../schemas/profile.schemas.js';

export const profilePaths = {
  '/profile': {
    get: {
      tags: ['Profile'],
      summary: 'Get the profile and the current net worth',
      description:
        'Applies any monthly income and subscription charges that are due before answering, so the net worth is always up to date.',
      ...secured,
      responses: {
        200: { description: 'The profile', content: json(profileResponseSchema) },
        ...protectedErrors,
      },
    },
    put: {
      tags: ['Profile'],
      summary: 'Change the name or the monthly income',
      description: 'Send only the fields to change. A new monthly income applies from the next 1st of the month on.',
      ...secured,
      requestBody: { required: true, content: json(updateProfileSchema) },
      responses: {
        200: { description: 'The updated profile', content: json(profileResponseSchema) },
        ...protectedBodyErrors,
      },
    },
  },
  '/profile/net-worth': {
    put: {
      tags: ['Profile'],
      summary: 'Set the net worth by hand',
      description:
        'The first time, the value becomes the opening balance. After that, the difference to the current net worth is stored as an `adjustment` transaction, so the history stays correct.',
      ...secured,
      requestBody: { required: true, content: json(setNetWorthSchema) },
      responses: {
        200: { description: 'The updated profile', content: json(profileResponseSchema) },
        ...protectedBodyErrors,
      },
    },
  },
};
