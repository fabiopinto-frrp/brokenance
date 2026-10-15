import { Router } from 'express';
import helmet from 'helmet';
import swaggerUi from 'swagger-ui-express';
import { buildOpenApiDocument } from '../docs/openapi.js';

/**
 * Serves the API documentation:
 *   GET /docs          interactive Swagger UI
 *   GET /openapi.json  the raw OpenAPI 3.1 document (for Postman, code generators, ...)
 */
export function createDocsRouter() {
  const document = buildOpenApiDocument();
  const router = Router();

  router.get('/openapi.json', (req, res) => {
    res.json(document);
  });

  router.use(
    '/docs',
    // The default `upgrade-insecure-requests` rule makes browsers load the UI's files over
    // https, which does not exist on a local http server. The other rules stay as they are.
    helmet.contentSecurityPolicy({
      useDefaults: true,
      directives: { 'upgrade-insecure-requests': null },
    }),
    swaggerUi.serve,
    swaggerUi.setup(document, {
      customSiteTitle: 'Brokenance API',
      swaggerOptions: { persistAuthorization: true, displayRequestDuration: true },
    }),
  );

  return router;
}
