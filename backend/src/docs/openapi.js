import { createDocument } from 'zod-openapi';
import packageJson from '../../package.json' with { type: 'json' };
import { authPaths } from './auth.docs.js';
import { dashboardPaths } from './dashboard.docs.js';
import { goalPaths } from './goal.docs.js';
import { healthPaths } from './health.docs.js';
import { profilePaths } from './profile.docs.js';
import { savingsTargetPaths } from './savings-target.docs.js';
import { subscriptionPaths } from './subscription.docs.js';
import { transactionPaths } from './transaction.docs.js';

// Every feature describes its endpoints in its own `<feature>.docs.js` in this folder. Add new ones here.
export function buildOpenApiDocument() {
  return createDocument({
    openapi: '3.1.0',
    info: {
      title: 'Brokenance API',
      version: packageJson.version,
      description: [
        'REST API of the Brokenance personal finance app.',
        '',
        '**Authentication:** log in with `POST /auth/login`, then send the access token as `Authorization: Bearer <token>`. ' +
          'Use the **Authorize** button above to try protected endpoints.',
        '',
        '**Errors:** every error is JSON shaped as `{ "error": { "code", "message" } }`. Use `code` in the app, it is stable.',
        '',
        '**Money:** amounts are integers in cents (1250 = 12.50).',
        '',
        '**Dates:** days are `YYYY-MM-DD`, months `YYYY-MM`, both in the user time zone (Europe/Lisbon).',
        '',
        '**Net worth** = opening balance + every transaction. The monthly income (on the 1st) and subscription charges (on their billing day) are applied automatically, also for days the app was closed, and never twice.',
      ].join('\n'),
    },
    tags: [
      { name: 'Health', description: 'Is the API up?' },
      { name: 'Auth', description: 'Register, log in, stay logged in (refresh) and log out' },
      { name: 'Profile', description: 'Name, monthly income and net worth' },
      { name: 'Transactions', description: 'Despesas, Saídas/Férias, Lazer, and the automatic history (income, subscription charges, adjustments)' },
      { name: 'Subscriptions', description: 'Subscrições: monthly or yearly charges applied automatically' },
      { name: 'Savings targets', description: 'Poupança: how much to save per month' },
      { name: 'Goals', description: 'Objetivos: save X to buy Y' },
      { name: 'Dashboard', description: 'Numbers for the charts' },
    ],
    paths: {
      ...healthPaths,
      ...authPaths,
      ...profilePaths,
      ...transactionPaths,
      ...subscriptionPaths,
      ...savingsTargetPaths,
      ...goalPaths,
      ...dashboardPaths,
    },
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'The `accessToken` returned by `/auth/login`, `/auth/register` or `/auth/refresh`.',
        },
      },
    },
  });
}
