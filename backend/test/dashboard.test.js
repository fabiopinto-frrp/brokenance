import { afterAll, afterEach, beforeEach, describe, expect, it } from 'vitest';
import { prisma } from '../src/lib/prisma.js';
import { dashboardResponseSchema } from '../src/schemas/dashboard.schemas.js';
import { createUser, resetDatabase, restoreNow, setNow } from './helpers.js';

let user;

beforeEach(async () => {
  await resetDatabase();

  // October: opening balance 1000.00, then 30.00 of spending.
  setNow('2026-10-15T10:00:00Z');
  user = await createUser();
  await user.put('/profile/net-worth').send({ netWorthCents: 100000 });
  await user.put('/profile').send({ monthlyIncomeCents: 90000 });
  await user.post('/transactions').send({ type: 'expense', name: 'Supermarket', amountCents: 2000 });
  await user.post('/transactions').send({ type: 'leisure', name: 'Cinema', amountCents: 1000 });

  // November: income 900.00, then 115.00 of spending.
  setNow('2026-11-10T10:00:00Z');
  await user.post('/transactions').send({ type: 'expense', name: 'Pharmacy', amountCents: 5000 });
  await user.post('/transactions').send({ type: 'outing', name: 'Porto', amountCents: 3000 });
  await user.post('/subscriptions').send({ name: 'Gym', amountCents: 3500, billingDay: 10 });
  await user.post('/savings-targets').send({ amountCents: 30000 });
  await user.post('/goals').send({ name: 'Laptop', targetCents: 100000, savedCents: 25000 });
});

afterEach(restoreNow);

afterAll(async () => {
  await prisma.$disconnect();
});

describe('GET /dashboard/summary', () => {
  it('summarises the money month by month', async () => {
    const response = await user.get('/dashboard/summary?months=2');

    expect(response.status).toBe(200);
    expect(response.body.months).toEqual([
      {
        month: '2026-10',
        incomeCents: 0,
        spendingCents: 3000,
        leftCents: -3000,
        spendingByCategory: { expense: 2000, outing: 0, leisure: 1000, subscription_charge: 0 },
        netWorthCents: 97000,
      },
      {
        month: '2026-11',
        incomeCents: 90000,
        spendingCents: 11500,
        leftCents: 78500,
        spendingByCategory: { expense: 5000, outing: 3000, leisure: 0, subscription_charge: 3500 },
        netWorthCents: 175500,
      },
    ]);
    expect(response.body.currentMonth).toEqual(response.body.months[1]);
    expect(response.body.netWorthCents).toBe(175500);
    expect(dashboardResponseSchema.parse(response.body)).toEqual(response.body);
  });

  it('compares what is left with the savings target', async () => {
    const { body } = await user.get('/dashboard/summary');

    expect(body.savings).toEqual({ targetCents: 30000, leftThisMonthCents: 78500, onTrack: true });
  });

  it('includes goals and subscriptions', async () => {
    const { body } = await user.get('/dashboard/summary');

    expect(body.goals).toMatchObject({ totalTargetCents: 100000, totalSavedCents: 25000 });
    expect(body.goals.items[0]).toMatchObject({ name: 'Laptop', estimatedMonthsLeft: 3 });
    expect(body.subscriptions).toEqual({
      activeCount: 1,
      monthlyTotalCents: 3500,
      yearlyTotalCents: 0,
      averagePerMonthCents: 3500,
    });
  });

  it('counts adjustments in the net worth, not as income or spending', async () => {
    await user.put('/profile/net-worth').send({ netWorthCents: 200000 });
    const { body } = await user.get('/dashboard/summary?months=1');

    expect(body.currentMonth).toMatchObject({ incomeCents: 90000, spendingCents: 11500, netWorthCents: 200000 });
  });

  it('returns 6 months by default, oldest first', async () => {
    const { body } = await user.get('/dashboard/summary');

    expect(body.months.map((month) => month.month)).toEqual([
      '2026-06',
      '2026-07',
      '2026-08',
      '2026-09',
      '2026-10',
      '2026-11',
    ]);
    expect(body.months[0].netWorthCents).toBe(100000);
  });

  it('validates months', async () => {
    for (const query of ['?months=0', '?months=25', '?months=abc']) {
      expect((await user.get(`/dashboard/summary${query}`)).status, query).toBe(400);
    }
  });
});
