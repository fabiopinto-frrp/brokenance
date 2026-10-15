import '../../src/config/load-env.js';

// Tests use their own database on the same Postgres server, never the development one:
// DATABASE_URL (from .env) with `_test` added to the database name.
// Override with TEST_DATABASE_URL if needed. The database name must end with `_test`.
function testDatabaseUrl() {
  if (process.env.TEST_DATABASE_URL) return process.env.TEST_DATABASE_URL;
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is empty. Set it in .env to run the tests.');
  }
  const url = new URL(process.env.DATABASE_URL);
  url.pathname = `${url.pathname}_test`;
  return url.toString();
}

export const TEST_DATABASE_URL = testDatabaseUrl();
