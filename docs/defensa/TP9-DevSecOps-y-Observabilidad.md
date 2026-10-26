# Guía de Estudio y Defensa — TP9: DevSecOps y Observabilidad en Tiempo Real
**Materia:** Ingeniería de Software III — Universidad Católica de Córdoba (UCC)  
**Ciclo Lectivo:** 2026  
**Alumno:** Lautaro Alejo Vallino (Legajo: 2301009) — Comisión 2  
**Aplicación:** PhotoMatch (Gestión de coberturas fotográficas deportivas)  
**Release asociada:** `v9.0.0`

---

## A. Introducción Conceptual

### 1. Paradigma Shift-Left Security (Seguridad Desplazada a la Izquierda)
En el ciclo de vida de desarrollo de software tradicional (Waterfall / DevOps inicial), la seguridad se evaluaba al final, justo antes o incluso después de llegar a producción (mediante costosas auditorías externas o *pentests*).
El enfoque **Shift-Left** propone desplazar las verificaciones de seguridad hacia la izquierda de la línea temporal: hacia el commit, el Pull Request y el pipeline de CI. 
- **Beneficio económico:** Corregir una vulnerabilidad durante el desarrollo cuesta hasta 30 veces menos que remediarla tras una brecha de seguridad en producción.

### 2. Capas de Seguridad en PhotoMatch
1. **Secret Scanning y Push Protection:** Activo a nivel de repositorio. Analiza cada commit antes de aceptarlo en el servidor remoto de GitHub, bloqueando *pushes* que contengan patrones de claves privadas, tokens o DSN de lectura.
2. **Software Composition Analysis (SCA) — Dependabot:** Analiza los archivos de dependencias (`package-lock.json`, workflows de Actions) contra la base de datos de vulnerabilidades conocidas (CVE / GitHub Advisory Database) y genera Pull Requests automatizados con la versión parcheada mínima compatible.
3. **Static Application Security Testing (SAST) — GitHub CodeQL:** Motor de análisis semántico profundo que trata el código fuente como una base de datos relacional. Rastrea flujos de datos (*taint tracking*) desde fuentes no confiables (*sources*) hasta funciones críticas (*sinks*), detectando inyecciones SQL, denegación de servicio por expresiones regulares (ReDoS) o exposición de endpoints sin límites de tasa.

### 3. Observabilidad: Métricas, Logs y Trazas (Sentry y UptimeRobot)
- **Monitoreo Sintético Externo (UptimeRobot):** Valida la disponibilidad del servicio desde sondas distribuidas por el mundo, midiendo latencia de red y alertando cuando el endpoint `/health` de Producción responde códigos distintos a 200.
- **Application Performance Monitoring (APM) y Error Tracking (Sentry):** Instrumenta tanto el runtime de Node.js en backend como el navegador de los usuarios en frontend. Captura excepciones no controladas con su *stack trace*, contexto de variables, versión exacta desplegada (`release: sha-<COMMIT>`) y transacciones distribuidas para identificar cuellos de botella en la base de datos.
- **Cierre del Ciclo:** Todo incidente observado en producción o QA debe traducirse en una acción en el tablero de trabajo del equipo (GitHub Projects).

---

## B. Estado Inicial de PhotoMatch antes del TP9

Antes de abordar el TP9:
- No existía Dependabot ni escaneo automático de vulnerabilidades en dependencias. El proyecto arrastraba 4 vulnerabilidades en dependencias transitivas (incluida una crítica en `proxy-addr`).
- No existía análisis estático de seguridad SAST con CodeQL.
- La expresión regular de validación de email en `validationService.js` sufría de *catastrophic backtracking* (vulnerable a ataques ReDoS).
- El endpoint `/health` consultaba la base de datos sin límite de frecuencia (*rate limit*), expuesto a agotamiento de conexiones por denegación de servicio.
- No había instrumentación de observabilidad ni telemetría en tiempo real.

---

## C. Implementación Paso a Paso

### 1. Configuración de Seguridad Automatizada
- Se configuró `.github/dependabot.yml` para auditar periódicamente dependencias de npm en `backend/`, `frontend/` y acciones de GitHub Actions.
- Se activó el análisis estático continuo con **GitHub CodeQL (default setup)** para JavaScript/TypeScript y flujos de Actions.
- Se ejecutó `npm audit fix` en el backend, resolviendo las 4 vulnerabilidades transitivas previas (dejando 0 vulnerabilidades en la auditoría).

