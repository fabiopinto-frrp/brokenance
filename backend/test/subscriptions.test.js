import { afterAll, afterEach, beforeEach, describe, expect, it } from 'vitest';
import { prisma } from '../src/lib/prisma.js';
import { subscriptionListResponseSchema, subscriptionResponseSchema } from '../src/schemas/subscription.schemas.js';
import { createUser, resetDatabase, restoreNow, setNow } from './helpers.js';

// CRUD of subscriptions. The charges themselves are tested in recurring.test.js.

let user;
const netflix = { name: 'Netflix', amountCents: 1599, billingDay: 8 };

beforeEach(async () => {
  await resetDatabase();
  setNow('2026-10-15T10:00:00Z');
  user = await createUser();
});

afterEach(restoreNow);

afterAll(async () => {
  await prisma.$disconnect();
});

describe('POST /subscriptions', () => {
  it('creates a subscription with its defaults', async () => {
    const response = await user.post('/subscriptions').send(netflix);

    expect(response.status).toBe(201);
    expect(response.body.subscription).toMatchObject({
      name: 'Netflix',
      amountCents: 1599,
      period: 'monthly',
      billingDay: 8,
      billingMonth: null,
      active: true,
      nextChargeDate: '2026-11-08',
    });
    expect(subscriptionResponseSchema.parse(response.body)).toEqual(response.body);
  });

  it('validates the body', async () => {
    const invalid = [
      { ...netflix, billingDay: 0 },
      { ...netflix, billingDay: 32 },
      { ...netflix, amountCents: 0 },
      { ...netflix, name: '' },
      { ...netflix, billingDay: 8.5 },
    ];
    for (const body of invalid) {
      expect((await user.post('/subscriptions').send(body)).status, JSON.stringify(body)).toBe(400);
    }
  });
});

describe('GET /subscriptions', () => {
  it('lists active ones first and sums only the active ones, per period', async () => {
    await user.post('/subscriptions').send(netflix);
    await user.post('/subscriptions').send({ ...netflix, name: 'Gym', amountCents: 3500 });
    await user.post('/subscriptions').send({ ...netflix, name: 'Abandoned', amountCents: 999, active: false });
    await user
      .post('/subscriptions')
      .send({ name: 'Insurance', amountCents: 12000, period: 'yearly', billingDay: 1, billingMonth: 3 });

    const response = await user.get('/subscriptions');

    expect(response.body.items.map((item) => item.name)).toEqual(['Gym', 'Insurance', 'Netflix', 'Abandoned']);
    expect(response.body).toMatchObject({
      monthlyTotalCents: 1599 + 3500,
      yearlyTotalCents: 12000,
      averagePerMonthCents: 1599 + 3500 + 1000,
    });
    expect(subscriptionListResponseSchema.parse(response.body)).toEqual(response.body);
  });
});

describe('PUT /subscriptions/:id', () => {
  it('replaces the fields', async () => {
    const { body } = await user.post('/subscriptions').send(netflix);
    const response = await user
      .put(`/subscriptions/${body.subscription.id}`)
      .send({ name: 'Netflix Premium', amountCents: 1999, billingDay: 10 });

    expect(response.status).toBe(200);
    expect(response.body.subscription).toMatchObject({
      name: 'Netflix Premium',
      amountCents: 1999,
      billingDay: 10,
      nextChargeDate: '2026-11-10',
    });
  });
});

describe('yearly subscriptions', () => {
  const insurance = { name: 'Car insurance', amountCents: 24000, period: 'yearly', billingDay: 10, billingMonth: 3 };

  it('creates a yearly subscription', async () => {
    const response = await user.post('/subscriptions').send(insurance);

    expect(response.status).toBe(201);
    expect(response.body.subscription).toMatchObject({
      period: 'yearly',
      billingDay: 10,
      billingMonth: 3,
      nextChargeDate: '2027-03-10',
    });
    expect(subscriptionResponseSchema.parse(response.body)).toEqual(response.body);
  });

  it('accepts 29 February and rejects days a month never has', async () => {
    expect((await user.post('/subscriptions').send({ ...insurance, billingDay: 29, billingMonth: 2 })).status).toBe(201);

    const invalid = [
      { ...insurance, billingDay: 30, billingMonth: 2 },
      { ...insurance, billingDay: 31, billingMonth: 4 },
      { ...insurance, billingMonth: 13 },
      { ...insurance, billingMonth: 0 },
      { ...insurance, billingMonth: undefined },
      { ...netflix, billingMonth: 3 },
      { ...netflix, period: 'weekly' },
    ];
    for (const body of invalid) {
      const response = await user.post('/subscriptions').send(body);
      expect(response.status, JSON.stringify(body)).toBe(400);
      expect(response.body.error.code).toBe('validation_error');
    }
  });

  it('can switch between monthly and yearly', async () => {
    const { body } = await user.post('/subscriptions').send(netflix);
    const yearly = await user.put(`/subscriptions/${body.subscription.id}`).send({ ...netflix, period: 'yearly', billingMonth: 12 });

    expect(yearly.body.subscription).toMatchObject({ period: 'yearly', billingMonth: 12, nextChargeDate: '2026-12-08' });

    const monthly = await user.put(`/subscriptions/${body.subscription.id}`).send(netflix);
    expect(monthly.body.subscription).toMatchObject({ period: 'monthly', billingMonth: null, nextChargeDate: '2026-11-08' });
  });
});

describe('ownership', () => {
  it('other users cannot see, edit or delete a subscription', async () => {
    const { body } = await user.post('/subscriptions').send(netflix);
    const other = await createUser();

    expect((await other.get('/subscriptions')).body.items).toHaveLength(0);
    expect((await other.put(`/subscriptions/${body.subscription.id}`).send(netflix)).status).toBe(404);
    expect((await other.delete(`/subscriptions/${body.subscription.id}`)).status).toBe(404);
    expect((await user.get('/subscriptions')).body.items).toHaveLength(1);
  });
});
