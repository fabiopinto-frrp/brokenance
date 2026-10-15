import { afterAll, afterEach, beforeEach, describe, expect, it } from 'vitest';
import { prisma } from '../src/lib/prisma.js';
import { applyDueRecurring } from '../src/services/recurring.service.js';
import { createUser, netWorth, resetDatabase, restoreNow, setNow, transactions } from './helpers.js';

// The recurring engine: monthly income on the 1st and subscription charges on their billing
// day, in the Lisbon time zone, catching up on missed months and never applying twice.

const incomes = (user) => transactions(user, '?type=income');
const charges = (user) => transactions(user, '?type=subscription_charge');

afterEach(restoreNow);

afterAll(async () => {
  await prisma.$disconnect();
});

beforeEach(resetDatabase);

describe('monthly income', () => {
  let user;

  beforeEach(async () => {
    setNow('2026-10-15T10:00:00Z');
    user = await createUser();
    await user.put('/profile').send({ monthlyIncomeCents: 90000 });
  });

  it('is not paid for the month the account was created', async () => {
    setNow('2026-10-31T12:00:00Z');

    expect(await incomes(user)).toHaveLength(0);
  });

  it('is added on the 1st and counts in the net worth', async () => {
    setNow('2026-11-01T08:00:00Z');

    expect(await incomes(user)).toEqual([
      expect.objectContaining({ type: 'income', amountCents: 90000, date: '2026-11-01', editable: false }),
    ]);
    expect(await netWorth(user)).toBe(90000);
  });

  it('catches up on every month that was missed', async () => {
    setNow('2027-02-10T12:00:00Z');

    expect((await incomes(user)).map((income) => income.date)).toEqual([
      '2027-02-01',
      '2027-01-01',
      '2026-12-01',
      '2026-11-01',
    ]);
  });

  it('is never added twice, even with simultaneous requests', async () => {
    setNow('2026-11-01T08:00:00Z');

    await Promise.all(Array.from({ length: 5 }, () => user.get('/profile')));
    await user.get('/dashboard/summary');

    expect(await incomes(user)).toHaveLength(1);
  });

  it('a new amount applies from the next 1st on', async () => {
    setNow('2026-11-05T12:00:00Z');
    await user.get('/profile');
    await user.put('/profile').send({ monthlyIncomeCents: 100000 });
    setNow('2026-12-01T12:00:00Z');

    expect((await incomes(user)).map((income) => income.amountCents)).toEqual([100000, 90000]);
  });

  it('adds nothing while the income is 0', async () => {
    await user.put('/profile').send({ monthlyIncomeCents: 0 });
    setNow('2026-12-15T12:00:00Z');

    expect(await incomes(user)).toHaveLength(0);
  });
});

describe('the 1st follows the Lisbon time zone', () => {
  it('pays at midnight in Lisbon, which is 23:00 UTC in summer', async () => {
    setNow('2026-06-15T10:00:00Z');
    const user = await createUser();
    await user.put('/profile').send({ monthlyIncomeCents: 90000 });

    setNow('2026-06-30T22:30:00Z'); // 23:30 on 30 June in Lisbon
    expect(await incomes(user)).toHaveLength(0);

    setNow('2026-06-30T23:30:00Z'); // 00:30 on 1 July in Lisbon
    expect(await incomes(user)).toEqual([expect.objectContaining({ date: '2026-07-01' })]);
  });
});

