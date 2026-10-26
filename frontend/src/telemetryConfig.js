function startTelemetry(config, sdk) {
  if (!config.dsn || typeof config.dsn !== 'string') return false;
  sdk.init({
    dsn: config.dsn,
    environment: config.environment || 'development',
    release: config.release || 'unknown',
    integrations: [sdk.browserTracingIntegration()],
    tracesSampleRate: 1.0
  });
  return true;
}

module.exports = { startTelemetry };
