import { afterAll, afterEach, beforeEach, describe, expect, it } from 'vitest';
import { prisma } from '../src/lib/prisma.js';
import { transactionListResponseSchema, transactionResponseSchema } from '../src/schemas/transaction.schemas.js';
import { createUser, netWorth, resetDatabase, restoreNow, setNow, transactions } from './helpers.js';

let user;

const groceries = { type: 'expense', name: 'Supermarket', amountCents: 4250, date: '2026-10-14', note: 'Weekly' };

beforeEach(async () => {
  await resetDatabase();
  setNow('2026-10-15T10:00:00Z');
  user = await createUser();
  await user.put('/profile/net-worth').send({ netWorthCents: 100000 });
});

afterEach(restoreNow);

afterAll(async () => {
  await prisma.$disconnect();
});

describe('POST /transactions', () => {
  it('adds an expense and subtracts it from the net worth', async () => {
    const response = await user.post('/transactions').send(groceries);

    expect(response.status).toBe(201);
    expect(response.body.transaction).toMatchObject({
      type: 'expense',
      name: 'Supermarket',
      amountCents: -4250,
      date: '2026-10-14',
      note: 'Weekly',
      subscriptionId: null,
      editable: true,
    });
    expect(transactionResponseSchema.parse(response.body)).toEqual(response.body);
    expect(await netWorth(user)).toBe(100000 - 4250);
  });

  it('accepts outings and leisure too', async () => {
    for (const type of ['outing', 'leisure']) {
      const response = await user.post('/transactions').send({ ...groceries, type });
      expect(response.status).toBe(201);
      expect(response.body.transaction.type).toBe(type);
    }
  });

  it('uses today when no date is sent, and stores an empty note as null', async () => {
    const response = await user.post('/transactions').send({ type: 'leisure', name: 'Cinema', amountCents: 800, note: ' ' });

    expect(response.body.transaction).toMatchObject({ date: '2026-10-15', note: null });
  });

  it('rejects a date in the future (in the user time zone)', async () => {
    const response = await user.post('/transactions').send({ ...groceries, date: '2026-10-16' });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('date_in_future');
  });

  it('does not let the user create automatic types', async () => {
    for (const type of ['income', 'subscription_charge', 'adjustment']) {
      expect((await user.post('/transactions').send({ ...groceries, type })).status).toBe(400);
    }
  });

  it('validates the amount and the fields', async () => {
    const invalid = [
      { ...groceries, amountCents: 0 },
      { ...groceries, amountCents: -100 },
      { ...groceries, amountCents: 12.5 },
      { ...groceries, amountCents: 1_000_000_001 },
      { ...groceries, name: '' },
      { ...groceries, date: '2026-13-01' },
      { ...groceries, note: 'x'.repeat(501) },
    ];
    for (const body of invalid) {
      const response = await user.post('/transactions').send(body);
      expect(response.status, JSON.stringify(body)).toBe(400);
      expect(response.body.error.code).toBe('validation_error');
    }
  });
});

describe('PUT /transactions/:id', () => {
  it('edits the item and the net worth follows', async () => {
    const { body } = await user.post('/transactions').send(groceries);
    const response = await user
      .put(`/transactions/${body.transaction.id}`)
      .send({ ...groceries, type: 'leisure', amountCents: 1000 });

    expect(response.status).toBe(200);
    expect(response.body.transaction).toMatchObject({ type: 'leisure', amountCents: -1000 });
    expect(await netWorth(user)).toBe(100000 - 1000);
  });

  it('does not change automatic transactions', async () => {
    await user.put('/profile/net-worth').send({ netWorthCents: 90000 });
    const [adjustment] = await transactions(user);

    const response = await user.put(`/transactions/${adjustment.id}`).send(groceries);

    expect(response.status).toBe(409);
    expect(response.body.error.code).toBe('transaction_not_editable');
  });
});

describe('DELETE /transactions/:id', () => {
  it('deletes the item and gives the money back', async () => {
    const { body } = await user.post('/transactions').send(groceries);
    const response = await user.delete(`/transactions/${body.transaction.id}`);

    expect(response.status).toBe(204);
    expect(await netWorth(user)).toBe(100000);
    expect(await transactions(user)).toHaveLength(0);
  });

  it('does not delete automatic transactions', async () => {
    await user.put('/profile/net-worth').send({ netWorthCents: 90000 });
    const [adjustment] = await transactions(user);

    expect((await user.delete(`/transactions/${adjustment.id}`)).status).toBe(409);
  });

  it('answers 404 for an unknown id and 400 for an invalid one', async () => {
    expect((await user.delete('/transactions/01a1322a-ff14-76e9-83c0-3174db7dac15')).status).toBe(404);
    expect((await user.delete('/transactions/not-an-id')).status).toBe(400);
  });
});

describe('GET /transactions', () => {
  beforeEach(async () => {
    await user.post('/transactions').send({ ...groceries, date: '2026-10-01' });
    await user.post('/transactions').send({ ...groceries, type: 'outing', date: '2026-10-10' });
    await user.post('/transactions').send({ ...groceries, type: 'leisure', date: '2026-10-15' });
  });

  it('lists newest first, with the total', async () => {
    const response = await user.get('/transactions');

    expect(response.status).toBe(200);
    expect(response.body.items.map((item) => item.date)).toEqual(['2026-10-15', '2026-10-10', '2026-10-01']);
    expect(response.body.total).toBe(3);
    expect(transactionListResponseSchema.parse(response.body)).toEqual(response.body);
  });

  it('filters by type', async () => {
    const items = await transactions(user, '?type=expense,leisure');

    expect(items.map((item) => item.type).sort()).toEqual(['expense', 'leisure']);
  });

  it('filters by date range, both days included', async () => {
    const items = await transactions(user, '?from=2026-10-10&to=2026-10-15');

    expect(items.map((item) => item.date)).toEqual(['2026-10-15', '2026-10-10']);
  });

  it('pages with limit and offset', async () => {
    const response = await user.get('/transactions?limit=1&offset=1');

    expect(response.body.items.map((item) => item.date)).toEqual(['2026-10-10']);
    expect(response.body.total).toBe(3);
  });

  it('validates the filters', async () => {
    for (const query of ['?type=food', '?from=2026-10-20&to=2026-10-01', '?limit=0', '?from=yesterday']) {
      expect((await user.get(`/transactions${query}`)).status, query).toBe(400);
    }
  });
});

describe('users only see their own data', () => {
  it('hides and protects the transactions of other users', async () => {
    const { body } = await user.post('/transactions').send(groceries);
    const other = await createUser();

    expect(await transactions(other)).toHaveLength(0);
    expect((await other.put(`/transactions/${body.transaction.id}`).send(groceries)).status).toBe(404);
    expect((await other.delete(`/transactions/${body.transaction.id}`)).status).toBe(404);
    expect(await netWorth(user)).toBe(100000 - 4250);
  });
});
