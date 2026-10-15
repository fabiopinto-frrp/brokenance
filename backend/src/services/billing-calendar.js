import { addMonths, billingDateIn, monthOf } from '../lib/dates.js';

// When a subscription is charged. A subscription is charged once per period:
//   monthly: the period is a month ('2026-10'), charged on billingDay of that month;
//   yearly:  the period is a year ('2026'), charged on billingDay of billingMonth.
// Days that do not exist in the month use its last day (31 -> 30 April, 29-31 -> 28 February,
// or 29 in leap years). Periods compare correctly as strings.

const pad = (value) => String(value).padStart(2, '0');

export function billingCalendar({ period, billingDay, billingMonth }) {
  if (period === 'YEARLY') {
    return {
      periodOf: (date) => date.slice(0, 4),
      next: (year) => String(Number(year) + 1),
      chargeDate: (year) => billingDateIn(`${year}-${pad(billingMonth)}`, billingDay),
    };
  }
  return {
    periodOf: monthOf,
    next: (month) => addMonths(month, 1),
    chargeDate: (month) => billingDateIn(month, billingDay),
  };
}
