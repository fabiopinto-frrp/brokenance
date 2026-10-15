import { fromDbDate } from '../lib/dates.js';
import { TRANSACTION_TYPES } from '../schemas/transaction.schemas.js';
import { isEditable } from '../services/transaction.service.js';

const API_TYPES = Object.fromEntries(Object.entries(TRANSACTION_TYPES).map(([api, db]) => [db, api]));

export const toTransaction = (transaction) => ({
  id: transaction.id,
  type: API_TYPES[transaction.type],
  name: transaction.name,
  amountCents: transaction.amountCents,
  date: fromDbDate(transaction.date),
  note: transaction.note,
  subscriptionId: transaction.subscriptionId,
  editable: isEditable(transaction),
  createdAt: transaction.createdAt.toISOString(),
  updatedAt: transaction.updatedAt.toISOString(),
});

export const toTransactionResponse = (transaction) => ({ transaction: toTransaction(transaction) });

export const toTransactionListResponse = ({ items, total }) => ({ items: items.map(toTransaction), total });
