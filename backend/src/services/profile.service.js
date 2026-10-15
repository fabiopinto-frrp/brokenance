import { todayIn, toDbDate } from '../lib/dates.js';
import { HttpError } from '../lib/http-error.js';
import { prisma, withTransaction } from '../lib/prisma.js';
import { applyDueRecurring } from './recurring.service.js';

// Net worth is never stored as a number that can drift. It is always:
//   openingBalance + SUM(every transaction)
// so adding, editing or deleting an item changes it automatically.

/** Current net worth in cents. `db` can be the client or a transaction. */
export async function getNetWorthCents(db, userId) {
  const [profile, sum] = await Promise.all([
    db.profile.findUnique({ where: { userId }, select: { openingBalanceCents: true } }),
    db.transaction.aggregate({ where: { userId }, _sum: { amountCents: true } }),
  ]);
  return profile.openingBalanceCents + (sum._sum.amountCents ?? 0);
}

/** Today's date ('YYYY-MM-DD') in the user's time zone. */
export async function getUserToday(db, userId) {
  const profile = await db.profile.findUnique({ where: { userId }, select: { timezone: true } });
  return todayIn(profile.timezone);
}

/** Rejects dates after today (in the user's time zone). */
export async function assertNotInFuture(db, userId, date) {
  if (date > (await getUserToday(db, userId))) {
    throw new HttpError(400, 'date_in_future', 'The date cannot be in the future');
  }
}

async function loadProfile(db, userId) {
  const user = await db.user.findUnique({ where: { id: userId }, include: { profile: true } });
  if (!user) {
    throw new HttpError(401, 'unauthorized', 'User no longer exists');
  }
  return { user, profile: user.profile, netWorthCents: await getNetWorthCents(db, userId) };
}

export async function getProfile(userId) {
  await applyDueRecurring(userId);
  return loadProfile(prisma, userId);
}

/** Changes the name and/or the monthly income. A new income applies from the next 1st on. */
export async function updateProfile(userId, changes) {
  // Income that is already due is paid with the old amount.
  await applyDueRecurring(userId);
  await prisma.profile.update({ where: { userId }, data: changes });
  return loadProfile(prisma, userId);
}

/**
 * Sets the net worth to the value the user typed.
 * - First time: it becomes the opening balance (so the net worth equals the typed value).
 * - Later: the difference is stored as an ADJUSTMENT transaction, so the history and the
 *   charts stay correct.
 */
export async function setNetWorth(userId, netWorthCents) {
  // Apply what is due first, so the difference is computed against the real current value.
  await applyDueRecurring(userId);

  await withTransaction(async (tx) => {
    await tx.$queryRaw`SELECT user_id FROM profiles WHERE user_id = ${userId}::uuid FOR UPDATE`;
    const profile = await tx.profile.findUnique({ where: { userId } });
    const current = await getNetWorthCents(tx, userId);

    if (!profile.netWorthSetAt) {
      await tx.profile.update({
        where: { userId },
        data: {
          openingBalanceCents: profile.openingBalanceCents + (netWorthCents - current),
          netWorthSetAt: new Date(),
        },
      });
      return;
    }

    const difference = netWorthCents - current;
    if (difference !== 0) {
      await tx.transaction.create({
        data: {
          userId,
          type: 'ADJUSTMENT',
          name: 'Net worth adjustment',
          amountCents: difference,
          date: toDbDate(todayIn(profile.timezone)),
        },
      });
    }
  });

  return loadProfile(prisma, userId);
}
