#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  header: context {
    if here().page() > 1 [
      #grid(
        columns: (1fr, 1fr),
        align(left)[#text(size: 8pt, fill: rgb("#64748b"))[PhotoMatch · TP9: DevSecOps y Observabilidad]],
        align(right)[#text(size: 8pt, fill: rgb("#64748b"))[Ingeniería de Software III · UCC]]
      )
      #v(-4pt)
      #line(length: 100%, stroke: 0.5pt + rgb("#cbd5e1"))
    ]
  },
  footer: context [
    #line(length: 100%, stroke: 0.5pt + rgb("#cbd5e1"))
    #v(2pt)
    #grid(
      columns: (1fr, 1fr),
      align(left)[#text(size: 8pt, fill: rgb("#64748b"))[Lautaro Alejo Vallino · Legajo 2301009]],
      align(right)[#text(size: 8pt, fill: rgb("#64748b"))[Página #counter(page).display() de #counter(page).final().first()]]
    )
  ]
)

#set text(
  font: "Helvetica",
  size: 10pt,
  fill: rgb("#1e293b"),
  lang: "es"
)

#set par(
  justify: true,
  leading: 0.65em
)

#show heading: it => [
  #set text(fill: rgb("#0f172a"), weight: "bold")
  #v(1.2em)
  #it
  #v(0.6em)
]

#show heading.where(level: 1): it => [
  #set text(size: 15pt, fill: rgb("#1e3a8a"))
  #block(
    width: 100%,
    stroke: (bottom: 2pt + rgb("#1e3a8a")),
    inset: (bottom: 6pt),
    it.body
  )
]

#show heading.where(level: 2): it => [
  #set text(size: 12pt, fill: rgb("#0369a1"))
  #it.body
]

#show heading.where(level: 3): it => [
  #set text(size: 10.5pt, fill: rgb("#334155"))
  #it.body
]

#let callout(title: "Nota", body, color: rgb("#0284c7")) = {
  block(
    width: 100%,
    stroke: (left: 4pt + color),
    fill: color.lighten(92%),
    inset: (x: 12pt, y: 10pt),
    radius: (right: 4pt),
    [
      #text(weight: "bold", fill: color)[#title] \
      #v(4pt)
      #body
    ]
  )
}

#let questionbox(number: "1", q, a) = {
  block(
    width: 100%,
    stroke: 1pt + rgb("#cbd5e1"),
    fill: rgb("#f8fafc"),
    inset: 12pt,
    radius: 6pt,
    [
      #text(weight: "bold", fill: rgb("#1e3a8a"))[Pregunta #number: #q] \
      #v(6pt)
      #text(weight: "bold", fill: rgb("#047857"))[Respuesta para defender:] \
      #v(2pt)
      #a
    ]
  )
}

// PORTADA / ENCABEZADO
#align(center)[
  #block(
    fill: rgb("#1e3a8a"),
    inset: 18pt,
    radius: 8pt,
    width: 100%,
    [
      #text(size: 20pt, weight: "bold", fill: white)[PhotoMatch — Manual Técnico de Defensa]\
      #v(4pt)
      #text(size: 13pt, fill: rgb("#93c5fd"))[Trabajo Práctico 09: DevSecOps y Observabilidad en Tiempo Real]\
      #v(2pt)
      #text(size: 10pt, fill: rgb("#cbd5e1"))[Ingeniería de Software III · Universidad Católica de Córdoba (UCC) · 2026]
    ]
  )
]

#v(10pt)

#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
  block(
    fill: rgb("#f1f5f9"),
    inset: 10pt,
    radius: 4pt,
    [
      #text(weight: "bold")[Alumno:] Lautaro Alejo Vallino \
      #text(weight: "bold")[Legajo:] 2301009 · Comisión 2 \
      #text(weight: "bold")[Seguridad:] Dependabot + CodeQL + Secret Scanning
    ]
  ),
  block(
    fill: rgb("#f1f5f9"),
    inset: 10pt,
    radius: 4pt,
    [
      #text(weight: "bold")[Release Oficial:] `v9.0.0` \
      #text(weight: "bold")[APM / Errores:] Sentry (Node.js & Browser) \
      #text(weight: "bold")[Monitoreo Externo:] UptimeRobot (Incidente 503/UP)
    ]
  )
)

= A. Introducción Conceptual

== 1. Paradigma Shift-Left Security
Desplazar la seguridad a las etapas iniciales del ciclo de vida del software (en lugar de verificarla al final en producción) reduce drásticamente el costo de mitigación y previene brechas de seguridad:
- *Secret Scanning & Push Protection:* Intercepta secretos y tokens en el instante del commit.
- *Dependabot (SCA):* Monitorea dependencias y propone parches automatizados mediante Pull Requests.
- *CodeQL (SAST):* Analiza semánticamente el flujo de datos para detectar ReDoS e inyecciones.

== 2. Observabilidad: De la Detección a la Acción
- *Sentry (Caja Blanca):* Captura excepciones en tiempo real, stack traces y tiempos de transacción tanto en Express como en el navegador web.
- *UptimeRobot (Caja Negra):* Sondea desde Internet la salud de Producción, alertando ante degradaciones o caídas (HTTP 503).
- *Cierre de Ciclo:* Toda anomalía observada se traduce en una tarjeta en el tablero de trabajo de GitHub Projects.

= B. Estado Inicial de PhotoMatch antes del TP9
- 4 dependencias transitivas vulnerables en el backend.
- Sin análisis estático SAST ni escaneo automático de vulnerabilidades.
- Expresión regular de email vulnerable a ataques ReDoS por retroceso catastrófico.
- Endpoint `/health` expuesto a agotamiento de conexiones por denegación de servicio.
- Sin telemetría de errores ni monitoreo externo.

