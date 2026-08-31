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
