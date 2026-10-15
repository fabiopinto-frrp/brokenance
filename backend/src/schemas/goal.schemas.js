import { z } from 'zod';
import { MAX_AMOUNT_CENTS, amountCents, calendarDate, itemName, timestamp } from './common.schemas.js';

// ---------- Requests ----------

export const goalBodySchema = z
  .object({
    name: itemName.meta({ description: 'What you are saving for', example: 'New laptop' }),
    targetCents: amountCents.meta({ description: 'How much you need, in cents', example: 150000 }),
    savedCents: z.number().int().min(0).max(MAX_AMOUNT_CENTS).default(0).meta({
      description: 'How much is already saved, in cents. Updated by hand.',
      example: 20000,
    }),
    deadline: calendarDate.nullish().transform((value) => value ?? null).meta({ description: 'Optional target date' }),
  })
  .meta({ id: 'GoalRequest' });

export const contributionBodySchema = z
  .object({
    amountCents: amountCents.meta({ description: 'Amount to add to the saved amount, in cents', example: 5000 }),
  })
  .meta({ id: 'GoalContributionRequest' });

// ---------- Responses ----------

export const goalSchema = z
  .object({
    id: z.uuid(),
    name: z.string().meta({ example: 'New laptop' }),
    targetCents: z.number().int().meta({ example: 150000 }),
    savedCents: z.number().int().meta({ example: 20000 }),
    remainingCents: z.number().int().meta({ description: 'Still missing, never below 0', example: 130000 }),
    progressPercent: z.number().int().meta({ description: 'saved / target, rounded down. Can pass 100.', example: 13 }),
    completed: z.boolean(),
    deadline: calendarDate.nullable(),
    estimatedMonthsLeft: z.number().int().nullable().meta({
      description: 'Months to finish at the current monthly savings target (Poupança). Null without a target.',
      example: 5,
    }),
    createdAt: timestamp,
    updatedAt: timestamp,
  })
  .meta({ id: 'Goal' });

export const goalResponseSchema = z.object({ goal: goalSchema }).meta({ id: 'GoalResponse' });

export const goalListResponseSchema = z.object({ items: z.array(goalSchema) }).meta({ id: 'GoalList' });
