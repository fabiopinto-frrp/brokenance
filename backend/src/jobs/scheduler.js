import { deleteExpiredRefreshTokens } from '../services/auth.service.js';
import { applyDueRecurringForAllUsers } from '../services/recurring.service.js';

const HOUR_MS = 60 * 60 * 1000;

/**
 * Background housekeeping, run once at start and then every hour.
 *
 * The recurring engine already runs whenever the app reads data, so this is only a safety net:
 * income and subscription charges also land on time for days nobody opens the app.
 */
export async function runScheduledJobs(now = new Date()) {
  const users = await applyDueRecurringForAllUsers(now);
  const deletedTokens = await deleteExpiredRefreshTokens(now);
  return { users, deletedTokens };
}

/** Starts the jobs. Returns a function that stops them. */
export function startScheduler({ intervalMs = HOUR_MS } = {}) {
  const run = async () => {
    try {
      await runScheduledJobs();
    } catch (error) {
      console.error('Scheduled jobs failed:', error);
    }
  };

  run();
  const timer = setInterval(run, intervalMs);
  timer.unref();
  return () => clearInterval(timer);
}
