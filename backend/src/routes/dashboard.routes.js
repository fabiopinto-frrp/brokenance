import { Router } from 'express';
import * as dashboardController from '../controllers/dashboard.controller.js';
import { requireAuth } from '../middleware/require-auth.js';
import { validateQuery } from '../middleware/validate.js';
import { dashboardQuery } from '../schemas/dashboard.schemas.js';

export const dashboardRouter = Router();

dashboardRouter.use(requireAuth);

dashboardRouter.get('/summary', validateQuery(dashboardQuery), dashboardController.summary);
