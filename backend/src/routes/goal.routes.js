import { Router } from 'express';
import * as goalController from '../controllers/goal.controller.js';
import { requireAuth } from '../middleware/require-auth.js';
import { validateBody, validateParams } from '../middleware/validate.js';
import { idParams } from '../schemas/common.schemas.js';
import { contributionBodySchema, goalBodySchema } from '../schemas/goal.schemas.js';

export const goalRouter = Router();

goalRouter.use(requireAuth);

goalRouter.get('/', goalController.list);
goalRouter.post('/', validateBody(goalBodySchema), goalController.create);
goalRouter.put('/:id', validateParams(idParams), validateBody(goalBodySchema), goalController.update);
goalRouter.post(
  '/:id/contributions',
  validateParams(idParams),
  validateBody(contributionBodySchema),
  goalController.addContribution,
);
goalRouter.delete('/:id', validateParams(idParams), goalController.remove);
