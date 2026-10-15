import { addMonths, firstDayOf, monthOf, monthsBetween, toDbDate } from '../lib/dates.js';
import { prisma } from '../lib/prisma.js';
import * as goalService from './goal.service.js';
import { getNetWorthCents, getUserToday } from './profile.service.js';
import { applyDueRecurring } from './recurring.service.js';
import { getCurrentTarget } from './savings-target.service.js';
import { subscriptionTotals } from './subscription.service.js';

const SPENDING_TYPES = {
  EXPENSE: 'expense',
  OUTING: 'outing',
  LEISURE: 'leisure',
  SUBSCRIPTION_CHARGE: 'subscription_charge',
};

const emptyCategories = () => Object.fromEntries(Object.values(SPENDING_TYPES).map((name) => [name, 0]));

/** Everything the dashboard shows, in one request. */
export async function getSummary(userId, { months }) {
  await applyDueRecurring(userId);

  const today = await getUserToday(prisma, userId);
  const currentMonth = monthOf(today);
  const firstMonth = addMonths(currentMonth, -(months - 1));
  const from = toDbDate(firstDayOf(firstMonth));

  const [netWorthCents, totals, beforeRange, profile, target, goals, subscriptions] = await Promise.all([
    getNetWorthCents(prisma, userId),
    // One row per month and type with the sum of the amounts.
    prisma.$queryRaw`
      SELECT to_char(date, 'YYYY-MM') AS month, type::text AS type, SUM(amount_cents)::bigint AS total
      FROM transactions
      WHERE user_id = ${userId}::uuid AND date >= ${from}
      GROUP BY 1, 2`,
    prisma.transaction.aggregate({ where: { userId, date: { lt: from } }, _sum: { amountCents: true } }),
    prisma.profile.findUnique({ where: { userId }, select: { openingBalanceCents: true } }),
    getCurrentTarget(prisma, userId),
    goalService.list(userId),
    prisma.subscription.findMany({ where: { userId, active: true }, select: { active: true, period: true, amountCents: true } }),
  ]);

  // Net worth at the end of each month: everything before the range, then month by month.
  let runningNetWorth = profile.openingBalanceCents + (beforeRange._sum.amountCents ?? 0);

  const monthSummaries = monthsBetween(firstMonth, currentMonth).map((month) => {
    const summary = { month, incomeCents: 0, spendingCents: 0, spendingByCategory: emptyCategories() };
    for (const row of totals.filter((total) => total.month === month)) {
      const total = Number(row.total);
      runningNetWorth += total;
      if (row.type === 'INCOME') summary.incomeCents += total;
      if (SPENDING_TYPES[row.type]) {
        summary.spendingCents -= total;
        summary.spendingByCategory[SPENDING_TYPES[row.type]] -= total;
      }
    }
    return { ...summary, leftCents: summary.incomeCents - summary.spendingCents, netWorthCents: runningNetWorth };
  });

  const current = monthSummaries.at(-1);
  const targetCents = target?.amountCents ?? null;

  return {
    netWorthCents,
    currentMonth: current,
    months: monthSummaries,
    savings: {
      targetCents,
      leftThisMonthCents: current.leftCents,
      onTrack: targetCents === null ? null : current.leftCents >= targetCents,
    },
    goals: {
      items: goals,
      totalTargetCents: goals.reduce((total, goal) => total + goal.targetCents, 0),
      totalSavedCents: goals.reduce((total, goal) => total + goal.savedCents, 0),
    },
    subscriptions: { activeCount: subscriptions.length, ...subscriptionTotals(subscriptions) },
  };
}
