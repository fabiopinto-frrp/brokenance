import * as goalService from '../services/goal.service.js';
import { toGoalListResponse, toGoalResponse } from '../views/goal.view.js';

export async function list(req, res) {
  res.json(toGoalListResponse(await goalService.list(req.userId)));
}

export async function create(req, res) {
  res.status(201).json(toGoalResponse(await goalService.create(req.userId, req.body)));
}

export async function update(req, res) {
  res.json(toGoalResponse(await goalService.update(req.userId, req.params.id, req.body)));
}

export async function addContribution(req, res) {
  const goal = await goalService.addContribution(req.userId, req.params.id, req.body.amountCents);
  res.json(toGoalResponse(goal));
}

export async function remove(req, res) {
  await goalService.remove(req.userId, req.params.id);
  res.status(204).end();
}
