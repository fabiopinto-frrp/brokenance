import * as subscriptionService from '../services/subscription.service.js';
import { toSubscriptionListResponse, toSubscriptionResponse } from '../views/subscription.view.js';

export async function list(req, res) {
  res.json(toSubscriptionListResponse(await subscriptionService.list(req.userId)));
}

export async function create(req, res) {
  const subscription = await subscriptionService.create(req.userId, req.body);
  res.status(201).json(toSubscriptionResponse(subscription));
}

export async function update(req, res) {
  const subscription = await subscriptionService.update(req.userId, req.params.id, req.body);
  res.json(toSubscriptionResponse(subscription));
}

export async function remove(req, res) {
  await subscriptionService.remove(req.userId, req.params.id);
  res.status(204).end();
}
