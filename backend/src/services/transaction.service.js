import { toDbDate } from '../lib/dates.js';
import { HttpError } from '../lib/http-error.js';
import { prisma } from '../lib/prisma.js';
import { MANUAL_TYPES, TRANSACTION_TYPES } from '../schemas/transaction.schemas.js';
import { assertNotInFuture, getUserToday } from './profile.service.js';
import { applyDueRecurring } from './recurring.service.js';

const MANUAL_DB_TYPES = MANUAL_TYPES.map((type) => TRANSACTION_TYPES[type]);

export const isEditable = (transaction) => MANUAL_DB_TYPES.includes(transaction.type);

export async function list(userId, { type, from, to, limit, offset }) {
  await applyDueRecurring(userId);

  const date = {};
  if (from) date.gte = toDbDate(from);
  if (to) date.lte = toDbDate(to);
  const where = {
    userId,
    ...(type && { type: { in: type.map((name) => TRANSACTION_TYPES[name]) } }),
    ...(from || to ? { date } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.transaction.findMany({
      where,
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      skip: offset,
    }),
    prisma.transaction.count({ where }),
  ]);
  return { items, total };
}

/** Turns the request body into database fields. Money spent is stored as a negative amount. */
async function toData(userId, { type, name, amountCents, date, note }) {
  const day = date ?? (await getUserToday(prisma, userId));
  await assertNotInFuture(prisma, userId, day);
  return { type: TRANSACTION_TYPES[type], name, amountCents: -amountCents, date: toDbDate(day), note };
}

export async function create(userId, body) {
  return prisma.transaction.create({ data: { userId, ...(await toData(userId, body)) } });
}

async function findEditable(userId, id) {
  const transaction = await prisma.transaction.findFirst({ where: { id, userId } });
  if (!transaction) {
    throw new HttpError(404, 'transaction_not_found', 'Transaction not found');
  }
  if (!isEditable(transaction)) {
    throw new HttpError(
      409,
      'transaction_not_editable',
      'Automatic transactions (income, subscription charges, adjustments) cannot be changed',
    );
  }
  return transaction;
}

export async function update(userId, id, body) {
  await findEditable(userId, id);
  return prisma.transaction.update({ where: { id }, data: await toData(userId, body) });
}

export async function remove(userId, id) {
  await findEditable(userId, id);
  await prisma.transaction.delete({ where: { id } });
}
