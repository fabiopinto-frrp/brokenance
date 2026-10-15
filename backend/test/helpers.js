import request from 'supertest';
import { vi } from 'vitest';
import { createApp } from '../src/app.js';
import { signAccessToken } from '../src/lib/tokens.js';
import { prisma } from '../src/lib/prisma.js';

// Shared helpers for the feature tests.

export const app = createApp();

export const resetDatabase = () => prisma.$executeRawUnsafe('TRUNCATE TABLE users CASCADE');

/**
 * Freezes "now" at the given instant. Only `Date` is faked, so timers, the database driver and
 * argon2 keep working. Remember: Lisbon is UTC+1 in summer and UTC+0 in winter.
 */
export function setNow(isoInstant) {
  vi.useFakeTimers({ toFake: ['Date'] });
  vi.setSystemTime(new Date(isoInstant));
}

export const restoreNow = () => vi.useRealTimers();

let userCount = 0;

/** Registers a user through the API and returns a client that is logged in as that user. */
export async function createUser() {
  userCount += 1;
  const response = await request(app)
    .post('/auth/register')
    .send({ firstName: 'Test', lastName: 'User', username: `user${userCount}`, password: 'correct horse battery' });
  return asUser(response.body.user.id);
}

/**
 * A logged-in client. A fresh access token is signed for every request, so tests can move the
 * clock months ahead without the 15-minute token expiring.
 */
export function asUser(userId) {
  const send = (method) => (url) =>
    request(app)[method](url).set('Authorization', `Bearer ${signAccessToken(userId).token}`);
  return { userId, get: send('get'), post: send('post'), put: send('put'), delete: send('delete') };
}

/** Shortcuts for readable assertions. */
export const netWorth = async (user) => (await user.get('/profile')).body.profile.netWorthCents;

export const transactions = async (user, query = '') => (await user.get(`/transactions${query}`)).body.items;
