# Plan de Trabajo P2 — PhotoMatch (TP5 a TP9)

> **Actualización 26/10/2026:** se eligió el fallback local permitido en TP6–TP8 porque no hay cuentas Neon/Render. La implementación verificable está en el PR #18; el estado y los faltantes actuales están en `ESTADO-P2.md`. Las tablas siguientes conservan la planificación original y sus rutas Render/Neon como referencia histórica. Orden de cierre restante: (1) integrar PR con autorización y comprobar GHCR + QA; (2) demostrar rechazo, aprobación y rollback reales de PROD; (3) demostrar E2E roja por fallo de app, fix y promoción; (4) repetir Terraform con imágenes GHCR; (5) configurar Sentry/monitor y cerrar evidencias de TP9; (6) crear cada release sólo cuando su TP cumpla la consigna.
**Ingeniería de Software III — Universidad Católica de Córdoba (UCC) — Ciclo 2026**  
**Alumno:** Lautaro Alejo Vallino (Legajo: 2301009) — Comisión 2  
**Fecha límite de entrega:** Lunes 26 de octubre de 2026 a las 23:59  
**Fecha y horario de defensa oral:** Viernes 6 de noviembre de 2026 a las 13:30 (10:00 min)  
**Repositorio:** [https://github.com/LautyUCC/ingesoft3](https://github.com/LautyUCC/ingesoft3)  
**Repositorio oficial cátedra:** [https://github.com/ingsoft3ucc/TPs_2026](https://github.com/ingsoft3ucc/TPs_2026)  

---

## 1. Resumen Ejecutivo y Diagnóstico Inicial

PhotoMatch es una aplicación monolítica modular en Node.js + Express con vistas renderizadas en servidor mediante EJS, base de datos PostgreSQL y frontend proxy/assets en Nginx. Durante P1 (TP1–TP4) se establecieron las bases de Git Flow, Docker multi-stage, GitHub Projects y CI con GitHub Actions y caché de capas en Buildx.

Para P2 (TP5 a TP9), el foco cambia de la verificación aislada a la **calidad exigida por contrato, entrega continua a entornos reales, inmutabilidad de imágenes, infraestructura como código y operación segura/observada**.

### Reglas críticas de la cátedra para P2 (defensa-P2.pdf y consignas):
1. **Se corrige lo que está en `main` al corte (lunes 26/10 23:59)**: no se corrige lo que se suba después. Se evalúa el commit de cada release.
2. **Las cinco releases obligatorias**: `v5.0.0`, `v6.0.0`, `v7.0.0`, `v8.0.0` y `v9.0.0`. La `v7.0.0` debe apuntar al commit exacto que está corriendo en PROD.
3. **`decisiones.md` acumulativo**: con una sección por cada TP. Arriba de todo, los enlaces del TP6 y TP7 (paquetes públicos ghcr.io, URLs de QA y PROD, corridas clave). **No hay `evidencias.md` en P2** (todo es público y navegable en GitHub, Render, Neon, Sentry).
4. **Entornos QA y PROD vivos hasta la defensa**: se navegan en vivo en la mesa evaluadora.
5. **PR frenado del TP5 abierto y en rojo**: debe permanecer abierto en GitHub hasta el día de la defensa para probar que el quality gate funciona y no puede mergearse.
6. **Carpeta `infra/` lista para correr**: en la defensa se solicita `terraform plan` o `apply` desde la terminal.
7. **Sentry y monitor Uptime**: histórico con vigencia menor a 30 días (con error real y caída registrada).
8. **Evaluación 50% repositorio + 50% defensa oral (10 minutos con reloj)**: "Si no lo podés explicar, no lo aprobás — aunque funcione".

---

## 2. Matriz de Requisitos Oficiales vs. Estado Actual

| TP | Requisitos Obligatorios | Estado Actual | Qué Falta Implementar | Evidencias Requeridas | Riesgos y Dificultades |
|---|---|---|---|---|---|
| **TP5: Testing y Calidad** | • Backend: mín. 8 unit tests (AAA, ≥4 reglas de negocio, 1 parametrizado, 1 error/borde, 1 con MOCK obligatorio).<br>• Frontend: justificación formal en `decisiones.md` (no aplica JS cliente al ser EJS server-rendered, regla explícita de cátedra).<br>• Cobertura medida en pipeline con reporte y summary.<br>• Umbral estricto que **rompe el build** si no se cumple.<br>• Exclusiones justificadas (db/init, views, app.js).<br>• Quality gate en branch protection de `main`.<br>• **2 PRs**: PR1 completo (rojo→tests→verde→merge) y PR2 (abierto y en rojo hasta la defensa).<br>• Ejercicio del camino sin cubrir (línea, input, decisión).<br>• Release `v5.0.0`. | **Parcial**<br>(Existen 11 tests unitarios de validación en `validationService.test.js`, pero falta el mock, parametrizados explícitos, coverage en CI, umbral y los 2 PRs). | • Refactorizar `authService.js` para inyectar `userRepository` y crear test con mock nativo (`node:test`).<br>• Agregar tests parametrizados para reglas de pricing y coberturas.<br>• Integrar `c8` para coverage y umbral (`--check-coverage`).<br>• Actualizar `.github/workflows/ci.yml` para correr tests y verificar umbral.<br>• Ejecutar el flujo de los dos PRs (mergeado y bloqueado abierto).<br>• Completar sección TP5 en `decisiones.md`.<br>• Crear tag y release `v5.0.0`. | • Run de PR con tests verdes.<br>• Run rojo por umbral.<br>• PR1 mergeado.<br>• PR2 abierto y en rojo.<br>• Release `v5.0.0`. | • Calibrar el umbral exacto para que el PR bloqueado falle por cobertura y no por error de sintaxis o tests rotos. |
| **TP6: CD & Environments** | • Publicación de imágenes en GitHub Container Registry (`ghcr.io`) solo en `main` tras tests verdes.<br>• Paquetes públicos (`docker pull` sin credenciales).<br>• Despliegue automático a entorno QA real (Render + Neon).<br>• Smoke test post-deploy con reintentos.<br>• Gate humano a PROD con Required Reviewer en environment `production`.<br>• Evidencia de rechazo justificado.<br>• Despliegue de PROD aprobado + smoke test.<br>• Plan de rollback cronometrado y probado en Render.<br>• Release `v6.0.0`. | **Pendiente**<br>(Pipeline actual tiene `push: false`; no hay environments de GitHub ni cuentas de Render/Neon conectadas). | • Configurar base de datos Neon (databases separadas `photomatch_qa` y `photomatch_prod`).<br>• Configurar servicios en Render con Auto-Deploy en OFF.<br>• Crear GitHub Environments (`qa` y `production`) y secrets (deploy hooks, URLs).<br>• Extender `ci.yml` con jobs `deploy-qa`, smoke test, `deploy-prod`.<br>• Generar corrida con rechazo en PROD y corrida con aprobación.<br>• Ejecutar rollback cronometrado en Render.<br>• Documentar en `decisiones.md` con enlaces arriba.<br>• Release `v6.0.0`. | • Paquetes en `ghcr.io` públicos.<br>• Run de PR con step publish salteado.<br>• Run de `main` con publish como último step.<br>• URLs activas QA y PROD.<br>• Corridas con rechazo y aprobación.<br>• Tiempo de rollback registrado.<br>• Release `v6.0.0`. | • Cold start de Render free tier puede hacer fallar el smoke test si los timeouts o reintentos son insuficientes.<br>• Disponibilidad de cuota free tier. |
| **TP7: Contenedores & E2E** | • Build once, deploy many: Render ejecuta la imagen inmutable del registry vía deploy hook `imgURL=...:sha-<commit>`.<br>• Suite de integración (3 tests en `frontend/e2e/api.spec.js` con Playwright `request` sin browser contra API de QA con DB real: CRUD con timestamp único, alta inválida 400, tercera regla).<br>• Suite E2E (3 flujos críticos con Playwright browser contra QA: creación, error, flujo diario; limpieza de datos).<br>• Pipeline con gate completo: `deploy-qa` → `integracion` → `e2e` → `deploy-prod`.<br>• Demostración de gate rojo: commit rompiendo la app (no el test), integración verde, e2e roja, deploy-prod bloqueado → fix → verde hasta PROD.<br>• Release `v7.0.0` sobre el commit de PROD. | **Pendiente**<br>(No hay Playwright instalado ni suites e2e/integración). | • Adaptar deploy hooks de Render con parámetro `imgURL`.<br>• Instalar Playwright en el proyecto.<br>• Implementar endpoints REST o adaptadores para integración y tests E2E con limpieza.<br>• Agregar jobs `integracion` y `e2e` al workflow con subida de artefactos de reporte Playwright.<br>• Ejecutar simulación de fallo en frontend (integración verde, e2e roja) y posterior corrección.<br>• Crear release `v7.0.0` sobre el commit verificado en PROD.<br>• Documentar en `decisiones.md`. | • Enlaces a imágenes `sha-<commit>`.<br>• Run con integración verde y e2e roja.<br>• Reportes Playwright subidos como artefactos.<br>• Run verde completo a PROD.<br>• Release `v7.0.0` apuntando a PROD. | • Flakiness en Playwright por latencia de Render free tier.<br>• Garantizar que la rotura afecte solo a la UI (e2e) manteniendo la API (integración) intacta. |
| **TP8: IaC (Terraform)** | • Entorno `preprod` declarado en carpeta `infra/` con Terraform.<br>• Providers fijados por versión en `versions.tf` / `.terraform.lock.hcl`.<br>• Sin credenciales en HCL (variables de entorno o tfvars ignorados).<br>• Cadenas y URLs derivadas dinámicamente.<br>• QA y PROD no se tocan.<br>• Ciclo de vida probado: `apply` crea preprod, `destroy` lo elimina cleanly.<br>• En la defensa: terminal lista para ejecutar plan/apply.<br>• Release `v8.0.0`. | **Pendiente**<br>(No existe carpeta `infra/` ni archivos Terraform). | • Instalar Terraform localmente vía Homebrew.<br>• Diseñar configuración en `infra/` (Neon project/branch + Render web service o plan C Docker provider).<br>• Probar `terraform init`, `validate`, `plan`, `apply` y `destroy`.<br>• Asegurar `.gitignore` para `.terraform/`, `.tfstate`, `*.tfvars`.<br>• Crear release `v8.0.0` e incorporar sección en `decisiones.md`. | • Código en carpeta `infra/` en `main`.<br>• `.terraform.lock.hcl` versionado.<br>• Release `v8.0.0`.<br>• Capacidad de ejecutar `plan` y `apply` en la defensa oral. | • Límites de servicios en Render free tier (solo permite cierta cantidad de web services simultáneos). Se debe evaluar si preprod se destruye inmediatamente tras validar o si se usa plan C Docker si hay bloqueo de API tokens. |
| **TP9: DevSecOps & Observabilidad** | • `dependabot.yml` activo en backend, frontend y GitHub Actions.<br>• Al menos 1 PR de Dependabot mergeado con pipeline en verde.<br>• CodeQL habilitado en GitHub Security.<br>• Secret scanning y Push Protection activos.<br>• Monitor externo (UptimeRobot) sobre `/health` de PROD.<br>• Caída provocada con alertas DOWN y UP registradas (y monitor pausado).<br>• Sentry integrado en backend (y frontend) capturando errores y performance.<br>• Tarjeta en GitHub Project nacida de una métrica observada.<br>• Release `v9.0.0`. | **Pendiente**<br>(Falta configuración de Dependabot, CodeQL, UptimeRobot y Sentry). | • Crear `.github/dependabot.yml`.<br>• Provocar o forzar actualización de dependencia menor y mergear PR vía CI.<br>• Configurar CodeQL workflow en `.github/workflows/codeql.yml` o default setup.<br>• Verificar Push Protection en repo settings.<br>• Configurar monitor en UptimeRobot y provocar fallo temporal de PROD.<br>• Integrar `@sentry/node` en backend y registrar error de prueba.<br>• Crear tarjeta en Project del TP3 con la operación analizada.<br>• Crear release `v9.0.0` y documentar en `decisiones.md`. | • Pestaña Security activa en GitHub.<br>• PR de Dependabot mergeado.<br>• Historial de UptimeRobot con evento DOWN/UP.<br>• Evento y transacciones en Sentry.<br>• Tarjeta en GitHub Projects.<br>• Release `v9.0.0`. | • Retención de 30 días de Sentry y UptimeRobot: los eventos deben ocurrir dentro del mes previo a la defensa (defensa: 6 de noviembre, hoy es 23 de octubre, por lo que quedan perfectamente vigentes). |

---

## 3. Arquitectura Técnica de PhotoMatch para P2

```
                                      [ GitHub Repository: LautyUCC/ingesoft3 ]
                                                         │
             ┌───────────────────────────────────────────┴───────────────────────────────────────────┐
             ▼                                                                                       ▼
       [ Pull Request ]                                                                        [ Push to main ]
             │                                                                                       │
      (Quality Gate)                                                                           (CI Pipeline)
• Unit Tests + AAA                                                                      • Build & Unit Tests
• c8 Coverage (Lines ≥80%, Branches ≥70%)                                               • c8 Coverage Check
• Falla si no alcanza umbral                                                            • Publish Images to ghcr.io
• PR bloqueado abierto (demo)                                                             (tags: sha-<commit>)
                                                                                                     │
                                                                                                     ▼
                                                                                               [ Deploy to QA ]
                                                                                        • Trigger Render Deploy Hook
                                                                                        • imgURL=ghcr.io/...:sha-<commit>
                                                                                        • Run Smoke Test (Retries)
                                                                                                     │
                                                                                                     ▼
                                                                                         [ Automated Testing Gate ]
                                                                                        • Integration Suite (Playwright)
                                                                                        • E2E Browser Suite (Playwright)
                                                                                                     │
                                                                                                     ▼
                                                                                         [ Manual Approval Gate ]
                                                                                        • GitHub Environment: production
                                                                                        • Required Reviewer (LautyUCC)
                                                                                        • Rejection evidence documented
                                                                                                     │
                                                                                                     ▼
                                                                                            [ Deploy to PROD ]
                                                                                        • Same sha-<commit> promoted
                                                                                        • Neon DB (Production)
                                                                                        • UptimeRobot Monitor + Sentry
```

---

## 4. Plan de Ejecución por Etapas Detalladas

### Fase 1: TP5 — Calidad Automatizada y Freno de Cobertura
1. **Refactor y Suite de Tests Unitarios**:
   - Refactorizar `backend/src/services/authService.js` para desacoplar el acceso a base de datos permitiendo inyección de dependencias (`userRepository`).
   - Crear test unitario con mock en `backend/test/authService.test.js` utilizando la librería nativa de Node.js `node:test` (`mock.fn` o doble controlado).
   - Añadir tests parametrizados para las reglas de negocio de `pricingService.js` (productos single, pack6, all, validaciones de fotos).
   - Verificar que existan mínimo 8 métodos de prueba sobre al menos 4 reglas de negocio distintas con estructura AAA.
2. **Cobertura con Umbral Estricto**:
   - Configurar `c8` en `backend/package.json` con scripts `"test": "node --test"` y `"test:coverage": "c8 --check-coverage --lines 80 --branches 70 --reporter=text --reporter=html --reporter=lcov node --test"`.
   - Definir exclusiones precisas en `.c8rc.json` o configuración: excluir `src/db/`, `src/app.js`, archivos de configuración de arranque.
   - Modificar `.github/workflows/ci.yml` para ejecutar la cobertura, publicar el reporte en Step Summary y como artefacto descargable.
3. **Quality Gate y Demostración Rojo/Verde**:
   - Rama `feature/tp5-suite-calidad`: introducir nueva lógica y tests, abrir PR1.
   - Demostrar el freno: incluir un módulo nuevo sin tests suficientes que rompa el umbral de cobertura (pipeline rojo por umbral).
   - Agregar los tests faltantes, verificar que el pipeline se pone verde y mergear PR1 a `main`.
   - Rama `demo/tp5-gate-bloqueado`: crear PR2 con una regla sin cobertura para que el required check de cobertura quede en rojo. Dejar este PR **abierto y en rojo hasta la defensa**.
4. **Cierre de TP5**:
   - Crear tag y release `v5.0.0`.
   - Redactar sección TP5 en `decisiones.md` (con ejercicio del camino sin cubrir y enlaces de las corridas y PRs).

### Fase 2: TP6 — CD: Environments, Aprobaciones y Promoción
1. **Infraestructura Cloud Inicial**:
   - Crear proyecto en Neon PostgreSQL con bases separadas `photomatch_qa` y `photomatch_prod`.
   - Crear servicios Web en Render para Backend y Frontend en QA y PROD (Auto-Deploy en OFF).
2. **Pipeline de Entrega**:
   - Configurar GitHub Container Registry (`ghcr.io`) para publicar imágenes etiquetadas con `sha-<commit>` solo en pushes a `main` tras pasar la verificación de tests.
   - Paquetes marcados como públicos.
   - Configurar GitHub Environments `qa` y `production`.
   - Implementar steps de deploy hook hacia Render y smoke test con reintentos mediante curl/fetch en `ci.yml`.
3. **Gate Humano y Rollback**:
   - Configurar required reviewer en environment `production`.
   - Ejecutar corrida con rechazo documentado.
   - Ejecutar corrida con aprobación y despliegue exitoso a PROD.
   - Probar y cronometrar un rollback real en Render, registrando los tiempos exactos.
4. **Cierre de TP6**:
   - Crear tag y release `v6.0.0`.
   - Redactar sección TP6 en `decisiones.md` y agregar arriba los "Enlaces de este TP" (paquetes, corridas, URLs QA y PROD).

### Fase 3: TP7 — Contenedores en Pipeline, Integración y E2E
1. **Inmutabilidad de la Imagen**:
   - Configurar Render para recibir el parámetro `imgURL` en el deploy hook, ejecutando exactamente la imagen `ghcr.io/lautyucc/...:sha-<commit>`.
2. **Suites de Pruebas**:
   - Instalar e inicializar Playwright.
   - Escribir suite de integración `frontend/e2e/api.spec.js` (3 pruebas con `request` contra API de QA con base real, identificadores con timestamp, validación 400 y borrado).
   - Escribir suite E2E `frontend/e2e/app.spec.js` (3 flujos críticos con navegador contra URL de QA).
3. **Pipeline con Gate de Promoción**:
   - Cadena de jobs en `ci.yml`: `deploy-qa` → `integracion` → `e2e` → `deploy-prod`.
   - Provocar rotura en UI (frontend) para demostrar integración verde + e2e roja frenando la promoción a PROD.
   - Reparar la rotura, verificar corrida completa verde y aprobación.
4. **Cierre de TP7**:
   - Crear tag y release `v7.0.0` sobre el commit exacto desplegado en PROD.
   - Completar sección TP7 en `decisiones.md`.

### Fase 4: TP8 — Infraestructura como Código (IaC) con Terraform
1. **Configuración Terraform**:
   - Instalar `terraform` localmente.
   - Crear directorio `infra/` con `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`.
   - Declarar entorno `preprod` (Neon + Render o provider Docker para plan C).
   - Derivar dinámicamente URLs y cadenas de conexión.
2. **Ciclo de Vida**:
   - Ejecutar `terraform init`, `terraform plan`, `terraform apply`.
   - Validar endpoint de vida y conectividad de preprod.
   - Ejecutar `terraform destroy` para comprobar que nace y muere cleanly sin afectar QA ni PROD.
3. **Cierre de TP8**:
   - Crear tag y release `v8.0.0`.
   - Redactar sección TP8 en `decisiones.md`.

### Fase 5: TP9 — DevSecOps y Observabilidad
1. **Seguridad Shift-Left**:
   - Configurar `.github/dependabot.yml` para backend, frontend y actions.
   - Provocar una actualización de dependencia y mergear su PR con pipeline verde.
   - Activar análisis de CodeQL y verificar escaneo en GitHub Security.
   - Verificar Push Protection activa en Settings de GitHub.
2. **Observabilidad Externa y de Aplicación**:
   - Crear monitor en UptimeRobot hacia `/health` de PROD.
   - Provocar caída temporal en PROD, registrar notificación DOWN y recuperación UP. Pausar monitor.
   - Integrar Sentry (`@sentry/node`) en backend de PhotoMatch, capturar excepción real y telemetría de transacciones.
   - Identificar operación más lenta o con error y crear tarjeta en el GitHub Project.
3. **Cierre de TP9**:
   - Crear tag y release `v9.0.0`.
   - Redactar sección TP9 en `decisiones.md`.

### Fase 6: Consolidación, Auditoría Final y Preparación de Defensa
1. Revisar que `decisiones.md` contenga las secciones de TP1 a TP9 sin faltantes y con todos los links verificables.
2. Asegurar que QA y PROD respondan rápidamente (calentar instancias).
3. Verificar que el PR frenado de TP5 permanezca abierto y en rojo.
4. Completar el Formulario P2 oficial de la cátedra con los datos exactos.
5. Ensayo del cuestionario de 10 minutos de defensa según las preguntas guía de cada TP.

---

## 5. Cronograma Recomendado

- **Viernes 23 (Tarde/Noche)**:
  - Completar TP5 al 100% (tests, mock, coverage, umbral, los 2 PRs, release v5.0.0).
  - Iniciar setup cloud para TP6 (cuentas Neon y Render, secrets).
- **Sábado 24**:
  - Completar TP6 (pipeline deploy QA/PROD, required review, rollback medido, release v6.0.0).
  - Completar TP7 (Playwright integración y e2e, demostración gate rojo->verde, release v7.0.0 sobre PROD).
- **Domingo 25**:
  - Completar TP8 (Terraform infra/ preprod, pruebas apply/destroy, release v8.0.0).
  - Completar TP9 (Dependabot, CodeQL, Push Protection, UptimeRobot, Sentry, board card, release v9.0.0).
- **Lunes 26 (Día de Entrega - Cierre 23:59)**:
  - Auditoría general exhaustiva de URLs, paquetes en ghcr.io, releases y enlaces de `decisiones.md`.
  - Carga formal del formulario P2 de la cátedra.
  - Simulacro oral de defensa.
