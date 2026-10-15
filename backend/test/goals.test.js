import { afterAll, afterEach, beforeEach, describe, expect, it } from 'vitest';
import { prisma } from '../src/lib/prisma.js';
import { goalListResponseSchema, goalResponseSchema } from '../src/schemas/goal.schemas.js';
import { createUser, netWorth, resetDatabase, restoreNow, setNow } from './helpers.js';

let user;
const laptop = { name: 'New laptop', targetCents: 150000 };

beforeEach(async () => {
  await resetDatabase();
  setNow('2026-10-15T10:00:00Z');
  user = await createUser();
});

afterEach(restoreNow);

afterAll(async () => {
  await prisma.$disconnect();
});

describe('goals (Objetivos)', () => {
  it('creates a goal with its progress', async () => {
    const response = await user.post('/goals').send({ ...laptop, savedCents: 20000, deadline: '2027-06-01' });

    expect(response.status).toBe(201);
    expect(response.body.goal).toMatchObject({
      name: 'New laptop',
      targetCents: 150000,
      savedCents: 20000,
      remainingCents: 130000,
      progressPercent: 13,
      completed: false,
      deadline: '2027-06-01',
      estimatedMonthsLeft: null,
    });
    expect(goalResponseSchema.parse(response.body)).toEqual(response.body);
  });

  it('starts at 0 saved with no deadline', async () => {
    const response = await user.post('/goals').send(laptop);

    expect(response.body.goal).toMatchObject({ savedCents: 0, progressPercent: 0, deadline: null });
  });

  it('estimates the months left with the current savings target', async () => {
    await user.post('/savings-targets').send({ amountCents: 30000 });
    await user.post('/goals').send({ ...laptop, savedCents: 20000 });

    const response = await user.get('/goals');

    expect(response.body.items[0].estimatedMonthsLeft).toBe(5); // 130000 / 30000, rounded up
    expect(goalListResponseSchema.parse(response.body)).toEqual(response.body);
  });

  it('"+ add to goal" adds to the saved amount until it is completed', async () => {
    const { body } = await user.post('/goals').send({ ...laptop, savedCents: 140000 });
    const url = `/goals/${body.goal.id}/contributions`;

    const first = await user.post(url).send({ amountCents: 5000 });
    expect(first.body.goal).toMatchObject({ savedCents: 145000, completed: false });

    const second = await user.post(url).send({ amountCents: 20000 });
    expect(second.body.goal).toMatchObject({
      savedCents: 165000,
      remainingCents: 0,
      progressPercent: 110,
      completed: true,
      estimatedMonthsLeft: 0,
    });
  });

  it('counts simultaneous contributions', async () => {
    const { body } = await user.post('/goals').send(laptop);
    const url = `/goals/${body.goal.id}/contributions`;

    await Promise.all(Array.from({ length: 5 }, () => user.post(url).send({ amountCents: 1000 })));

    expect((await user.get('/goals')).body.items[0].savedCents).toBe(5000);
  });

  it('editing sets the exact saved amount', async () => {
    const { body } = await user.post('/goals').send({ ...laptop, savedCents: 20000 });
    const response = await user.put(`/goals/${body.goal.id}`).send({ ...laptop, savedCents: 5000 });

    expect(response.body.goal.savedCents).toBe(5000);
  });

  it('deletes a goal', async () => {
    const { body } = await user.post('/goals').send(laptop);

    expect((await user.delete(`/goals/${body.goal.id}`)).status).toBe(204);
    expect((await user.get('/goals')).body.items).toHaveLength(0);
  });

  it('never changes the net worth', async () => {
    const { body } = await user.post('/goals').send({ ...laptop, savedCents: 20000 });
    await user.post(`/goals/${body.goal.id}/contributions`).send({ amountCents: 5000 });

    expect(await netWorth(user)).toBe(0);
  });

  it('validates the body', async () => {
    const invalid = [{ ...laptop, targetCents: 0 }, { ...laptop, savedCents: -1 }, { name: 'No target' }];
    for (const body of invalid) {
      expect((await user.post('/goals').send(body)).status, JSON.stringify(body)).toBe(400);
    }
    const { body } = await user.post('/goals').send(laptop);
    expect((await user.post(`/goals/${body.goal.id}/contributions`).send({ amountCents: 0 })).status).toBe(400);
  });

  it('other users cannot touch a goal', async () => {
    const { body } = await user.post('/goals').send(laptop);
    const other = await createUser();

    expect((await other.get('/goals')).body.items).toHaveLength(0);
    expect((await other.put(`/goals/${body.goal.id}`).send(laptop)).status).toBe(404);
    expect((await other.post(`/goals/${body.goal.id}/contributions`).send({ amountCents: 1 })).status).toBe(404);
    expect((await other.delete(`/goals/${body.goal.id}`)).status).toBe(404);
  });
});
