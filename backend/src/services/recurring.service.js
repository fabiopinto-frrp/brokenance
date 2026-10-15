import { prisma, withTransaction } from '../lib/prisma.js';
import { addMonths, firstDayOf, fromDbDate, monthOf, toDbDate, todayIn } from '../lib/dates.js';
import { billingCalendar } from './billing-calendar.js';

// The recurring engine: adds the monthly income on the 1st and charges every active
// subscription on its billing date (every month, or every year for yearly ones).
//
// It is "lazy and idempotent": it runs before the user's data is read (and once an hour as a
// safety net, see jobs/scheduler.js), works out every period that is due but not applied yet,
// and applies them all. So nothing is missed when the API or the app was off on the 1st, and
// nothing is ever applied twice:
//   - the user's profile row is locked, so two requests cannot run it at the same time;
//   - `last...` markers remember the last period applied;
//   - every automatic transaction has a unique `recurringKey` per period, as a final guard.

export const incomeKey = (month) => `income:${month}`;
export const subscriptionChargeKey = (subscriptionId, period) => `subscription:${subscriptionId}:${period}`;

/** Applies every income and subscription charge that is due for the user. Safe to call often. */
export function applyDueRecurring(userId, now = new Date()) {
  return withTransaction(async (tx) => {
    const locked = await tx.$queryRaw`
      SELECT user_id FROM profiles WHERE user_id = ${userId}::uuid FOR UPDATE`;
    if (locked.length === 0) return;

    const profile = await tx.profile.findUnique({ where: { userId } });
    const today = todayIn(profile.timezone, now);

    await applyIncome(tx, profile, today);
    await applySubscriptionCharges(tx, userId, today);
  });
}

/** Runs the engine for every user. Used by the scheduled job. */
export async function applyDueRecurringForAllUsers(now = new Date()) {
  const users = await prisma.user.findMany({ select: { id: true } });
  for (const { id } of users) {
    await applyDueRecurring(id, now);
  }
  return users.length;
}

/**
 * One INCOME transaction, dated the 1st, for every month after the last one applied.
 * The month the account is created is never paid: that money is already in the net worth the
 * user types. A monthly income of 0 adds nothing but still moves the marker.
 */
async function applyIncome(tx, profile, today) {
  const currentMonth = monthOf(today);
  const lastApplied = profile.lastIncomeAppliedMonth
    ? monthOf(fromDbDate(profile.lastIncomeAppliedMonth))
    : null;

  if (lastApplied && lastApplied >= currentMonth) return;

  if (lastApplied && profile.monthlyIncomeCents > 0) {
    const rows = [];
    for (let month = addMonths(lastApplied, 1); month <= currentMonth; month = addMonths(month, 1)) {
      rows.push({
        userId: profile.userId,
        type: 'INCOME',
        name: 'Monthly income',
        amountCents: profile.monthlyIncomeCents,
        date: toDbDate(firstDayOf(month)),
        recurringKey: incomeKey(month),
      });
    }
    await tx.transaction.createMany({ data: rows, skipDuplicates: true });
  }

  await tx.profile.update({
    where: { userId: profile.userId },
    data: { lastIncomeAppliedMonth: toDbDate(firstDayOf(currentMonth)) },
  });
}

/**
 * One SUBSCRIPTION_CHARGE transaction (negative) for every billing date that has arrived,
 * from `chargeFrom` on: one per month for monthly subscriptions, one per year for yearly ones.
 */
async function applySubscriptionCharges(tx, userId, today) {
  const subscriptions = await tx.subscription.findMany({ where: { userId, active: true } });

  for (const subscription of subscriptions) {
    const calendar = billingCalendar(subscription);
    const chargeFrom = fromDbDate(subscription.chargeFrom);
    const firstPeriod = subscription.lastChargedPeriod
      ? calendar.next(calendar.periodOf(fromDbDate(subscription.lastChargedPeriod)))
      : calendar.periodOf(chargeFrom);

    const rows = [];
    for (let period = firstPeriod; period <= calendar.periodOf(today); period = calendar.next(period)) {
      const date = calendar.chargeDate(period);
      if (date > today) break;
      if (date < chargeFrom) continue;

      rows.push({
        userId,
        type: 'SUBSCRIPTION_CHARGE',
        name: subscription.name,
        amountCents: -subscription.amountCents,
        date: toDbDate(date),
        subscriptionId: subscription.id,
        recurringKey: subscriptionChargeKey(subscription.id, period),
      });
    }

    if (rows.length > 0) {
      await tx.transaction.createMany({ data: rows, skipDuplicates: true });
      await tx.subscription.update({
        where: { id: subscription.id },
        data: { lastChargedPeriod: rows.at(-1).date },
      });
    }
  }
}
