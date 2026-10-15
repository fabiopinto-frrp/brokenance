import * as savingsTargetService from '../services/savings-target.service.js';
import { toSavingsTargetListResponse, toSavingsTargetResponse } from '../views/savings-target.view.js';

export async function list(req, res) {
  res.json(toSavingsTargetListResponse(await savingsTargetService.list(req.userId)));
}

export async function create(req, res) {
  const target = await savingsTargetService.create(req.userId, req.body);
  res.status(201).json(toSavingsTargetResponse(target));
}

export async function update(req, res) {
  const target = await savingsTargetService.update(req.userId, req.params.id, req.body);
  res.json(toSavingsTargetResponse(target));
}

export async function remove(req, res) {
  await savingsTargetService.remove(req.userId, req.params.id);
  res.status(204).end();
}
