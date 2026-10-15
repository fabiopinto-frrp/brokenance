import * as dashboardService from '../services/dashboard.service.js';
import { toDashboardResponse } from '../views/dashboard.view.js';

export async function summary(req, res) {
  res.json(toDashboardResponse(await dashboardService.getSummary(req.userId, req.query)));
}
