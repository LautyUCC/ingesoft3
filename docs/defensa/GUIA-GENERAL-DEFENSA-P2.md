# Guía Maestra de Estudio y Defensa — PhotoMatch Parte 2 (TP5 a TP9)
**Materia:** Ingeniería de Software III — Universidad Católica de Córdoba (UCC)  
**Ciclo Lectivo:** 2026  
**Alumno:** Lautaro Alejo Vallino (Legajo: 2301009) — Comisión 2  
**Aplicación:** PhotoMatch (Gestión de coberturas fotográficas deportivas)  
**Fecha de Entrega:** Lunes 26 de octubre de 2026, 23:59 ART  
**Defensa Oral:** Viernes 6 de noviembre de 2026, 13:30 ART (10 minutos)

---

## 1. Visión General de la Parte 2 (TP5 – TP9)

La Parte 2 de Ingeniería de Software III transforma la aplicación PhotoMatch de un monolito con pruebas unitarias iniciales a un sistema de grado empresarial con ingeniería de software rigurosa, automatización de punta a punta, infraestructura declarativa, seguridad proactiva y observabilidad en tiempo real.

```
       [ DESARROLLADOR ]
              |  git push
              v
   [ GitHub Repository ] <--- Secret Scanning & Push Protection (TP9)
              |
              +--- Pull Request ---> CodeQL SAST & Dependabot SCA (TP9)
              |                      Quality Gate Cobertura c8 >=80% (TP5)
              |                      (PR #17 permanece bloqueado como demo)
              v  merge a main
   [ GitHub Actions CI/CD ]
              |
              +---> Job: build-backend & build-frontend (TP6)
              |     (Compilan imágenes una sola vez y exportan .tar)
              |
              +---> Job: publish (TP6)
              |     (Publica en GHCR: sha-<COMMIT>)
              |
              +---> Job: deploy-qa (TP6)
              |     (Despliega en QA local :3001)
              |     (Ejecuta smoke.sh: /health 200 OK + DB)
              |
              +---> Job: integracion (TP7)
              |     (3/3 pruebas API con Playwright contra PostgreSQL real)
              |
              +---> Job: e2e (TP7)
              |     (3/3 flujos con Chromium headless contra QA)
              |     [SI FALLA: deploy-prod se bloquea / omite (PR #37)]
              |
              +---> Job: deploy-prod (TP6 & TP7)
                    (Requiere APROBACIÓN HUMANA de LautyUCC)
                    (Despliega en PROD local :3002)
                    (Sondeado por UptimeRobot y vigilado por Sentry)
```

---

## 2. Matriz Consolidada de Entregables Oficiales

