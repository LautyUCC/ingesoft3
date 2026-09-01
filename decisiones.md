# Decisiones técnicas

## TP1 — Git colaborativo

### Flujo de trabajo elegido

Se utiliza GitHub Flow porque el proyecto mantiene una única rama estable (`main`) y los cambios son pequeños e incrementales. Cada cambio se realiza en una rama corta y entra mediante un Pull Request. Esto permite revisar el diff, conservar una conversación asociada al cambio y detectar problemas antes de modificar la versión estable.

La protección de `main` no se basa en la confianza entre integrantes. Su propósito es convertir el proceso acordado en una regla verificable: evita cambios accidentales, obliga a integrar mediante PR y deja trazabilidad entre la intención, la revisión y los commits.

### Conflicto de merge

El conflicto se provoca modificando la misma línea del `README.md` de manera diferente en dos ramas creadas desde el mismo punto. Después de integrar la primera rama, Git no puede elegir automáticamente cuál de las dos versiones representa la intención correcta. Ambas modificaciones son válidas desde el punto de vista del algoritmo, pero son incompatibles entre sí; la decisión requiere contexto humano.

El conflicto podría haberse evitado coordinando el trabajo para que las ramas modificaran líneas o archivos diferentes, integrando ramas más pequeñas con mayor frecuencia o actualizando la segunda rama con `main` antes de abrir su PR. Actualizarla antes no elimina necesariamente el conflicto, pero permite resolverlo temprano en la rama de trabajo y no durante la integración final.

### Versionado

La primera entrega se identifica como `v1.0.0`. De acuerdo con versionado semántico, el primer número representa cambios incompatibles, el segundo funcionalidades compatibles y el tercero correcciones compatibles. En este TP el tag funciona como una referencia inmutable al estado presentado. Además se crea el tag `tp1`, solicitado por la cátedra para localizar el snapshot académico del trabajo.

### Problemas encontrados y soluciones

- El repositorio personal estaba vacío. Se creó una estructura mínima para que el historial del semestre comience en este TP.
- El cliente Git de Windows no podía usar HTTPS debido a una política que bloqueaba su biblioteca `libcurl`. Se utilizó Git dentro de WSL sobre la misma carpeta de trabajo.
- El directorio donde estaban las consignas también contenía cambios locales de PhotoMatch. Para no mezclarlos ni perderlos, la entrega se clonó en `C:\ingesoft3\entrega-tp1` y esos cambios quedaron intactos.
- Las evidencias de rechazo, conflicto y Release no se inventan: se incorporan después de ejecutar cada operación real en GitHub.

### Uso de inteligencia artificial

Se utilizó un asistente de IA para preparar la estructura inicial, redactar una primera versión de la documentación y explicar el modelo de ramas, conflictos y versionado. La verificación se realiza contrastando el documento con la consigna oficial, ejecutando los comandos sobre el repositorio real y comprobando en GitHub que la protección rechace el push, que el PR muestre el conflicto y que los tags y la Release apunten al commit correcto. El contenido será revisado y comprendido antes de la defensa oral.

## TP2 — Contenedores

### Elección de la aplicación

Se eligió PhotoMatch, una aplicación propia para administrar el trabajo de un fotógrafo deportivo. Se puede ejecutar con Docker, sus comandos son explícitos (`npm ci` y `node src/app.js`), la conexión PostgreSQL está centralizada en `DATABASE_URL`, contiene reglas comprobables y su tamaño permite comprenderla durante la defensa.

La app tiene presentación, backend y base. Como usa HTML renderizado con EJS, Nginx funciona como contenedor frontal: sirve CSS y reenvía las solicitudes hacia Express. No se presenta falsamente como SPA ni como microservicios.

### Imágenes multi-stage

El backend usa `node:22-alpine`. Sus stages separan dependencias completas, pruebas, dependencias productivas y runtime. La imagen final no recibe tests, Supertest, caché de npm ni archivos locales. Node es interpretado y no posee una separación SDK/runtime como .NET; aquí el beneficio es aislar pruebas y dependencias de desarrollo.

El frontend usa Alpine para reunir assets y `nginx:1.29-alpine` como runtime. Nginx sirve `/css/` y usa el nombre DNS `backend` para el proxy. Cada contexto tiene su propio `.dockerignore`.

### Red, salud y persistencia

Compose crea una red interna: el backend resuelve `db` y Nginx resuelve `backend`. PostgreSQL no publica su puerto al host. `depends_on` solo no asegura disponibilidad; por eso PostgreSQL ejecuta `pg_isready`, el backend expone `/health` y las dependencias esperan `service_healthy`.

El volumen `photomatch_data` persiste `/var/lib/postgresql/data`. `down` conserva datos y `down -v` elimina deliberadamente el volumen. Frontend y backend son descartables.

### Secretos

`.env` está ignorado y contiene la configuración local. `.env.example` documenta las variables sin ser fuente de secretos reales. Compose interpola esas variables; en futuros pipelines vivirán en GitHub Secrets o en secretos del entorno.

### Problemas encontrados

- La versión inicial tenía un solo Dockerfile y no era multi-stage. Se crearon contextos de frontend y backend independientes.
- Compose incluía claves fijas y publicaba PostgreSQL. Se migró a variables y red interna.
- Faltaba una señal de disponibilidad. Se agregaron `/health` y healthchecks encadenados.
- Docker Desktop estaba detenido; se inició y se verificó todo desde build limpio.
- Node no estaba instalado en Windows; los tests se ejecutaron dentro del stage `test`.

