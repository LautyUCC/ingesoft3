import * as Sentry from '@sentry/browser';
import { startTelemetry } from './telemetryConfig';

startTelemetry({
  dsn: window.PHOTOMATCH_SENTRY_DSN,
  environment: window.PHOTOMATCH_DEPLOY_ENV,
  release: window.PHOTOMATCH_COMMIT_SHA
}, Sentry);
