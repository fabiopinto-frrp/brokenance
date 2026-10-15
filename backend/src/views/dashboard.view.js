import { toGoal } from './goal.view.js';

export const toDashboardResponse = (summary) => ({
  ...summary,
  goals: { ...summary.goals, items: summary.goals.items.map(toGoal) },
});
