import { Router } from 'express';
import * as subscriptionController from '../controllers/subscription.controller.js';
import { requireAuth } from '../middleware/require-auth.js';
import { validateBody, validateParams } from '../middleware/validate.js';
import { idParams } from '../schemas/common.schemas.js';
import { subscriptionBodySchema } from '../schemas/subscription.schemas.js';

export const subscriptionRouter = Router();

subscriptionRouter.use(requireAuth);

subscriptionRouter.get('/', subscriptionController.list);
subscriptionRouter.post('/', validateBody(subscriptionBodySchema), subscriptionController.create);
subscriptionRouter.put(
  '/:id',
  validateParams(idParams),
  validateBody(subscriptionBodySchema),
  subscriptionController.update,
);
subscriptionRouter.delete('/:id', validateParams(idParams), subscriptionController.remove);
