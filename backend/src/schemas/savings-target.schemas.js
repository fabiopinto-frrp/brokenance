import { z } from 'zod';
import { amountCents, calendarDate, timestamp } from './common.schemas.js';

// ---------- Requests ----------

export const savingsTargetBodySchema = z
  .object({
    amountCents: amountCents.meta({ description: 'How much you want to save per month, in cents', example: 30000 }),
    effectiveDate: calendarDate.optional().meta({
      description: 'From when this target applies. Defaults to today. Cannot be in the future.',
    }),
  })
  .meta({ id: 'SavingsTargetRequest' });

// ---------- Responses ----------

export const savingsTargetSchema = z
  .object({
    id: z.uuid(),
    amountCents: z.number().int().meta({ example: 30000 }),
    effectiveDate: calendarDate,
    isCurrent: z.boolean().meta({ description: 'True for the one target that counts now' }),
    createdAt: timestamp,
  })
  .meta({ id: 'SavingsTarget' });

export const savingsTargetResponseSchema = z
  .object({ savingsTarget: savingsTargetSchema })
  .meta({ id: 'SavingsTargetResponse' });

export const savingsTargetListResponseSchema = z
  .object({
    current: savingsTargetSchema.nullable().meta({
      description: 'The target that counts now: the latest effective date, then the latest created. Null when there is none.',
    }),
    items: z.array(savingsTargetSchema).meta({ description: 'Every target, current first, then the history' }),
  })
  .meta({ id: 'SavingsTargetList' });
