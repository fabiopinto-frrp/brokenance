import jwt from 'jsonwebtoken';
import request from 'supertest';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { config } from '../src/config/index.js';
import { prisma } from '../src/lib/prisma.js';
import {
  meResponseSchema,
  sessionResponseSchema,
  tokensResponseSchema,
} from '../src/schemas/auth.schemas.js';
import { errorSchema } from '../src/docs/responses.js';

const app = createApp();

const credentials = {
  firstName: 'Fábio',
  lastName: 'Pinto',
  username: 'fabio',
  password: 'correct horse battery',
};
const expectedUser = { username: 'fabio', firstName: 'Fábio', lastName: 'Pinto' };

const register = (body = credentials) => request(app).post('/auth/register').send(body);
const login = (body = credentials) => request(app).post('/auth/login').send(body);
const changePassword = (accessToken, body) =>
  request(app).put('/auth/password').set('Authorization', `Bearer ${accessToken}`).send(body);
const refresh = (refreshToken) => request(app).post('/auth/refresh').send({ refreshToken });
const me = (accessToken) =>
  request(app).get('/auth/me').set('Authorization', `Bearer ${accessToken}`);

beforeEach(async () => {
  config.registrationEnabled = true;
  await prisma.$executeRawUnsafe('TRUNCATE TABLE users CASCADE');
});

afterAll(async () => {
  await prisma.$disconnect();
});

describe('POST /auth/register', () => {
  it('creates the account and returns tokens', async () => {
    const response = await register();

    expect(response.status).toBe(201);
    expect(response.body.user).toMatchObject(expectedUser);
    expect(response.body.accessToken).toEqual(expect.any(String));
    expect(response.body.refreshToken).toEqual(expect.any(String));
    expect(response.body.user.passwordHash).toBeUndefined();
  });

  it('stores an argon2id hash, never the password', async () => {
    await register();

    const user = await prisma.user.findUnique({ where: { username: 'fabio' } });
    expect(user.passwordHash).toMatch(/^\$argon2id\$/);
    expect(user.passwordHash).not.toContain(credentials.password);
  });

  it('stores only a hash of the refresh token', async () => {
    const { body } = await register();

    const tokens = await prisma.refreshToken.findMany();
    expect(tokens).toHaveLength(1);
    expect(tokens[0].tokenHash).not.toBe(body.refreshToken);
  });

  it('creates the profile with the first and last name, accents included', async () => {
    await register({ ...credentials, firstName: '  Conceição ', lastName: 'Gonçalves' });

    const profile = await prisma.profile.findFirst();
    expect(profile).toMatchObject({ firstName: 'Conceição', lastName: 'Gonçalves' });
  });

  it('normalises the username to lowercase', async () => {
    const response = await register({ ...credentials, username: '  Fabio.Pinto_1 ' });

    expect(response.status).toBe(201);
    expect(response.body.user.username).toBe('fabio.pinto_1');
  });

  it('rejects a taken username with 409, whatever the case', async () => {
    await register();
    const response = await register({ ...credentials, username: 'FABIO' });

    expect(response.status).toBe(409);
    expect(response.body.error.code).toBe('username_taken');
  });

  it('does not store or require an email', async () => {
    const response = await register({ ...credentials, email: 'fabio@example.com' });

    expect(response.status).toBe(201);
    expect(response.body.user.email).toBeUndefined();
  });

  it('validates the body', async () => {
    const { firstName, lastName, ...withoutNames } = credentials;
    const invalidBodies = [
      { ...credentials, password: 'short' },
      { ...credentials, password: 'x'.repeat(129) },
      { ...credentials, username: 'ab' },
      { ...credentials, username: 'x'.repeat(31) },
      { ...credentials, username: 'fabio pinto' },
      { ...credentials, username: 'fabio@example.com' },
      { ...credentials, firstName: '   ' },
      { ...credentials, lastName: 'x'.repeat(51) },
      withoutNames,
      { ...withoutNames, firstName },
      { ...withoutNames, lastName },
    ];

    for (const body of invalidBodies) {
      const response = await register(body);
      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('validation_error');
    }
  });

  it('can be disabled', async () => {
    config.registrationEnabled = false;
    const response = await register();

    expect(response.status).toBe(403);
    expect(response.body.error.code).toBe('registration_disabled');
  });
});

