import { createApp } from './app.js';
import { config } from './config/index.js';
import { startScheduler } from './jobs/scheduler.js';
import { prisma } from './lib/prisma.js';

const app = createApp();

const server = app.listen(config.port, () => {
  console.log(`API listening on port ${config.port} (${config.env})`);
});

const stopScheduler = startScheduler();

async function shutdown(signal) {
  console.log(`${signal} received, shutting down`);
  stopScheduler();
  server.close(async () => {
    await prisma.$disconnect();
    process.exit(0);
  });
  // Force exit if connections do not close in time.
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
