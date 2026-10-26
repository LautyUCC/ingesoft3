# Estado Real P2 — PhotoMatch

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
