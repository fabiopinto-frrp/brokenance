// Same .env loading as the API.
import './src/config/load-env.js';
import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    // Read directly (not with env()) so `prisma generate` also works without a database URL,
    // for example while building the Docker image.
    url: process.env.DATABASE_URL,
  },
});
