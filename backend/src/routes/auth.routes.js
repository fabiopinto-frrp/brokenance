import { Router } from 'express';
import { createRateLimiter } from '../middleware/rate-limit.js';
import { validateBody } from '../middleware/validate.js';
import * as authController from '../controllers/auth.controller.js';
import { changePasswordSchema, loginSchema, refreshSchema, registerSchema } from '../schemas/auth.schemas.js';
import { requireAuth } from '../middleware/require-auth.js';

export const authRouter = Router();

// Stricter limit for the endpoints that can be used to guess passwords.
const credentialsLimiter = createRateLimiter({ limit: 10 });

// Routes only wire URL -> middleware -> controller. The documentation of each endpoint is in
// docs/auth.docs.js.
authRouter.post('/register', credentialsLimiter, validateBody(registerSchema), authController.register);
authRouter.post('/login', credentialsLimiter, validateBody(loginSchema), authController.login);
authRouter.post('/refresh', validateBody(refreshSchema), authController.refresh);
authRouter.post('/logout', validateBody(refreshSchema), authController.logout);
authRouter.get('/me', requireAuth, authController.me);
authRouter.put(
  '/password',
  requireAuth,
  credentialsLimiter,
  validateBody(changePasswordSchema),
  authController.changePassword,
);