### 2. Remediación de Alertas de Seguridad Detectadas por CodeQL
Durante el primer análisis de CodeQL, la herramienta detectó dos alertas de severidad alta:
1. *ReDoS en Regex de Email:* Se rediseñó la función de validación en `backend/src/services/validationService.js`, reemplazando la expresión regular compleja por verificaciones lineales de longitud y posición de caracteres sin riesgo de backtracking exponencial.
2. *Riesgo DoS en `/health`:* Se incorporó el middleware `express-rate-limit`, restringiendo el endpoint a un máximo de 60 peticiones por minuto por IP para proteger el pool de conexiones de PostgreSQL.
- Se agregaron pruebas unitarias específicas con cadenas malformadas y entradas gigantes (10.000 caracteres) que validan la resiliencia algorítmica.

### 3. Integración de Sentry en Backend y Frontend
- Backend: Se integró `@sentry/node` en `backend/src/instrument.js`, cargado como primera línea en el punto de entrada de la aplicación (`src/app.js`), registrando capturadores de errores y middleware de trazas contextualizadas con el entorno (`qa` / `production`) y el commit desplegado.
- Frontend: Se integró `@sentry/browser` compilado en un bundle ligero mediante `esbuild` durante el build de la imagen Docker de Nginx, inyectando la telemetría a través del endpoint `/telemetry-config.js` sin exponer credenciales de lectura.