= C. Implementación Paso a Paso

1. *Automatización de Seguridad:* Configuración de `.github/dependabot.yml` y activación de CodeQL default setup en GitHub Actions. `npm audit fix` eliminó las 4 vulnerabilidades transitivas.
2. *Remediaciones de Código por Alertas CodeQL:*
  - *ReDoS:* Validación de email refactorizada a algoritmo lineal seguro en `validationService.js`.
  - *DoS en `/health`:* Inclusión de rate limiting (máximo 60 peticiones por minuto con `express-rate-limit`).
3. *Integración de Sentry:* `@sentry/node` en Express (`instrument.js`) y `@sentry/browser` compilado con `esbuild` en frontend.
4. *Captura de Incidente Real y Gestión en Tablero:* Desconexión intencional de PostgreSQL generó la excepción fatal real *PHOTOMATCH-BACKEND-1*. Se creó la *Issue #38* vinculada al tablero de GitHub Projects en `Todo`.
5. *Monitoreo UptimeRobot:* Sondeo a `/health` de Producción registró el incidente real 503 (#372997347011072787) y su posterior recuperación a `Up` tras 5m 04s.

= D. Decisiones de Ingeniería y Trade-offs

#table(
  columns: (1fr, 1.2fr, 1.2fr),
  fill: (x, y) => if y == 0 { rgb("#1e3a8a") } else if calc.even(y) { rgb("#f8fafc") } else { white },
  stroke: 0.5pt + rgb("#cbd5e1"),
  inset: 7pt,
  table.header(
    [*Decisión Tomada*],
    [*Alternativa Descartada*],
    [*Justificación Técnica y Trade-off*]
  ),
  [#text(weight: "bold")[Dependabot Automatizado]],
  [Revisiones manuales de CVEs],
  [Crea Pull Requests de remediación continua evaluados por la suite de CI sin intervención humana previa.],

  [#text(weight: "bold")[CodeQL SAST en CI]],
  [Linters estáticos superficiales],
  [CodeQL analiza flujo de datos semántico (taint tracking), detectando ReDoS que un linter estándar no ve.],

  [#text(weight: "bold")[Pausar UptimeRobot post-test]],
  [Dejar sondeo 24/7 en máquina local],
  [Evita falsos positivos de caída cuando la laptop del desarrollador entra en suspensión o se apaga.]
)

= E. Pruebas y Evidencias Reales

#callout(title: "Evidencias Auditables en GitHub y Consolas", color: rgb("#047857"))[
  1. *PR de Dependabot Integrado:* PR #30 (`pg` 8.23.0 -> 8.23.1) fusionado exitosamente en commit `43f142e` con CI verde. \
  2. *CodeQL y Auditoría:* análisis activo; alerta HIGH #2 de rate limiting en login figura `fixed` tras el merge de PR #41. `npm audit` reportó 0 vulnerabilidades de dependencias. \
  3. *Sentry:* incidente fatal PHOTOMATCH-BACKEND-1 con entorno `qa`. Explore muestra trazas backend `prod`: GET /clients fue la más usada (6); POST /login, la más lenta por p75 (2,23 s). Frontend tiene pageloads, pero el entorno 127.0.0.1 aún mezcla QA/PROD; PR #42 está fusionado y espera despliegue PROD. \
  4. *GitHub Projects:* Issue #38 vinculada al tablero oficial en columna `Todo`. \
  5. *UptimeRobot:* Incidente real resuelto #372997347011072787 (DOWN 503 detectado, notificación y recuperación tras 5m 04s). \
  6. *Release Oficial:* `v9.0.0` publicada en GitHub.
]

= F. Preparación para la Defensa Oral

#questionbox(
  number: "1",
  [¿Qué es Shift-Left Security y cómo se evidencia en PhotoMatch?],
  [Es la práctica de incorporar la seguridad en fases tempranas. En PhotoMatch se evidencia en tres barreras: Push Protection al hacer git push, Dependabot analizando dependencias en el repositorio, y CodeQL evaluando el código en cada PR antes de mergear.]
)

#v(8pt)

#questionbox(
  number: "2",
  [¿Cómo solucionaron la vulnerabilidad ReDoS detectada por CodeQL?],
  [Reemplazamos la expresión regular vulnerable por verificaciones lineales de subcadenas (`indexOf`, `slice`) con complejidad $O(N)$ acotada por una guarda inicial de 254 caracteres, garantizando que el event loop de Node.js nunca se bloquee.]
)

#v(8pt)

#questionbox(
  number: "3 (Difícil)",
  [¿Por qué agregaron un rate limiter al endpoint `/health` si suele ser público?],
  [Porque nuestro healthcheck es "profundo": ejecuta `SELECT 1` sobre PostgreSQL. Sin rate limiting, un atacante podría inundar `/health` para agotar las conexiones del pool de la base de datos y provocar una denegación de servicio a los usuarios reales.]
)

= G. Resumen Final de Estudio

- *Shift-Left:* Dependabot, CodeQL, Push Protection y saneamiento de dependencias.
- *Observabilidad:* Sentry (APM / Errores reales) y UptimeRobot (Disponibilidad externa).
- *Cierre de Ciclo:* Incidente de Sentry traducido a la tarjeta #38 en GitHub Projects.
- *Pitch de 2 minutos:* _"TP9 integra Dependabot (#30), CodeQL y push protection. PR #41 corrigió la alerta HIGH de login, ahora marcada fixed en GitHub. Sentry capturó un error QA que originó la tarjeta #38 y mostró una tabla de trazas reales PROD; PR #42 corrige la etiqueta browser y espera despliegue PROD. UptimeRobot registró un DOWN 503 real y el UP tras 5 minutos; el monitor quedó pausado."_
