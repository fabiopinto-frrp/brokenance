import { Router } from 'express';
import { authRouter } from './auth.routes.js';
import { dashboardRouter } from './dashboard.routes.js';
import { goalRouter } from './goal.routes.js';
import { healthRouter } from './health.routes.js';
import { profileRouter } from './profile.routes.js';
import { savingsTargetRouter } from './savings-target.routes.js';
import { subscriptionRouter } from './subscription.routes.js';
import { transactionRouter } from './transaction.routes.js';

export const routes = Router();

routes.use('/health', healthRouter);
routes.use('/auth', authRouter);

// Every router except health and auth protects its routes with `requireAuth`.
routes.use('/profile', profileRouter);
routes.use('/transactions', transactionRouter);
routes.use('/subscriptions', subscriptionRouter);
routes.use('/savings-targets', savingsTargetRouter);
routes.use('/goals', goalRouter);
routes.use('/dashboard', dashboardRouter);
