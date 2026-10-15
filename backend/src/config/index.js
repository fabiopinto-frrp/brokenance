import { z } from 'zod';
import './load-env.js';

const booleanFromString = z.enum(['true', 'false']).transform((value) => value === 'true');

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is empty. Set it in .env (see .env.example)'),
  CORS_ORIGIN: z.string().default('*'),
  JWT_ACCESS_SECRET: z
    .string()
    .min(32, 'JWT_ACCESS_SECRET must be at least 32 characters. Set it in .env (see .env.example)'),
  ACCESS_TOKEN_TTL: z.string().default('15m'),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(30),
  REGISTRATION_ENABLED: booleanFromString.default('true'),
  DOCS_ENABLED: booleanFromString.default('true'),
});

const parsed = schema.safeParse(process.env);

if (!parsed.success) {
  const problems = parsed.error.issues
    .map((issue) => `  - ${issue.path.join('.')}: ${issue.message}`)
    .join('\n');
  throw new Error(`Invalid environment configuration:\n${problems}`);
}

const env = parsed.data;

export const config = {
  env: env.NODE_ENV,
  isProduction: env.NODE_ENV === 'production',
  port: env.PORT,
  databaseUrl: env.DATABASE_URL,
  // '*' allows any origin (development). Otherwise a comma-separated list of exact origins.
  corsOrigin:
    env.CORS_ORIGIN.trim() === '*'
      ? '*'
      : env.CORS_ORIGIN.split(',')
          .map((origin) => origin.trim())
          .filter(Boolean),
  jwt: {
    accessSecret: env.JWT_ACCESS_SECRET,
    accessTtl: env.ACCESS_TOKEN_TTL,
    refreshTtlDays: env.REFRESH_TOKEN_TTL_DAYS,
  },
  registrationEnabled: env.REGISTRATION_ENABLED,
  docsEnabled: env.DOCS_ENABLED,
};
