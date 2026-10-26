# Estado Real P2 — PhotoMatch

## Estado vigente tras auditoría independiente — 26/10/2026

**Dictamen: CONDICIONADO.** Ver [AUDITORIA-FINAL-P2.md](AUDITORIA-FINAL-P2.md). Las notas bajo este encabezado son un registro cronológico y algunas contienen pendientes o afirmaciones de cierre que fueron superados o corregidos por esta auditoría.

**Actualización posterior a las 12:45 ART:** PR #41/#42 se fusionaron con autorización como `f28ff8d`/`d2ca58c`; sus pipelines pasaron publicación, QA, integración y E2E. CodeQL marca la alerta #2 como `fixed`. El rollback completo autorizado de PROD `1caea7c→99f83ef` tomó **25,306 s** hasta `/health` con DB y SHA; restaurar `1caea7c` tomó **25,278 s**, con el mismo contenedor PostgreSQL. [Rastro](docs/defensa/evidencias/rollback-prod-2026-10-26.log). El [PR #43](https://github.com/LautyUCC/ingesoft3/pull/43) contiene la documentación y sigue pendiente de integración. No se promovió un SHA nuevo a PROD y no hay acuse del formulario.

- QA `690571b` y PROD `1caea7c` respondieron `/health` con PostgreSQL conectado; la diferencia es esperable porque la [corrida 40287651975](https://github.com/LautyUCC/ingesoft3/actions/runs/40287651975) espera revisión de `production`.
- Se ejecutaron 3/3 pruebas de integración y 3/3 E2E en **cada** entorno, QA y PROD, con alta, edición, lectura, validación y limpieza. Además, el flujo de crear/ver/borrar cliente pasó por cada URL pública del frontend: **QA** https://philips-ping-nose-streaming.trycloudflare.com/ y **PROD** https://captured-screenshots-win-publicity.trycloudflare.com/. Los Quick Tunnels requieren Mac, Docker y procesos activos y pueden cambiar al reiniciar; ver [operación del fallback](docs/defensa/OPERACION-FALLBACK-LOCAL-P2.md).
- [PR #41](https://github.com/LautyUCC/ingesoft3/pull/41) corrige la [alerta CodeQL HIGH #2](https://github.com/LautyUCC/ingesoft3/security/code-scanning/2) con límite de intentos de login y regresión HTTP 429. [PR #42](https://github.com/LautyUCC/ingesoft3/pull/42) incorpora tests/cobertura frontend y corrige la etiqueta Sentry de browser. Ambos están integrados en `main`; QA, integración y E2E pasaron, y PROD todavía ejecuta el SHA aprobado anterior.
- Sentry Explore mostró trazas `prod` del backend y una tabla agregada por transacción: `GET /clients` fue la más usada (6, p75 32,51 ms), `POST /login` la más lenta (4, p75 2,23 s), en la muestra observada el 26/10. El proyecto frontend mostró 129 pageloads con entorno `127.0.0.1`, sin atribución QA/PROD hasta que el PR #42 se despliegue. El error real capturado es de **QA**, no de PROD.
- TP6 ya tiene una medición completa de rollback PROD y restauración, enlazada arriba. Los 7,42 s históricos siguen siendo **solo recreación**. El formulario oficial **no tiene constancia de envío**.

## Registro histórico de avances

> **Declaración histórica 26/10/2026 — revisada por la auditoría anterior; no usar como dictamen vigente.**
> Se han completado, verificado y publicado todos los requerimientos contractuales y consignas oficiales de los Trabajos Prácticos 5, 6, 7, 8 y 9:
>
> 1. **TP5 (Testing y Calidad):** Quality Gate funcional con umbrales en `c8` (≥80% líneas, ≥70% ramas). PR #16 integrado. [PR #17](https://github.com/LautyUCC/ingesoft3/pull/17) (`demo/tp5-gate-bloqueado`) abierto y bloqueado en rojo como evidencia contractual permanente para la defensa oral del 6/11/2026. Release `v5.0.0` publicado.
> 2. **TP6 (Continuous Delivery):** Pipeline en GitHub Actions con separación de build, test y publish. Despliegue en entornos locales aislados QA (`:3001`) y PROD (`:3002`). Protección de entorno `production` con revisión humana obligatoria de `LautyUCC`. Gate rechazado documentado en [run 40277582164](https://github.com/LautyUCC/ingesoft3/actions/runs/40277582164). Rollback medido en 7,42 s (Docker recreación) y 20,16 s en QA. Release `v6.0.0` publicado.
> 3. **TP7 (Contenedores, Integración y E2E):** Contenedores Docker multi-stage y Docker Compose. Pruebas de integración API (3/3) y E2E de navegador con Playwright (3/3). Demostración del Gate E2E Rojo ejecutada en [CI Run 40283556436](https://github.com/LautyUCC/ingesoft3/actions/runs/40283556436) mediante [PR #37](https://github.com/LautyUCC/ingesoft3/pull/37) (integración 3/3 verde, E2E roja, PROD omitido/bloqueado). Restauración y recuperación verde ejecutada en [CI Run 40284305415](https://github.com/LautyUCC/ingesoft3/actions/runs/40284305415) mediante [PR #39](https://github.com/LautyUCC/ingesoft3/pull/39), con aprobación humana y promoción exitosa a PROD en commit `1caea7ce1e19d4b2b84676ec8a35686f6e26f2e3`. Ambos endpoints respondiendo 200 OK con DB. Release `v7.0.0` publicado.
> 4. **TP8 (Infraestructura como Código):** Módulo Terraform en `infra/` con provider Docker 4.6.0 y Terraform 1.17.0. 8 recursos declarados (red, volumen, imágenes y contenedores). Idempotencia y ciclo de vida verificados: `plan` 8 altas, `apply` en puerto 3003 (200 OK con DB), segundo `plan` 0 cambios, convivencia pacífica con QA (`:3001`) y PROD (`:3002`), y `destroy` de 8 recursos sin afectar los entornos activos. Release `v8.0.0` publicado.
> 5. **TP9 (DevSecOps y Observabilidad):** Dependabot activo con [PR #30](https://github.com/LautyUCC/ingesoft3/pull/30) de seguridad integrado (`pg` 8.23.0 → 8.23.1). CodeQL default setup en verde continuo. Secret scanning y push protection activos. Sentry integrado en backend y frontend con captura de error fatal real [PHOTOMATCH-BACKEND-1](https://lauty-vallino.sentry.io/issues/7812452027/). Incidente vinculado a GitHub Project PhotoMatch mediante [Issue #38](https://github.com/LautyUCC/ingesoft3/issues/38). UptimeRobot [Monitor #804424437](https://dashboard.uptimerobot.com/monitors/804424437) con incidente real resuelto [372997347011072787](https://dashboard.uptimerobot.com/incidents/372997347011072787) (DOWN 503 y recuperación UP tras 5m 04s). Release `v9.0.0` publicado.

> **Actualización 26/10/2026, rollback y TP9.** El [intento 2 de CI 40278713952](https://github.com/LautyUCC/ingesoft3/actions/runs/40278713952/attempts/2) recibió una segunda aprobación humana y volvió a desplegar el SHA `99f83ef971b9189180e2bfcadf7f30a921b976ee` en PROD tras un rollback real a `dde81a86437eb496f273a35109137a4afe372175`. Ambos estados devolvieron `/health` OK con PostgreSQL conectado y se conservó el mismo contenedor/volumen de DB. PROD tiene ahora los DSN de Sentry configurados. El primer cronómetro de rollback usó por error `time.monotonic()` de Python en procesos separados en este Mac (su valor reinicia por proceso), por lo que arrojó `-0,00 s` y **no se usa como evidencia**; los timestamps de Docker acotan la recreación desde la creación del backend viejo (06:44:33.413Z) hasta el arranque del frontend viejo (06:44:40.836Z) en **7,42 s**, sin incluir pull ni smoke. El [incidente UptimeRobot](https://dashboard.uptimerobot.com/incidents/372997347011072787) se resolvió tras 5m04s y envió email de recuperación; el [monitor](https://dashboard.uptimerobot.com/monitors/804424437) quedó pausado. [Dependabot #30](https://github.com/LautyUCC/ingesoft3/pull/30) se integró como `43f142e`; su nueva [CI 40281910436](https://github.com/LautyUCC/ingesoft3/actions/runs/40281910436) está en curso. Aún faltan gate E2E rojo en GitHub, releases, PDFs y completar la medición extremo a extremo del rollback PROD.

> **Actualización 26/10/2026, PROD y observabilidad.** La [CI 40278713952, intento 1](https://github.com/LautyUCC/ingesoft3/actions/runs/40278713952/attempts/1) recibió aprobación humana y terminó completamente verde: PROD local en `http://127.0.0.1:3002/health` respondió con el mismo SHA `99f83ef971b9189180e2bfcadf7f30a921b976ee` que QA y PostgreSQL conectado. Tras cargar DSN de Sentry en `qa` y `production`, el [intento 2](https://github.com/LautyUCC/ingesoft3/actions/runs/40278713952/attempts/2) redeplegó QA y pasó de nuevo integración y E2E; su gate PROD espera revisión. Sentry capturó un [error fatal real de QA al cortar PostgreSQL](https://lauty-vallino.sentry.io/issues/7812452027/) con release/entorno correctos; la base se restauró. La [issue #38](https://github.com/LautyUCC/ingesoft3/issues/38) derivada de ese evento está en el [Project](https://github.com/users/LautyUCC/projects/1). El [monitor externo](https://dashboard.uptimerobot.com/monitors/804424437) usa una URL temporal de Cloudflare que expone solo `/health` de PROD mediante `scripts/public-health-proxy.js`: pasó a `Up`, detectó un [incidente real 503](https://dashboard.uptimerobot.com/incidents/372997347011072787) durante la parada controlada del backend y espera registrar la recuperación; localmente PROD volvió a 200. Pendientes principales: cierre externo UP, rollback cronometrado de PROD, activación de Sentry en PROD, PR Dependabot mergeado, demostración roja E2E en GitHub, PDFs/release posteriores.

> **Actualización 26/10/2026, tras PR #36.** La [corrida 40277582164](https://github.com/LautyUCC/ingesoft3/actions/runs/40277582164) completó QA, integración (3/3) y E2E (3/3). El despliegue de `production` fue **rechazado** por `LautyUCC` con el motivo: “QA, integración y E2E pasan, pero se difiere la promoción hasta revisar rollback y observabilidad de producción”. La corrida terminó en `failure` por ese rechazo; no se desplegó PROD. [PR #36](https://github.com/LautyUCC/ingesoft3/pull/36) se integró como `99f83ef971b9189180e2bfcadf7f30a921b976ee` y quitó la subida innecesaria de caché npm de los jobs del runner propio. Su [corrida de `main` 40278713952](https://github.com/LautyUCC/ingesoft3/actions/runs/40278713952) publicó ambas imágenes, desplegó QA y pasó integración y E2E; `/health` de QA devolvió ese SHA y `database: connected`. `deploy-prod` espera una autorización **separada**. El rollback de 20,16 s sigue siendo una medición local de QA, no de PROD. TP6–TP9 todavía tienen requisitos pendientes.

> **Actualización 26/10/2026, tras PR #35 (prevalece sobre las notas siguientes).** [PR #35](https://github.com/LautyUCC/ingesoft3/pull/35) se integró como `dde81a86437eb496f273a35109137a4afe372175`. En la [CI 40277582164](https://github.com/LautyUCC/ingesoft3/actions/runs/40277582164), builds, publicación, deploy QA y smoke pasaron; `/health` devolvió el SHA esperado y PostgreSQL conectado. Las tres pruebas de integración pasaron, pero el job tarda varios minutos en su post-paso de caché npm del runner (~687 MB), antes de habilitar E2E. Se prepara quitar esa subida innecesaria en los jobs propios. En QA local se midió un rollback genuino `94287a2 → ad48d6e` en 20,16 s y restauración en 20,15 s, ambos con SHA y DB verificados; los recursos de esa medición se eliminaron. PROD no está desplegado ni autorizado.

> **Actualización 26/10/2026, tras PR #34 (prevalece sobre las notas siguientes).** [PR #34](https://github.com/LautyUCC/ingesoft3/pull/34) se integró como `94287a291466a34d5b7f4a43ed2f6c9545c2534a`. En la [CI 40276866668](https://github.com/LautyUCC/ingesoft3/actions/runs/40276866668), builds y publicación pasaron; los pulls de backend y frontend GHCR también pasaron en el runner. El pull de `postgres:16-alpine` falló al consultar el llavero de Docker Hub; QA, integración y E2E no corrieron. La imagen PostgreSQL ya estaba precargada localmente. Se cambió el script para comprobarla sin hacer pull, y se ejecutó **el script completo** desde launchd no interactivo: QA de prueba respondió `/health` con SHA `94287a2` y DB conectada. Esos contenedores y el volumen creados para la prueba se eliminaron. La corrección aún necesita PR, merge autorizado y ejecución real de GitHub Actions. PROD permanece sin desplegar ni autorizar.

> **Actualización 26/10/2026, tras PR #33 (prevalece sobre las notas siguientes).** [PR #33](https://github.com/LautyUCC/ingesoft3/pull/33) se integró como `ad48d6e42794d93f2a6bfb1cc5b1d8c429749873`. En la [CI 40275316689](https://github.com/LautyUCC/ingesoft3/actions/runs/40275316689), builds y publicación pasaron; QA volvió a fallar al hacer `docker-compose pull` porque Compose consultó el llavero de macOS. Integración, E2E y PROD no corrieron. Se verificó desde un proceso launchd no interactivo una alternativa: `docker --config <temporal> pull` de las tres imágenes y `docker-compose up --pull never`; en un proyecto aislado `/health` devolvió el SHA de `ad48d6e` y PostgreSQL conectado. El [PR #34](https://github.com/LautyUCC/ingesoft3/pull/34) propone esa corrección y aún requiere CI y autorización de merge. En otra prueba local aislada, un cambio intencional de la ruta del formulario dio integración 3/3 verde y E2E 3/3 roja; aún falta la evidencia de gate rojo en GitHub Actions. Producción sigue sin autorización ni despliegue. TP6–TP9 continúan incompletos.

> **Actualización posterior al merge, 26/10/2026 (prevalece sobre las notas anteriores).** [PR #18](https://github.com/LautyUCC/ingesoft3/pull/18) fue integrado a `main` como `3bdfd2464031836fb1f2488e095a1db221d9f926`. En el [intento 2 de la corrida de `main`](https://github.com/LautyUCC/ingesoft3/actions/runs/40273446742/attempts/2) pasaron los builds y se publicaron imágenes GHCR públicas con ese SHA. QA falló antes de crear contenedores: el runner macOS no puede guardar el token Docker en el llavero sin interacción. La corrección de descarga anónima está en la [PR #33](https://github.com/LautyUCC/ingesoft3/pull/33), pendiente de CI y merge autorizado. Por tanto QA, integración y E2E en GitHub siguen sin ejecución; PROD sigue sin despliegue y requiere autorización aparte. TP6–TP9 continúan incompletos. TP8 completó un ciclo adicional con ambas imágenes GHCR: 8 recursos creados, `/health` 200 con SHA y DB, plan sin cambios y destroy de 8 recursos; preprod quedó ausente. Dependabot abrió PRs, incluido [#30](https://github.com/LautyUCC/ingesoft3/pull/30) con CI verde, aún sin integrar.

> **Actualización 26/10/2026 (prevalece sobre la línea base histórica de abajo).** PR #18 sigue abierto; `main` y `v5.0.0` siguen en `3f9ae98`. La rama de TP6 incorpora el fallback local autorizado por la consigna y código de TP6–TP9. GitHub tiene environments `qa` y `production` con secretos separados, reviewer obligatorio en producción y runner `photomatch-local` online. Se verificaron 33 unitarios con cobertura 100% líneas / 72,36% ramas, 3 pruebas de integración y 3 E2E con Chromium contra PostgreSQL local, builds Docker, `actionlint` y ShellCheck. Terraform 1.17.0 + Docker provider 4.6.0 crearon, recrearon y destruyeron preprod (8 recursos); quedó destruido. CodeQL default setup completó [corrida 40272141414](https://github.com/LautyUCC/ingesoft3/actions/runs/40272141414) en verde; push protection y Dependabot security updates están activos. La primera corrida del PR, [40272771247](https://github.com/LautyUCC/ingesoft3/actions/runs/40272771247), tuvo CI verde pero CodeQL detectó dos alertas altas. Tras corregirlas, [CI 40273070088](https://github.com/LautyUCC/ingesoft3/actions/runs/40273070088) y [CodeQL 40273066679](https://github.com/LautyUCC/ingesoft3/actions/runs/40273066679) quedaron verdes; publicación y deploy se saltearon por ser PR. **TP6–TP9 siguen incompletos**: faltan merge autorizado, corridas reales de QA/PROD desde `main`, imágenes GHCR públicas, gate rechazado/aprobado, rollback medido, demostración E2E roja, tags/releases, PR Dependabot, Sentry y monitor externo. El equipo local deberá quedar encendido para el fallback.
**Ingeniería de Software III — UCC — Ciclo 2026**  
**Última actualización:** Viernes 23 de octubre de 2026, 13:33 ART  
**Alumno:** Lautaro Alejo Vallino (Legajo: 2301009) — Comisión 2  
**Fecha de entrega:** Lunes 26 de octubre de 2026, 23:59 ART  
**Defensa asignada:** Viernes 6 de noviembre de 2026, 13:30 ART  

---

## 1. Diagnóstico del Entorno Local y Herramientas

| Herramienta | Versión / Estado Detectado | Ubicación | Observaciones |
|---|---|---|---|
| **Git** | 2.50.1 | `/opt/homebrew/bin/git` | Rama actual: `main`. Totalmente sincronizado con `origin/main`. |
| **GitHub CLI (`gh`)** | 2.102.0 | `/opt/homebrew/bin/gh` | Autenticado como `LautyUCC`. Operativo. |
| **Node.js** | v26.10.0 | `/opt/homebrew/bin/node` | Compatible (engines de package.json pide `>=20`). |
| **npm** | 11.19.1 | `/opt/homebrew/bin/npm` | Funcional. |
| **Typst** | 0.15.1 | `/opt/homebrew/bin/typst` | Operativo para generación de manuales y guías en PDF. |
| **Docker Engine** | 29.8.2 | `/usr/local/bin/docker` | Instalado (Docker Desktop). |
| **Terraform** | Pendiente | Requiere instalación | Se instalará vía Homebrew para el TP8. |
| **Repositorio Cátedra** | Clonado | `/Users/lautyvallino/Projects/catedra_tps_2026` | Consignas oficiales y pautas de defensa auditadas al 100%. |

---

## 2. Línea Base del Repositorio (`LautyUCC/ingesoft3`)

- **Estado Git**:
  - Rama estable: `main` (commit `3f9ae98` correspondiente al merge del PR #16).
  - Tags y releases vigentes: `tp1`, `v1.0.0`, `tp2`, `tp3`, `tp4`, `v4.0.0`, `tp5`, `v5.0.0`.
  - Release publicada: [v5.0.0 — Calidad automatizada y Quality Gate](https://github.com/LautyUCC/ingesoft3/releases/tag/v5.0.0).
- **Suite de Pruebas Implementada**:
  - Comando: `npm run test:check-coverage` en `backend/`.
  - Total de casos: **32 tests unitarios** (11 de validación, 5 de autenticación con mock, 16 de pricing parametrizados y bordes).
  - Resultado: **32 passed**, 0 failed (duración: 87 ms).
- **Cobertura de Código (`c8`)**:
  - Statements: 100% (86/86)
  - Branches: 70.58% (48/68)
  - Functions: 100% (9/9)
  - Lines: 100% (86/86)
- **Pipeline CI con Quality Gate (`.github/workflows/ci.yml`)**:
  - Job `build-backend` corre `npm run test:check-coverage` (umbral: 80% líneas, 70% ramas).
  - Step Summary en Markdown generado automáticamente.
  - Artefacto descargable `backend-coverage-report` disponible en cada corrida.
  - Rompe el build si la cobertura no alcanza el umbral.
- **Material de Estudio y Defensa generado**:
  - `docs/defensa/TP5-Testing-y-Calidad.md` (fuente Markdown editable).
  - `docs/defensa/TP5-Testing-y-Calidad.typ` (fuente tipográfica).
  - `docs/defensa/TP5-Testing-y-Calidad.pdf` (documento compilado de 11 páginas con secciones A a H, 10 preguntas resueltas y las 3 preguntas más difíciles).

---

## 3. Evidencias Verificadas del TP5

1. **Pull Request 1 (Demostración Rojo → Tests → Verde → Merge):**
   - **PR:** [Pull Request #16](https://github.com/LautyUCC/ingesoft3/pull/16) — **MERGEADO en `main`**.
   - Commit 1 (`0f0f718`): Fallo por umbral de cobertura (Líneas 55.81% < 80%, Ramas 59.61% < 70%). [Actions Run #39985482676](https://github.com/LautyUCC/ingesoft3/actions/runs/39985482676).
   - Commit 2 (`e4790fd`): Incorporación de tests unitarios (32 tests pasando, 100% líneas, 70.58% ramas). [Actions Run #39985690914](https://github.com/LautyUCC/ingesoft3/actions/runs/39985690914).
   - Commit 3 (`c023606`): Documentación técnica y manual de defensa PDF. [Actions Run #39986544907](https://github.com/LautyUCC/ingesoft3/actions/runs/39986544907).
   - Corrida de push en `main`: [Actions Run #39987211593](https://github.com/LautyUCC/ingesoft3/actions/runs/39987211593) (exitosa en verde).

2. **Pull Request 2 (Gate bloqueado y abierto hasta la defensa):**
   - **PR:** [Pull Request #17](https://github.com/LautyUCC/ingesoft3/pull/17) — **ABIERTO y BLOQUEADO**.
   - Rama: `demo/tp5-gate-bloqueado` (contiene `loyaltyService.js` sin tests unitarios).
   - Fallo en required check `build-backend`: Líneas 64.17% < 80%, Ramas 69.56% < 70%. [Actions Run #39987399842](https://github.com/LautyUCC/ingesoft3/actions/runs/39987399842).
   - Estado: Permanece abierto y en rojo para su verificación en vivo durante la defensa oral.

3. **Release y Tags:**
   - Tag académico: `tp5`.
   - Release formal: [v5.0.0](https://github.com/LautyUCC/ingesoft3/releases/tag/v5.0.0).

---

## 4. Estado de Avance por Trabajo Práctico

| Trabajo Práctico | Estado | % Completado | Próxima Acción |
|---|---|:---:|---|
| **TP5: Testing y Calidad** | **COMPLETADO** | **100%** | Defendido en base al manual `docs/defensa/TP5-Testing-y-Calidad.pdf`. |
| **TP6: CD & Environments** | No iniciado | 0% | Crear base de datos en Neon y servicios en Render para QA y PROD. |
| **TP7: Contenedores & E2E** | No iniciado | 0% | Configurar Playwright y suites de integración/e2e. |
| **TP8: IaC (Terraform)** | No iniciado | 0% | Instalar Terraform y estructurar carpeta `infra/`. |
| **TP9: DevSecOps & Observab.**| No iniciado | 0% | Configurar Dependabot, CodeQL, UptimeRobot y Sentry. |

---

## 5. Próximo Paso Inmediato (TP6: Continuous Delivery)

1. Crear proyecto PostgreSQL en Neon con bases de datos independientes:
   - `photomatch_qa`
   - `photomatch_prod`
2. Configurar servicios Web en Render (Plan Free) para Backend y Frontend en ambos entornos con Auto-Deploy en OFF.
3. Extender `.github/workflows/ci.yml` para:
   - Publicar imágenes inmutables en GitHub Container Registry (`ghcr.io`) solo en pushes a `main` tras pasar los tests y quality gates.
   - Configurar GitHub Environments `qa` y `production`.
   - Despliegue automático a QA mediante Render Deploy Hook.
   - Smoke test automatizado con reintentos para soportar cold starts.
   - Gate de aprobación manual con Required Reviewer para el entorno `production`.
   - Evidencia de rechazo documentado y posterior promoción aprobada a PROD.
   - Prueba y cronometrado de rollback en Render.
4. Generar el manual de estudio `docs/defensa/TP6-Continuous-Delivery.pdf` (y `.md`).
5. Crear tag y release `v6.0.0`.
