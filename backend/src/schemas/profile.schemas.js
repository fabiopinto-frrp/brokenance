import { z } from 'zod';
import { MAX_AMOUNT_CENTS, personName } from './common.schemas.js';

// ---------- Requests ----------

export const updateProfileSchema = z
  .object({
    firstName: personName.meta({ example: 'Fábio' }),
    lastName: personName.meta({ example: 'Pinto' }),
    monthlyIncomeCents: z.number().int().min(0).max(MAX_AMOUNT_CENTS).meta({
      description: 'Company payment added to the net worth on the 1st of every month, in cents. 0 turns it off.',
      example: 90000,
    }),
  })
  .partial()
  .refine((body) => Object.keys(body).length > 0, 'Send at least one field to change')
  .meta({ id: 'UpdateProfileRequest', description: 'Send only the fields to change' });

export const setNetWorthSchema = z
  .object({
    netWorthCents: z.number().int().min(-MAX_AMOUNT_CENTS).max(MAX_AMOUNT_CENTS).meta({
      description: 'The money you have right now, in cents. Can be negative.',
      example: 250000,
    }),
  })
  .meta({ id: 'SetNetWorthRequest' });

// ---------- Responses ----------

export const profileResponseSchema = z
  .object({
    profile: z.object({
      username: z.string().meta({ example: 'fabio' }),
      firstName: z.string().meta({ example: 'Fábio' }),
      lastName: z.string().meta({ example: 'Pinto' }),
      monthlyIncomeCents: z.number().int().meta({ example: 90000 }),
      netWorthCents: z.number().int().meta({
        description: 'Current net worth: opening balance + every transaction',
        example: 250000,
      }),
      netWorthSet: z.boolean().meta({
        description: 'False until the user types their net worth the first time. The app can ask for it then.',
      }),
      currency: z.string().meta({ example: 'EUR' }),
      timezone: z.string().meta({ description: 'Used for "today" and for the 1st of the month', example: 'Europe/Lisbon' }),
    }),
  })
  .meta({ id: 'Profile' });
