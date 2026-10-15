import { z } from 'zod';
import { amountCents, calendarDate, itemName, timestamp } from './common.schemas.js';

// Subscription periods as the API names them, and how the database names them.
export const SUBSCRIPTION_PERIODS = { monthly: 'MONTHLY', yearly: 'YEARLY' };

// Longest each month can be (February counts as 29: in other years the 28th is used).
const MAX_DAY_IN_MONTH = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

const period = z.enum(Object.keys(SUBSCRIPTION_PERIODS));

// ---------- Requests ----------

export const subscriptionBodySchema = z
  .object({
    name: itemName.meta({ example: 'Gym' }),
    amountCents: amountCents.meta({ description: 'Charged every period (month or year), in cents', example: 3500 }),
    period: period.default('monthly').meta({ description: '`monthly` (default) or `yearly`' }),
    billingDay: z.number().int().min(1).max(31).meta({
      description:
        'Day of the month it is charged (1-31). When the month is shorter, it is charged on the last day: 29, 30 or 31 -> 28 February (29 in leap years), 31 -> 30 April. If the date is today it is charged right away; if it already passed, the first charge is in the next period.',
      example: 8,
    }),
    billingMonth: z.number().int().min(1).max(12).nullish().meta({
      description: 'Yearly only (required): the month it is charged, 1 = January ... 12 = December. Leave it out for monthly.',
      example: 3,
    }),
    active: z.boolean().default(true).meta({
      description: 'False pauses it: no charges while paused, and paused periods are never charged later',
    }),
  })
  .superRefine((body, ctx) => {
    if (body.period === 'monthly' && body.billingMonth != null) {
      ctx.addIssue({ code: 'custom', path: ['billingMonth'], message: 'Only yearly subscriptions have a month' });
    }
    if (body.period === 'yearly' && body.billingMonth == null) {
      ctx.addIssue({ code: 'custom', path: ['billingMonth'], message: 'Yearly subscriptions need a month' });
    }
    if (body.period === 'yearly' && body.billingMonth && body.billingDay > MAX_DAY_IN_MONTH[body.billingMonth - 1]) {
      ctx.addIssue({ code: 'custom', path: ['billingDay'], message: 'That month does not have this day' });
    }
  })
  .meta({ id: 'SubscriptionRequest' });

// ---------- Responses ----------

export const subscriptionSchema = z
  .object({
    id: z.uuid(),
    name: z.string().meta({ example: 'Gym' }),
    amountCents: z.number().int().meta({ example: 3500 }),
    period,
    billingDay: z.number().int().meta({ example: 8 }),
    billingMonth: z.number().int().nullable().meta({ description: 'Yearly only, null for monthly', example: null }),
    active: z.boolean(),
    nextChargeDate: calendarDate.nullable().meta({ description: 'Next day it will be charged. Null when paused.' }),
    createdAt: timestamp,
    updatedAt: timestamp,
  })
  .meta({ id: 'Subscription' });

export const subscriptionResponseSchema = z
  .object({ subscription: subscriptionSchema })
  .meta({ id: 'SubscriptionResponse' });

/** Totals of the active subscriptions, shared by the list and the dashboard. */
export const subscriptionTotalsSchema = {
  monthlyTotalCents: z.number().int().meta({ description: 'Sum of the active monthly subscriptions', example: 5099 }),
  yearlyTotalCents: z.number().int().meta({ description: 'Sum of the active yearly subscriptions', example: 12000 }),
  averagePerMonthCents: z.number().int().meta({
    description: 'What they cost per month on average: monthly + yearly / 12 (rounded)',
    example: 6099,
  }),
};

export const subscriptionListResponseSchema = z
  .object({ items: z.array(subscriptionSchema), ...subscriptionTotalsSchema })
  .meta({ id: 'SubscriptionList' });