### Uso de inteligencia artificial

Se utilizó IA para auditar la consigna, proponer la separación compatible con EJS, preparar Dockerfiles, Compose y documentación, y operar las verificaciones. Se validó con `docker compose config`, once tests, tres servicios saludables, solicitudes HTTP end-to-end y pruebas reales de persistencia usando `down`, `up` y `down -v`. El contenido debe ser comprendido antes de defenderlo.

## TP3 — Planificación y trazabilidad

### Duración del sprint

Sprint 1 dura 14 días, desde el 31 de agosto hasta el 13 de septiembre de 2026. Dos semanas permiten completar una porción verificable del pipeline, recibir devolución y ajustar sin acumular un mes de trabajo. Un sprint más corto generaría demasiado costo de planificación para una persona y uno más largo demoraría el feedback.

### Límite de trabajo en progreso

El límite de `In Progress` es 2: cantidad de personas (una) más una tarea adicional. Permite continuar con una segunda actividad cuando la primera espera una respuesta o revisión, pero evita empezar muchas cosas y no terminar ninguna. Si nunca se alcanza, el límite sería demasiado alto; si bloquea continuamente trabajo razonable, se revisaría con evidencia.

### Diagnóstico de la historia mal escrita

“Como desarrollador quiero crear la tabla usuarios para guardar los datos” es una tarea técnica disfrazada de historia: describe implementación y no valor para un usuario. Se reescribiría como “Como administrador quiero registrar usuarios para que cada integrante acceda de forma segura a las funciones que le corresponden”; crear la tabla sería una tarea hija.

### Problemas encontrados

- GitHub CLI no tenía alcance `project`; se amplió la autorización desde el flujo oficial por dispositivo.
- El Project creado por CLI era privado y solo tenía vista de tabla. Se hizo público y se creó una vista Board agrupada por Status mediante la API.
- La versión de `gh` instalada inicialmente no era conocida; se verificó que era 2.98 y soportaba sub-issues nativos.
- El CLI no permite crear campos Iteration directamente. Se utilizó la API GraphQL para crear Sprint 1 con duración de 14 días y asignar historia y tareas.
- Se comprobó por API que el workflow “Item closed” está habilitado; al cerrar una tarea debe moverla automáticamente a Done.

### Uso de inteligencia artificial

Se utilizó IA para auditar la consigna, crear y relacionar issues, operar GitHub Projects mediante CLI, REST y GraphQL, redactar la documentación y preparar la trazabilidad. Se verificó consultando el Project público, las relaciones Parent issue/Sub-issues progress, el campo Sprint, el workflow automático y el estado del issue después del merge. Todo debe recorrerse y explicarse durante la defensa.

## TP4 — CI: Pipelines as Code

### Estructura del pipeline

El workflow tiene dos jobs independientes: `build-backend` y `build-frontend`. Cada imagen posee su propio Dockerfile, contexto y cache, así que no existe una dependencia que obligue a ejecutarlas en secuencia. GitHub asigna un runner limpio a cada job y puede construirlas en paralelo; si cualquiera falla, el pipeline queda rojo.

`pull_request` verifica la combinación con `main` antes del merge y alimenta el gate. `push` sobre `main` genera una corrida posterior y mantiene actualizado el badge.

### Dockerfiles como contrato

El pipeline usa los Dockerfiles del TP2 con `docker/build-push-action`. Existe así una sola definición de build para desarrollo, CI y despliegue futuro. Ejecutar comandos Node o Nginx distintos en el workflow podría dejar CI verde mientras la imagen desplegable estuviera rota.

En TP4 `push: false`: se verifica que las imágenes se construyan en una máquina limpia, sin publicarlas. Los tests se incorporan al pipeline en TP5.

### Cache

Buildx importa y exporta capas con `type=gha`; `mode=max` conserva también capas intermedias. Los scopes `backend` y `frontend` son estantes separados para que el último job no sobrescriba el cache del otro.

En backend se reutilizan la imagen base, la copia del lockfile y `npm ci --omit=dev` mientras no cambien dependencias. Cambiar `package.json` o el lockfile invalida esa capa y las posteriores. En frontend se reutilizan la base Nginx, configuración y assets no modificados.

Si el cache desaparece, el pipeline reconstruye todo y vuelve a poblarlo. El cache mejora rendimiento, pero no es necesario para la corrección.

### Gate

`main` exige Pull Request, aplica la regla al administrador y requiere `build-backend` y `build-frontend` en verde. `strict: true` obliga a verificar la rama contra el estado actual de `main`, evitando integrar un verde calculado sobre una base vieja.

### Problemas encontrados

- El workflow del TP3 solo hacía checkout; se reemplazó por los dos jobs reales.
- Se definieron scopes separados porque compartir el scope predeterminado haría que los caches se pisaran.
- Los nuevos checks debían correr al menos una vez antes de configurar el gate.
- PhotoMatch usa Node interpretado; la demostración rompe una dependencia, porque un error de sintaxis no necesariamente se evalúa durante `docker build`.

### Uso de inteligencia artificial

Se utilizó IA para analizar la consigna, adaptar el workflow, configurar cache y protección de rama, operar la demostración rojo–verde y redactar la defensa. Se verificó con corridas reales, logs con capas reutilizadas, un PR bloqueado por un build fallido, el fix posterior y consultas a la protección de `main`.
