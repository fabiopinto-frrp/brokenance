import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';

// Behaviour of the app as a whole (CORS, JSON errors). Feature tests live next to this file.
const app = createApp();

describe('CORS', () => {
  it('answers preflight requests from any origin in development', async () => {
    const response = await request(app)
      .options('/health')
      .set('Origin', 'http://localhost:54321')
      .set('Access-Control-Request-Method', 'POST')
      .set('Access-Control-Request-Headers', 'authorization,content-type');

    expect(response.status).toBe(204);
    expect(response.headers['access-control-allow-origin']).toBe('*');
    expect(response.headers['access-control-allow-headers']).toContain('Authorization');
    expect(response.headers['access-control-allow-methods']).toContain('POST');
  });

  it('adds the CORS header to normal responses', async () => {
    const response = await request(app).get('/health').set('Origin', 'http://localhost:54321');

    expect(response.headers['access-control-allow-origin']).toBe('*');
  });
});

describe('unknown routes', () => {
  it('returns a JSON 404', async () => {
    const response = await request(app).get('/does-not-exist');

    expect(response.status).toBe(404);
    expect(response.body.error.code).toBe('not_found');
  });
});

describe('invalid JSON body', () => {
  it('returns a JSON 400', async () => {
    const response = await request(app)
      .post('/auth/login')
      .set('Content-Type', 'application/json')
      .send('{ not json');

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('invalid_json');
  });
});
