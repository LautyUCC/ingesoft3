const Sentry = require('@sentry/node');

if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.DEPLOY_ENV || process.env.NODE_ENV || 'development',
    release: process.env.COMMIT_SHA || 'unknown',
    tracesSampleRate: 1.0
  });
}

module.exports = Sentry;
