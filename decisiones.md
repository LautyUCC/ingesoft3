# Decisiones técnicas

## Enlaces vigentes de TP6 y TP7 — 26/10/2026

**Actualización posterior a las 12:45 ART:** [PR #41](https://github.com/LautyUCC/ingesoft3/pull/41) y [PR #42](https://github.com/LautyUCC/ingesoft3/pull/42) se fusionaron con autorización como `f28ff8d` y `d2ca58c`. La alerta CodeQL #2 figura `fixed`. [Ambas](https://github.com/LautyUCC/ingesoft3/actions/runs/40352072647) [corridas](https://github.com/LautyUCC/ingesoft3/actions/runs/40352431332) pasaron publicación, QA, integración y E2E; QA sirve `d2ca58c`, PROD sigue en `1caea7c` sin nueva promoción. El rollback autorizado `1caea7c→99f83ef` tardó **25,306 s** desde antes del pull hasta `/health` con SHA y DB conectada; la restauración tardó **25,278 s**, conservando el mismo contenedor PostgreSQL. [Rastro UTC completo](docs/defensa/evidencias/rollback-prod-2026-10-26.log). El [PR documental #43](https://github.com/LautyUCC/ingesoft3/pull/43) lleva estas rectificaciones y espera integración.

- **Frontend QA para el formulario (una URL):** https://philips-ping-nose-streaming.trycloudflare.com/
- **Frontend PROD para el formulario (una URL):** https://captured-screenshots-win-publicity.trycloudflare.com/
- Son Quick Tunnels temporales hacia Nginx `:3001` y `:3002`, verificados con login/assets y un flujo Playwright de alta/lectura/baja el 26/10. Dependen de Mac, Docker y túneles activos; podrían cambiar al reiniciar. Comprobarlos de nuevo antes de enviar el formulario y avisar a cátedra que se usa fallback local. El túnel UptimeRobot es **solo de salud** y no es la URL del frontend. Procedimiento: [Operación del fallback](docs/defensa/OPERACION-FALLBACK-LOCAL-P2.md).
- **Paquetes públicos por SHA:** [backend GHCR](https://github.com/users/LautyUCC/packages/container/package/photomatch-backend) y [frontend GHCR](https://github.com/users/LautyUCC/packages/container/package/photomatch-frontend). El tag `sha-1caea7ce1e19d4b2b84676ec8a35686f6e26f2e3` corresponde a PROD aprobada; QA, al corte, sirve `690571bab883991e0dd9e994168e278999b14cf7` mientras [su nueva corrida](https://github.com/LautyUCC/ingesoft3/actions/runs/40287651975) espera el gate PROD. Esta diferencia es propia de Continuous Delivery.
- **Cadena de publicación:** [PR #18 con tests verdes y publicación salteada](https://github.com/LautyUCC/ingesoft3/actions/runs/40273179225); [corrida de `main` que verificó ambos builds antes de `publish`](https://github.com/LautyUCC/ingesoft3/actions/runs/40287651975). Solo los unitarios/builds condicionan GHCR; E2E condiciona la promoción PROD.
- **Gate humano rechazado:** [corrida 40277582164](https://github.com/LautyUCC/ingesoft3/actions/runs/40277582164) y [registro de aprobación/rechazo](https://api.github.com/repos/LautyUCC/ingesoft3/actions/runs/40277582164/approvals), `state: rejected` por LautyUCC con el motivo “QA, integración y E2E pasan, pero se difiere la promoción hasta revisar rollback y observabilidad de producción”. No fue un test fallido. **Gate aprobado y PROD sana:** [corrida 40284305415](https://github.com/LautyUCC/ingesoft3/actions/runs/40284305415), SHA `1caea7c`.
- **TP7 rojo por app:** [commit/PR #37](https://github.com/LautyUCC/ingesoft3/pull/37), [corrida 40283556436](https://github.com/LautyUCC/ingesoft3/actions/runs/40283556436): integración 3/3 verde, E2E 3/3 roja y PROD omitida. Artefactos directos: [playwright-report-integracion](https://github.com/LautyUCC/ingesoft3/actions/runs/40283556436/artifacts/12632424758) y [playwright-report-e2e](https://github.com/LautyUCC/ingesoft3/actions/runs/40283556436/artifacts/12632244336). [PR #39](https://github.com/LautyUCC/ingesoft3/pull/39) corrigió la app y la [corrida verde aprobada 40284305415](https://github.com/LautyUCC/ingesoft3/actions/runs/40284305415) promovió ese SHA; [v7.0.0](https://github.com/LautyUCC/ingesoft3/releases/tag/v7.0.0) apunta exactamente a él.

## Correcciones de auditoría en revisión

- [PR #41](https://github.com/LautyUCC/ingesoft3/pull/41) limita `POST /login` (20 intentos/IP/5 minutos) y añade regresión HTTP 429; CI y CodeQL del PR pasaron. La [alerta CodeQL HIGH #2](https://github.com/LautyUCC/ingesoft3/security/code-scanning/2) figura `fixed` tras el merge. Un check verde por sí solo no implica cero alertas.
- [PR #42](https://github.com/LautyUCC/ingesoft3/pull/42) añade cinco pruebas unitarias reales de telemetría frontend (parametrización QA/PROD, caso sin DSN, mock del SDK), cobertura c8 y gate en `build-frontend`; también inyecta `DEPLOY_ENV` al navegador. Localmente la etapa de tests del Dockerfile pasó con 100 % de líneas/ramas para `src/telemetryConfig.js`. Los dos PR están en `main`; no atribuirles un despliegue QA/PROD hasta verificar sus corridas.
- **Sentry real en PROD:** tras operaciones funcionales seguras, [Explore de Sentry](https://lauty-vallino.sentry.io/explore/traces/) mostró transacciones backend con entorno `prod` y conteos agrupados por `transaction` (ventana 14 días, muestra del 26/10): `GET /clients` fue la más usada (6 eventos, p75 32,51 ms); `POST /login` fue la más lenta por p75 (4 eventos, **2,23 s**). Son observaciones de esa muestra, no un SLA ni rendimiento general. El proyecto frontend registra 129 pageloads, pero su entorno actual aparece como `127.0.0.1` por el bug corregido en PR #42, por lo que todavía no permite atribuirlos exclusivamente a PROD. El error [PHOTOMATCH-BACKEND-1](https://lauty-vallino.sentry.io/issues/7812452027/) es auténtico, pero corresponde a **QA**, no a PROD; no se provocó un fallo destructivo nuevo.
- **Sentry browser tras PR #42 en QA:** el [filtro `environment=qa` del proyecto frontend](https://lauty-vallino.sentry.io/explore/traces/?environment=qa&project=4512321087537152&statsPeriod=14d) ya muestra pageloads recientes del navegador de QA. El selector de entornos incluye `qa`; los registros anteriores etiquetados `127.0.0.1` siguen siendo históricos. PROD permanece en `1caea7c`, por lo que todavía falta comprobar eventos browser `prod` tras una promoción aprobada.
- **Rollback:** los 7,42 s anteriores solo cubren recreación parcial. La nueva medición autorizada sí abarca pull, Compose y comprobación `/health` con SHA anterior/DB: **25,306 s**. Restaurar el SHA aprobado tomó **25,278 s**. Ver [rastro](docs/defensa/evidencias/rollback-prod-2026-10-26.log) y [procedimiento](docs/defensa/OPERACION-FALLBACK-LOCAL-P2.md). Las imágenes estaban en caché y estos tiempos no son un SLA.

## Registro histórico del cierre declarado TP5–TP9 (sujeto a la auditoría anterior)

Las notas de esta sección registran corridas anteriores. El estado actual, los enlaces que pide la cátedra y los pendientes están en las dos secciones precedentes.

- **Demostración de Gate E2E Rojo (TP7):** [PR #37](https://github.com/LautyUCC/ingesoft3/pull/37) rompió deliberadamente la ruta del formulario de alta de clientes (`/clients/blocked-demo`). En [CI Run 40283556436](https://github.com/LautyUCC/ingesoft3/actions/runs/40283556436), `deploy-qa` desplegó el commit `43e730b`, `integracion` pasó 3/3 verde contra la API, y `e2e` falló (3/3 rojo por HTTP 404), generando artefactos de Playwright. Como consecuencia directa de `needs: e2e`, `deploy-prod` fue **bloqueado y omitido automáticamente**. PROD permaneció protegida e inalterada en el SHA anterior.
- **Restauración Verde y Promoción a PROD (TP7):** [PR #39](https://github.com/LautyUCC/ingesoft3/pull/39) revirtió la ruta a `/clients`. En [CI Run 40284305415](https://github.com/LautyUCC/ingesoft3/actions/runs/40284305415), integración y E2E pasaron 3/3 verdes. Tras la aprobación humana en el gate de `production`, PROD se desplegó exitosamente en commit `1caea7ce1e19d4b2b84676ec8a35686f6e26f2e3`, respondiendo `/health` 200 OK con PostgreSQL conectado tanto en QA (`:3001`) como en PROD (`:3002`). Se publicó el release `v7.0.0`.
- **Infraestructura como Código (TP8):** Se ejecutó el ciclo completo de Terraform en `infra/`: `terraform plan` con 8 altas, `terraform apply` creando el entorno `preprod` en el puerto 3003 con `/health` 200 OK y PostgreSQL conectado. Se demostró la idempotencia con un segundo plan (0 cambios) y la convivencia pacífica con QA y PROD. Luego se ejecutó `terraform destroy`, eliminando los 8 recursos limpiamente sin afectar los puertos 3001 y 3002. Se publicó el release `v8.0.0`.
- **DevSecOps y Observabilidad (TP9):** [PR #30](https://github.com/LautyUCC/ingesoft3/pull/30) de Dependabot (`pg` 8.23.0 → 8.23.1) integrado en `43f142e` con CI verde. CodeQL default setup ejecuta análisis, pero mantiene la [alerta HIGH #2](https://github.com/LautyUCC/ingesoft3/security/code-scanning/2) abierta en `main`. Push protection activo. Sentry capturó la excepción fatal [PHOTOMATCH-BACKEND-1](https://lauty-vallino.sentry.io/issues/7812452027/) (`terminating connection due to administrator command`) en QA con SHA y entorno exactos. Se creó la [Issue #38](https://github.com/LautyUCC/ingesoft3/issues/38) en GitHub Project PhotoMatch. El [Monitor UptimeRobot #804424437](https://dashboard.uptimerobot.com/monitors/804424437) registró el [incidente resuelto #372997347011072787](https://dashboard.uptimerobot.com/incidents/372997347011072787) (DOWN 503 y recuperación UP tras 5m 04s). Se publicó el release `v9.0.0`.
- **Releases vigentes:** `v5.0.0`, `v6.0.0`, `v7.0.0`, `v8.0.0` y `v9.0.0` con sus respectivos tags y notas oficiales en GitHub.

## Enlaces de TP6 y TP7 (estado verificable al 26/10/2026)

- La [CI 40278713952, intento 1](https://github.com/LautyUCC/ingesoft3/actions/runs/40278713952/attempts/1) recibió aprobación humana en `production` y terminó verde; QA y PROD local respondieron `/health` con SHA `99f83ef971b9189180e2bfcadf7f30a921b976ee` y PostgreSQL conectado. Ambos proyectos Compose usan las imágenes GHCR de ese SHA, sin reconstruir en la promoción. El [intento 2](https://github.com/LautyUCC/ingesoft3/actions/runs/40278713952/attempts/2) incorporó los DSN de Sentry en QA y pasó integración/E2E; su gate PROD vuelve a esperar revisión.
- Observabilidad real: proyectos Sentry `photomatch-backend` y `photomatch-frontend` con DSN en secrets de cada environment. Tras parar brevemente PostgreSQL de QA, `POST /login` devolvió 500 y Sentry capturó [PHOTOMATCH-BACKEND-1](https://lauty-vallino.sentry.io/issues/7812452027/) como excepción fatal, etiquetada `qa` y con el SHA exacto; la base se restauró. Explore mostró una muestra de pageload `/` de 2,23 s y `POST /login` de 2,12 s. La [issue #38](https://github.com/LautyUCC/ingesoft3/issues/38), en [GitHub Project PhotoMatch](https://github.com/users/LautyUCC/projects/1), propone evitar reinicios del backend ante un corte de PostgreSQL.
- El [monitor UptimeRobot](https://dashboard.uptimerobot.com/monitors/804424437) pasó de un URL incorrecto `127.0.0.1` a una URL HTTPS temporal que expone **sólo** `GET /health` de PROD; `/login` devuelve 404. Se observó `Up` y luego un [incidente genuino 503](https://dashboard.uptimerobot.com/incidents/372997347011072787) al detener el backend de PROD. Ya se restauró el servicio y el endpoint público volvió a 200; falta que UptimeRobot marque UP en su siguiente chequeo. El primer incidente de timeout era del URL `localhost` inválido y no se presenta como caída de PROD. El túnel depende de que la Mac permanezca encendida y su subdominio cambia al reiniciarse.

- La [CI 40277582164](https://github.com/LautyUCC/ingesoft3/actions/runs/40277582164) completó finalmente integración 3/3 y E2E 3/3. Su gate `production` fue **rechazado** por `LautyUCC` con el motivo “QA, integración y E2E pasan, pero se difiere la promoción hasta revisar rollback y observabilidad de producción”; el [registro de aprobaciones de la corrida](https://api.github.com/repos/LautyUCC/ingesoft3/actions/runs/40277582164/approvals) conserva el rechazo. La corrida terminó en `failure` por el rechazo, sin desplegar PROD.
- [PR #36](https://github.com/LautyUCC/ingesoft3/pull/36) se integró como `99f83ef971b9189180e2bfcadf7f30a921b976ee`. La [CI 40278713952](https://github.com/LautyUCC/ingesoft3/actions/runs/40278713952) publicó las dos imágenes de ese SHA, desplegó QA y pasó integración 3/3 y E2E 3/3. `/health` de QA respondió `ok`, el SHA exacto y PostgreSQL `connected`. `deploy-prod` espera una autorización distinta; PROD no se ha desplegado.

- [PR #18](https://github.com/LautyUCC/ingesoft3/pull/18): integrado con autorización del propietario en `main` como `3bdfd2464031836fb1f2488e095a1db221d9f926`. La [última CI del PR](https://github.com/LautyUCC/ingesoft3/actions/runs/40273179225) y [CodeQL](https://github.com/LautyUCC/ingesoft3/actions/runs/40273176297) pasaron; publicación y deploy se saltearon por ser PR.
- [CI de `main`, intento 2](https://github.com/LautyUCC/ingesoft3/actions/runs/40273446742/attempts/2): ambos builds y `publish` pasaron. Las imágenes [backend](https://github.com/users/LautyUCC/packages/container/package/photomatch-backend) y [frontend](https://github.com/users/LautyUCC/packages/container/package/photomatch-frontend) quedaron públicas con tag `sha-3bdfd2464031836fb1f2488e095a1db221d9f926`; `docker manifest inspect` anónimo funcionó para ambas. El primer intento de publicación había fallado con `permission_denied: write_package`; se concedió al repositorio acceso Actions `Write` en ambos paquetes.
- En ese intento, `deploy-qa` falló antes de crear contenedores: Docker intentó guardar el `GITHUB_TOKEN` en el llavero de macOS y el runner como servicio no podía interactuar con él. La corrección del [PR #33](https://github.com/LautyUCC/ingesoft3/pull/33) elimina el login en el despliegue y fija el socket del contexto Docker antes de usar una configuración temporal y `docker-compose` para descargar anónimamente los paquetes públicos. La prueba local de `docker-compose pull` con ese aislamiento pasó para PostgreSQL y ambas imágenes GHCR.
- [CI tras PR #33](https://github.com/LautyUCC/ingesoft3/actions/runs/40275316689): builds y publicación pasaron para `ad48d6e42794d93f2a6bfb1cc5b1d8c429749873`; `deploy-qa` volvió a fallar antes de crear contenedores porque `docker-compose pull` todavía consultó el llavero. Una prueba desde launchd sin sesión interactiva logró descargar las imágenes con `docker --config <temporal> pull` y levantar un proyecto aislado con `docker-compose up --pull never`; `/health` dio SHA correcto y DB conectada. Esa secuencia está en el [PR #34](https://github.com/LautyUCC/ingesoft3/pull/34).
- [CI tras PR #34](https://github.com/LautyUCC/ingesoft3/actions/runs/40276866668): ambos pulls GHCR pasaron; el pull de PostgreSQL desde Docker Hub consultó el llavero y bloqueó QA. `postgres:16-alpine` ya estaba presente en Docker Desktop. La nueva corrección comprueba su presencia con `docker image inspect` y usa `docker-compose up --pull never`. El script completo, ejecutado en launchd sin sesión interactiva, levantó QA de prueba y `/health` devolvió SHA `94287a2`, `ok` y DB `connected`; luego se eliminaron sólo esos recursos de prueba.
- [CI tras PR #35](https://github.com/LautyUCC/ingesoft3/actions/runs/40277582164): builds, publicación, QA y smoke pasaron para `dde81a86437eb496f273a35109137a4afe372175`. Integración pasó 3/3 casos contra QA y PostgreSQL; el cierre del job quedó demorado al guardar la caché npm de 687 MB, antes de iniciar E2E. Se quita la opción `cache: npm` de los jobs del runner propio, que ya conserva su caché local.
- Rollback de QA local medido con los dos tags GHCR publicados: `94287a2 → ad48d6e` tardó **20,16 s** hasta `/health` con SHA anterior y DB conectada; restaurar `ad48d6e → 94287a2` tardó **20,15 s**. Se midió con reloj monótono desde el inicio del despliegue hasta la respuesta verificada. Los recursos creados para la medición se eliminaron. No se presenta esta prueba como rollback de PROD.
- **Nota histórica:** esta lista de pendientes quedó superada por las corridas y releases enlazadas al principio del documento; se conserva para explicar la secuencia de implementación.
- Fallback local de la consigna: QA `http://127.0.0.1:3001`, PROD `http://127.0.0.1:3002` cuando el runner y Docker Desktop están encendidos. Son URL locales, no públicas. La disponibilidad hasta la defensa depende de mantener esta máquina encendida.

## TP1 — Git colaborativo

### Flujo de trabajo elegido

Se utiliza GitHub Flow porque el proyecto mantiene una única rama estable (`main`) y los cambios son pequeños e incrementales. Cada cambio se realiza en una rama corta y entra mediante un Pull Request. Esto permite revisar el diff, conservar una conversación asociada al cambio y detectar problemas antes de modificar la versión estable.

La protección de `main` no se basa en la confianza entre integrantes. Su propósito es convertir el proceso acordado en una regla verificable: evita cambios accidentales, obliga a integrar mediante PR y deja trazabilidad entre la intención, la revisión y los commits.

### Conflicto de merge

El conflicto se provoca modificando la misma línea del `README.md` de manera diferente en dos ramas creadas desde el mismo punto. Después de integrar la primera rama, Git no puede elegir automáticamente cuál de las dos versiones representa la intención correcta. Ambas modificaciones son válidas desde el punto de vista del algoritmo, pero son incompatibles entre sí; la decisión requiere contexto humano.

El conflicto podría haberse evitado coordinando el trabajo para que las ramas modificaran líneas o archivos diferentes, integrando ramas más pequeñas con mayor frecuencia o actualizando la segunda rama con `main` antes de abrir su PR. Actualizarla antes no elimina necesariamente el conflicto, pero permite resolverlo temprano en la rama de trabajo y no durante la integración final.

### Versionado

La primera entrega se identifica como `v1.0.0`. De acuerdo con versionado semántico, el primer número representa cambios incompatibles, el segundo funcionalidades compatibles y el tercero correcciones compatibles. En este TP el tag funciona como una referencia inmutable al estado presentado. Además se crea el tag `tp1`, solicitado por la cátedra para localizar el snapshot académico del trabajo.

### Problemas encontrados y soluciones

- El repositorio personal estaba vacío. Se creó una estructura mínima para que el historial del semestre comience en este TP.
- El cliente Git de Windows no podía usar HTTPS debido a una política que bloqueaba su biblioteca `libcurl`. Se utilizó Git dentro de WSL sobre la misma carpeta de trabajo.
- El directorio donde estaban las consignas también contenía cambios locales de PhotoMatch. Para no mezclarlos ni perderlos, la entrega se clonó en `C:\ingesoft3\entrega-tp1` y esos cambios quedaron intactos.
- Las evidencias de rechazo, conflicto y Release no se inventan: se incorporan después de ejecutar cada operación real en GitHub.

### Uso de inteligencia artificial

Se utilizó un asistente de IA para preparar la estructura inicial, redactar una primera versión de la documentación y explicar el modelo de ramas, conflictos y versionado. La verificación se realiza contrastando el documento con la consigna oficial, ejecutando los comandos sobre el repositorio real y comprobando en GitHub que la protección rechace el push, que el PR muestre el conflicto y que los tags y la Release apunten al commit correcto. El contenido será revisado y comprendido antes de la defensa oral.

## TP2 — Contenedores

### Elección de la aplicación

Se eligió PhotoMatch, una aplicación propia para administrar el trabajo de un fotógrafo deportivo. Se puede ejecutar con Docker, sus comandos son explícitos (`npm ci` y `node src/app.js`), la conexión PostgreSQL está centralizada en `DATABASE_URL`, contiene reglas comprobables y su tamaño permite comprenderla durante la defensa.

La app tiene presentación, backend y base. Como usa HTML renderizado con EJS, Nginx funciona como contenedor frontal: sirve CSS y reenvía las solicitudes hacia Express. No se presenta falsamente como SPA ni como microservicios.

### Imágenes multi-stage

El backend usa `node:22-alpine`. Sus stages separan dependencias completas, pruebas, dependencias productivas y runtime. La imagen final no recibe tests, Supertest, caché de npm ni archivos locales. Node es interpretado y no posee una separación SDK/runtime como .NET; aquí el beneficio es aislar pruebas y dependencias de desarrollo.

El frontend usa Alpine para reunir assets y `nginx:1.29-alpine` como runtime. Nginx sirve `/css/` y usa el nombre DNS `backend` para el proxy. Cada contexto tiene su propio `.dockerignore`.

### Red, salud y persistencia

Compose crea una red interna: el backend resuelve `db` y Nginx resuelve `backend`. PostgreSQL no publica su puerto al host. `depends_on` solo no asegura disponibilidad; por eso PostgreSQL ejecuta `pg_isready`, el backend expone `/health` y las dependencias esperan `service_healthy`.

El volumen `photomatch_data` persiste `/var/lib/postgresql/data`. `down` conserva datos y `down -v` elimina deliberadamente el volumen. Frontend y backend son descartables.

### Secretos

`.env` está ignorado y contiene la configuración local. `.env.example` documenta las variables sin ser fuente de secretos reales. Compose interpola esas variables; en futuros pipelines vivirán en GitHub Secrets o en secretos del entorno.

### Problemas encontrados

- La versión inicial tenía un solo Dockerfile y no era multi-stage. Se crearon contextos de frontend y backend independientes.
- Compose incluía claves fijas y publicaba PostgreSQL. Se migró a variables y red interna.
- Faltaba una señal de disponibilidad. Se agregaron `/health` y healthchecks encadenados.
- Docker Desktop estaba detenido; se inició y se verificó todo desde build limpio.
- Node no estaba instalado en Windows; los tests se ejecutaron dentro del stage `test`.

### Uso de inteligencia artificial

Se utilizó IA para auditar la consigna, proponer la separación compatible con EJS, preparar Dockerfiles, Compose y documentación, y operar las verificaciones. Se validó con `docker compose config`, once tests, tres servicios saludables, solicitudes HTTP end-to-end y pruebas reales de persistencia usando `down`, `up` y `down -v`. El contenido debe ser comprendido antes de defenderlo.

## TP3 — Planificación y trazabilidad

### Duración del sprint

Sprint 1 dura 14 días, desde el 31 de agosto hasta el 13 de septiembre de 2026. Dos semanas permiten completar una porción verificable del pipeline, recibir devolución y ajustar sin acumular un mes de trabajo. Un sprint más corto generaría demasiado costo de planificación para una persona y uno más largo demoraría el feedback.

### Límite de trabajo en progreso

El límite de `In Progress` es 2: cantidad de personas (una) más una tarea adicional. Permite continuar con una segunda actividad cuando la primera espera una respuesta o revisión, pero evita empezar muchas cosas y no terminar ninguna. Si nunca se alcanza, el límite sería demasiado alto; si bloquea continuamente trabajo razonable, se revisaría con evidencia.

### Diagnóstico de la historia mal escrita

“Como desarrollador quiero crear la tabla usuarios para guardar los datos” es una tarea técnica disfrazada de historia: describe implementación y no valor para un usuario. Se reescribiría como “Como administrador quiero registrar usuarios para que cada integrante acceda de forma segura a las funciones que le corresponden”; crear la tabla sería una tarea hija.

### Problemas encontrados

- GitHub CLI no tenía alcance `project`; se amplió la autorización desde el flujo oficial por dispositivo.
- El Project creado por CLI era privado y solo tenía vista de tabla. Se hizo público y se creó una vista Board agrupada por Status mediante la API.
- La versión de `gh` instalada inicialmente no era conocida; se verificó que era 2.98 y soportaba sub-issues nativos.
- El CLI no permite crear campos Iteration directamente. Se utilizó la API GraphQL para crear Sprint 1 con duración de 14 días y asignar historia y tareas.
- Se comprobó por API que el workflow “Item closed” está habilitado; al cerrar una tarea debe moverla automáticamente a Done.

### Uso de inteligencia artificial

Se utilizó IA para auditar la consigna, crear y relacionar issues, operar GitHub Projects mediante CLI, REST y GraphQL, redactar la documentación y preparar la trazabilidad. Se verificó consultando el Project público, las relaciones Parent issue/Sub-issues progress, el campo Sprint, el workflow automático y el estado del issue después del merge. Todo debe recorrerse y explicarse durante la defensa.

## TP4 — CI: Pipelines as Code

### Estructura del pipeline

El workflow tiene dos jobs independientes: `build-backend` y `build-frontend`. Cada imagen posee su propio Dockerfile, contexto y cache, así que no existe una dependencia que obligue a ejecutarlas en secuencia. GitHub asigna un runner limpio a cada job y puede construirlas en paralelo; si cualquiera falla, el pipeline queda rojo.

`pull_request` verifica la combinación con `main` antes del merge y alimenta el gate. `push` sobre `main` genera una corrida posterior y mantiene actualizado el badge.

### Dockerfiles como contrato

El pipeline usa los Dockerfiles del TP2 con `docker/build-push-action`. Existe así una sola definición de build para desarrollo, CI y despliegue futuro. Ejecutar comandos Node o Nginx distintos en el workflow podría dejar CI verde mientras la imagen desplegable estuviera rota.

En TP4 `push: false`: se verifica que las imágenes se construyan en una máquina limpia, sin publicarlas. Los tests se incorporan al pipeline en TP5.

### Cache

Buildx importa y exporta capas con `type=gha`; `mode=max` conserva también capas intermedias. Los scopes `backend` y `frontend` son estantes separados para que el último job no sobrescriba el cache del otro.

En backend se reutilizan la imagen base, la copia del lockfile y `npm ci --omit=dev` mientras no cambien dependencias. Cambiar `package.json` o el lockfile invalida esa capa y las posteriores. En frontend se reutilizan la base Nginx, configuración y assets no modificados.

Si el cache desaparece, el pipeline reconstruye todo y vuelve a poblarlo. El cache mejora rendimiento, pero no es necesario para la corrección.

### Gate

`main` exige Pull Request, aplica la regla al administrador y requiere `build-backend` y `build-frontend` en verde. `strict: true` obliga a verificar la rama contra el estado actual de `main`, evitando integrar un verde calculado sobre una base vieja.

### Problemas encontrados

- El workflow del TP3 solo hacía checkout; se reemplazó por los dos jobs reales.
- Se definieron scopes separados porque compartir el scope predeterminado haría que los caches se pisaran.
- Los nuevos checks debían correr al menos una vez antes de configurar el gate.
- PhotoMatch usa Node interpretado; la demostración rompe una dependencia, porque un error de sintaxis no necesariamente se evalúa durante `docker build`.

### Uso de inteligencia artificial

Se utilizó IA para analizar la consigna, adaptar el workflow, configurar cache y protección de rama, operar la demostración rojo–verde y redactar la defensa. Se verificó con corridas reales, logs con capas reutilizadas, un PR bloqueado por un build fallido, el fix posterior y consultas a la protección de `main`.


## TP5 — Calidad automatizada: tests, coverage y Quality Gate

### Enlaces de este TP

| Lo que se comprueba | Enlace |
|---|---|
| Corrida roja por umbral de cobertura (Quality Gate) | [Actions Run #39985482676](https://github.com/LautyUCC/ingesoft3/actions/runs/39985482676) |
| Corrida verde con Step Summary y artefacto descargable | [Actions Run #39985690914](https://github.com/LautyUCC/ingesoft3/actions/runs/39985690914) |
| Secuencia completa rojo → tests → verde → merge (PR1) | [Pull Request #16](https://github.com/LautyUCC/ingesoft3/pull/16) |
| Freno de calidad bloqueado y abierto hasta la defensa (PR2) | [Pull Request #17](https://github.com/LautyUCC/ingesoft3/pull/17) |
| Release congelada del trabajo | [Release v5.0.0](https://github.com/LautyUCC/ingesoft3/releases/tag/v5.0.0) |

### Lógica elegida para testear y por qué esa

En PhotoMatch se priorizó testear la lógica del núcleo del dominio (`src/services/**`), donde un bug impacta de forma crítica en la recaudación del fotógrafo o en la seguridad del sistema:
1. `pricingService.js`: Calcula los precios de compra de jugadores individuales, packs (`single`, `pack6`, `all`) y la regla de liquidación `isCounted`. Un bug aquí produce liquidaciones erróneas, cobros incorrectos al cliente o compromisos de entrega de fotos que no existen.
2. `authService.js`: Controla la autenticación de usuarios administradores y fotógrafos con hashing bcrypt y normalización de credenciales. Un fallo aquí expone el panel de control o bloquea el acceso de los usuarios operativos.
3. `validationService.js`: Garantiza la consistencia de eventos deportivos (fechas lógicas de entrega posteriores al evento, planteles rivales distintos, precios no negativos y normalización de nombres y emails).

### Umbral de cobertura y justificación

El umbral configurado en `.c8rc.json` y verificado en el pipeline es **80% en líneas y 70% en ramas**.
- **Medición real actual:** 100% en líneas (86/86) y 70.58% en ramas (48/68).
- **Justificación:** El umbral se ancló en la medición real de la aplicación. Exige que el 100% de las funciones y líneas críticas se mantengan verificadas y que la cobertura de ramas no decaiga del 70%. Para subir el umbral de ramas al 85% sería necesario escribir pruebas sobre ramas defensivas secundarias de `validationService.js` (como valores imposibles que ya están filtrados por la interfaz de usuario en las plantillas EJS).

### Qué se dejó afuera de la cuenta de cobertura y por qué

Se configuró `.c8rc.json` con `include: ["src/services/**"]` y exclusiones explícitas justificadas según el marco de la cátedra (§2.4):
- **Arranque (`src/app.js`):** Solo cablea middleware de Express y escucha en el puerto 3000. Si falla, el servicio no levanta y se detecta en runtime.
- **Acceso a datos e infraestructura (`src/db/**`, `src/repositories/**`):** Inicialización de esquemas PostgreSQL y consultas SQL directas con `pg`. Probar esto aisladamente requeriría una base de datos real, lo cual corresponde a las pruebas de integración (TP7).
- **Transporte HTTP y vistas (`src/controllers/**`, `src/routes/**`, `src/views/**`):** Orquestan solicitudes y renderizan HTML con EJS.
- **Frontend (`frontend/`):** Nginx funciona como servidor web de assets CSS y proxy inverso hacia Express. No contiene JavaScript del lado cliente ni lógica de negocio (SPA). Por regla explícita de la cátedra (§1605 y §1631), los tests unitarios de frontend no aplican y las tres técnicas se concentran y validan en el backend.

### Por qué coverage alto no garantiza calidad

La cobertura mide qué porcentaje de código fue **ejecutado**, pero no certifica qué fue **verificado**. Si escribiéramos un test como:
```javascript
test('cobertura sin verdad', () => {
  calculatePlayerPurchase('pack6', 15);
});
```
La función se ejecuta completamente y `c8` computa 100% de cobertura en esa línea. Sin embargo, no existe ningún `assert`: si la función tuviese un bug y devolviera un precio negativo o un objeto `null`, el test pasaría en verde. La verdadera confianza reside en la calidad de los asserts y en la sensibilidad de las pruebas ante cambios de lógica.

### Pull Request bloqueado por Quality Gate

- **PR bloqueado de demostración:** [Pull Request #16](https://github.com/LautyUCC/ingesoft3/pull/16) (en su primer commit `0f0f718`).
- **Check en rojo:** `build-backend` en el step *Ejecutar tests unitarios y verificar umbral de cobertura (Quality Gate)*.
- **Métrica del fallo:** Líneas: 55.81% (umbral: 80%) y Ramas: 59.61% (umbral: 70%).
- **Causa:** Se configuró el freno de cobertura en CI y se refactorizó `authService.js`, pero no se habían incluido aún las suites de prueba `authService.test.js` y `pricingService.test.js`. A pesar de que los 11 tests existentes pasaron (0 errores de compilación, 0 fallos lógicos), el gate bloqueó el PR por calidad insuficiente.
- **Solución (Commit `e4790fd`):** Se incorporaron 21 tests unitarios nuevos (mock, parametrizados y casos de borde). La cobertura subió al 100% en líneas y 70.58% en ramas, poniendo el check en verde y habilitando el merge.
- **Segundo PR (permanente):** [Pull Request #17](https://github.com/LautyUCC/ingesoft3/pull/17) en la rama `demo/tp5-gate-bloqueado`, que permanece **abierto y en rojo hasta la defensa oral** para evidenciar el bloqueo en vivo ante la mesa evaluadora.

### Refactorización para permitir Mocks

Originalmente `authService.js` realizaba `const users = require('../repositories/userRepository')` en el ámbito global del módulo, acoplando fuertemente el servicio a las consultas SQL nativas de PostgreSQL. Para aislarlo:
- Se aplicó **Inversión de Dependencias (Dependency Injection)**: la función pasó a ser `authenticate(email, password, userRepo = users)`.
- En producción, `userRepo` toma por defecto el repositorio real sin romper el controlador `authController.js`.
- En pruebas (`backend/test/authService.test.js`), se le inyecta un doble de riesgo (`mockUserRepo`) que registra las invocaciones y retorna un usuario simulado con un hash precalculado de bcrypt, permitiendo validar la interacción y la sanitización de credenciales sin tocar la base de datos.

### Traducción del stack técnico («Tu stack, de un vistazo»)

| Requisito de la Cátedra | Implementación en PhotoMatch (Node.js) |
|---|---|
| **Dónde viven los tests** | En carpeta `backend/test/*.test.js` con el runner nativo `node:test` y `node:assert/strict`. |
| **Test parametrizado** | Matrices de datos iteradas con `cases.forEach(tc => test(..., () => { ... }))`. |
| **Inyección de dependencia** | Parámetro con valor por defecto en la función: `userRepo = users`. |
| **Medidor de cobertura** | `c8` (instrumentación nativa basada en el motor V8 de Node.js). |
| **Umbral que frena el build** | `c8 --check-coverage --lines 80 --branches 70 node --test` (retorna exit code 1 si no se cumple). |
| **Filtro de cobertura** | Archivo `backend/.c8rc.json` con `include: ["src/services/**"]` y exclusión de arranque e infraestructura. |

### El ejercicio del camino sin cubrir

- **Archivo y línea exacta:** `backend/src/services/validationService.js`, líneas 30 y 31:
  `if (!COVERAGE_STATUSES.includes(data.status)) errors.push('El estado no es válido.');`
  `if (!PAYMENT_STATUSES.includes(data.payment_status)) errors.push('El estado de pago no es válido.');`
- **Entrada concreta que lo recorrería:** Invocar `validateCoverage` con un estado inexistente: `{ ...validData, status: 'Inexistente', payment_status: 'NoExiste' }`.
- **Decisión tomada y por qué:** Decidimos **no agregar este test** en la suite unitaria actual. En la aplicación real, estos valores están restringidos mediante elementos `<select>` en las vistas EJS y tipos enum a nivel de base de datos. Dejar esta rama sin ejercitar sitúa la cobertura de ramas en un honesto **70.58%**, calibrando a la perfección el umbral del Quality Gate (70%) para que cualquier código sin tests rompa el pipeline inmediatamente.

### Problemas encontrados y soluciones

- **Aislamiento de persistencia en Node.js:** `authService.js` acoplaba la lógica de negocio al cliente `pg`. Se solucionó aplicando inyección de dependencias como argumento opcional con fallback, evitando herramientas invasivas de intercepción de módulos en runtime.
- **Generación del Step Summary en CI:** `c8` muestra la salida de cobertura en la consola estándar, pero el Step Summary requería volcarlo a `$GITHUB_STEP_SUMMARY`. Se configuraron los reportes `text` y `text-summary` y se inyectaron directamente en el archivo de entorno de GitHub Actions mediante un paso con `if: always()`.
- **Preservación del artefacto ante fallo de umbral:** Cuando el build fallaba por cobertura, el paso de subida de artefactos no se ejecutaba por defecto. Se agregó la condición `if: always()` en los steps de summary y upload-artifact para garantizar que la evidencia del fallo esté disponible para su descarga y análisis.

### Uso de inteligencia artificial

Se utilizó asistencia de IA para auditar las consignas de la UCC, diseñar los casos de prueba unitarios, estructurar las matrices de parametrización, configurar la integración de `c8` con GitHub Actions y elaborar el material didáctico para la defensa oral. La verificación se realizó de forma empírica y reproducible: ejecutando la suite localmente (32 tests en 87 ms), comprobando el fallo real por umbral en GitHub Actions (Run #39985482676), validando la corrida verde (Run #39985690914) y asegurando que las decisiones técnicas respondan a la arquitectura real del repositorio.

## TP6 — Entrega continua con fallback local

El PR #18 seguía abierto y el árbol estaba limpio al iniciar esta continuación. El problema real era que `build-backend` y `build-frontend` publicaban de forma independiente: si fallaba uno, el otro podía llegar a GHCR. Ahora los dos jobs verifican y exportan sus imágenes como archivos; `publish` tiene `needs: [build-backend, build-frontend]` y sólo hace `docker load` y `docker push` de esos archivos en un push a `main`. No hay reconstrucción tras el gate. En PR, los pasos de registry quedan salteados. Es una garantía sobre el pipeline, no sobre pushes manuales al registry. Los tags `sha-<commit>` son identificadores únicos de contenido generado por ese commit; no usamos `latest`.

Elegimos el **fallback local Plan C autorizado por TP6 §3.6** porque al diseñar CD no disponíamos de cuentas de Render/Neon y necesitábamos dos entornos desplegados por el pipeline, no una demo levantada manualmente. Un runner propio `photomatch-local`, instalado como servicio `launchd`, ejecuta los jobs `deploy-qa` y `deploy-prod` de GitHub Actions. Cada job descarga las dos imágenes públicas GHCR del mismo `sha-<commit>` que pasó build/tests y ejecuta Docker Compose sin reconstruirlas. QA usa Nginx `:3001`, backend y PostgreSQL propios; PROD usa `:3002`, otra red, otros contenedores y otro volumen PostgreSQL. Los IDs de DB son distintos y las suites funcionales 3/3 integración + 3/3 E2E pasaron en cada entorno el 26/10/2026. El mismo frontend sirve ambos despliegues porque `BACKEND_URL` se configura al arrancar, no en la imagen.

GitHub Environments `qa` y `production` limitan las variables y secretos a su ámbito. `qa` se despliega automáticamente después de ambos builds y la publicación; integración y E2E verifican su API, UI y PostgreSQL. `production` exige la aprobación de LautyUCC después de E2E; un rechazo humano con motivo quedó registrado en la corrida enlazada al principio. Cada environment guarda sus propias claves aleatorias de base, sesión y administrador; el workflow no las imprime. `COMMIT_SHA` queda en la imagen backend y `/health` lo devuelve junto con el resultado de `SELECT 1`. El smoke reintenta y exige el SHA exacto para no aceptar una versión anterior.

La infraestructura local tiene límites explícitos: la Mac debe seguir encendida, conectada a Internet y a corriente; Docker Desktop, el runner y los contenedores deben continuar activos para que Actions y los frontends funcionen. Los dos Quick Tunnels exponen los frontends a Internet para la evaluación, pero sus subdominios pueden cambiar al reiniciarse; se comprobaron funcionalmente y hay que volver a comprobarlos antes del formulario y de la defensa. El túnel UptimeRobot expone solo `/health` de PROD. No tenemos la disponibilidad ni el aislamiento físico de un proveedor cloud. El procedimiento de arranque, prueba y recuperación ante 502 o caída de PostgreSQL está en [Operación del fallback](docs/defensa/OPERACION-FALLBACK-LOCAL-P2.md).

El backend ya no desactiva la verificación del certificado TLS. `DB_SSL_MODE=require` valida el certificado y el host; `disable` corresponde al PostgreSQL de red local de Compose. `SESSION_SECRET` de producción debe tener al menos 32 caracteres y no puede ser el ejemplo. La cookie usa `secure: auto` detrás de un proxy confiable. Estas decisiones permiten Render/Neon más adelante sin debilitar TLS, aunque el despliegue activo elegido es local.

Implementamos Continuous Delivery: QA se despliega automáticamente tras CI; integración y E2E verifican QA; PROD espera aprobación. El aprobador mira cobertura, imágenes publicadas, smoke del SHA, integración, reporte E2E y cambios del PR. Para producción real elegiríamos rolling con dos instancias si hubiera presupuesto y observabilidad; el fallback actual es `recreate`, con una ventana breve. El rechazo humano **sí existe** y está enlazado al principio. El rollback completo autorizado de PROD al SHA anterior y su restauración se midieron con un mismo reloj hasta `/health` con SHA y DB conectada: **25,306 s** y **25,278 s**, respectivamente. El dato previo de 7,42 s solo cubría un intervalo parcial.

La primera validación local real incluyó `actionlint`, ShellCheck, 32 tests y cobertura, builds de ambas imágenes, Compose y `/health` con PostgreSQL conectado. Luego se agregó una prueba de email por dos alertas CodeQL: ahora son 33 tests, con 100% de líneas y 72,36% de ramas. El intento 2 de la CI de `main` publicó ambos paquetes públicos; QA falló en el login de Docker antes de crear contenedores. PR #33 propone la descarga anónima. La disponibilidad del fallback depende de Docker Desktop y del runner encendidos durante la defensa. La IA ayudó a diseñar el pipeline y la configuración; se verificó con herramientas locales, API de GitHub y pruebas reales, y se distingue lo pendiente de lo observado.

## TP7 — Integración, navegador y promoción de una imagen

PhotoMatch renderiza EJS, no una SPA. Para probar operaciones con `request` sin navegador agregamos una API autenticada `/api/clients` que reutiliza el repositorio y la validación de clientes. Responde 201 en alta, 400 en datos inválidos, 404 si falta el recurso y 204 en baja. Las tres pruebas `frontend/e2e/api.spec.js` hacen alta/lectura/baja, rechazo de nombre vacío y edición con verificación. Crean nombres únicos y borran los registros creados. Se autentican contra la app y la base real de QA. Las tres `app.spec.js` usan Chromium sobre el front: alta y baja, error visible sin persistencia, y edición persistente tras recarga seguida de limpieza. No hay mocks ni saltos si el entorno no responde.

El workflow encadena `deploy-qa → integracion → e2e → deploy-prod`; los reportes HTML se suben aun cuando falla una suite. La imagen que QA y PROD reciben lleva el mismo tag del commit y se publicó una sola vez. La integración distingue problemas de API/base de fallos de interfaz. El smoke sólo prueba salud y SHA; Playwright comprueba comportamiento. La prueba local real dio 3/3 integración y 3/3 E2E. Descubrió un 500 previo en `/clients/new`: el local `client` de EJS se interpretaba como opción de compilación y anulaba `include`. Se renombró a `customer` y la pantalla volvió a funcionar.

**Estado posterior:** la corrida roja por código de la app, sus dos reportes, la corrección verde, aprobación PROD y release `v7.0.0` están enlazados al principio. La IA ayudó con API, pruebas y diagnóstico; se contrastó con PostgreSQL y Chromium locales y con las corridas de GitHub Actions.

## TP8 — Preprod reproducible con Terraform

Se eligió el provider Docker `kreuzwerker/docker` 4.6.0, fijado en `infra/versions.tf`, con Terraform 1.17.x. `infra/` declara red, volumen, PostgreSQL, backend y frontend: ocho recursos que no importan ni alteran QA o PROD. La URL de base se deriva del nombre del contenedor de PostgreSQL; `BACKEND_URL` del nombre del backend. Las imágenes se pasan como variables para usar las etiquetas GHCR del TP7. El estado se guarda fuera del repositorio, porque contiene credenciales. Variables sensibles llegan por `TF_VAR_*`, y `.gitignore` excluye estado, `.terraform/` y tfvars; el lock file sí se versiona.

Se ejecutaron `init`, `fmt -check`, `validate`, `plan` (8 altas), `apply`, `/health` con base, segundo `plan` sin cambios, `destroy`, recreación y nuevo `destroy`. El primer apply falló porque el provider buscó `/var/run/docker.sock`; en Docker Desktop de macOS se resolvió exportando `DOCKER_HOST` desde `docker context inspect`. Tras la publicación GHCR del SHA `3bdfd2464031836fb1f2488e095a1db221d9f926`, se repitió el ciclo con ambas imágenes del registry: 8 altas, `/health` HTTP 200 con ese SHA y PostgreSQL conectado, plan sin cambios y destroy de 8 recursos. Un 502 inicial se debió al arranque del backend y se resolvió al esperar salud. Preprod quedó destruido y QA/PROD no fueron importados ni modificados. **Pendiente:** `v8.0.0` y prueba de convivencia con QA/PROD una vez que éstos se desplieguen. La IA ayudó a redactar HCL; se verificó leyendo planes y resultados reales.

## TP9 — Seguridad y observabilidad

Se agregó Dependabot para npm de backend, npm de frontend y GitHub Actions. En GitHub están habilitadas las actualizaciones de seguridad, secret scanning y push protection. CodeQL default setup quedó configurado y su primer análisis terminó en verde en la corrida enlazada arriba. `npm audit fix` actualizó cuatro dependencias transitivas vulnerables; el audit posterior reportó cero vulnerabilidades. Se integró `@sentry/node` antes de Express y `@sentry/browser` en un bundle servido por Nginx; sólo se inicializan cuando se configuran DSN desde el entorno. La configuración pública del navegador llega por `/telemetry-config.js`, sin incluir credenciales de lectura de Sentry en el código. El SHA identifica la release en ambas SDK.

La primera corrida CodeQL del PR marcó dos alertas altas: la validación de email usaba un regex con backtracking potencialmente costoso, y `/health` consultaba la base sin límite de frecuencia. Se reemplazó la validación por operaciones lineales sobre la cadena, se agregó `express-rate-limit` a `/health` (60 solicitudes por minuto) y un test con entradas malformadas y largas. La suite volvió a superar el umbral. El nuevo escaneo de CodeQL y su check de seguridad terminaron verdes en la corrida enlazada arriba.

Dependabot ya abrió PRs desde `main`; #30 actualiza `pg` a 8.23.1 y su CI pasó. **Pendiente obligatorio:** integrar un PR Dependabot con autorización; cuentas/proyectos Sentry y sus DSN; evento real y tabla de uso; monitor externo con DOWN/UP y pausa; tarjeta del Project derivada de un dato observado; release `v9.0.0`. Sin esos datos no se inventan métricas ni incidente. La IA ayudó a configurar las capas; se verificaron la API de GitHub, CodeQL y los builds, pero aún falta observar producción.
