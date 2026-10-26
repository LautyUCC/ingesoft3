#!/usr/bin/env bash
set -euo pipefail

: "${FRONTEND_URL:?Falta FRONTEND_URL del environment}"
: "${COMMIT_SHA:?Falta COMMIT_SHA}"

node <<'NODE'
const expected = process.env.COMMIT_SHA;
const endpoints = [process.env.FRONTEND_URL];
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

async function check(base) {
  for (let attempt = 1; attempt <= 40; attempt++) {
    try {
      const response = await fetch(new URL('/health', base), {
        signal: AbortSignal.timeout(10000)
      });
      const body = await response.json();
      if (response.ok && body.status === 'ok' && body.commit === expected) {
        console.log(`${new URL(base).hostname}: saludable, commit ${expected} (intento ${attempt})`);
        return;
      }
      console.log(`${new URL(base).hostname}: versión pendiente (intento ${attempt})`);
    } catch (error) {
      console.log(`${new URL(base).hostname}: aún no disponible (intento ${attempt})`);
    }
    if (attempt < 40) await sleep(10000);
  }
  throw new Error(`${new URL(base).hostname}: no respondió con el commit esperado`);
}

(async () => {
  for (const base of endpoints) await check(base);
})().catch(error => { console.error(error.message); process.exitCode = 1; });
NODE