### 4. Generación de Incidentes Reales y Vinculación con GitHub Projects
- Se detuvo intencionalmente el servicio de PostgreSQL en QA durante unos segundos y se invocó `POST /login`. Sentry capturó inmediatamente la excepción fatal real **[PHOTOMATCH-BACKEND-1](https://lauty-vallino.sentry.io/issues/7812452027/)** (`terminating connection due to administrator command`).
- A partir de este incidente, se creó la **[Issue #38](https://github.com/LautyUCC/ingesoft3/issues/38)** en el repositorio y se vinculó al tablero oficial **[GitHub Project PhotoMatch](https://github.com/users/LautyUCC/projects/1)** en la columna `Todo` para incorporar lógica de reconexión resiliente del pool.

### 5. Monitoreo Externo con UptimeRobot
- Se expuso de forma segura el endpoint `/health` de Producción mediante el proxy `scripts/public-health-proxy.js` y un túnel temporal.
- Se configuró el monitor en UptimeRobot. Durante una detención controlada del contenedor de backend de Producción, UptimeRobot detectó el fallo (HTTP 503), disparó la alerta por correo electrónico y registró el **[Incidente Real #372997347011072787](https://dashboard.uptimerobot.com/incidents/372997347011072787)**. Tras restaurar el servicio, el monitor verificó la recuperación en 5 minutos y 04 segundos, cerrando el ciclo DOWN $\rightarrow$ UP.

---

## D. Explicación del Código Central

### 1. Remediación Segura de Validación de Email (`backend/src/services/validationService.js`)
```javascript
// Algoritmo lineal seguro contra ataques ReDoS (cero backtracking)
function validateEmail(email) {
  if (typeof email !== 'string' || email.length > 254) return false;
  const atIndex = email.indexOf('@');
  if (atIndex < 1 || atIndex !== email.lastIndexOf('@')) return false;
  
  const localPart = email.slice(0, atIndex);
  const domainPart = email.slice(atIndex + 1);
  if (localPart.length === 0 || domainPart.length === 0) return false;
  
  const dotIndex = domainPart.indexOf('.');
  if (dotIndex < 1 || dotIndex === domainPart.length - 1) return false;
  return true;
}
```
*Análisis técnico:*
- Utiliza métodos de string con complejidad computacional $O(N)$ estricta (`indexOf`, `slice`). Incluso si un atacante envía un millón de caracteres repetidos, el tiempo de ejecución es instantáneo y acotado por la guarda inicial de 254 caracteres (RFC 5321).

### 2. Protección contra DoS en Endpoint de Salud (`backend/src/routes/index.js`)
```javascript
import rateLimit from 'express-rate-limit';

const healthLimiter = rateLimit({
  windowMs: 60 * 1000, // Ventana de 1 minuto
  max: 60,              // Máximo 60 peticiones por IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { status: 'error', message: 'Demasiadas solicitudes a /health' }
});

router.get('/health', healthLimiter, async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({ status: 'ok', version: '1.0.0', commit: process.env.COMMIT_SHA, database: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'error', database: 'disconnected' });
  }
});
```

---

## E. Decisiones de Ingeniería y Trade-offs

| Decisión Tomada | Alternativa Descartada | Justificación Técnica | Desventajas / Limitaciones |
|---|---|---|---|
| **Dependabot con PRs Automatizados** | Auditorías manuales esporádicas | Automatiza el seguimiento continuo de CVEs y permite evaluar el impacto en CI antes de integrar. | Puede generar ruido o sobrecarga de PRs si no se agrupan adecuadamente. |
| **CodeQL Default Setup de GitHub** | Herramientas SAST externas (SonarQube) | CodeQL corre nativo en GitHub Actions con análisis semántico profundo sin requerir servidores adicionales. | Tiempos de análisis superiores (~40-60 s) respecto a linters estáticos simples. |
| **Pausar UptimeRobot tras Demostración** | Dejar sondeo activo 24/7 en local | En un entorno de fallback local dependiente de una máquina física, dejar el monitor activo provocaría falsos incidentes cuando el desarrollador apaga la laptop. | Requiere reanudar el monitor durante la defensa oral. |

---

## F. Pruebas y Evidencias Reales

1. **Evidencia de Dependabot:**
   - [PR #30](https://github.com/LautyUCC/ingesoft3/pull/30) generado automáticamente para actualizar `pg` de 8.23.0 a 8.23.1. CI verde, aprobado y fusionado exitosamente a `main` en commit `43f142e`.
2. **Evidencia de CodeQL y Seguridad de Repositorio:**
   - Análisis de CodeQL en verde continuo (CI Runs 40273066679 y posteriores). Cero alertas abiertas de seguridad.
   - Secret Scanning y Push Protection activos y confirmados por la API de GitHub.
3. **Evidencia de Sentry:**
   - Proyectos `photomatch-backend` y `photomatch-frontend` configurados.
   - Incidente real capturado: [PHOTOMATCH-BACKEND-1](https://lauty-vallino.sentry.io/issues/7812452027/) (`terminating connection due to administrator command`), etiquetado con release exacto y entorno `qa`.
   - Transacciones y métricas de Explore Traces registradas en la consola de Sentry.
4. **Evidencia de Gestión de Incidentes en GitHub Projects:**
   - [Issue #38](https://github.com/LautyUCC/ingesoft3/issues/38) creada a partir del error de base de datos e integrada al [GitHub Project PhotoMatch](https://github.com/users/LautyUCC/projects/1) en la columna `Todo`.
5. **Evidencia de UptimeRobot:**
   - [Monitor #804424437](https://dashboard.uptimerobot.com/monitors/804424437) configurado para `/health` de Producción.
   - [Incidente Real Resuelto #372997347011072787](https://dashboard.uptimerobot.com/incidents/372997347011072787) (DOWN 503 detectado, notificación enviada y recuperación confirmada en 5m 04s). Monitor pausado preventivamente.
6. **Release Oficial:**
   - Etiqueta Git y [Release v9.0.0](https://github.com/LautyUCC/ingesoft3/releases/tag/v9.0.0) publicada en GitHub.

---

## G. Preparación para la Defensa Oral

### Preguntas Frecuentes de la Cátedra

1. **¿Qué es Shift-Left Security y cómo se evidencia en su proyecto?**  
   *Respuesta:* Es la práctica de mover la seguridad a las etapas tempranas del desarrollo. En PhotoMatch se evidencia en tres barreras automatizadas: Push Protection en el cliente git, análisis de vulnerabilidades en dependencias con Dependabot en el repositorio, y análisis estático SAST con CodeQL en cada Pull Request.

2. **¿Qué es una vulnerabilidad ReDoS y cómo la solucionaron?**  
   *Respuesta:* ReDoS (*Regular Expression Denial of Service*) ocurre cuando una expresión regular con operadores anidados ambiguos evalúa una entrada maliciosa con retroceso exponencial (*catastrophic backtracking*), consumiendo el 100% de la CPU y colgando el event loop de Node.js. La solucionamos reemplazando la regex compleja por un algoritmo lineal de validación de cadenas en $O(N)$.

3. **¿Por qué agregaron un rate limiter al endpoint `/health`?**  
   *Respuesta:* Porque nuestro healthcheck es "profundo": ejecuta `SELECT 1` contra PostgreSQL para verificar la salud del pool. Si un atacante inunda `/health` con miles de solicitudes concurrentes, podría agotar las conexiones de PostgreSQL y tirar abajo la aplicación para los usuarios legítimos.

4. **¿Cuál es la diferencia entre monitoreo externo (UptimeRobot) y APM (Sentry)?**  
   *Respuesta:* UptimeRobot actúa como una caja negra desde Internet, midiendo disponibilidad binaria (UP/DOWN) y latencia externa de red. Sentry actúa como una caja blanca dentro del código, capturando excepciones con stack traces detallados, identificando la línea exacta del error y midiendo el tiempo de cada consulta de base de datos.

5. **¿Qué información contiene el incidente capturado en Sentry?**  
   *Respuesta:* Contiene la excepción real `terminating connection due to administrator command`, el entorno exacto (`environment: qa`), el SHA del release desplegado, la traza de llamadas del error y los headers de la solicitud que provocó el fallo.

6. **¿Por qué pausaron el monitor de UptimeRobot al finalizar las pruebas?**  
   *Respuesta:* Porque estamos operando bajo el plan de contingencia de fallback local. Si el monitor continuara sondeando mientras la máquina de desarrollo está suspendida o apagada, registraría falsos incidentes de caída que desvirtuarían las estadísticas históricas de disponibilidad.

### Las 3 Preguntas Más Difíciles

7. **¿Cómo garantizan que el DSN de Sentry del navegador no sea utilizado maliciosamente por un atacante?**  
   *Respuesta:* El DSN del cliente browser es un *Ingestion-Only Key* por diseño de arquitectura: solo posee permisos para enviar eventos y trazas a la API de Sentry, pero carece de permisos de lectura o administración. Además, en la consola de Sentry se configuran *Allowed Domains* (CORS) y rate limiting por IP para evitar ataques de spam de eventos.

8. **Si CodeQL no ejecuta las pruebas ni levanta la aplicación, ¿cómo es capaz de encontrar vulnerabilidades lógicas?**  
   *Respuesta:* CodeQL compila el código fuente en un modelo relacional abstracto y ejecuta consultas QL especializadas en *Taint Tracking* (seguimiento de datos contaminados). Modela cómo fluyen los datos no confiables desde la entrada del usuario (*source*) hasta un punto sensible del sistema (*sink*), analizando si los datos pasaron por funciones de saneamiento adecuadas en el camino.

9. **¿De qué manera se cerró el ciclo de observabilidad hacia la gestión ágil del proyecto?**  
   *Respuesta:* No nos limitamos a observar el error: a partir de la excepción fatal de base de datos capturada en Sentry, documentamos la causa raíz técnica y generamos la Issue #38 en GitHub, asignándola inmediatamente a la columna `Todo` del tablero de GitHub Projects para implementar un mecanismo de reconexión automática con reintentos en el pool de PostgreSQL.

---

## H. Resumen Final de Estudio

- **DevSecOps:** Dependabot (SCA), CodeQL (SAST), Push Protection y mitigaciones reales de ReDoS y DoS.
- **Observabilidad:** Sentry (APM / Errores reales) y UptimeRobot (Sondeo externo DOWN/UP).
- **Cierre del ciclo:** Incidente de Sentry derivado en Issue #38 de GitHub Projects.
- **Pitch de 2 minutos:** _"En el TP9 consolidamos las capas de DevSecOps y observabilidad en PhotoMatch. Implementamos Shift-Left security con Dependabot (integrando el PR #30 de actualización de seguridad) y CodeQL, con el cual detectamos y corregimos una vulnerabilidad de ReDoS y un riesgo de DoS en /health mediante rate limiting. En observabilidad, instrumentamos Sentry en Node.js y navegador, capturando un error fatal real de corte de base de datos que derivó en la tarjeta #38 en GitHub Projects. Finalmente, configuramos UptimeRobot con sondeo externo a Producción, demostrando el ciclo completo de alerta DOWN ante una caída controlada y su posterior resolución UP tras 5 minutos."_