describe('subscription charges', () => {
  let user;
  const gym = { name: 'Gym', amountCents: 3500, billingDay: 20 };

  beforeEach(async () => {
    setNow('2026-10-15T10:00:00Z');
    user = await createUser();
  });

  it('charges right away when the billing day is today', async () => {
    const response = await user.post('/subscriptions').send({ ...gym, billingDay: 15 });

    expect(response.body.subscription.nextChargeDate).toBe('2026-11-15');
    expect(await charges(user)).toEqual([
      expect.objectContaining({
        type: 'subscription_charge',
        name: 'Gym',
        amountCents: -3500,
        date: '2026-10-15',
        subscriptionId: response.body.subscription.id,
        editable: false,
      }),
    ]);
    expect(await netWorth(user)).toBe(-3500);
  });

  it('charges on the billing day', async () => {
    const response = await user.post('/subscriptions').send(gym);
    expect(response.body.subscription.nextChargeDate).toBe('2026-10-20');
    expect(await charges(user)).toHaveLength(0);

    setNow('2026-10-20T08:00:00Z');
    expect(await charges(user)).toEqual([expect.objectContaining({ date: '2026-10-20' })]);
  });

  it('uses the last day of shorter months', async () => {
    await user.post('/subscriptions').send({ ...gym, billingDay: 31 });
    setNow('2027-04-30T12:00:00Z');

    expect((await charges(user)).map((charge) => charge.date)).toEqual([
      '2027-04-30',
      '2027-03-31',
      '2027-02-28',
      '2027-01-31',
      '2026-12-31',
      '2026-11-30',
      '2026-10-31',
    ]);
  });

  it('charges days 29, 30 and 31 on the last day of February, once', async () => {
    for (const billingDay of [29, 30, 31]) {
      await user.post('/subscriptions').send({ ...gym, name: `Day ${billingDay}`, billingDay });
    }

    setNow('2027-02-27T12:00:00Z');
    const beforeEnd = (await charges(user)).filter((charge) => charge.date.startsWith('2027-02'));
    expect(beforeEnd).toHaveLength(0);

    setNow('2027-02-28T12:00:00Z');
    const february = (await charges(user)).filter((charge) => charge.date.startsWith('2027-02'));
    expect(february.map((charge) => [charge.name, charge.date]).sort()).toEqual([
      ['Day 29', '2027-02-28'],
      ['Day 30', '2027-02-28'],
      ['Day 31', '2027-02-28'],
    ]);

    // Back to the normal day in March.
    setNow('2027-03-31T12:00:00Z');
    const march = (await charges(user)).filter((charge) => charge.date.startsWith('2027-03'));
    expect(march.map((charge) => [charge.name, charge.date]).sort()).toEqual([
      ['Day 29', '2027-03-29'],
      ['Day 30', '2027-03-30'],
      ['Day 31', '2027-03-31'],
    ]);
  });

  it('uses 29 February in leap years', async () => {
    setNow('2028-02-10T12:00:00Z');
    const leapUser = await createUser();
    const response = await leapUser.post('/subscriptions').send({ ...gym, billingDay: 31 });

    expect(response.body.subscription.nextChargeDate).toBe('2028-02-29');
    setNow('2028-02-29T12:00:00Z');
    expect((await charges(leapUser)).map((charge) => charge.date)).toEqual(['2028-02-29']);
  });

  it('catches up on every missed charge, once', async () => {
    await user.post('/subscriptions').send(gym);
    setNow('2027-01-25T12:00:00Z');
    await Promise.all([user.get('/subscriptions'), user.get('/profile'), user.get('/transactions')]);

    expect((await charges(user)).map((charge) => charge.date)).toEqual([
      '2027-01-20',
      '2026-12-20',
      '2026-11-20',
      '2026-10-20',
    ]);
  });

  it('does not charge this month when the day already passed', async () => {
    const response = await user.post('/subscriptions').send({ ...gym, billingDay: 8 });

    expect(await charges(user)).toHaveLength(0);
    expect(response.body.subscription.nextChargeDate).toBe('2026-11-08');

    setNow('2026-11-08T12:00:00Z');
    expect((await charges(user)).map((charge) => charge.date)).toEqual(['2026-11-08']);
  });

  it('never charges the months it was paused', async () => {
    const { body } = await user.post('/subscriptions').send(gym);
    const id = body.subscription.id;

    setNow('2026-10-22T12:00:00Z');
    const paused = await user.put(`/subscriptions/${id}`).send({ ...gym, active: false });
    expect(paused.body.subscription.nextChargeDate).toBeNull();

    setNow('2027-01-10T12:00:00Z');
    const resumed = await user.put(`/subscriptions/${id}`).send({ ...gym, active: true });
    expect(resumed.body.subscription.nextChargeDate).toBe('2027-01-20');
    expect(await charges(user)).toHaveLength(1);

    setNow('2027-01-20T12:00:00Z');
    expect((await charges(user)).map((charge) => charge.date)).toEqual(['2027-01-20', '2026-10-20']);
  });

  it('a new amount applies to future charges only', async () => {
    const { body } = await user.post('/subscriptions').send(gym);
    setNow('2026-10-21T12:00:00Z');
    await user.put(`/subscriptions/${body.subscription.id}`).send({ ...gym, amountCents: 4000 });
    setNow('2026-11-20T12:00:00Z');

    expect((await charges(user)).map((charge) => charge.amountCents)).toEqual([-4000, -3500]);
  });

  it('changing the billing day never charges the same month twice', async () => {
    const { body } = await user.post('/subscriptions').send(gym);
    setNow('2026-10-21T12:00:00Z');
    await user.get('/profile');
    const response = await user.put(`/subscriptions/${body.subscription.id}`).send({ ...gym, billingDay: 28 });

    expect(response.body.subscription.nextChargeDate).toBe('2026-11-28');
    setNow('2026-10-30T12:00:00Z');
    expect(await charges(user)).toHaveLength(1);
  });

  it('deleting a subscription keeps its past charges', async () => {
    const { body } = await user.post('/subscriptions').send(gym);
    setNow('2026-10-20T12:00:00Z');
    await user.get('/profile');

    expect((await user.delete(`/subscriptions/${body.subscription.id}`)).status).toBe(204);
    setNow('2026-12-20T12:00:00Z');

    expect(await charges(user)).toEqual([expect.objectContaining({ date: '2026-10-20', subscriptionId: null })]);
    expect(await netWorth(user)).toBe(-3500);
  });
});

