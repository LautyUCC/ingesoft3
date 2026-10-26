const { test, expect } = require('@playwright/test');

if (!process.env.E2E_BASE_URL || !process.env.E2E_EMAIL || !process.env.E2E_PASSWORD) {
  throw new Error('Faltan E2E_BASE_URL o credenciales de QA');
}

const unique = prefix => `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2)}`;

async function login(page) {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.E2E_EMAIL);
  await page.getByLabel('Contraseña').fill(process.env.E2E_PASSWORD);
  await page.getByRole('button', { name: 'Ingresar' }).click();
  await expect(page.getByRole('link', { name: 'Clientes' })).toBeVisible();
}

async function createClient(page, name) {
  await page.goto('/clients');
  await page.getByRole('link', { name: /Nuevo cliente/ }).click();
  await page.getByLabel('Nombre *').fill(name);
  await page.getByLabel('Tipo *').selectOption('club');
  await page.getByRole('button', { name: 'Guardar cliente' }).click();
  await expect(page.getByRole('row', { name: new RegExp(name) })).toBeVisible();
}

async function deleteClient(page, name) {
  page.once('dialog', dialog => dialog.accept());
  await page.getByRole('row', { name: new RegExp(name) })
    .getByRole('button', { name: 'Eliminar' }).click();
  await expect(page.getByRole('row', { name: new RegExp(name) })).toHaveCount(0);
}

test('crear cliente, verlo y borrarlo desde la interfaz', async ({ page }) => {
  const name = unique('ui-alta');
  await login(page);
  await createClient(page, name);
  await deleteClient(page, name);
});

test('el formulario muestra error y no guarda nombre vacío', async ({ page }) => {
  await login(page);
  const before = await (await page.request.get('/api/clients')).json();
  await page.goto('/clients/new');
  await page.getByLabel('Nombre *').fill('   ');
  await page.getByLabel('Tipo *').selectOption('club');
  await page.getByRole('button', { name: 'Guardar cliente' }).click();
  await expect(page.getByText('El nombre es obligatorio.')).toBeVisible();
  const after = await (await page.request.get('/api/clients')).json();
  expect(after.map(client => client.id)).toEqual(before.map(client => client.id));
});

test('editar cliente persiste al recargar y luego se limpia', async ({ page }) => {
  const name = unique('ui-editar');
  const updated = `${name}-nuevo`;
  await login(page);
  await createClient(page, name);
  try {
    await page.getByRole('row', { name: new RegExp(name) })
      .getByRole('link', { name: 'Editar' }).click();
    await page.getByLabel('Nombre *').fill(updated);
    await page.getByRole('button', { name: 'Guardar cliente' }).click();
    await page.reload();
    await expect(page.getByRole('row', { name: new RegExp(updated) })).toBeVisible();
  } finally {
    await page.goto('/clients');
    await deleteClient(page, updated);
  }
});
