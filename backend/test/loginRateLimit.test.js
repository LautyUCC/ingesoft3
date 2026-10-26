const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { createApp } = require('../src/app');

test('limita intentos de login sin bloquear la pantalla ni otras IP', async () => {
  const app = createApp();
  const source = '198.51.100.21';
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const response = await request(app)
      .post('/login')
      .set('X-Forwarded-For', source)
      .type('form')
      .send({ email: '', password: '' });
    assert.equal(response.status, 401);
  }

  const blocked = await request(app)
    .post('/login')
    .set('X-Forwarded-For', source)
    .type('form')
    .send({ email: '', password: '' });
  assert.equal(blocked.status, 429);
  assert.match(blocked.headers.ratelimit || '', /r=0/);

  const anotherSource = await request(app)
    .post('/login')
    .set('X-Forwarded-For', '198.51.100.22')
    .type('form')
    .send({ email: '', password: '' });
  assert.equal(anotherSource.status, 401);
  assert.equal((await request(app).get('/login').set('X-Forwarded-For', source)).status, 200);
});
