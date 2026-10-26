import * as Sentry from '@sentry/browser';

if (window.PHOTOMATCH_SENTRY_DSN) {
  Sentry.init({
    dsn: window.PHOTOMATCH_SENTRY_DSN,
    environment: window.location.hostname,
    release: window.PHOTOMATCH_COMMIT_SHA,
    integrations: [Sentry.browserTracingIntegration()],
    tracesSampleRate: 1.0
  });
}
