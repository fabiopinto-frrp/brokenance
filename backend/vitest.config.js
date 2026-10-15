import { defineConfig } from 'vitest/config';
import { TEST_DATABASE_URL } from './test/setup/test-database.js';

export default defineConfig({
  test: {
    env: {
      NODE_ENV: 'test',
      DATABASE_URL: TEST_DATABASE_URL,
      JWT_ACCESS_SECRET: 'test-secret-test-secret-test-secret-123',
    },
    globalSetup: ['./test/setup/global-setup.js'],
    // Tests share one database, so test files run one after another.
    fileParallelism: false,
  },
});
