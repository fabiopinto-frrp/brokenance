import { fromDbDate, latestDate, toDbDate } from '../lib/dates.js';
import { HttpError } from '../lib/http-error.js';
import { prisma } from '../lib/prisma.js';
import { SUBSCRIPTION_PERIODS } from '../schemas/subscription.schemas.js';
import { billingCalendar } from './billing-calendar.js';
import { getUserToday } from './profile.service.js';
import { applyDueRecurring } from './recurring.service.js';

// Subscriptions are rules, monthly or yearly. The money moves through the SUBSCRIPTION_CHARGE
// transactions the recurring engine creates (see recurring.service.js). Deleting a subscription
// keeps its past charges in the history.

/** The next day the subscription will be charged, or null when it is paused. */
export function nextChargeDate(subscription, today) {
  if (!subscription.active) return null;

  const calendar = billingCalendar(subscription);
  const from = latestDate(today, fromDbDate(subscription.chargeFrom));
  const lastCharged = subscription.lastChargedPeriod
    ? calendar.periodOf(fromDbDate(subscription.lastChargedPeriod))
    : null;

  for (let period = calendar.periodOf(from); ; period = calendar.next(period)) {
    const date = calendar.chargeDate(period);
    if (date >= from && (!lastCharged || period > lastCharged)) return date;
  }
}

/** Totals of the active subscriptions. */
export function subscriptionTotals(subscriptions) {
  const sum = (period) =>
    subscriptions
      .filter((subscription) => subscription.active && subscription.period === period)
      .reduce((total, subscription) => total + subscription.amountCents, 0);
  const monthlyTotalCents = sum('MONTHLY');
  const yearlyTotalCents = sum('YEARLY');
  return {
    monthlyTotalCents,
    yearlyTotalCents,
    averagePerMonthCents: monthlyTotalCents + Math.round(yearlyTotalCents / 12),
  };
}

const withNextCharge = (subscription, today) => ({
  ...subscription,
  nextChargeDate: nextChargeDate(subscription, today),
});

/** Request body -> database fields. Monthly subscriptions never keep a month. */
const toData = ({ name, amountCents, period, billingDay, billingMonth, active }) => ({
  name,
  amountCents,
  period: SUBSCRIPTION_PERIODS[period],
  billingDay,
  billingMonth: period === 'yearly' ? billingMonth : null,
  active,
});

async function findOwned(userId, id) {
  const subscription = await prisma.subscription.findFirst({ where: { id, userId } });
  if (!subscription) {
    throw new HttpError(404, 'subscription_not_found', 'Subscription not found');
  }
  return subscription;
}

export async function list(userId) {
  await applyDueRecurring(userId);
  const today = await getUserToday(prisma, userId);
  const subscriptions = await prisma.subscription.findMany({
    where: { userId },
    orderBy: [{ active: 'desc' }, { name: 'asc' }],
  });

  return {
    items: subscriptions.map((subscription) => withNextCharge(subscription, today)),
    ...subscriptionTotals(subscriptions),
  };
}

export async function create(userId, body) {
  const today = await getUserToday(prisma, userId);

  const { id } = await prisma.subscription.create({
    data: { userId, ...toData(body), chargeFrom: toDbDate(today) },
  });

  // A subscription whose billing date is today is charged right away.
  await applyDueRecurring(userId);
  return withNextCharge(await findOwned(userId, id), today);
}

export async function update(userId, id, body) {
  await findOwned(userId, id);
  // Charges that are already due happen with the old terms (amount, dates, active).
  await applyDueRecurring(userId);
  const existing = await findOwned(userId, id);
  const today = await getUserToday(prisma, userId);
  const data = toData(body);

  // Resuming restarts the charges from today, so the paused periods are never charged.
  // Switching between monthly and yearly starts a new schedule from today.
  const resumed = data.active && !existing.active;
  const periodChanged = data.period !== existing.period;

  await prisma.subscription.update({
    where: { id },
    data: {
      ...data,
      ...((resumed || periodChanged) && { chargeFrom: toDbDate(today) }),
      ...(periodChanged && { lastChargedPeriod: null }),
    },
  });

  await applyDueRecurring(userId);
  return withNextCharge(await findOwned(userId, id), today);
}

export async function remove(userId, id) {
  await findOwned(userId, id);
  // A charge that was due before the deletion still happens.
  await applyDueRecurring(userId);
  await prisma.subscription.delete({ where: { id } });
}
