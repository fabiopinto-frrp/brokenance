import { fromDbDate } from '../lib/dates.js';

export const toSavingsTarget = (target) => ({
  id: target.id,
  amountCents: target.amountCents,
  effectiveDate: fromDbDate(target.effectiveDate),
  isCurrent: target.isCurrent,
  createdAt: target.createdAt.toISOString(),
});

export const toSavingsTargetResponse = (target) => ({ savingsTarget: toSavingsTarget(target) });

export const toSavingsTargetListResponse = ({ current, items }) => ({
  current: current && toSavingsTarget(current),
  items: items.map(toSavingsTarget),
});
