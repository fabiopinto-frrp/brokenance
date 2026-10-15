import { toSessionResponse, toTokensResponse, toUserResponse } from '../views/auth.view.js';
import * as authService from '../services/auth.service.js';

// Controllers are the HTTP layer: they read the (already validated) request, call the service,
// and send the response. Business rules belong in the service, not here.

export async function register(req, res) {
  const result = await authService.register(req.body);
  res.status(201).json(toSessionResponse(result));
}

export async function login(req, res) {
  const result = await authService.login(req.body);
  res.json(toSessionResponse(result));
}

export async function refresh(req, res) {
  const tokens = await authService.refreshSession(req.body.refreshToken);
  res.json(toTokensResponse(tokens));
}

export async function logout(req, res) {
  await authService.logout(req.body.refreshToken);
  res.status(204).end();
}

export async function changePassword(req, res) {
  const tokens = await authService.changePassword(req.userId, req.body);
  res.json(toTokensResponse(tokens));
}

export async function me(req, res) {
  const user = await authService.getCurrentUser(req.userId);
  res.json({ user: toUserResponse(user) });
}
