# Operación del fallback local para la defensa P2

**QA:** `https://philips-ping-nose-streaming.trycloudflare.com/`

**PROD:** `https://captured-screenshots-win-publicity.trycloudflare.com/`

Son **las URLs del frontend**, una por entorno. Se verificaron el 26/10/2026 con login, CSS, JavaScript y el flujo Playwright de crear, ver y borrar un cliente desde Internet; en ambos casos hubo 200 en `/health` con PostgreSQL conectado. Son túneles Quick Tunnel: dependen de esta Mac y **pueden cambiar si se reinician**. Antes de llenar el formulario y antes de la defensa se deben volver a comprobar; no se debe copiar una URL que ya no abra la app. El túnel anterior `happen-dimension-anonymous-collapse.trycloudflare.com` expone solo `/health` para UptimeRobot y **no** sirve como URL del frontend.

## Preparación antes de empezar la defensa

1. Encender la Mac, conectarla a Internet y a corriente. Evitar que se suspenda durante la demostración. Iniciar Docker Desktop y esperar que `docker info` responda.
2. Comprobar que el runner registrado como servicio está activo: `launchctl list | rg 'actions.runner.LautyUCC-ingesoft3.photomatch-local'`. En GitHub, verificar que el runner aparezca `Idle` u `Online` en *Settings → Actions → Runners*.
3. Comprobar los seis contenedores: `docker ps --format '{{.Names}} {{.Status}}'`. Deben estar sanos `photomatch-qa-{db,backend,frontend}-1` y `photomatch-prod-{db,backend,frontend}-1`. Las redes y volúmenes de QA/PROD son independientes; **no ejecutar `docker compose down -v`**.
4. Comprobar ambos frontends locales: `curl -fsS http://127.0.0.1:3001/health` y `curl -fsS http://127.0.0.1:3002/health`. Cada JSON debe decir `status: ok`, `database: connected` y su SHA esperado. QA puede estar en un commit más nuevo mientras PROD espera el gate; comparar contra GitHub Deployments y releases.
5. Comprobar túneles activos: `launchctl list | rg 'com.photomatch.(qa|prod).front.tunnel'`. Abrir las **dos URLs indicadas arriba** en una ventana privada. `/` debe llevar a la pantalla de login; `/css/styles.css` y `/js/telemetry.js` deben cargar. El docente recibe solo la URL raíz de cada frontend, sin `/health` ni URL del backend.
6. Iniciar sesión y ejecutar en cada entorno una operación controlada: crear un cliente con nombre único de prueba, verificarlo en la tabla, editarlo, recargar y finalmente borrarlo. Confirmar que no queda dato de prueba. Las suites `frontend/e2e/app.spec.js` y `frontend/e2e/api.spec.js` realizan estos recorridos con limpieza. En la verificación del 26/10 pasaron **3/3 integración y 3/3 navegador en QA y PROD locales**; sobre cada túnel pasó el flujo crear/ver/borrar.
7. Abrir de antemano GitHub Actions (gate rechazado y aprobado), GHCR, Sentry Explore, UptimeRobot e Issue #38/Project. El monitor de UptimeRobot debe permanecer pausado tras la evidencia DOWN/UP.

## Si el frontend devuelve 502

1. Comprobar el origen local: `curl -i http://127.0.0.1:3001/health` o `:3002/health`. Si localhost funciona y el túnel no, revisar el proceso `cloudflared`, red y URL actual; no tocar los contenedores.
2. Si localhost también falla, ver `docker ps` y `docker logs --tail 100 photomatch-<qa|prod>-frontend-1` y `photomatch-<qa|prod>-backend-1`. Un 502 de Nginx suele indicar que el upstream backend no responde o no resolvió su DNS en Docker.
3. Comprobar PostgreSQL: `docker ps --filter name=photomatch-<qa|prod>-db-1` y `docker logs --tail 100 photomatch-<qa|prod>-db-1`. Si la DB no está sana, recuperarla primero y esperar `/health` con `database: connected`. No borrar su volumen.
4. Si DB está sana y backend detenido, revisar los logs de backend y el estado del contenedor. Reiniciarlo solo después de identificar el fallo y comprobar otra vez `/health` y login. Si el problema es de versión, usar el workflow de despliegue correspondiente y su gate de producción; no construir manualmente una imagen distinta.
5. Si hay que reiniciar un Quick Tunnel, la URL probablemente cambiará. Actualizar la referencia antes de presentarla; una URL caducada no cumple el formulario. El túnel de monitoreo de solo salud es independiente.

## Recuperar túneles si se caen

Con Docker y los frontends locales ya sanos, se pueden crear de nuevo con:

```bash
launchctl submit -l com.photomatch.qa.front.tunnel -o /tmp/photomatch-qa-tunnel.log -e /tmp/photomatch-qa-tunnel.err -- /opt/homebrew/bin/cloudflared tunnel --url http://127.0.0.1:3001 --no-autoupdate
launchctl submit -l com.photomatch.prod.front.tunnel -o /tmp/photomatch-prod-tunnel.log -e /tmp/photomatch-prod-tunnel.err -- /opt/homebrew/bin/cloudflared tunnel --url http://127.0.0.1:3002 --no-autoupdate
```

Leer el nuevo `https://...trycloudflare.com` de los logs, comprobar `/login` y un flujo funcional, y comunicar cualquier cambio de URL a la cátedra. No publicar contraseñas en el formulario ni en este documento. La dirección `127.0.0.1` solo sirve en esta Mac; los evaluadores necesitarán los enlaces públicos vigentes o la demostración local autorizada por la cátedra.

## Medir un rollback completo cuando se autorice

La medición autorizada del 26/10/2026 está en el [rastro UTC completo](evidencias/rollback-prod-2026-10-26.log): `1caea7c→99f83ef` tomó **25,306 s** y restaurar `99f83ef→1caea7c` tomó **25,278 s**. Un mismo proceso midió cada tramo **antes de invocar** `scripts/deploy-local.sh` hasta la primera respuesta `/health` que confirmó simultáneamente `status: ok`, `database: connected` y el SHA esperado. El contenedor PostgreSQL conservó su ID. El script de deploy mantuvo el volumen. Las imágenes estaban cacheadas; las cifras son evidencia de ese ciclo, no un tiempo garantizado. La cifra histórica de **7,42 s** solo medía parte de la recreación. Una nueva maniobra sobre PROD vuelve a requerir autorización expresa.
