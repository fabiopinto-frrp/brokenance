import { describe, expect, it } from 'vitest';
import {
  addMonths,
  billingDateIn,
  daysInMonth,
  fromDbDate,
  monthsBetween,
  toDbDate,
  todayIn,
} from '../src/lib/dates.js';

describe('calendar helpers', () => {
  it('uses the user time zone for today', () => {
    // 23:30 UTC on 30 June is already 1 July in Lisbon (UTC+1 in summer).
    const instant = new Date('2026-06-30T23:30:00Z');

    expect(todayIn('Europe/Lisbon', instant)).toBe('2026-07-01');
    expect(todayIn('UTC', instant)).toBe('2026-06-30');
  });

  it('adds months across years, forwards and backwards', () => {
    expect(addMonths('2026-12', 1)).toBe('2027-01');
    expect(addMonths('2026-01', -1)).toBe('2025-12');
    expect(addMonths('2026-10', 15)).toBe('2028-01');
  });

  it('moves billing days that do not exist to the last day of the month', () => {
    expect(billingDateIn('2026-02', 31)).toBe('2026-02-28');
    expect(billingDateIn('2028-02', 30)).toBe('2028-02-29');
    expect(billingDateIn('2026-04', 31)).toBe('2026-04-30');
    expect(billingDateIn('2026-10', 8)).toBe('2026-10-08');
  });

  it('knows the length of every month', () => {
    expect(daysInMonth('2026-02')).toBe(28);
    expect(daysInMonth('2028-02')).toBe(29);
    expect(daysInMonth('2026-12')).toBe(31);
  });

  it('lists the months of a range', () => {
    expect(monthsBetween('2026-11', '2027-02')).toEqual(['2026-11', '2026-12', '2027-01', '2027-02']);
  });

  it('round-trips DATE columns', () => {
    expect(fromDbDate(toDbDate('2026-10-15'))).toBe('2026-10-15');
  });
});
