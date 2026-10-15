import { SUBSCRIPTION_PERIODS } from '../schemas/subscription.schemas.js';

const API_PERIODS = Object.fromEntries(Object.entries(SUBSCRIPTION_PERIODS).map(([api, db]) => [db, api]));

export const toSubscription = (subscription) => ({
  id: subscription.id,
  name: subscription.name,
  amountCents: subscription.amountCents,
  period: API_PERIODS[subscription.period],
  billingDay: subscription.billingDay,
  billingMonth: subscription.billingMonth,
  active: subscription.active,
  nextChargeDate: subscription.nextChargeDate,
  createdAt: subscription.createdAt.toISOString(),
  updatedAt: subscription.updatedAt.toISOString(),
});

export const toSubscriptionResponse = (subscription) => ({ subscription: toSubscription(subscription) });

export const toSubscriptionListResponse = ({ items, ...totals }) => ({
  items: items.map(toSubscription),
  ...totals,
});