describe('applyDueRecurring', () => {
  it('does nothing for an unknown user', async () => {
    await expect(applyDueRecurring('01a1322a-ff14-76e9-83c0-3174db7dac15')).resolves.toBeUndefined();
  });
});

describe('yearly subscription charges', () => {
  let user;
  const insurance = { name: 'Car insurance', amountCents: 24000, period: 'yearly', billingDay: 10, billingMonth: 3 };

  beforeEach(async () => {
    setNow('2026-10-15T10:00:00Z');
    user = await createUser();
  });

  it('charges once a year on its day and month', async () => {
    await user.post('/subscriptions').send(insurance);
    expect(await charges(user)).toHaveLength(0);

    setNow('2027-03-10T08:00:00Z');
    expect(await charges(user)).toEqual([
      expect.objectContaining({ name: 'Car insurance', amountCents: -24000, date: '2027-03-10' }),
    ]);

    setNow('2028-03-09T12:00:00Z');
    expect(await charges(user)).toHaveLength(1);

    setNow('2028-03-10T08:00:00Z');
    expect((await charges(user)).map((charge) => charge.date)).toEqual(['2028-03-10', '2027-03-10']);
  });

  it('charges right away when the date is today, and not when it already passed this year', async () => {
    await user.post('/subscriptions').send({ ...insurance, name: 'Today', billingDay: 15, billingMonth: 10 });
    const passed = await user.post('/subscriptions').send({ ...insurance, name: 'Passed', billingDay: 14, billingMonth: 10 });

    expect((await charges(user)).map((charge) => [charge.name, charge.date])).toEqual([['Today', '2026-10-15']]);
    expect(passed.body.subscription.nextChargeDate).toBe('2027-10-14');
  });

  it('charges 29 February on the 28th in other years', async () => {
    await user.post('/subscriptions').send({ ...insurance, billingDay: 29, billingMonth: 2 });
    setNow('2028-03-01T12:00:00Z');

    expect((await charges(user)).map((charge) => charge.date)).toEqual(['2028-02-29', '2027-02-28']);
  });

  it('catches up on missed years, once', async () => {
    await user.post('/subscriptions').send(insurance);
    setNow('2029-04-01T12:00:00Z');
    await Promise.all([user.get('/subscriptions'), user.get('/profile')]);

    expect((await charges(user)).map((charge) => charge.date)).toEqual(['2029-03-10', '2028-03-10', '2027-03-10']);
  });

  it('moving the date after this year was charged waits for next year', async () => {
    const { body } = await user.post('/subscriptions').send({ ...insurance, billingMonth: 10, billingDay: 15 });
    const moved = await user.put(`/subscriptions/${body.subscription.id}`).send({ ...insurance, billingMonth: 12 });

    expect(moved.body.subscription.nextChargeDate).toBe('2027-12-10');
    setNow('2026-12-31T12:00:00Z');
    expect(await charges(user)).toHaveLength(1);
  });

  it('never charges the years it was paused', async () => {
    const { body } = await user.post('/subscriptions').send(insurance);
    const id = body.subscription.id;
    await user.put(`/subscriptions/${id}`).send({ ...insurance, active: false });

    setNow('2028-06-01T12:00:00Z');
    const resumed = await user.put(`/subscriptions/${id}`).send({ ...insurance, active: true });

    expect(resumed.body.subscription.nextChargeDate).toBe('2029-03-10');
    expect(await charges(user)).toHaveLength(0);
  });
});

describe('changes never rewrite what was already due', () => {
  it('a new income amount does not change a 1st that already passed', async () => {
    setNow('2026-10-15T10:00:00Z');
    const user = await createUser();
    await user.put('/profile').send({ monthlyIncomeCents: 90000 });

    // Nobody opened the app on 1 November.
    setNow('2026-11-05T12:00:00Z');
    await user.put('/profile').send({ monthlyIncomeCents: 100000 });

    expect((await incomes(user)).map((income) => income.amountCents)).toEqual([90000]);
  });
});
