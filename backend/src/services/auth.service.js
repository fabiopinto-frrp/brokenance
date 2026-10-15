import { randomUUID } from 'node:crypto';
import { config } from '../config/index.js';
import { DEFAULT_TIME_ZONE, firstDayOf, monthOf, toDbDate, todayIn } from '../lib/dates.js';
import { prisma } from '../lib/prisma.js';
import { HttpError } from '../lib/http-error.js';
import { burnPasswordCheck, hashPassword, verifyPassword } from '../lib/password.js';
import { generateRefreshToken, hashToken, signAccessToken } from '../lib/tokens.js';

const DAY_MS = 24 * 60 * 60 * 1000;

const invalidCredentials = () =>
  new HttpError(401, 'invalid_credentials', 'Username or password is incorrect');

const invalidRefreshToken = () =>
  new HttpError(401, 'invalid_refresh_token', 'Refresh token is invalid, please log in again');


/**
 * Creates a new refresh token (and a matching access token) for the user.
 * Every login starts a new family, and each rotation keeps the same family.
 */
async function issueTokens(db, userId, familyId = randomUUID()) {
  const refreshToken = generateRefreshToken();
  const refreshExpiresAt = new Date(Date.now() + config.jwt.refreshTtlDays * DAY_MS);

  await db.refreshToken.create({
    data: { userId, familyId, tokenHash: hashToken(refreshToken), expiresAt: refreshExpiresAt },
  });

  const access = signAccessToken(userId);

  return {
    accessToken: access.token,
    accessTokenExpiresAt: access.expiresAt,
    refreshToken,
    refreshTokenExpiresAt: refreshExpiresAt,
  };
}

const revokeFamily = (familyId) =>
  prisma.refreshToken.updateMany({
    where: { familyId, revokedAt: null },
    data: { revokedAt: new Date() },
  });

export async function register({ username, password, firstName, lastName }) {
  if (!config.registrationEnabled) {
    throw new HttpError(403, 'registration_disabled', 'Registration is disabled');
  }

  const passwordHash = await hashPassword(password);

  let user;
  try {
    user = await prisma.user.create({
      data: {
        username,
        passwordHash,
        profile: {
          create: {
            firstName,
            lastName,
            timezone: DEFAULT_TIME_ZONE,
            // This month's income is already part of the net worth the user will type, so the
            // first automatic income is on the 1st of next month.
            lastIncomeAppliedMonth: toDbDate(firstDayOf(monthOf(todayIn(DEFAULT_TIME_ZONE)))),
          },
        },
      },
      include: { profile: true },
    });
  } catch (error) {
    if (error.code === 'P2002') {
      throw new HttpError(409, 'username_taken', 'This username is already taken');
    }
    throw error;
  }

  return { user, tokens: await issueTokens(prisma, user.id) };
}

export async function login({ username, password }) {
  const user = await prisma.user.findUnique({ where: { username }, include: { profile: true } });

  if (!user) {
    await burnPasswordCheck(password);
    throw invalidCredentials();
  }

  if (!(await verifyPassword(user.passwordHash, password))) {
    throw invalidCredentials();
  }

  return { user, tokens: await issueTokens(prisma, user.id) };
}

/**
 * Exchanges a refresh token for a new access token and a NEW refresh token (rotation).
 * The old refresh token stops working. If an old one is used again, someone may have copied
 * it, so the whole family is revoked and the user has to log in again.
 */
export async function refreshSession(refreshToken) {
  const stored = await prisma.refreshToken.findUnique({
    where: { tokenHash: hashToken(refreshToken) },
  });

  if (!stored) {
    throw invalidRefreshToken();
  }

  if (stored.revokedAt) {
    await revokeFamily(stored.familyId);
    throw invalidRefreshToken();
  }

  if (stored.expiresAt <= new Date()) {
    throw new HttpError(401, 'refresh_token_expired', 'Session expired, please log in again');
  }

  const tokens = await prisma.$transaction(async (tx) => {
    // Only one request can claim the token. A concurrent second request gets count 0.
    const claimed = await tx.refreshToken.updateMany({
      where: { id: stored.id, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    if (claimed.count !== 1) return null;
    return issueTokens(tx, stored.userId, stored.familyId);
  });

  if (!tokens) {
    await revokeFamily(stored.familyId);
    throw invalidRefreshToken();
  }

  return tokens;
}

/** Logs out this device by revoking the refresh token family. Always succeeds. */
export async function logout(refreshToken) {
  const stored = await prisma.refreshToken.findUnique({
    where: { tokenHash: hashToken(refreshToken) },
  });
  if (stored) {
    await revokeFamily(stored.familyId);
  }
}

/**
 * Changes the password. Every session of the user is revoked, so other devices (and anyone who
 * may know the old password) are logged out. This device gets a new pair of tokens.
 */
export async function changePassword(userId, { currentPassword, newPassword }) {
  const user = await getCurrentUser(userId);

  if (!(await verifyPassword(user.passwordHash, currentPassword))) {
    throw new HttpError(400, 'invalid_current_password', 'Current password is incorrect');
  }

  const passwordHash = await hashPassword(newPassword);

  return prisma.$transaction(async (tx) => {
    await tx.user.update({ where: { id: userId }, data: { passwordHash } });
    await tx.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return issueTokens(tx, userId);
  });
}

export async function getCurrentUser(userId) {
  const user = await prisma.user.findUnique({ where: { id: userId }, include: { profile: true } });
  if (!user) {
    throw new HttpError(401, 'unauthorized', 'User no longer exists');
  }
  return user;
}

/**
 * Deletes refresh tokens that have expired. They can no longer be used, and once expired a
 * reused token is rejected as unknown, so keeping them adds nothing.
 */
export async function deleteExpiredRefreshTokens(now = new Date()) {
  const { count } = await prisma.refreshToken.deleteMany({ where: { expiresAt: { lt: now } } });
  return count;
}
