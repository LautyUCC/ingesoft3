#!/usr/bin/env node
'use strict';

const http = require('node:http');

const port = Number(process.env.HEALTH_PROXY_PORT || 3004);
const target = 'http://127.0.0.1:3002/health';

http.createServer(async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Content-Type', 'application/json; charset=utf-8');

  if (req.method !== 'GET' || req.url !== '/health') {
    res.writeHead(404);
    res.end(JSON.stringify({ status: 'not_found' }));
    return;
  }

  try {
    const response = await fetch(target, { signal: AbortSignal.timeout(5000) });
    const health = await response.json();
    const healthy = response.ok && health.status === 'ok' && health.database === 'connected';
    res.writeHead(healthy ? 200 : 503);
    res.end(JSON.stringify({ status: healthy ? 'ok' : 'unhealthy' }));
  } catch {
    res.writeHead(503);
    res.end(JSON.stringify({ status: 'unhealthy' }));
  }
}).listen(port, '127.0.0.1', () => {
  process.stdout.write(`Health proxy listening on 127.0.0.1:${port}\n`);
});
