import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { prisma } from '../src/lib/prisma.js';

const app = createApp();

afterAll(async () => {
  await prisma.$disconnect();
});

describe('GET /health', () => {
  it('returns ok', async () => {
    const response = await request(app).get('/health');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'ok' });
  });
});

describe('GET /health/ready', () => {
  it('confirms the database is reachable', async () => {
    const response = await request(app).get('/health/ready');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'ok', database: 'up' });
  });
});
