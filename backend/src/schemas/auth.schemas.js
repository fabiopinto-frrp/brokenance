import { z } from 'zod';
import { personName } from './common.schemas.js';

// These schemas do two jobs: they validate incoming requests (via validateBody) and they
// generate the API documentation (see auth.docs.js). `.meta()` only adds documentation.

const username = z
  .string()
  .trim()
  .toLowerCase()
  .regex(/^[a-z0-9._-]{3,30}$/, 'Use 3 to 30 letters, digits, ".", "_" or "-"')
  .meta({
    description: '3 to 30 letters, digits, `.`, `_` or `-`. Not case-sensitive: it is stored in lowercase.',
    example: 'fabio',
  });


const newPassword = z.string().min(8).max(128).meta({
  description: 'Between 8 and 128 characters. It is hashed with argon2id and never stored as text.',
  example: 'correct horse battery',
});

// Only checks that something was sent: the length rules apply when a password is created, and
// a wrong password must give the same error whatever its length.
const existingPassword = z.string().min(1).max(128).meta({ example: 'correct horse battery' });

// ---------- Requests ----------

// "Confirm password" is checked by the app's form only, so the API receives the password once.
export const registerSchema = z
  .object({
    firstName: personName.meta({ example: 'Fábio' }),
    lastName: personName.meta({ example: 'Pinto' }),
    username,
    password: newPassword,
  })
  .meta({ id: 'RegisterRequest' });

export const loginSchema = z
  .object({
    username,
    password: existingPassword,
  })
  .meta({ id: 'LoginRequest' });

export const changePasswordSchema = z
  .object({
    currentPassword: existingPassword,
    newPassword,
  })
  .meta({ id: 'ChangePasswordRequest' });

export const refreshSchema = z
  .object({
    refreshToken: z.string().min(1).meta({
      description: 'The refresh token received at login or at the last refresh',
      example: 'pESdESfFXikdwAsDW_wtSCeQsgzbePiaYxmxugcDYboZcZ4fTH_X1Ms4rsJqu10n',
    }),
  })
  .meta({ id: 'RefreshRequest' });

// ---------- Responses ----------
// Responses are not validated at runtime. These schemas describe what views/auth.view.js sends,
// and test/auth.test.js checks real responses against them so they cannot drift.

export const userResponseSchema = z
  .object({
    id: z.uuid().meta({ example: '01a13202-60ac-743f-b715-0f63f97b5f7b' }),
    username: z.string().meta({ example: 'fabio' }),
    firstName: z.string().meta({ example: 'Fábio' }),
    lastName: z.string().meta({ example: 'Pinto' }),
  })
  .meta({ id: 'User', description: 'The logged-in user' });

export const tokensResponseSchema = z
  .object({
    accessToken: z.string().meta({
      description: 'Short-lived JWT (15 minutes). Send it as `Authorization: Bearer <accessToken>`.',
    }),
    accessTokenExpiresAt: z.iso.datetime().meta({ example: '2026-10-12T21:41:19.000Z' }),
    refreshToken: z.string().meta({
      description:
        'Long-lived token (30 days). Store it in secure storage. It can be used once: every refresh returns a new one.',
    }),
    refreshTokenExpiresAt: z.iso.datetime().meta({ example: '2026-11-11T21:26:19.056Z' }),
  })
  .meta({ id: 'Tokens' });

export const sessionResponseSchema = tokensResponseSchema
  .extend({ user: userResponseSchema })
  .meta({ id: 'Session', description: 'The user and a new pair of tokens' });

export const meResponseSchema = z.object({ user: userResponseSchema }).meta({ id: 'Me' });
