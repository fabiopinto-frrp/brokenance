import { fromDbDate } from '../lib/dates.js';

export const toGoal = (goal) => ({
  id: goal.id,
  name: goal.name,
  targetCents: goal.targetCents,
  savedCents: goal.savedCents,
  remainingCents: goal.remainingCents,
  progressPercent: goal.progressPercent,
  completed: goal.completed,
  deadline: goal.deadline && fromDbDate(goal.deadline),
  estimatedMonthsLeft: goal.estimatedMonthsLeft,
  createdAt: goal.createdAt.toISOString(),
  updatedAt: goal.updatedAt.toISOString(),
});

export const toGoalResponse = (goal) => ({ goal: toGoal(goal) });

export const toGoalListResponse = (goals) => ({ items: goals.map(toGoal) });
