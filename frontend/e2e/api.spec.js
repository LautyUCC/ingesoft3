const { test, expect } = require('@playwright/test');

const base = process.env.API_BASE_URL;
const email = process.env.E2E_EMAIL;
const password = process.env.E2E_PASSWORD;
if (!base || !email || !password) throw new Error('Faltan API_BASE_URL o credenciales de QA');
const unique = prefix => `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2)}`;

test.beforeEach(async ({ request }) => {
  const response = await request.post(new URL('/login', base).toString(), {
    form: { email, password }
  });
  expect(response.ok()).toBeTruthy();
});

test('alta, lectura y baja de cliente contra PostgreSQL de QA', async ({ request }) => {
  const name = unique('api-alta');
  const create = await request.post(new URL('/api/clients', base).toString(), {
    data: { name, type: 'club' }
  });
  expect(create.status()).toBe(201);
  const { id } = await create.json();
  try {
    const show = await request.get(new URL(`/api/clients/${id}`, base).toString());
    expect(show.status()).toBe(200);
    expect((await show.json()).name).toBe(name);
  } finally {
    expect((await request.delete(new URL(`/api/clients/${id}`, base).toString())).status()).toBe(204);
  }
  expect((await request.get(new URL(`/api/clients/${id}`, base).toString())).status()).toBe(404);
});

test('alta inválida devuelve 400 y no crea cliente', async ({ request }) => {
  const url = new URL('/api/clients', base).toString();
  const before = (await (await request.get(url)).json()).map(client => client.id);
  const response = await request.post(url, { data: { name: '   ', type: 'club' } });
  expect(response.status()).toBe(400);
  expect((await response.json()).errors).toContain('El nombre es obligatorio.');
  const after = (await (await request.get(url)).json()).map(client => client.id);
  expect(after).toEqual(before);
});

test('modificar un cliente persiste y la baja lo limpia', async ({ request }) => {
  const name = unique('api-editar');
  const updatedName = `${name}-actualizado`;
  const create = await request.post(new URL('/api/clients', base).toString(), {
    data: { name, type: 'medio' }
  });
  expect(create.status()).toBe(201);
  const { id } = await create.json();
  try {
    const update = await request.put(new URL(`/api/clients/${id}`, base).toString(), {
      data: { name: updatedName, type: 'medio' }
    });
    expect(update.status()).toBe(200);
    const show = await request.get(new URL(`/api/clients/${id}`, base).toString());
    expect((await show.json()).name).toBe(updatedName);
  } finally {
    expect((await request.delete(new URL(`/api/clients/${id}`, base).toString())).status()).toBe(204);
  }
  expect((await request.get(new URL(`/api/clients/${id}`, base).toString())).status()).toBe(404);
});
