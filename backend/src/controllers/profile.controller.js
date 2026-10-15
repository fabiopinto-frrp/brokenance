import * as profileService from '../services/profile.service.js';
import { toProfileResponse } from '../views/profile.view.js';

export async function get(req, res) {
  res.json(toProfileResponse(await profileService.getProfile(req.userId)));
}

export async function update(req, res) {
  res.json(toProfileResponse(await profileService.updateProfile(req.userId, req.body)));
}

export async function setNetWorth(req, res) {
  const result = await profileService.setNetWorth(req.userId, req.body.netWorthCents);
  res.json(toProfileResponse(result));
}
