const test = require('node:test');
const assert = require('node:assert/strict');
const { startTelemetry } = require('../src/telemetryConfig');

function fakeSdk() {
  const calls = [];
  const integration = { name: 'browserTracing' };
  return {
    calls,
    integration,
    init(options) { calls.push(options); },
    browserTracingIntegration() { return integration; }
  };
}

test('no inicializa ni transmite telemetría sin DSN', () => {
  const sdk = fakeSdk();
  assert.equal(startTelemetry({ dsn: '' }, sdk), false);
  assert.equal(startTelemetry({ dsn: null }, sdk), false);
  assert.equal(sdk.calls.length, 0);
});

for (const environment of ['qa', 'prod']) {
  test(`etiqueta la telemetría del navegador como ${environment}`, () => {
    const sdk = fakeSdk();
    const config = { dsn: 'https://public@example.invalid/1', environment, release: 'abc123' };
    assert.equal(startTelemetry(config, sdk), true);
    assert.deepEqual(sdk.calls, [{
      dsn: config.dsn,
      environment,
      release: 'abc123',
      integrations: [sdk.integration],
      tracesSampleRate: 1.0
    }]);
  });
}

test('usa valores explícitos de desarrollo cuando faltan entorno y SHA', () => {
  const sdk = fakeSdk();
  startTelemetry({ dsn: 'https://public@example.invalid/1' }, sdk);
  assert.equal(sdk.calls[0].environment, 'development');
  assert.equal(sdk.calls[0].release, 'unknown');
});

test('no oculta un fallo de inicialización del SDK', () => {
  const sdk = fakeSdk();
  sdk.init = () => { throw new Error('SDK no disponible'); };
  assert.throws(() => startTelemetry({ dsn: 'https://public@example.invalid/1' }, sdk), /SDK no disponible/);
});
