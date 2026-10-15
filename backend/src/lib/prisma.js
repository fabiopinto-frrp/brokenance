import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../../generated/prisma/client.ts';
import { config } from '../config/index.js';

// The client connects lazily, so importing this module does not require a running database.
const adapter = new PrismaPg({ connectionString: config.databaseUrl });

export const prisma = new PrismaClient({ adapter });

/**
 * Runs `fn(tx)` inside a database transaction. It commits if `fn` resolves and rolls back
 * if it throws. Use it for operations that must be atomic, like applying recurring income
 * and subscription charges.
 *
 * For row locks use `tx.$queryRaw`, for example:
 *   await tx.$queryRaw`SELECT user_id FROM profiles WHERE user_id = ${id}::uuid FOR UPDATE`;
 */
export const withTransaction = (fn, options) => prisma.$transaction(fn, options);
