#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  header: context {
    if here().page() > 1 [
      #grid(
        columns: (1fr, 1fr),
        align(left)[#text(size: 8pt, fill: rgb("#64748b"))[PhotoMatch · TP8: Infraestructura como Código]],
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
      #text(size: 13pt, fill: rgb("#93c5fd"))[Trabajo Práctico 08: Infraestructura como Código (IaC) con Terraform]\
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
      #text(weight: "bold")[Herramienta:] Terraform v1.17.0
    ]
  ),
  block(
    fill: rgb("#f1f5f9"),
    inset: 10pt,
    radius: 4pt,
    [
      #text(weight: "bold")[Release Oficial:] `v8.0.0` \
      #text(weight: "bold")[Provider:] kreuzwerker/docker 4.6.0 \
      #text(weight: "bold")[Entorno:] Preproducción efímera (:3003)
    ]
  )
)

= A. Introducción Conceptual

== 1. Paradigma Declarativo vs. Imperativo
- *Imperativo (Scripts Bash):* Se detalla paso a paso qué comandos ejecutar. Falla si un recurso ya existe o requiere condicionales defensivos complejos.
- *Declarativo (Terraform):* Se especifica el *estado deseado final*. Terraform infiere el grafo de dependencias y calcula la ruta óptima para converger hacia ese estado.

== 2. Estado (`terraform.tfstate`), Drift e Idempotencia
- *Archivo de Estado:* Mapea los identificadores lógicos del código HCL con los IDs físicos del proveedor Docker. Dado que contiene secretos en texto plano, está estrictamente excluido del versionado en `.gitignore`.
- *Drift (Desviación):* Desincronización entre la realidad del proveedor y el código. Se detecta con `terraform plan`.
- *Idempotencia:* La ejecución sucesiva de `terraform apply` sobre una infraestructura que ya convergió no introduce ninguna modificación adicional (`0 to add, 0 to change, 0 to destroy`).

= B. Estado Inicial de PhotoMatch antes del TP8
- Solo se utilizaba Docker Compose (`compose.yml`) para QA y Producción.
- No existía módulo formal de IaC ni gestión declarativa de estado con Terraform.
- No existía un tercer ambiente efímero (*preprod*) capaz de nacer, validarse y destruirse a demanda sin afectar QA ni Producción.

= C. Implementación Paso a Paso

1. *Módulo Modular en `infra/`:*
  - `versions.tf`: Fija Terraform `v1.17.0` y el proveedor Docker en `~> 4.6.0`.
  - `variables.tf`: Parametriza imágenes GHCR inmutables y credenciales con `sensitive = true`.
  - `main.tf`: Declara los 8 recursos interconectados de preproducción.
  - `outputs.tf`: Expone la URL web `http://127.0.0.1:3003`.
2. *Los 8 Recursos Declarados:*
  - `docker_network.preprod`: Red aislada `photomatch-preprod`.
  - `docker_volume.db`: Volumen de persistencia `photomatch-preprod-data`.
  - 3 recursos de imagen: `docker_image.postgres`, `backend` y `frontend` (consumiendo etiquetas SHA de GHCR).
  - 3 contenedores: base de datos PostgreSQL 16, backend Express y frontend Nginx en el puerto 3003.
3. *Resolución de Conectividad en macOS:* Se exportó `DOCKER_HOST` a partir del socket expuesto por Docker Desktop y se parametrizó un `SESSION_SECRET` con longitud válida (≥32 caracteres).

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
  [#text(weight: "bold")[Provider Docker fijado en 4.6.0]],
  [Provider de nube comercial (AWS/Azure)],
  [Permite aprovisionamiento profesional local reproducible sin costos de tarjeta ni límites de cuota universitaria.],

  [#text(weight: "bold")[Aislamiento en Puerto 3003]],
  [Reutilizar puertos de QA o PROD],
  [Permite demostrar la convivencia pacífica simultánea de tres ambientes sin interferencias cruzadas.],

  [#text(weight: "bold")[Variables Sensibles `sensitive = true`]],
  [Archivo `terraform.tfvars` versionado],
  [Evita que contraseñas y secrets queden registrados en el historial de Git o expuestos en logs de terminal.]
)

= E. Pruebas y Evidencias Reales

#callout(title: "Evidencias Auditables en Vivo", color: rgb("#047857"))[
  1. *Aprovisionamiento Exitoso:* `terraform apply` -> 8 recursos creados. Endpoint `/health` verificado en `http://127.0.0.1:3003/health` (200 OK con DB). \
  2. *Coexistencia Simultánea:* Verificación concurrente de QA (:3001), PROD (:3002) y PREPROD (:3003) respondiendo 200 OK. \
  3. *Idempotencia Demostrada:* Segundo `terraform plan` -> _"No changes. Your infrastructure matches the configuration"_. \
  4. *Destrucción Limpia:* `terraform destroy` -> 8 recursos eliminados. QA y PROD continuaron operativos sin interrupción. \
  5. *Release Oficial:* `v8.0.0` publicada en GitHub.
]

= F. Preparación para la Defensa Oral

#questionbox(
  number: "1",
  [¿Por qué el archivo `terraform.tfstate` nunca debe subirse al repositorio de Git?],
  [Porque almacena en texto plano todos los atributos de los recursos creados, incluyendo contraseñas de base de datos y claves secretas de sesión. Además, versionar el estado en Git generaría conflictos de concurrencia inmanejables si múltiples operadores aplican cambios simultáneos.]
)

#v(8pt)

#questionbox(
  number: "2",
  [¿Qué significa el término "Drift" en Infraestructura como Código?],
  [Es la divergencia que ocurre cuando alguien modifica manualmente un recurso (ej. detiene un contenedor o borra una red en Docker) por fuera de Terraform. En el siguiente `terraform plan`, Terraform detecta esa diferencia y planifica las acciones necesarias para restaurar el estado deseado.]
)

#v(8pt)

#questionbox(
  number: "3 (Difícil)",
  [¿Qué pasaría si dos miembros del equipo ejecutan `terraform apply` al mismo tiempo?],
  [Se produciría una condición de carrera sobre el archivo de estado, provocando corrupción de datos o creación de recursos duplicados. Para prevenirlo se utiliza *State Locking*, un mecanismo que bloquea el estado durante las operaciones de escritura (en entornos locales se bloquea automáticamente; en la nube se usa DynamoDB o Consul).]
)

= G. Resumen Final de Estudio

- *IaC:* Gestión declarativa y versionada de infraestructura con grafo de dependencias automático.
- *Idempotencia:* Aplicaciones sucesivas garantizan cero cambios residuales.
- *Ciclo de vida:* `plan` (8 altas) -> `apply` (:3003 200 OK) -> `destroy` (8 bajas limpias).
- *Pitch de 2 minutos:* _"En el TP8 aplicamos Infraestructura como Código a PhotoMatch utilizando Terraform con el provider de Docker. Declaramos de forma reproducible 8 recursos en infra/: red aislada, volumen persistente, imágenes inmutables de GHCR y contenedores enlazados dinámicamente. Demostramos el ciclo de vida completo: levantamos el ambiente preprod en el puerto 3003 verificando 200 OK con base de datos, demostramos estricta idempotencia y convivencia simultánea con QA y Producción, y finalizamos con la destrucción limpia de los recursos sin afectar la operación continua del sistema."_
