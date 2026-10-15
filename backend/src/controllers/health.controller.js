import { prisma } from '../lib/prisma.js';

// Liveness: the process is up.
export function liveness(req, res) {
  res.json({ status: 'ok' });
}

// Readiness: the process is up and can reach the database.
export async function readiness(req, res) {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: 'ok', database: 'up' });
  } catch {
    res.status(503).json({ status: 'unavailable', database: 'down' });
  }
}