describe('POST /auth/login', () => {
  it('returns tokens for the right credentials', async () => {
    await register();
    const response = await login();

    expect(response.status).toBe(200);
    expect(response.body.user).toEqual({ id: expect.any(String), ...expectedUser });
    expect(response.body.accessToken).toEqual(expect.any(String));
    expect(response.body.refreshToken).toEqual(expect.any(String));
  });

  it('accepts the username in any case', async () => {
    await register();
    const response = await login({ username: ' FaBiO ', password: credentials.password });

    expect(response.status).toBe(200);
  });

  it('rejects a wrong password and an unknown username with the same error', async () => {
    await register();
    const wrongPassword = await login({ ...credentials, password: 'wrong password!' });
    const unknownUsername = await login({ ...credentials, username: 'nobody' });

    expect(wrongPassword.status).toBe(401);
    expect(unknownUsername.status).toBe(401);
    expect(wrongPassword.body).toEqual(unknownUsername.body);
    expect(wrongPassword.body.error.code).toBe('invalid_credentials');
  });
});

describe('GET /auth/me and requireAuth', () => {
  it('returns the current user for a valid access token', async () => {
    const { body } = await register();
    const response = await me(body.accessToken);

    expect(response.status).toBe(200);
    expect(response.body.user).toMatchObject(expectedUser);
  });

  it('rejects a missing token', async () => {
    const response = await request(app).get('/auth/me');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('unauthorized');
  });

  it('rejects a tampered token', async () => {
    const { body } = await register();
    const response = await me(`${body.accessToken}x`);

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('invalid_token');
  });

  it('rejects a token signed with another secret', async () => {
    const { body } = await register();
    const forged = jwt.sign({}, 'another-secret-another-secret-123456', {
      subject: body.user.id,
      issuer: 'brokenance',
      expiresIn: '15m',
    });
    const response = await me(forged);

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('invalid_token');
  });

  it('tells the app when the access token has expired', async () => {
    const { body } = await register();
    const expired = jwt.sign({}, config.jwt.accessSecret, {
      subject: body.user.id,
      issuer: 'brokenance',
      expiresIn: -10,
    });
    const response = await me(expired);

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('token_expired');
  });
});

describe('POST /auth/refresh (staying logged in)', () => {
  it('gives a new access token and a new refresh token', async () => {
    const { body: session } = await register();
    const response = await refresh(session.refreshToken);

    expect(response.status).toBe(200);
    expect(response.body.refreshToken).not.toBe(session.refreshToken);
    expect((await me(response.body.accessToken)).status).toBe(200);
  });

  it('keeps the user logged in across app restarts', async () => {
    // The app only keeps the refresh token. After a restart it uses it to get a session.
    const { body: firstSession } = await login(await registerAndReturnCredentials());
    const afterRestart = await refresh(firstSession.refreshToken);
    const afterSecondRestart = await refresh(afterRestart.body.refreshToken);

    expect(afterRestart.status).toBe(200);
    expect(afterSecondRestart.status).toBe(200);
    expect((await me(afterSecondRestart.body.accessToken)).status).toBe(200);
  });

  it('extends the expiry on every refresh (sliding session)', async () => {
    const { body: session } = await register();
    await prisma.refreshToken.updateMany({
      data: { expiresAt: new Date(Date.now() + 60 * 1000) },
    });

    const response = await refresh(session.refreshToken);

    const daysLeft = (new Date(response.body.refreshTokenExpiresAt) - Date.now()) / 86_400_000;
    expect(daysLeft).toBeGreaterThan(config.jwt.refreshTtlDays - 1);
  });

  it('rejects an unknown token', async () => {
    const response = await refresh('not-a-real-token');

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('invalid_refresh_token');
  });

  it('rejects an expired refresh token, so the app must log in again', async () => {
    const { body: session } = await register();
    await prisma.refreshToken.updateMany({ data: { expiresAt: new Date(Date.now() - 1000) } });

    const response = await refresh(session.refreshToken);

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe('refresh_token_expired');
  });

  it('revokes the whole family when an old token is reused', async () => {
    const { body: session } = await register();
    const rotated = await refresh(session.refreshToken);

    const reuse = await refresh(session.refreshToken);
    const newestToken = await refresh(rotated.body.refreshToken);

    expect(reuse.status).toBe(401);
    expect(newestToken.status).toBe(401);
  });

  it('does not affect other devices when one is revoked', async () => {
    await register();
    const phone = await login();
    const tablet = await login();

    await refresh(phone.body.refreshToken);
    await refresh(phone.body.refreshToken); // reuse on the phone

    expect((await refresh(tablet.body.refreshToken)).status).toBe(200);
  });

  it('lets only one of two simultaneous refreshes succeed', async () => {
    const { body: session } = await register();

    const [a, b] = await Promise.all([
      refresh(session.refreshToken),
      refresh(session.refreshToken),
    ]);

    expect([a.status, b.status].sort()).toEqual([200, 401]);
  });

  it('validates the body', async () => {
    const response = await request(app).post('/auth/refresh').send({});

    expect(response.status).toBe(400);
  });
});

