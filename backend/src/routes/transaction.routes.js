import { Router } from 'express';
import * as transactionController from '../controllers/transaction.controller.js';
import { requireAuth } from '../middleware/require-auth.js';
import { validateBody, validateParams, validateQuery } from '../middleware/validate.js';
import { idParams } from '../schemas/common.schemas.js';
import { listTransactionsQuery, transactionBodySchema } from '../schemas/transaction.schemas.js';

export const transactionRouter = Router();

transactionRouter.use(requireAuth);

transactionRouter.get('/', validateQuery(listTransactionsQuery), transactionController.list);
transactionRouter.post('/', validateBody(transactionBodySchema), transactionController.create);
transactionRouter.put(
  '/:id',
  validateParams(idParams),
  validateBody(transactionBodySchema),
  transactionController.update,
);
transactionRouter.delete('/:id', validateParams(idParams), transactionController.remove);
