import { z } from 'zod';
import { goalSchema } from './goal.schemas.js';
import { subscriptionTotalsSchema } from './subscription.schemas.js';

// ---------- Requests ----------

export const dashboardQuery = z.object({
  months: z.coerce.number().int().min(1).max(24).default(6).meta({
    description: 'How many months of history, including the current one',
    example: 6,
  }),
});

// ---------- Responses ----------

const cents = (description, example) => z.number().int().meta({ description, example });

const spendingByCategory = z
  .object({
    expense: cents('Despesas', 32000),
    outing: cents('Saídas/Férias', 8000),
    leisure: cents('Lazer', 4500),
    subscription_charge: cents('Subscrições', 5099),
  })
  .meta({ id: 'SpendingByCategory', description: 'Money spent per category, in cents (positive)' });

const monthSummary = z
  .object({
    month: z.string().meta({ description: '`YYYY-MM`', example: '2026-10' }),
    incomeCents: cents('Monthly income received', 90000),
    spendingCents: cents('Everything spent (positive)', 49599),
    leftCents: cents('income - spending. Negative when more was spent than received.', 40401),
    spendingByCategory,
    netWorthCents: cents('Net worth at the end of the month (today for the current month)', 250000),
  })
  .meta({ id: 'MonthSummary' });

export const dashboardResponseSchema = z
  .object({
    netWorthCents: cents('Current net worth', 250000),
    currentMonth: monthSummary,
    months: z.array(monthSummary).meta({ description: 'Oldest first, the current month last' }),
    savings: z.object({
      targetCents: z.number().int().nullable().meta({ description: 'Current monthly savings target (Poupança). Null when none.' }),
      leftThisMonthCents: cents('What is left this month (income - spending)', 40401),
      onTrack: z.boolean().nullable().meta({ description: 'leftThisMonth >= target. Null without a target.' }),
    }),
    goals: z.object({
      items: z.array(goalSchema),
      totalTargetCents: cents('Sum of every goal target', 150000),
      totalSavedCents: cents('Sum of every saved amount', 20000),
    }),
    subscriptions: z.object({
      activeCount: z.number().int().meta({ example: 3 }),
      ...subscriptionTotalsSchema,
    }),
  })
  .meta({ id: 'Dashboard' });
