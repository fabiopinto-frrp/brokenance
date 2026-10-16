import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { config } from './config/index.js';
import { errorHandler, notFound } from './middleware/error-handler.js';
import { createRateLimiter } from './middleware/rate-limit.js';
import { createDocsRouter } from './routes/docs.routes.js';
import { routes } from './routes/index.js';

export function createApp() {
  const app = express();

  app.disable('x-powered-by');
  // Behind a reverse proxy, req.ip (used by the rate limits) comes from X-Forwarded-For.
  app.set('trust proxy', config.trustProxy);
  // This is an API consumed from other origins, so resources must not be restricted to same-origin.
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  // Registered before the rate limiter and routes so preflight (OPTIONS) requests are answered first.
  app.use(
    cors({
      origin: config.corsOrigin,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      maxAge: 600,
    }),
  );
  app.use(createRateLimiter({ limit: 600 }));
  app.use(express.json({ limit: '100kb' }));

  if (config.docsEnabled) {
    app.use(createDocsRouter());
  }
  app.use(routes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}
