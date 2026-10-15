import { z } from 'zod';

// Building blocks shared by the feature schemas.

// 10 000 000.00 €. Keeps every amount, and the sums of them, far inside a 32-bit integer
// column and JavaScript's safe integers.
export const MAX_AMOUNT_CENTS = 1_000_000_000;

/** A positive amount of money in cents (1250 = 12.50). */
export const amountCents = z
  .number()
  .int('Use whole cents, for example 1250 for 12.50')
  .positive()
  .max(MAX_AMOUNT_CENTS)
  .meta({ description: 'Amount in cents (1250 = 12.50). Always positive.', example: 1250 });

// First or last name. Accents and any alphabet are allowed ("João", "Conceição").
export const personName = z.string().trim().min(1).max(50);

/** A calendar day, 'YYYY-MM-DD'. */
export const calendarDate = z.iso.date().meta({ description: 'A day, `YYYY-MM-DD`', example: '2026-10-15' });

/** The name of an item (expense, subscription, goal...). */
export const itemName = z.string().trim().min(1).max(80).meta({ example: 'Supermarket' });

/** Optional free text. Empty text is stored as null. */
export const note = z
  .string()
  .trim()
  .max(500)
  .nullish()
  .transform((value) => value || null)
  .meta({ description: 'Optional note, up to 500 characters', example: 'Weekly groceries' });

export const idParams = z.object({
  id: z.uuid().meta({ description: 'The id of the item', example: '01a1322a-ff14-76e9-83c0-3174db7dac15' }),
});

/** Response schema for a timestamp. */
export const timestamp = z.iso.datetime().meta({ example: '2026-10-15T09:30:00.000Z' });
