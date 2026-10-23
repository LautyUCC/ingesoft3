# Estado Real P2 — PhotoMatch
**Ingeniería de Software III — UCC — Ciclo 2026**  
**Última actualización:** Viernes 23 de octubre de 2026, 13:25 ART  
**Alumno:** Lautaro Alejo Vallino (Legajo: 2301009) — Comisión 2  
**Fecha de entrega:** Lunes 26 de octubre de 2026, 23:59 ART  
**Defensa asignada:** Viernes 6 de noviembre de 2026, 13:30 ART  

---

## 1. Diagnóstico del Entorno Local y Herramientas

| Herramienta | Versión / Estado Detectado | Ubicación | Observaciones |
|---|---|---|---|
| **Git** | 2.50.1 | `/opt/homebrew/bin/git` | Rama actual: `feature/tp5-suite-calidad`. PR #16 abierto y en verde. |
| **GitHub CLI (`gh`)** | 2.102.0 | `/opt/homebrew/bin/gh` | Autenticado como `LautyUCC`. Operativo. |
| **Node.js** | v26.10.0 | `/opt/homebrew/bin/node` | Compatible (engines de package.json pide `>=20`). |
| **npm** | 11.19.1 | `/opt/homebrew/bin/npm` | Funcional. |
| **Typst** | 0.15.1 | `/opt/homebrew/bin/typst` | Instalado vía Homebrew para generación de manuales PDF de alta calidad. |
| **Docker Engine** | 29.8.2 | `/usr/local/bin/docker` | Instalado (Docker Desktop). |
| **Terraform** | Pendiente | Requiere instalación | Se instalará para el TP8. |
| **Repositorio Cátedra** | Clonado | `/Users/lautyvallino/Projects/catedra_tps_2026` | Consignas oficiales y pautas de defensa auditadas al 100%. |

---

## 2. Línea Base del Repositorio (`LautyUCC/ingesoft3`)

- **Estado Git**:
  - Rama base: `main` (protegida con `build-backend` y `build-frontend` como required checks).
  - Rama de trabajo: `feature/tp5-suite-calidad`.
  - Tags existentes: `tp1`, `v1.0.0`, `tp2`, `tp3`, `tp4`, `v4.0.0`.
- **Suite de Pruebas Implementada**:
  - Comando: `npm run test:check-coverage` en `backend/`.
  - Total de casos: **32 tests unitarios** (11 de validación, 5 de autenticación con mock, 16 de pricing parametrizados y bordes).
  - Resultado: **32 passed**, 0 failed (duración: 87 ms).
- **Cobertura alcanzada (`c8`)**:
  - Statements: 100% (86/86)
  - Branches: 70.58% (48/68)
  - Functions: 100% (9/9)
  - Lines: 100% (86/86)
- **Pipeline CI con Quality Gate (`.github/workflows/ci.yml`)**:
  - Job `build-backend` corre `npm run test:check-coverage` (umbral: 80% líneas, 70% ramas).
  - Publica reporte detallado en `$GITHUB_STEP_SUMMARY`.
  - Sube artefacto `backend-coverage-report` descargable.
  - Rompe el build si la cobertura no alcanza el umbral.
- **Material de Estudio y Defensa generado**:
  - `docs/defensa/TP5-Testing-y-Calidad.md` (fuente Markdown editable).
  - `docs/defensa/TP5-Testing-y-Calidad.typ` (fuente tipográfica).
  - `docs/defensa/TP5-Testing-y-Calidad.pdf` (documento compilado de 11 páginas con secciones A a H, 10 preguntas frecuentes y las 3 preguntas más difíciles).

---

## 3. Evidencias Verificadas del TP5

1. **Pull Request 1 (Demostración Rojo → Tests → Verde → Merge):**
   - PR: [Pull Request #16](https://github.com/LautyUCC/ingesoft3/pull/16)
   - Commit 1 (`0f0f718`): Fallo por umbral de cobertura (Líneas 55.81% < 80%, Ramas 59.61% < 70%). [Actions Run #39985482676](https://github.com/LautyUCC/ingesoft3/actions/runs/39985482676)
   - Commit 2 (`e4790fd`): Incorporación de tests unitarios (32 tests pasando, 100% líneas, 70.58% ramas). [Actions Run #39985690914](https://github.com/LautyUCC/ingesoft3/actions/runs/39985690914)
   - Commit 3 (`c023606`): Documentación técnica y manual de defensa PDF. [Actions Run #39986544907](https://github.com/LautyUCC/ingesoft3/actions/runs/39986544907)
   - Estado actual: **Checks en verde, listo para mergear tras autorización**.

2. **Pull Request 2 (Gate bloqueado y abierto hasta la defensa):**
   - Pendiente de creación tras mergear PR #16 sobre `main`.
   - Rama a crear: `demo/tp5-gate-bloqueado`.

---

## 4. Estado de Avance por Trabajo Práctico

| Trabajo Práctico | Estado | % Completado | Próxima Acción |
|---|---|:---:|---|
| **TP5: Testing y Calidad** | En progreso | 85% | Solicitar autorización para mergear PR #16, crear PR #2 bloqueado y taggear `v5.0.0`. |
| **TP6: CD & Environments** | No iniciado | 0% | Crear bases de datos en Neon y servicios en Render. |
| **TP7: Contenedores & E2E** | No iniciado | 0% | Configurar Playwright y suites de integración/e2e. |
| **TP8: IaC (Terraform)** | No iniciado | 0% | Instalar Terraform y estructurar carpeta `infra/`. |
| **TP9: DevSecOps & Observab.**| No iniciado | 0% | Configurar Dependabot, CodeQL, UptimeRobot y Sentry. |

---

## 5. Próximo Paso Inmediato

1. Solicitar autorización del usuario para mergear el PR #16 (`feature/tp5-suite-calidad` -> `main`).
2. Actualizar `main` localmente con `git pull`.
3. Crear rama `demo/tp5-gate-bloqueado` desde `main`, agregar código nuevo sin tests para romper el umbral y abrir PR #17 (que permanecerá abierto y en rojo hasta la defensa oral).
4. Crear tag y release `v5.0.0` sobre `main`.
5. Pasar formalmente al desarrollo del **TP6 (Continuous Delivery & Environments)**.
