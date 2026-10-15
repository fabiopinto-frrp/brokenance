import request from 'supertest';
import { afterAll, afterEach, beforeEach, describe, expect, it } from 'vitest';
import { prisma } from '../src/lib/prisma.js';
import { profileResponseSchema } from '../src/schemas/profile.schemas.js';
import { app, createUser, netWorth, resetDatabase, restoreNow, setNow, transactions } from './helpers.js';

let user;

beforeEach(async () => {
  await resetDatabase();
  setNow('2026-10-15T10:00:00Z');
  user = await createUser();
});

afterEach(restoreNow);

afterAll(async () => {
  await prisma.$disconnect();
});

describe('GET /profile', () => {
  it('returns the profile with its defaults', async () => {
    const response = await user.get('/profile');

    expect(response.status).toBe(200);
    expect(response.body.profile).toEqual({
      username: expect.stringMatching(/^user\d+$/),
      firstName: 'Test',
      lastName: 'User',
      monthlyIncomeCents: 0,
      netWorthCents: 0,
      netWorthSet: false,
      currency: 'EUR',
      timezone: 'Europe/Lisbon',
    });
    expect(profileResponseSchema.parse(response.body)).toEqual(response.body);
  });

  it('requires an access token', async () => {
    expect((await request(app).get('/profile')).status).toBe(401);
  });
});

describe('PUT /profile', () => {
  it('changes only the fields that are sent', async () => {
    const response = await user.put('/profile').send({ monthlyIncomeCents: 90000 });

    expect(response.status).toBe(200);
    expect(response.body.profile).toMatchObject({ firstName: 'Test', lastName: 'User', monthlyIncomeCents: 90000 });
  });

  it('changes the names, accents included', async () => {
    const response = await user.put('/profile').send({ firstName: ' João ', lastName: 'Conceição' });

    expect(response.body.profile).toMatchObject({ firstName: 'João', lastName: 'Conceição' });
  });

  it('validates the body', async () => {
    for (const body of [{}, { monthlyIncomeCents: -1 }, { monthlyIncomeCents: 12.5 }, { firstName: '  ' }]) {
      const response = await user.put('/profile').send(body);
      expect(response.status, JSON.stringify(body)).toBe(400);
      expect(response.body.error.code).toBe('validation_error');
    }
  });
});

describe('PUT /profile/net-worth', () => {
  it('the first value becomes the opening balance, with no transaction', async () => {
    const response = await user.put('/profile/net-worth').send({ netWorthCents: 250000 });

    expect(response.status).toBe(200);
    expect(response.body.profile).toMatchObject({ netWorthCents: 250000, netWorthSet: true });
    expect(await transactions(user)).toHaveLength(0);
  });

  it('the first value already counts expenses added before it', async () => {
    await user.post('/transactions').send({ type: 'expense', name: 'Coffee', amountCents: 150 });
    await user.put('/profile/net-worth').send({ netWorthCents: 250000 });

    expect(await netWorth(user)).toBe(250000);
  });

  it('later changes are stored as an adjustment', async () => {
    await user.put('/profile/net-worth').send({ netWorthCents: 250000 });
    const response = await user.put('/profile/net-worth').send({ netWorthCents: 200000 });

    expect(response.body.profile.netWorthCents).toBe(200000);
    expect(await transactions(user)).toEqual([
      expect.objectContaining({ type: 'adjustment', amountCents: -50000, date: '2026-10-15', editable: false }),
    ]);
  });

  it('setting the same value adds nothing', async () => {
    await user.put('/profile/net-worth').send({ netWorthCents: 250000 });
    await user.put('/profile/net-worth').send({ netWorthCents: 250000 });

    expect(await transactions(user)).toHaveLength(0);
  });

  it('accepts a negative net worth', async () => {
    const response = await user.put('/profile/net-worth').send({ netWorthCents: -5000 });

    expect(response.body.profile.netWorthCents).toBe(-5000);
  });

  it('validates the body', async () => {
    for (const body of [{}, { netWorthCents: '100' }, { netWorthCents: 1.5 }]) {
      expect((await user.put('/profile/net-worth').send(body)).status).toBe(400);
    }
  });
});
