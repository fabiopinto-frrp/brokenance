import { execFileSync } from 'node:child_process';
import request from 'supertest';
import { afterAll, afterEach, beforeEach, describe, expect, it } from 'vitest';
import { runScheduledJobs } from '../src/jobs/scheduler.js';
import { prisma } from '../src/lib/prisma.js';
import { verifyPassword } from '../src/lib/password.js';
import { app, createUser, resetDatabase, restoreNow, setNow } from './helpers.js';

beforeEach(resetDatabase);

afterEach(restoreNow);

afterAll(async () => {
  await prisma.$disconnect();
});

describe('scheduled jobs', () => {
  it('applies due income for every user, even if nobody opens the app', async () => {
    setNow('2026-10-15T10:00:00Z');
    const first = await createUser();
    const second = await createUser();
    await first.put('/profile').send({ monthlyIncomeCents: 90000 });
    await second.put('/profile').send({ monthlyIncomeCents: 120000 });

    const now = new Date('2026-11-01T06:00:00Z');
    const result = await runScheduledJobs(now);

    expect(result.users).toBe(2);
    const rows = await prisma.transaction.findMany({ where: { type: 'INCOME' }, orderBy: { amountCents: 'asc' } });
    expect(rows.map((row) => row.amountCents)).toEqual([90000, 120000]);
  });

  it('deletes expired refresh tokens and keeps the valid ones', async () => {
    setNow('2026-10-15T10:00:00Z');
    await createUser();
    await prisma.refreshToken.create({
      data: {
        userId: (await prisma.user.findFirst()).id,
        familyId: '01a1322a-ff14-76e9-83c0-3174db7dac15',
        tokenHash: 'expired',
        expiresAt: new Date('2026-10-01T00:00:00Z'),
      },
    });

    const result = await runScheduledJobs(new Date());

    expect(result.deletedTokens).toBe(1);
    expect(await prisma.refreshToken.count()).toBe(1);
  });
});

describe('npm run user:reset-password', () => {
  const runScript = (...args) =>
    execFileSync('node', ['scripts/reset-password.js', ...args], {
      env: { ...process.env },
      encoding: 'utf8',
      stdio: 'pipe',
    });

  it('sets a new random password and logs the user out everywhere', async () => {
    const response = await request(app)
      .post('/auth/register')
      .send({ firstName: 'Fábio', lastName: 'Pinto', username: 'fabio', password: 'correct horse battery' });

    const output = runScript('FABIO');
    const password = output.match(/New password: (\S+)/)[1];

    const user = await prisma.user.findUnique({ where: { username: 'fabio' } });
    expect(await verifyPassword(user.passwordHash, password)).toBe(true);
    expect(await verifyPassword(user.passwordHash, 'correct horse battery')).toBe(false);
    const refresh = await request(app).post('/auth/refresh').send({ refreshToken: response.body.refreshToken });
    expect(refresh.status).toBe(401);
  });

  it('fails for an unknown user', () => {
    expect(() => runScript('nobody')).toThrow(/No user called "nobody"/);
  });
});
