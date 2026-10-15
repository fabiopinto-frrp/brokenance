import { Router } from 'express';
import * as savingsTargetController from '../controllers/savings-target.controller.js';
import { requireAuth } from '../middleware/require-auth.js';
import { validateBody, validateParams } from '../middleware/validate.js';
import { idParams } from '../schemas/common.schemas.js';
import { savingsTargetBodySchema } from '../schemas/savings-target.schemas.js';

export const savingsTargetRouter = Router();

savingsTargetRouter.use(requireAuth);

savingsTargetRouter.get('/', savingsTargetController.list);
savingsTargetRouter.post('/', validateBody(savingsTargetBodySchema), savingsTargetController.create);
savingsTargetRouter.put(
  '/:id',
  validateParams(idParams),
  validateBody(savingsTargetBodySchema),
  savingsTargetController.update,
);
savingsTargetRouter.delete('/:id', validateParams(idParams), savingsTargetController.remove);
