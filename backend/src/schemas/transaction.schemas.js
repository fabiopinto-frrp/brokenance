import { z } from 'zod';
import { amountCents, calendarDate, itemName, note, timestamp } from './common.schemas.js';

// Transaction types as the API names them, and how the database names them.
export const TRANSACTION_TYPES = {
  expense: 'EXPENSE',
  outing: 'OUTING',
  leisure: 'LEISURE',
  income: 'INCOME',
  subscription_charge: 'SUBSCRIPTION_CHARGE',
  adjustment: 'ADJUSTMENT',
};

// The types the user adds by hand (Despesas, Saídas/Férias, Lazer). The others are created by
// the API (monthly income, subscription charges, net worth adjustments) and are read-only.
export const MANUAL_TYPES = ['expense', 'outing', 'leisure'];

const transactionType = z.enum(Object.keys(TRANSACTION_TYPES));

// ---------- Requests ----------

export const transactionBodySchema = z
  .object({
    type: z.enum(MANUAL_TYPES).meta({
      description: '`expense` (Despesas), `outing` (Saídas/Férias) or `leisure` (Lazer)',
      example: 'expense',
    }),
    name: itemName,
    amountCents: amountCents.meta({ description: 'How much was spent, in cents. Always positive.' }),
    date: calendarDate.optional().meta({ description: 'When the money was spent. Defaults to today. Cannot be in the future.' }),
    note,
  })
  .meta({ id: 'TransactionRequest' });

const typeList = z
  .string()
  .transform((value) => value.split(',').map((type) => type.trim()).filter(Boolean))
  .pipe(z.array(transactionType).min(1));

export const listTransactionsQuery = z
  .object({
    type: typeList.optional().meta({
      description: 'Only these types, comma-separated, for example `expense,leisure`',
      example: 'expense',
    }),
    from: calendarDate.optional().meta({ description: 'From this day (included)' }),
    to: calendarDate.optional().meta({ description: 'Up to this day (included)' }),
    limit: z.coerce.number().int().min(1).max(500).default(100),
    offset: z.coerce.number().int().min(0).default(0),
  })
  .refine((query) => !query.from || !query.to || query.from <= query.to, {
    message: '`from` must be before or equal to `to`',
    path: ['from'],
  });

// ---------- Responses ----------

export const transactionSchema = z
  .object({
    id: z.uuid(),
    type: transactionType,
    name: z.string().meta({ example: 'Supermarket' }),
    amountCents: z.number().int().meta({
      description: 'Effect on the net worth, in cents: negative for money out (expenses, charges), positive for money in.',
      example: -1250,
    }),
    date: calendarDate,
    note: z.string().nullable(),
    subscriptionId: z.uuid().nullable().meta({ description: 'Set on subscription charges' }),
    editable: z.boolean().meta({ description: 'Only expenses, outings and leisure can be edited or deleted' }),
    createdAt: timestamp,
    updatedAt: timestamp,
  })
  .meta({ id: 'Transaction' });

export const transactionResponseSchema = z.object({ transaction: transactionSchema }).meta({ id: 'TransactionResponse' });

export const transactionListResponseSchema = z
  .object({
    items: z.array(transactionSchema).meta({ description: 'Newest first' }),
    total: z.number().int().meta({ description: 'How many match the filters, ignoring limit and offset' }),
  })
  .meta({ id: 'TransactionList' });
