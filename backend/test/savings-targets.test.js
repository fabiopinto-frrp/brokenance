import { afterAll, afterEach, beforeEach, describe, expect, it } from 'vitest';
import { prisma } from '../src/lib/prisma.js';
import { savingsTargetListResponseSchema } from '../src/schemas/savings-target.schemas.js';
import { createUser, netWorth, resetDatabase, restoreNow, setNow } from './helpers.js';

let user;

const list = async () => (await user.get('/savings-targets')).body;

beforeEach(async () => {
  await resetDatabase();
  setNow('2026-10-15T10:00:00Z');
  user = await createUser();
});

afterEach(restoreNow);

afterAll(async () => {
  await prisma.$disconnect();
});

describe('savings targets (Poupança)', () => {
  it('starts with no current target', async () => {
    expect(await list()).toEqual({ current: null, items: [] });
  });

  it('the newest target is the current one, older ones are history', async () => {
    await user.post('/savings-targets').send({ amountCents: 20000, effectiveDate: '2026-09-01' });
    const created = await user.post('/savings-targets').send({ amountCents: 30000 });

    expect(created.status).toBe(201);
    expect(created.body.savingsTarget).toMatchObject({ amountCents: 30000, effectiveDate: '2026-10-15', isCurrent: true });

    const body = await list();
    expect(body.current.amountCents).toBe(30000);
    expect(body.items.map((item) => [item.amountCents, item.isCurrent])).toEqual([
      [30000, true],
      [20000, false],
    ]);
    expect(savingsTargetListResponseSchema.parse(body)).toEqual(body);
  });

  it('a target dated before the current one goes into the history', async () => {
    await user.post('/savings-targets').send({ amountCents: 30000 });
    const response = await user.post('/savings-targets').send({ amountCents: 10000, effectiveDate: '2026-01-01' });

    expect(response.body.savingsTarget.isCurrent).toBe(false);
    expect((await list()).current.amountCents).toBe(30000);
  });

  it('deleting the current target makes the previous one current again', async () => {
    await user.post('/savings-targets').send({ amountCents: 20000, effectiveDate: '2026-09-01' });
    const { body } = await user.post('/savings-targets').send({ amountCents: 30000 });

    expect((await user.delete(`/savings-targets/${body.savingsTarget.id}`)).status).toBe(204);
    expect((await list()).current.amountCents).toBe(20000);
  });

  it('editing keeps the date when no new one is sent', async () => {
    const { body } = await user.post('/savings-targets').send({ amountCents: 20000, effectiveDate: '2026-09-01' });
    const response = await user.put(`/savings-targets/${body.savingsTarget.id}`).send({ amountCents: 25000 });

    expect(response.body.savingsTarget).toMatchObject({ amountCents: 25000, effectiveDate: '2026-09-01' });
  });

  it('rejects future dates and invalid amounts', async () => {
    const future = await user.post('/savings-targets').send({ amountCents: 30000, effectiveDate: '2026-10-16' });
    expect(future.status).toBe(400);
    expect(future.body.error.code).toBe('date_in_future');

    expect((await user.post('/savings-targets').send({ amountCents: 0 })).status).toBe(400);
  });

  it('does not change the net worth', async () => {
    await user.post('/savings-targets').send({ amountCents: 30000 });

    expect(await netWorth(user)).toBe(0);
  });

  it('other users cannot touch a target', async () => {
    const { body } = await user.post('/savings-targets').send({ amountCents: 30000 });
    const other = await createUser();

    expect((await other.get('/savings-targets')).body.current).toBeNull();
    expect((await other.put(`/savings-targets/${body.savingsTarget.id}`).send({ amountCents: 1 })).status).toBe(404);
    expect((await other.delete(`/savings-targets/${body.savingsTarget.id}`)).status).toBe(404);
  });
});
