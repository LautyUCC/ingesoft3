#set page(
  paper: "a4",
  margin: (top: 2.2cm, bottom: 2.2cm, left: 2.2cm, right: 2.2cm),
  header: context {
    if here().page() > 1 [
      #grid(
        columns: (1fr, 1fr),
        align(left)[#text(size: 8pt, fill: rgb("#64748b"))[PhotoMatch · Guía General de Defensa P2]],
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
  size: 9.5pt,
  fill: rgb("#1e293b"),
  lang: "es"
)

#set par(
  justify: true,
  leading: 0.6em
)

#show heading: it => [
  #set text(fill: rgb("#0f172a"), weight: "bold")
  #v(1.1em)
  #it
  #v(0.5em)
]

#show heading.where(level: 1): it => [
  #set text(size: 14pt, fill: rgb("#1e3a8a"))
  #block(
    width: 100%,
    stroke: (bottom: 2pt + rgb("#1e3a8a")),
    inset: (bottom: 5pt),
    it.body
  )
]

#show heading.where(level: 2): it => [
  #set text(size: 11pt, fill: rgb("#0369a1"))
  #it.body
]

#let callout(title: "Nota", body, color: rgb("#0284c7")) = {
  block(
    width: 100%,
    stroke: (left: 4pt + color),
    fill: color.lighten(92%),
    inset: (x: 10pt, y: 8pt),
    radius: (right: 4pt),
    [
      #text(weight: "bold", fill: color)[#title] \
      #v(3pt)
      #body
    ]
  )
}

#let questionbox(number: "1", q, a) = {
  block(
    width: 100%,
    stroke: 1pt + rgb("#cbd5e1"),
    fill: rgb("#f8fafc"),
    inset: 10pt,
    radius: 5pt,
    [
      #text(weight: "bold", fill: rgb("#1e3a8a"))[Pregunta #number: #q] \
      #v(4pt)
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
    inset: 16pt,
    radius: 8pt,
    width: 100%,
    [
      #text(size: 19pt, weight: "bold", fill: white)[PhotoMatch — Guía Maestra de Defensa Oral]\
      #v(3pt)
      #text(size: 12pt, fill: rgb("#93c5fd"))[Parte 2: Ciclo Completo de Ingeniería de Software (TP5 a TP9)]\
      #v(2pt)
      #text(size: 9.5pt, fill: rgb("#cbd5e1"))[Ingeniería de Software III · Universidad Católica de Córdoba (UCC) · Ciclo 2026]
    ]
  )
]

#v(8pt)

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  block(
    fill: rgb("#f1f5f9"),
    inset: 8pt,
    radius: 4pt,
    [
      #text(weight: "bold")[Alumno:] Lautaro Alejo Vallino \
      #text(weight: "bold")[Legajo:] 2301009 · Comisión 2 \
      #text(weight: "bold")[Defensa Oral:] Viernes 6/11/2026 (13:30 ART)
    ]
  ),
  block(
    fill: rgb("#f1f5f9"),
    inset: 8pt,
    radius: 4pt,
    [
      #text(weight: "bold")[Releases Oficiales:] `v5.0.0` a `v9.0.0` (auditoría condicionada) \
      #text(weight: "bold")[Repositorio:] github.com/LautyUCC/ingesoft3 \
      #text(weight: "bold")[Tiempo Asignado:] 10 minutos
    ]
  )
)

= 1. Visión Holística del Pipeline de PhotoMatch

El flujo completo de ingeniería de software implementado garantiza calidad, trazabilidad y seguridad desde el código fuente hasta la operación en vivo:

