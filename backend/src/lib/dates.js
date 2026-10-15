// Calendar helpers. The API works with plain calendar values, never with times:
//   date  'YYYY-MM-DD'   (a day, as the user sees it)
//   month 'YYYY-MM'
// Both compare correctly as strings ('2026-09' < '2026-10'). "Today" always depends on the
// user's time zone, so the 1st of the month is the 1st in Lisbon, not in UTC.

export const DEFAULT_TIME_ZONE = 'Europe/Lisbon';

const pad = (value) => String(value).padStart(2, '0');

/** Today's date in a time zone, for example todayIn('Europe/Lisbon') -> '2026-10-15'. */
export function todayIn(timeZone, now = new Date()) {
  // en-CA formats dates as YYYY-MM-DD.
  return new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(now);
}

/** '2026-10-15' -> '2026-10' */
export const monthOf = (date) => date.slice(0, 7);

/** '2026-10' -> '2026-10-01' */
export const firstDayOf = (month) => `${month}-01`;

/** addMonths('2026-12', 1) -> '2027-01'. Works with negative values too. */
export function addMonths(month, count) {
  const [year, monthNumber] = month.split('-').map(Number);
  const index = year * 12 + (monthNumber - 1) + count;
  return `${Math.floor(index / 12)}-${pad((index % 12) + 1)}`;
}

/** Number of days in a month: daysInMonth('2026-02') -> 28. */
export function daysInMonth(month) {
  const [year, monthNumber] = month.split('-').map(Number);
  return new Date(Date.UTC(year, monthNumber, 0)).getUTCDate();
}

/**
 * The date a monthly charge happens in a month. Days that do not exist in that month are
 * moved to its last day: billingDateIn('2026-02', 31) -> '2026-02-28'.
 */
export function billingDateIn(month, billingDay) {
  return `${month}-${pad(Math.min(billingDay, daysInMonth(month)))}`;
}

/** Every month from `from` to `to`, both included. */
export function monthsBetween(from, to) {
  const months = [];
  for (let month = from; month <= to; month = addMonths(month, 1)) {
    months.push(month);
  }
  return months;
}

// Prisma maps PostgreSQL DATE columns to JavaScript Dates at midnight UTC.

/** '2026-10-15' -> Date for a DATE column */
export const toDbDate = (date) => new Date(`${date}T00:00:00.000Z`);

/** Date from a DATE column -> '2026-10-15' */
export const fromDbDate = (value) => value.toISOString().slice(0, 10);

/** Latest of several 'YYYY-MM-DD' dates. */
export const latestDate = (...dates) => dates.reduce((latest, date) => (date > latest ? date : latest));