describe('POST /auth/logout', () => {
  it('revokes the refresh token', async () => {
    const { body: session } = await register();

    const logout = await request(app)
      .post('/auth/logout')
      .send({ refreshToken: session.refreshToken });
    const afterLogout = await refresh(session.refreshToken);

    expect(logout.status).toBe(204);
    expect(afterLogout.status).toBe(401);
  });

  it('succeeds even if the token is unknown', async () => {
    const response = await request(app).post('/auth/logout').send({ refreshToken: 'whatever' });

    expect(response.status).toBe(204);
  });
});

describe('PUT /auth/password', () => {
  const newPassword = 'a brand new passphrase';

  it('changes the password', async () => {
    const { body: session } = await register();
    const response = await changePassword(session.accessToken, {
      currentPassword: credentials.password,
      newPassword,
    });

    expect(response.status).toBe(200);
    expect((await login()).status).toBe(401);
    expect((await login({ ...credentials, password: newPassword })).status).toBe(200);
  });

  it('logs out every other session and gives this device new tokens', async () => {
    const { body: thisDevice } = await register();
    const { body: otherDevice } = await login();

    const response = await changePassword(thisDevice.accessToken, {
      currentPassword: credentials.password,
      newPassword,
    });

    expect((await refresh(otherDevice.refreshToken)).status).toBe(401);
    expect((await refresh(thisDevice.refreshToken)).status).toBe(401);
    expect((await refresh(response.body.refreshToken)).status).toBe(200);
  });

  it('rejects a wrong current password and keeps the old one', async () => {
    const { body: session } = await register();
    const response = await changePassword(session.accessToken, {
      currentPassword: 'wrong password!',
      newPassword,
    });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('invalid_current_password');
    expect((await login()).status).toBe(200);
    expect((await refresh(session.refreshToken)).status).toBe(200);
  });

  it('applies the password rules to the new password', async () => {
    const { body: session } = await register();
    const response = await changePassword(session.accessToken, {
      currentPassword: credentials.password,
      newPassword: 'short',
    });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('validation_error');
  });

  it('requires an access token', async () => {
    const response = await request(app)
      .put('/auth/password')
      .send({ currentPassword: credentials.password, newPassword });

    expect(response.status).toBe(401);
  });
});

// The API documentation (/docs) is generated from the zod schemas. These tests check that real
// responses match them, so the documentation cannot silently drift from what the API sends.
describe('responses match the documented schemas', () => {
  // parse() throws on a missing or wrong field and drops unknown ones, so comparing the result
  // with the body also catches fields that are sent but not documented.
  const expectShape = (schema, body) => expect(schema.parse(body)).toEqual(body);

  it('register and login return a Session', async () => {
    const registered = await register();
    const loggedIn = await login();

    expectShape(sessionResponseSchema, registered.body);
    expectShape(sessionResponseSchema, loggedIn.body);
  });

  it('refresh returns Tokens', async () => {
    const { body: session } = await register();
    const response = await refresh(session.refreshToken);

    expectShape(tokensResponseSchema, response.body);
  });

  it('change password returns Tokens', async () => {
    const { body: session } = await register();
    const response = await changePassword(session.accessToken, {
      currentPassword: credentials.password,
      newPassword: 'a brand new passphrase',
    });

    expectShape(tokensResponseSchema, response.body);
  });

  it('me returns Me', async () => {
    const { body: session } = await register();
    const response = await me(session.accessToken);

    expectShape(meResponseSchema, response.body);
  });

  it('errors return Error', async () => {
    const response = await login({ ...credentials, password: 'wrong password!' });

    expectShape(errorSchema, response.body);
  });
});

async function registerAndReturnCredentials() {
  await register();
  return credentials;
}
