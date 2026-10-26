const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './e2e',
  timeout: 60000,
  expect: { timeout: 15000 },
  retries: 1,
  workers: 1,
  reporter: [['list'], ['html', { outputFolder: 'playwright-report', open: 'never' }]],
  use: {
    baseURL: process.env.E2E_BASE_URL,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure'
  }
});
