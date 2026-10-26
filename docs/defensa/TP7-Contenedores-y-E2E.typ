#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  header: context {
    if here().page() > 1 [
      #grid(
        columns: (1fr, 1fr),
        align(left)[#text(size: 8pt, fill: rgb("#64748b"))[PhotoMatch · TP7: Contenedores y E2E]],
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
      #text(size: 13pt, fill: rgb("#93c5fd"))[Trabajo Práctico 07: Contenedores, Integración y Pruebas E2E]\
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
      #text(weight: "bold")[Aplicación:] PhotoMatch (Node.js / EJS / PostgreSQL)
    ]
  ),
  block(
    fill: rgb("#f1f5f9"),
    inset: 10pt,
    radius: 4pt,
    [
      #text(weight: "bold")[Release Oficial:] `v7.0.0` \
      #text(weight: "bold")[Herramienta E2E:] Playwright (Chromium Headless) \
      #text(weight: "bold")[Gate Demostrado:] Bloqueo PROD ante fallo E2E
    ]
  )
)

= A. Introducción Conceptual

== 1. Integración vs. End-to-End (E2E)
- *Pruebas de Integración (API Testing):* Verifican la comunicación real entre el servidor Express y PostgreSQL sin interfaz gráfica, utilizando el contexto HTTP directo de Playwright (`request`). Se ejecutan en milisegundos y aíslan fallos en el contrato de datos.
- *Pruebas End-to-End (E2E):* Validan el recorrido de usuario completo en un navegador Chromium real automatizado con Playwright, verificando renderizado de plantillas EJS, redirecciones HTTP y mutaciones del DOM.

== 2. El Mecanismo del Gate E2E Rojo
Un pipeline de Continuous Delivery robusto debe aislar la causa raíz de un defecto:
- Si la base y la API responden pero la interfaz web se rompe: la integración pasa verde pero *E2E falla en rojo*.
- Mediante la dependencia `needs: e2e` en el workflow de GitHub Actions, el despliegue a producción se *omite y bloquea automáticamente*, impidiendo que el defecto afecte a los usuarios de Producción.

= B. Estado Inicial de PhotoMatch antes del TP7
- Solo se contaba con pruebas unitarias en memoria (TP5) y despliegue básico (TP6).
- No existían pruebas automatizadas contra la base de datos real ni validaciones de interfaz.
- La plantilla `form.ejs` arrastraba una colisión sintáctica con EJS (`client` vs `customer`) que provocaba HTTP 500 al renderizar.

= C. Implementación Paso a Paso

1. *Diseño de Suite de Integración API (`frontend/e2e/api.spec.js`):* 3 pruebas directas: alta/lectura/baja de cliente, validación de errores HTTP 400 y actualización con verificación en base de datos.
2. *Diseño de Suite E2E de Navegador (`frontend/e2e/app.spec.js`):* 3 pruebas con Chromium: flujo completo de autenticación y alta de cliente, visualización de errores de validación, y edición persistente post-recarga.
3. *Ejecución de la Demostración del Gate E2E Rojo:*
  - *PR #37:* Rompió deliberadamente el formulario HTML apuntando el POST a `/clients/blocked-demo`.
  - *CI Run 40283556436:* `integracion` pasó 3/3 verde; `e2e` falló 3/3 en rojo con HTTP 404; `deploy-prod` quedó *bloqueado y omitido*. PROD permaneció en el SHA sano.
  - *PR #39:* Restauró la ruta a `/clients`.
  - *CI Run 40284305415:* Integración y E2E pasaron 3/3 verdes. Se aprobó el gate humano y se desplegó Producción en commit `1caea7c`.

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
  [#text(weight: "bold")[Playwright Unificado]],
  [Supertest (API) + Cypress (UI)],
  [Playwright resuelve API y navegador en la misma biblioteca, con soporte nativo de Chrome DevTools Protocol y auto-waiting.],

  [#text(weight: "bold")[Pruebas contra QA Real]],
  [Servidor Express efímero en memoria],
  [Certifica la convivencia en contenedores Docker y PostgreSQL real tal como se desplegará en Producción.],

  [#text(weight: "bold")[Limpieza en Cada Prueba]],
  [Truncar la base completa],
  [Truncar la base destruye usuarios administradores semilla. Cada test genera nombres únicos y los elimina puntualmente.]
)

= E. Pruebas y Evidencias Reales

#callout(title: "Evidencias Auditables en GitHub", color: rgb("#047857"))[
  1. *Gate E2E Rojo Demostrado:* PR #37 fusionado a `main`. CI Run 40283556436: Integración 3/3 verde (26s); E2E 3/3 rojo (2m 08s); `deploy-prod` bloqueado y omitido. Producción permaneció intacta en SHA `43f142e`. \
  2. *Artefacto de Evidencia:* Reporte Playwright con screenshots y traces subido como `playwright-report-e2e` (ID 12632244336). \
  3. *Restauración y Promoción Verde:* PR #39 fusionado a `main`. CI Run 40284305415: Integración y E2E 3/3 verdes; `deploy-prod` aprobado y desplegado con commit `1caea7ce1e19d4b2b84676ec8a35686f6e26f2e3`. \
  4. *Release Oficial:* `v7.0.0` publicada en GitHub con notas y evidencias.
]

= F. Preparación para la Defensa Oral

#questionbox(
  number: "1",
  [¿Por qué la suite de integración pasó en verde durante el PR #37 si el formulario estaba roto?],
  [Porque el cambio defectuoso del PR #37 afectó exclusivamente el atributo `action` del formulario HTML en la plantilla EJS. La API REST en `/api/clients` y el controlador continuaron funcionando correctamente, demostrando la capacidad del pipeline de aislar fallos por capa.]
)

#v(8pt)

#questionbox(
  number: "2",
  [¿Cómo impidió el pipeline que el fallo E2E rompiera la producción?],
  [En `.github/workflows/ci.yml`, el job `deploy-prod` declara la directiva `needs: e2e`. Al fallar el job `e2e`, GitHub Actions evalúa la dependencia insatisfecha y omite automáticamente el despliegue a producción sin solicitar aprobación.]
)

#v(8pt)

#questionbox(
  number: "3 (Difícil)",
  [¿Cómo mitigan los flaky tests en las pruebas E2E de navegador?],
  [Eliminando esperas fijas (`sleep`) y utilizando el auto-waiting de Playwright (actionability checks que esperan estabilidad del DOM). Además, configuramos reintentos automáticos (`retries: 2` en CI) y registros con identificadores temporales únicos para evitar condiciones de carrera.]
)

= G. Resumen Final de Estudio

- *Integración:* 3/3 pruebas de API REST contra PostgreSQL sin navegador.
- *E2E:* 3/3 pruebas completas con Chromium headless simulando usuarios reales.
- *Gate E2E Rojo:* Bloqueo automático de Producción ante rotura de interfaz certificado en CI Run 40283556436.
- *Pitch de 2 minutos:* _"En el TP7 implementamos pruebas de integración y E2E con Playwright contra el ambiente desplegado en QA. Demostramos el funcionamiento del gate funcional: una rotura deliberada en la interfaz gráfica pasó la integración pero rompió la suite E2E, bloqueando automáticamente la promoción a producción y protegiendo el entorno real. Tras integrar la corrección, recuperamos el 100% verde y promovimos a producción con la release v7.0.0."_
