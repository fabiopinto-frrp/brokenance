import { fromDbDate, toDbDate } from '../lib/dates.js';
import { HttpError } from '../lib/http-error.js';
import { prisma } from '../lib/prisma.js';
import { assertNotInFuture, getUserToday } from './profile.service.js';

// Poupança: the monthly savings target. Adding a new one makes it the current one. Older rows
// stay as history. Targets never change the net worth.

// Newest first: the first row is the current target.
const ORDER = [{ effectiveDate: 'desc' }, { createdAt: 'desc' }];

/** The target that counts now, or null. `db` can be the client or a transaction. */
export const getCurrentTarget = (db, userId) => db.savingsTarget.findFirst({ where: { userId }, orderBy: ORDER });

export async function list(userId) {
  const targets = await prisma.savingsTarget.findMany({ where: { userId }, orderBy: ORDER });
  const items = targets.map((target, index) => ({ ...target, isCurrent: index === 0 }));
  return { current: items[0] ?? null, items };
}

async function findOwned(userId, id) {
  const target = await prisma.savingsTarget.findFirst({ where: { id, userId } });
  if (!target) {
    throw new HttpError(404, 'savings_target_not_found', 'Savings target not found');
  }
  return target;
}

async function toData(userId, { amountCents, effectiveDate }) {
  const date = effectiveDate ?? (await getUserToday(prisma, userId));
  await assertNotInFuture(prisma, userId, date);
  return { amountCents, effectiveDate: toDbDate(date) };
}

const withIsCurrent = async (userId, target) => ({
  ...target,
  isCurrent: (await getCurrentTarget(prisma, userId))?.id === target.id,
});

export async function create(userId, body) {
  const target = await prisma.savingsTarget.create({ data: { userId, ...(await toData(userId, body)) } });
  return withIsCurrent(userId, target);
}

export async function update(userId, id, body) {
  const existing = await findOwned(userId, id);
  // Without a new date the row keeps its own (an old target stays in the history).
  const effectiveDate = body.effectiveDate ?? fromDbDate(existing.effectiveDate);
  const target = await prisma.savingsTarget.update({
    where: { id },
    data: await toData(userId, { ...body, effectiveDate }),
  });
  return withIsCurrent(userId, target);
}

/** Deleting the current target makes the previous one current again. */
export async function remove(userId, id) {
  await findOwned(userId, id);
  await prisma.savingsTarget.delete({ where: { id } });
}