1. *Commit & Push:* Protegido por Secret Scanning y Push Protection en GitHub.
2. *Pull Request:* Dispara análisis SAST con CodeQL, auditoría SCA con Dependabot y el Quality Gate de cobertura con `c8` (≥80% líneas, ≥70% ramas). El *PR #17* permanece abierto y bloqueado en rojo como evidencia contractual permanente.
3. *Integración en `main`:*
  - `build-backend` y `build-frontend`: Compilan y empaquetan imágenes Docker una sola vez, exportando `.tar`.
  - `publish`: Publica en GHCR con etiqueta inmutable `sha-<COMMIT_SHA>`.
  - `deploy-qa`: Despliega en QA (`http://127.0.0.1:3001`) y corre `smoke.sh`.
  - `integracion`: Ejecuta 3/3 pruebas de API REST con Playwright contra PostgreSQL real.
  - `e2e`: Ejecuta 3/3 flujos completos con Chromium headless. Si falla, *deploy-prod se bloquea y cancela automáticamente* (evidencia real en CI Run 40283556436, PR #37).
  - `deploy-prod`: Requiere aprobación humana de `LautyUCC` en GitHub Environments. Despliega en Producción (`http://127.0.0.1:3002`), supervisado por Sentry y UptimeRobot.

= 2. Matriz Consolidada de Entregables Oficiales

#table(
  columns: (0.7fr, 1.2fr, 0.7fr, 1.6fr),
  fill: (x, y) => if y == 0 { rgb("#1e3a8a") } else if calc.even(y) { rgb("#f8fafc") } else { white },
  stroke: 0.5pt + rgb("#cbd5e1"),
  inset: 5pt,
  table.header(
    [*TP*],
    [*Eje Temático*],
    [*Release*],
    [*Evidencia Principal y Demostración*]
  ),
  [#text(weight: "bold")[TP5]],
  [Testing y Calidad],
  [`v5.0.0`],
  [Quality Gate con `c8`. *PR #17 abierto y bloqueado* en rojo por cobertura (64,2% < 80%).],

  [#text(weight: "bold")[TP6]],
  [Continuous Delivery],
  [`v6.0.0`],
  [Pipeline "Build Once, Deploy Many". *Gate rechazado* (CI 40277582164). Retorno real al SHA anterior; 7,42 s solo recreación parcial, total PROD pendiente.],

  [#text(weight: "bold")[TP7]],
  [Contenedores y E2E],
  [`v7.0.0`],
  [*Gate E2E Rojo Demostrado:* PR #37 / CI 40283556436 (E2E falló, PROD bloqueado). Recuperación verde en PR #39 (CI 40284305415).],

  [#text(weight: "bold")[TP8]],
  [Infraestructura (IaC)],
  [`v8.0.0`],
  [Módulo Terraform `infra/` con 8 recursos. *Ciclo de vida en vivo:* preprod en :3003, *idempotencia estricta* y destroy limpio.],

  [#text(weight: "bold")[TP9]],
  [DevSecOps y Observabilidad],
  [`v9.0.0`],
  [Dependabot PR #30 integrado y CodeQL activo; alerta HIGH #2 en login pendiente de integrar PR #41. *Sentry:* Error QA real -> Issue #38; trazas PROD. *UptimeRobot:* 503/UP.]
)

= 3. Guion Estratégico de Exposición (10 Minutos)

#callout(title: "Distribución Temporal Estricta", color: rgb("#1e3a8a"))[
  - *Min 0 a 2 (TP5):* Mostrar PR #17 bloqueado en vivo. Enfatizar que la calidad es un requisito contractual bloqueante. \
  - *Min 2 a 4 (TP6):* Mostrar el flujo "Build Once, Deploy Many", el rechazo humano y la limitación de los 7,42 s parciales de recreación. \
  - *Min 4 a 6 (TP7):* Enseñar la corrida roja de CI 40283556436 donde E2E bloqueó Producción, y la posterior recuperación verde en CI 40284305415. Mostrar curl a :3001 y :3002. \
  - *Min 6 a 8 (TP8):* Ejecutar `terraform plan` (8 altas), `apply` levantando :3003, segundo `plan` mostrando 0 cambios (idempotencia) y `destroy` limpio. \
  - *Min 8 a 10 (TP9):* Mostrar PR Dependabot, CodeQL con alerta HIGH #2 y PR #41, trazas PROD/error QA en Sentry, Issue #38 y monitor UptimeRobot 503/UP.
]

= 4. Preguntas Cruciales para la Mesa Examinadora

#questionbox(
  number: "1",
  [¿Cómo demostraron que una falla funcional en la interfaz no llega a producción?],
  [En el PR #37 rompimos la ruta del formulario HTML de clientes. En la corrida de GitHub Actions #40283556436, la integración pasó 3/3 verde contra la API, pero la suite E2E de Playwright falló en rojo. Dado que `deploy-prod` depende de `needs: e2e`, GitHub Actions canceló y omitió el despliegue a producción automáticamente, manteniendo PROD intacta en el commit sano.]
)

#v(6pt)

#questionbox(
  number: "2",
  [¿Por qué es superior el principio "Build Once, Deploy Many" frente a recompilar en cada ambiente?],
  [Porque garantiza paridad binaria absoluta. Si se reconstruye la imagen en Producción, una variación en repositorios de npm o paquetes base podría introducir una vulnerabilidad o defecto que no existía cuando se probó en QA. En PhotoMatch, QA y PROD despliegan exactamente el mismo digest inmutable publicado en GHCR.]
)

#v(6pt)

#questionbox(
  number: "3",
  [¿Qué es la idempotencia en Terraform y cómo la auditaron?],
  [Es la capacidad de ejecutar el aprovisionamiento repetidas veces asegurando que el estado real no sufra mutaciones si ya coincide con la declaración. Tras aplicar la infraestructura de preprod en :3003, ejecutamos un segundo `terraform plan` que devolvió: _"No changes. Your infrastructure matches the configuration"_.]
)

#v(6pt)

#questionbox(
  number: "4",
  [¿De qué manera conectaron la observabilidad técnica con la gestión ágil?],
  [A partir de la excepción fatal real `terminating connection due to administrator command` capturada en Sentry tras un corte de base de datos, analizamos la causa raíz técnica y creamos la Issue #38 en GitHub, vinculándola al tablero oficial de GitHub Projects en la columna Todo para implementar reconexión automática en el pool.]
)

= 5. Checklist para Demostración en Vivo frente al Docente

- [ ] *Terminal 1:* Docker containers activos (`photomatch-qa` en :3001 y `photomatch-prod` en :3002).
- [ ] *Terminal 2:* En `infra/`, ejecutar `terraform plan` y `terraform apply` levantando :3003 en vivo.
- [ ] *Navegador Tab 1:* PR #17 abierto y bloqueado en rojo (Quality Gate TP5).
- [ ] *Navegador Tab 2:* CI Run 40283556436 con E2E rojo y `deploy-prod` en gris (Skipped) (TP7).
- [ ] *Navegador Tab 3:* CI Run 40284305415 con recuperación verde y promoción a Producción (TP7).
- [ ] *Navegador Tab 4:* Consola Sentry con incidente PHOTOMATCH-BACKEND-1 y GitHub Project con Issue #38.
- [ ] *Navegador Tab 5:* Dashboard de UptimeRobot con incidente 503/UP y releases `v5.0.0` a `v9.0.0`.
