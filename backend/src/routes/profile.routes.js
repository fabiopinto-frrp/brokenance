import { Router } from 'express';
import * as profileController from '../controllers/profile.controller.js';
import { requireAuth } from '../middleware/require-auth.js';
import { validateBody } from '../middleware/validate.js';
import { setNetWorthSchema, updateProfileSchema } from '../schemas/profile.schemas.js';

export const profileRouter = Router();

profileRouter.use(requireAuth);

profileRouter.get('/', profileController.get);
profileRouter.put('/', validateBody(updateProfileSchema), profileController.update);
profileRouter.put('/net-worth', validateBody(setNetWorthSchema), profileController.setNetWorth);
