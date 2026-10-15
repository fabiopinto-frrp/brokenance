import { toDbDate } from '../lib/dates.js';
import { HttpError } from '../lib/http-error.js';
import { prisma } from '../lib/prisma.js';
import { MAX_AMOUNT_CENTS } from '../schemas/common.schemas.js';
import { getCurrentTarget } from './savings-target.service.js';

// Objetivos: save `target` to buy something. The saved amount is updated by hand and never
// changes the net worth.

/** Adds the numbers the app shows next to each goal. */
function withProgress(goal, monthlySavingsCents) {
  const remainingCents = Math.max(goal.targetCents - goal.savedCents, 0);
  let estimatedMonthsLeft = null;
  if (remainingCents === 0) estimatedMonthsLeft = 0;
  else if (monthlySavingsCents) estimatedMonthsLeft = Math.ceil(remainingCents / monthlySavingsCents);

  return {
    ...goal,
    remainingCents,
    progressPercent: Math.floor((goal.savedCents * 100) / goal.targetCents),
    completed: remainingCents === 0,
    estimatedMonthsLeft,
  };
}

async function monthlySavings(userId) {
  return (await getCurrentTarget(prisma, userId))?.amountCents ?? null;
}

const toData = ({ deadline, ...body }) => ({ ...body, deadline: deadline ? toDbDate(deadline) : null });

async function findOwned(userId, id) {
  const goal = await prisma.goal.findFirst({ where: { id, userId } });
  if (!goal) {
    throw new HttpError(404, 'goal_not_found', 'Goal not found');
  }
  return goal;
}

export async function list(userId) {
  const [goals, savings] = await Promise.all([
    prisma.goal.findMany({ where: { userId }, orderBy: { createdAt: 'asc' } }),
    monthlySavings(userId),
  ]);
  return goals.map((goal) => withProgress(goal, savings));
}

export async function create(userId, body) {
  const goal = await prisma.goal.create({ data: { userId, ...toData(body) } });
  return withProgress(goal, await monthlySavings(userId));
}

export async function update(userId, id, body) {
  await findOwned(userId, id);
  const goal = await prisma.goal.update({ where: { id }, data: toData(body) });
  return withProgress(goal, await monthlySavings(userId));
}

/** The quick "+ add to goal" action. */
export async function addContribution(userId, id, amountCents) {
  const existing = await findOwned(userId, id);
  if (existing.savedCents + amountCents > MAX_AMOUNT_CENTS) {
    throw new HttpError(400, 'amount_too_large', 'The saved amount would be too large');
  }
  // Increment in the database, so two quick taps both count.
  const goal = await prisma.goal.update({ where: { id }, data: { savedCents: { increment: amountCents } } });
  return withProgress(goal, await monthlySavings(userId));
}

export async function remove(userId, id) {
  await findOwned(userId, id);
  await prisma.goal.delete({ where: { id } });
}
