import request from 'supertest';
import { afterAll, afterEach, describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { config } from '../src/config/index.js';
import { prisma } from '../src/lib/prisma.js';

const app = createApp();

afterEach(() => {
  config.docsEnabled = true;
});

afterAll(async () => {
  await prisma.$disconnect();
});

const documentedEndpoints = (document) =>
  Object.entries(document.paths).flatMap(([path, methods]) =>
    Object.keys(methods).map((method) => ({ method, path })),
  );

describe('GET /openapi.json', () => {
  it('returns an OpenAPI 3.1 document', async () => {
    const response = await request(app).get('/openapi.json');

    expect(response.status).toBe(200);
    expect(response.body.openapi).toBe('3.1.0');
    expect(response.body.info.title).toBe('Brokenance API');
  });

  it('documents every endpoint of the API', async () => {
    const { body } = await request(app).get('/openapi.json');

    const documented = documentedEndpoints(body).map(({ method, path }) => `${method.toUpperCase()} ${path}`);

    // When you add an endpoint, add it here and document it in its module's *.docs.js.
    expect(documented.sort()).toEqual(
      [
        'GET /health',
        'GET /health/ready',
        'POST /auth/register',
        'POST /auth/login',
        'POST /auth/refresh',
        'POST /auth/logout',
        'GET /auth/me',
        'PUT /auth/password',
        'GET /profile',
        'PUT /profile',
        'PUT /profile/net-worth',
        'GET /transactions',
        'POST /transactions',
        'PUT /transactions/{id}',
        'DELETE /transactions/{id}',
        'GET /subscriptions',
        'POST /subscriptions',
        'PUT /subscriptions/{id}',
        'DELETE /subscriptions/{id}',
        'GET /savings-targets',
        'POST /savings-targets',
        'PUT /savings-targets/{id}',
        'DELETE /savings-targets/{id}',
        'GET /goals',
        'POST /goals',
        'PUT /goals/{id}',
        'DELETE /goals/{id}',
        'POST /goals/{id}/contributions',
        'GET /dashboard/summary',
      ].sort(),
    );
  });

  it('only documents endpoints that exist', async () => {
    const { body } = await request(app).get('/openapi.json');

    for (const { method, path } of documentedEndpoints(body)) {
      const url = path.replace('{id}', '01a1322a-ff14-76e9-83c0-3174db7dac15');
      const response = await request(app)[method](url).send({});
      expect(response.body.error?.code, `${method.toUpperCase()} ${path}`).not.toBe('not_found');
    }
  });

  it('every endpoint marked as protected rejects requests without a token', async () => {
    const { body } = await request(app).get('/openapi.json');

    for (const [path, methods] of Object.entries(body.paths)) {
      for (const [method, operation] of Object.entries(methods)) {
        if (!operation.security) continue;
        const url = path.replace('{id}', '01a1322a-ff14-76e9-83c0-3174db7dac15');
        const response = await request(app)[method](url).send({});
        expect(response.status, `${method.toUpperCase()} ${path}`).toBe(401);
      }
    }
  });

  it('describes the shared schemas as reusable components', async () => {
    const { body } = await request(app).get('/openapi.json');

    expect(Object.keys(body.components.schemas)).toEqual(
      expect.arrayContaining(['Error', 'User', 'Tokens', 'Session', 'LoginRequest', 'RegisterRequest', 'ChangePasswordRequest']),
    );
    expect(body.components.securitySchemes.bearerAuth).toMatchObject({ type: 'http', scheme: 'bearer' });
  });
});

describe('GET /docs', () => {
  it('serves the Swagger UI', async () => {
    const response = await request(app).get('/docs/');

    expect(response.status).toBe(200);
    expect(response.headers['content-type']).toMatch(/html/);
    expect(response.text).toContain('Brokenance API');
  });

  it('does not force https, so it works on a local http server', async () => {
    const response = await request(app).get('/docs/');

    expect(response.headers['content-security-policy']).not.toContain('upgrade-insecure-requests');
  });
});

describe('DOCS_ENABLED=false', () => {
  it('hides the documentation', async () => {
    config.docsEnabled = false;
    const appWithoutDocs = createApp();

    expect((await request(appWithoutDocs).get('/openapi.json')).status).toBe(404);
    expect((await request(appWithoutDocs).get('/docs/')).status).toBe(404);
  });
});