| TP | Eje Temático | Release Git | Evidencia Principal | Demostración Obligatoria para Defensa |
|---|---|:---:|---|---|
| **TP5** | Testing Automatizado y Quality Gates | `v5.0.0` | Cobertura `c8` (100% líneas, 72,4% ramas). PR #16 merged. | **[PR #17](https://github.com/LautyUCC/ingesoft3/pull/17) (`demo/tp5-gate-bloqueado`):** Abierto y bloqueado en rojo hasta la defensa oral. |
| **TP6** | Continuous Delivery y Ambientes Aislados | `v6.0.0` | Pipeline desacoplado (build $\rightarrow$ publish $\rightarrow$ deploy). Fallback local en runner propio. QA (:3001) y PROD (:3002). | **Gate Rechazado:** CI Run 40277582164 con motivo auditado. **Rollback:** Recreación de contenedores en 7,42 s. |
| **TP7** | Contenedores, Integración y E2E | `v7.0.0` | 3 pruebas API y 3 pruebas E2E con Playwright. Multi-stage Docker con Nginx reverse proxy. | **Gate E2E Rojo:** [PR #37](https://github.com/LautyUCC/ingesoft3/pull/37) / CI Run 40283556436 (E2E falló, PROD bloqueado). Recuperación verde en [PR #39](https://github.com/LautyUCC/ingesoft3/pull/39). |
| **TP8** | Infraestructura como Código (Terraform) | `v8.0.0` | Módulo `infra/` con provider Docker 4.6.0. 8 recursos declarados con derivación dinámica y secrets seguros. | **Ciclo de vida en vivo:** `plan` (8 altas) $\rightarrow$ `apply` (preprod :3003 200 OK) $\rightarrow$ segundo `plan` (0 cambios, idempotente) $\rightarrow$ `destroy`. |
| **TP9** | DevSecOps y Observabilidad en Tiempo Real | `v9.0.0` | Dependabot PR #30 merged. CodeQL verde. Mitigación ReDoS y DoS. Sentry APM. UptimeRobot. | **Sentry:** Incidente [PHOTOMATCH-BACKEND-1](https://lauty-vallino.sentry.io/issues/7812452027/) $\rightarrow$ [Issue #38](https://github.com/LautyUCC/ingesoft3/issues/38) en Project. **UptimeRobot:** [Incidente 503/UP #372997347011072787](https://dashboard.uptimerobot.com/incidents/372997347011072787). |

---

## 3. Guion Estratégico para la Defensa Oral (10 Minutos)

### Minuto 0:00 - 2:00 — TP5: Calidad Contractual y Quality Gate
- **Mensaje Clave:** *"La calidad en PhotoMatch no es un deseo declarativo; es una restricción contractual bloqueante en el pipeline."*
- **Qué Mostrar:**
  1. Abrir GitHub y mostrar el **[PR #17](https://github.com/LautyUCC/ingesoft3/pull/17)**.
  2. Explicar que todos los 32 tests pasan, pero la falta de cobertura en `loyaltyService.js` rompe el Quality Gate (`c8`) por no alcanzar el 80% de líneas.
  3. Mostrar que el botón de merge está deshabilitado por GitHub Branch Protection.

### Minuto 2:00 - 4:00 — TP6: Continuous Delivery, "Build Once" y Ambientes Aislados
- **Mensaje Clave:** *"Construimos una sola vez, publicamos artefactos inmutables en GHCR y protegemos Producción con gates humanos auditables."*
- **Qué Mostrar:**
  1. Mostrar en `.github/workflows/ci.yml` la separación entre build, publish y deploy.
  2. Explicar cómo el artefacto `.tar` viaja al job de publish para no recompilar.
  3. Enseñar la corrida rechazada (CI 40277582164) con el justificativo formal de negocio.
  4. Mostrar el rollback medido en 7,42 segundos recreando el contenedor anterior en Docker sin pérdida de datos en el volumen de PostgreSQL.

### Minuto 4:00 - 6:00 — TP7: Calidad Funcional y el Gate E2E Rojo
- **Mensaje Clave:** *"Si la interfaz de usuario se rompe, el pipeline protege la producción antes de que los clientes la sufran."*
- **Qué Mostrar:**
  1. Explicar las 3 pruebas de integración con Playwright API (`api.spec.js`) y las 3 de navegador (`app.spec.js`).
  2. Abrir la corrida **[CI 40283556436](https://github.com/LautyUCC/ingesoft3/actions/runs/40283556436)** del PR #37: mostrar que `integracion` fue verde (API intacta), pero `e2e` falló en rojo por el formulario roto, y `deploy-prod` figura en gris (*Skipped*).
  3. Abrir la corrida **[CI 40284305415](https://github.com/LautyUCC/ingesoft3/actions/runs/40284305415)** del PR #39: mostrar la restauración verde y la promoción aprobada a Producción.
  4. Ejecutar `curl` a `:3001` y `:3002` mostrando que ambos responden 200 OK con el commit `1caea7c`.

### Minuto 6:00 - 8:00 — TP8: Infraestructura como Código con Terraform
- **Mensaje Clave:** *"La infraestructura no se configura haciendo clics; se declara de forma versionada, idempotente y reproducible."*
- **Qué Mostrar:**
  1. Explicar `infra/main.tf`: 8 recursos (red, volumen, imágenes GHCR y contenedores con derivación dinámica).
  2. Demostrar en terminal: `terraform plan` $\rightarrow$ 8 altas; `terraform apply` levantando el puerto 3003; `curl http://127.0.0.1:3003/health` respondiendo 200 OK con base de datos.
  3. Correr un segundo `terraform plan` mostrando 0 cambios (idempotencia).
  4. Ejecutar `terraform destroy` demostrando que preprod desaparece limpiamente sin afectar QA (:3001) ni PROD (:3002).

### Minuto 8:00 - 10:00 — TP9: DevSecOps y Observabilidad en Tiempo Real
- **Mensaje Clave:** *"Seguridad Shift-Left en el código y observabilidad orientada a la acción en el tablero."*
- **Qué Mostrar:**
  1. Mostrar el PR #30 de Dependabot integrado y el análisis limpio de CodeQL.
  2. Explicar la remediación de ReDoS en `validationService.js` (algoritmo lineal) y rate limit en `/health`.
  3. Abrir la consola de Sentry: mostrar el error fatal real **PHOTOMATCH-BACKEND-1** (`terminating connection due to administrator command`) capturado con release exacto.
  4. Mostrar la **Issue #38** en el tablero de **GitHub Projects** derivada de ese error.
  5. Mostrar el monitor en UptimeRobot y el historial del **incidente resuelto 503/UP** tras 5 minutos.

---

## 4. Las 15 Preguntas Definitivas para la Mesa Examinadora

1. **¿Qué diferencia conceptual separa a Continuous Delivery de Continuous Deployment?**  
   *Respuesta:* En Continuous Delivery, cada versión aprobada por CI está lista para producción, pero el pase requiere una decisión humana explícita (gate). En Continuous Deployment, el pase a producción es 100% automático.
2. **¿Por qué es fundamental el principio "Build Once, Deploy Many"?**  
   *Respuesta:* Para asegurar paridad binaria total. Si se recompila la imagen en cada ambiente, cambios sutiles en dependencias o entornos pueden introducir defectos en Producción que no existían en QA.
3. **¿Cómo garantizan que un fallo de interfaz no llegue a los usuarios?**  
   *Respuesta:* Mediante la dependencia `needs: e2e` en el workflow. Si la suite de Playwright falla en QA, GitHub Actions omite automáticamente el despliegue a producción.
4. **¿Por qué Playwright y no Selenium?**  
   *Respuesta:* Playwright se comunica directamente con el motor del navegador vía Chrome DevTools Protocol sin drivers intermediarios, ofreciendo auto-waiting, aislamiento de contextos y velocidad hasta 4 veces superior.
5. **¿Qué problema de seguridad resuelve CodeQL que un linter estándar no detecta?**  
   *Respuesta:* CodeQL realiza *taint tracking* (análisis de flujo de datos semántico), detectando vulnerabilidades complejas como inyecciones o ReDoS (backtracking catastrófico en expresiones regulares).
6. **¿Por qué se colocó rate limiting en `/health`?**  
   *Respuesta:* Porque es un healthcheck profundo que ejecuta `SELECT 1` en PostgreSQL. Sin límite de frecuencia, un atacante podría agotar las conexiones del pool de la base de datos (DoS).
7. **¿Dónde se guarda el estado de Terraform y por qué está en `.gitignore`?**  
   *Respuesta:* En `terraform.tfstate`. Debe excluirse de Git porque almacena contraseñas y secrets en texto plano, y versionarlo en Git crearía conflictos de concurrencia graves.
8. **¿Qué es la idempotencia en Terraform y cómo la verificaron?**  
   *Respuesta:* Es la propiedad de no alterar la infraestructura si el estado ya coincide con la declaración. La verificamos ejecutando un segundo `terraform plan` tras el apply, el cual arrojó cero cambios.
9. **¿Cómo demostraron que preproducción en Terraform convive con QA y Producción?**  
   *Respuesta:* Ejecutamos `curl` en simultáneo a los puertos 3001 (QA), 3002 (PROD) y 3003 (PREPROD), respondiendo los tres 200 OK con sus bases de datos conectadas.
10. **¿Cómo midieron el tiempo de rollback de PhotoMatch?**  
    *Respuesta:* Medimos el intervalo entre la orden de recreación del contenedor con el SHA anterior y la respuesta confirmada de `/health` (7,42 s de recreación Docker y 20,16 s de ciclo total en QA).
11. **¿Qué sucede si el runner local pierde Internet durante un despliegue?**  
    *Respuesta:* La instrucción `set -e` aborta el script en el paso de descarga (`docker pull`), antes de invocar `docker-compose up`. Los contenedores productivos siguen corriendo intactos con la versión previa.
12. **¿Por qué se pausó el monitor de UptimeRobot al terminar las pruebas?**  
    *Respuesta:* Para evitar falsos positivos de caída cuando la máquina del desarrollador entra en suspensión o se apaga, preservando la veracidad histórica de las métricas.
13. **¿Cómo cierra el ciclo la observabilidad en PhotoMatch?**  
    *Respuesta:* Un dato observado en Sentry (corte de base de datos) no quedó en una simple métrica: se transformó en la Issue #38 en GitHub Projects para implementar reintentos en el pool.
14. **¿Por qué el DSN de Sentry del frontend puede ser público?**  
    *Respuesta:* Porque es una clave de solo ingestión (*Ingestion-Only*), diseñada exclusivamente para enviar reportes de errores sin permisos de lectura ni administración.
15. **¿Qué evidencia demuestra que el Quality Gate del TP5 bloquea un PR real?**  
    *Respuesta:* El PR #17 (`demo/tp5-gate-bloqueado`), que permanece abierto y en rojo con el required check `build-backend` fallando por no alcanzar el 80% de líneas.

---

## 5. Glosario Técnico Esencial

- **Quality Gate:** Umbral mínimo de calidad (cobertura, linters, tests) obligatorio para autorizar la integración de código.
- **Continuous Delivery:** Capacidad de desplegar a producción en cualquier momento bajo decisión humana.
- **Immutable Artifact:** Imagen de contenedor o paquete binario etiquetado de forma única que nunca se modifica tras su construcción.
- **Taint Tracking:** Técnica de análisis de seguridad que rastrea el camino que recorren datos no sanitizados desde su entrada hasta su ejecución.
- **ReDoS:** Denegación de servicio provocada por expresiones regulares con complejidad exponencial ante entradas maliciosas.
- **Drift:** Discrepancia entre la infraestructura física aprovisionada y el código de configuración de IaC.
- **Synthetic Monitoring:** Pruebas automatizadas periódicas desde el exterior para certificar disponibilidad y latencia.
- **APM:** Supervisión profunda del rendimiento del código, capturando excepciones, llamadas a base de datos y transacciones.
