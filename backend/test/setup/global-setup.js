import { execFileSync } from 'node:child_process';
import pg from 'pg';
import { TEST_DATABASE_URL } from './test-database.js';

// Runs once before all tests: creates the test database if needed and applies the migrations.
export default async function setup() {
  const url = new URL(TEST_DATABASE_URL);
  const dbName = url.pathname.slice(1);

  if (!dbName.endsWith('_test')) {
    throw new Error(`Refusing to run tests on database "${dbName}": its name must end with _test`);
  }

  const adminUrl = new URL(TEST_DATABASE_URL);
  adminUrl.pathname = '/postgres';
  const client = new pg.Client({ connectionString: adminUrl.toString() });

  try {
    await client.connect();
  } catch (error) {
    throw new Error(
      `Cannot connect to Postgres for the tests (${error.message}).\n` +
        'Start the database first: docker compose up -d db',
    );
  }

  const { rowCount } = await client.query('SELECT 1 FROM pg_database WHERE datname = $1', [dbName]);
  if (!rowCount) {
    await client.query(`CREATE DATABASE "${dbName}"`);
  }
  await client.end();

  execFileSync('node', ['node_modules/prisma/build/index.js', 'migrate', 'deploy'], {
    env: { ...process.env, DATABASE_URL: TEST_DATABASE_URL },
    stdio: 'pipe',
  });
}
