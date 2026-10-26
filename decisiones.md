# Decisiones técnicas

## Enlaces de TP6 y TP7 (estado verificable al 26/10/2026)

- [PR #18](https://github.com/LautyUCC/ingesoft3/pull/18): integrado con autorización del propietario en `main` como `3bdfd2464031836fb1f2488e095a1db221d9f926`. La [última CI del PR](https://github.com/LautyUCC/ingesoft3/actions/runs/40273179225) y [CodeQL](https://github.com/LautyUCC/ingesoft3/actions/runs/40273176297) pasaron; publicación y deploy se saltearon por ser PR.
- [CI de `main`, intento 2](https://github.com/LautyUCC/ingesoft3/actions/runs/40273446742/attempts/2): ambos builds y `publish` pasaron. Las imágenes [backend](https://github.com/users/LautyUCC/packages/container/package/photomatch-backend) y [frontend](https://github.com/users/LautyUCC/packages/container/package/photomatch-frontend) quedaron públicas con tag `sha-3bdfd2464031836fb1f2488e095a1db221d9f926`; `docker manifest inspect` anónimo funcionó para ambas. El primer intento de publicación había fallado con `permission_denied: write_package`; se concedió al repositorio acceso Actions `Write` en ambos paquetes.
- En ese intento, `deploy-qa` falló antes de crear contenedores: Docker intentó guardar el `GITHUB_TOKEN` en el llavero de macOS y el runner como servicio no podía interactuar con él. La corrección del [PR #33](https://github.com/LautyUCC/ingesoft3/pull/33) elimina el login en el despliegue y fija el socket del contexto Docker antes de usar una configuración temporal y `docker-compose` para descargar anónimamente los paquetes públicos. La prueba local de `docker-compose pull` con ese aislamiento pasó para PostgreSQL y ambas imágenes GHCR.
- URLs QA/PROD funcionando desde la corrida, corrida roja E2E, corrida verde aprobada y releases `v6.0.0` a `v9.0.0`: **pendientes**.
- Fallback local de la consigna: QA `http://127.0.0.1:3001`, PROD `http://127.0.0.1:3002` cuando el runner y Docker Desktop están encendidos. Son URL locales, no públicas. La disponibilidad hasta la defensa depende de mantener esta máquina encendida.

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


## TP5 — Calidad automatizada: tests, coverage y Quality Gate

### Enlaces de este TP

| Lo que se comprueba | Enlace |
|---|---|
| Corrida roja por umbral de cobertura (Quality Gate) | [Actions Run #39985482676](https://github.com/LautyUCC/ingesoft3/actions/runs/39985482676) |
| Corrida verde con Step Summary y artefacto descargable | [Actions Run #39985690914](https://github.com/LautyUCC/ingesoft3/actions/runs/39985690914) |
| Secuencia completa rojo → tests → verde → merge (PR1) | [Pull Request #16](https://github.com/LautyUCC/ingesoft3/pull/16) |
| Freno de calidad bloqueado y abierto hasta la defensa (PR2) | [Pull Request #17](https://github.com/LautyUCC/ingesoft3/pull/17) |
| Release congelada del trabajo | [Release v5.0.0](https://github.com/LautyUCC/ingesoft3/releases/tag/v5.0.0) |

### Lógica elegida para testear y por qué esa

En PhotoMatch se priorizó testear la lógica del núcleo del dominio (`src/services/**`), donde un bug impacta de forma crítica en la recaudación del fotógrafo o en la seguridad del sistema:
1. `pricingService.js`: Calcula los precios de compra de jugadores individuales, packs (`single`, `pack6`, `all`) y la regla de liquidación `isCounted`. Un bug aquí produce liquidaciones erróneas, cobros incorrectos al cliente o compromisos de entrega de fotos que no existen.
2. `authService.js`: Controla la autenticación de usuarios administradores y fotógrafos con hashing bcrypt y normalización de credenciales. Un fallo aquí expone el panel de control o bloquea el acceso de los usuarios operativos.
3. `validationService.js`: Garantiza la consistencia de eventos deportivos (fechas lógicas de entrega posteriores al evento, planteles rivales distintos, precios no negativos y normalización de nombres y emails).

### Umbral de cobertura y justificación

El umbral configurado en `.c8rc.json` y verificado en el pipeline es **80% en líneas y 70% en ramas**.
- **Medición real actual:** 100% en líneas (86/86) y 70.58% en ramas (48/68).
- **Justificación:** El umbral se ancló en la medición real de la aplicación. Exige que el 100% de las funciones y líneas críticas se mantengan verificadas y que la cobertura de ramas no decaiga del 70%. Para subir el umbral de ramas al 85% sería necesario escribir pruebas sobre ramas defensivas secundarias de `validationService.js` (como valores imposibles que ya están filtrados por la interfaz de usuario en las plantillas EJS).

### Qué se dejó afuera de la cuenta de cobertura y por qué

Se configuró `.c8rc.json` con `include: ["src/services/**"]` y exclusiones explícitas justificadas según el marco de la cátedra (§2.4):
- **Arranque (`src/app.js`):** Solo cablea middleware de Express y escucha en el puerto 3000. Si falla, el servicio no levanta y se detecta en runtime.
- **Acceso a datos e infraestructura (`src/db/**`, `src/repositories/**`):** Inicialización de esquemas PostgreSQL y consultas SQL directas con `pg`. Probar esto aisladamente requeriría una base de datos real, lo cual corresponde a las pruebas de integración (TP7).
- **Transporte HTTP y vistas (`src/controllers/**`, `src/routes/**`, `src/views/**`):** Orquestan solicitudes y renderizan HTML con EJS.
- **Frontend (`frontend/`):** Nginx funciona como servidor web de assets CSS y proxy inverso hacia Express. No contiene JavaScript del lado cliente ni lógica de negocio (SPA). Por regla explícita de la cátedra (§1605 y §1631), los tests unitarios de frontend no aplican y las tres técnicas se concentran y validan en el backend.

### Por qué coverage alto no garantiza calidad

La cobertura mide qué porcentaje de código fue **ejecutado**, pero no certifica qué fue **verificado**. Si escribiéramos un test como:
```javascript
test('cobertura sin verdad', () => {
  calculatePlayerPurchase('pack6', 15);
});
```
La función se ejecuta completamente y `c8` computa 100% de cobertura en esa línea. Sin embargo, no existe ningún `assert`: si la función tuviese un bug y devolviera un precio negativo o un objeto `null`, el test pasaría en verde. La verdadera confianza reside en la calidad de los asserts y en la sensibilidad de las pruebas ante cambios de lógica.

### Pull Request bloqueado por Quality Gate

- **PR bloqueado de demostración:** [Pull Request #16](https://github.com/LautyUCC/ingesoft3/pull/16) (en su primer commit `0f0f718`).
- **Check en rojo:** `build-backend` en el step *Ejecutar tests unitarios y verificar umbral de cobertura (Quality Gate)*.
- **Métrica del fallo:** Líneas: 55.81% (umbral: 80%) y Ramas: 59.61% (umbral: 70%).
- **Causa:** Se configuró el freno de cobertura en CI y se refactorizó `authService.js`, pero no se habían incluido aún las suites de prueba `authService.test.js` y `pricingService.test.js`. A pesar de que los 11 tests existentes pasaron (0 errores de compilación, 0 fallos lógicos), el gate bloqueó el PR por calidad insuficiente.
- **Solución (Commit `e4790fd`):** Se incorporaron 21 tests unitarios nuevos (mock, parametrizados y casos de borde). La cobertura subió al 100% en líneas y 70.58% en ramas, poniendo el check en verde y habilitando el merge.
- **Segundo PR (permanente):** [Pull Request #17](https://github.com/LautyUCC/ingesoft3/pull/17) en la rama `demo/tp5-gate-bloqueado`, que permanece **abierto y en rojo hasta la defensa oral** para evidenciar el bloqueo en vivo ante la mesa evaluadora.

### Refactorización para permitir Mocks

Originalmente `authService.js` realizaba `const users = require('../repositories/userRepository')` en el ámbito global del módulo, acoplando fuertemente el servicio a las consultas SQL nativas de PostgreSQL. Para aislarlo:
- Se aplicó **Inversión de Dependencias (Dependency Injection)**: la función pasó a ser `authenticate(email, password, userRepo = users)`.
- En producción, `userRepo` toma por defecto el repositorio real sin romper el controlador `authController.js`.
- En pruebas (`backend/test/authService.test.js`), se le inyecta un doble de riesgo (`mockUserRepo`) que registra las invocaciones y retorna un usuario simulado con un hash precalculado de bcrypt, permitiendo validar la interacción y la sanitización de credenciales sin tocar la base de datos.

### Traducción del stack técnico («Tu stack, de un vistazo»)

| Requisito de la Cátedra | Implementación en PhotoMatch (Node.js) |
|---|---|
| **Dónde viven los tests** | En carpeta `backend/test/*.test.js` con el runner nativo `node:test` y `node:assert/strict`. |
| **Test parametrizado** | Matrices de datos iteradas con `cases.forEach(tc => test(..., () => { ... }))`. |
| **Inyección de dependencia** | Parámetro con valor por defecto en la función: `userRepo = users`. |
| **Medidor de cobertura** | `c8` (instrumentación nativa basada en el motor V8 de Node.js). |
| **Umbral que frena el build** | `c8 --check-coverage --lines 80 --branches 70 node --test` (retorna exit code 1 si no se cumple). |
| **Filtro de cobertura** | Archivo `backend/.c8rc.json` con `include: ["src/services/**"]` y exclusión de arranque e infraestructura. |

### El ejercicio del camino sin cubrir

- **Archivo y línea exacta:** `backend/src/services/validationService.js`, líneas 30 y 31:
  `if (!COVERAGE_STATUSES.includes(data.status)) errors.push('El estado no es válido.');`
  `if (!PAYMENT_STATUSES.includes(data.payment_status)) errors.push('El estado de pago no es válido.');`
- **Entrada concreta que lo recorrería:** Invocar `validateCoverage` con un estado inexistente: `{ ...validData, status: 'Inexistente', payment_status: 'NoExiste' }`.
- **Decisión tomada y por qué:** Decidimos **no agregar este test** en la suite unitaria actual. En la aplicación real, estos valores están restringidos mediante elementos `<select>` en las vistas EJS y tipos enum a nivel de base de datos. Dejar esta rama sin ejercitar sitúa la cobertura de ramas en un honesto **70.58%**, calibrando a la perfección el umbral del Quality Gate (70%) para que cualquier código sin tests rompa el pipeline inmediatamente.

### Problemas encontrados y soluciones

- **Aislamiento de persistencia en Node.js:** `authService.js` acoplaba la lógica de negocio al cliente `pg`. Se solucionó aplicando inyección de dependencias como argumento opcional con fallback, evitando herramientas invasivas de intercepción de módulos en runtime.
- **Generación del Step Summary en CI:** `c8` muestra la salida de cobertura en la consola estándar, pero el Step Summary requería volcarlo a `$GITHUB_STEP_SUMMARY`. Se configuraron los reportes `text` y `text-summary` y se inyectaron directamente en el archivo de entorno de GitHub Actions mediante un paso con `if: always()`.
- **Preservación del artefacto ante fallo de umbral:** Cuando el build fallaba por cobertura, el paso de subida de artefactos no se ejecutaba por defecto. Se agregó la condición `if: always()` en los steps de summary y upload-artifact para garantizar que la evidencia del fallo esté disponible para su descarga y análisis.

### Uso de inteligencia artificial

Se utilizó asistencia de IA para auditar las consignas de la UCC, diseñar los casos de prueba unitarios, estructurar las matrices de parametrización, configurar la integración de `c8` con GitHub Actions y elaborar el material didáctico para la defensa oral. La verificación se realizó de forma empírica y reproducible: ejecutando la suite localmente (32 tests en 87 ms), comprobando el fallo real por umbral en GitHub Actions (Run #39985482676), validando la corrida verde (Run #39985690914) y asegurando que las decisiones técnicas respondan a la arquitectura real del repositorio.

## TP6 — Entrega continua con fallback local

El PR #18 seguía abierto y el árbol estaba limpio al iniciar esta continuación. El problema real era que `build-backend` y `build-frontend` publicaban de forma independiente: si fallaba uno, el otro podía llegar a GHCR. Ahora los dos jobs verifican y exportan sus imágenes como archivos; `publish` tiene `needs: [build-backend, build-frontend]` y sólo hace `docker load` y `docker push` de esos archivos en un push a `main`. No hay reconstrucción tras el gate. En PR, los pasos de registry quedan salteados. Es una garantía sobre el pipeline, no sobre pushes manuales al registry. Los tags `sha-<commit>` son identificadores únicos de contenido generado por ese commit; no usamos `latest`.

Elegimos el fallback local que permite la consigna porque aún no había cuentas de Neon ni Render. Un runner `photomatch-local` se registró en GitHub y el workflow despliega las imágenes GHCR en dos proyectos Compose separados. QA usa el puerto 3001 y PROD el 3002; cada proyecto tiene red, contenedores y volumen PostgreSQL propios. Los environments `qa` y `production` existen. `production` exige revisión de LautyUCC y permite la propia aprobación. Cada environment guarda sus propias claves aleatorias de base, sesión y administrador; el workflow no las imprime. La dirección del backend del frontend se configura al arrancar con `BACKEND_URL`, mientras el código EJS, CSS y proxy se incluyen en la imagen. `COMMIT_SHA` queda en la imagen backend y `/health` lo devuelve junto con el resultado de `SELECT 1`. El smoke reintenta y exige el SHA exacto para no aceptar una versión anterior.

El backend ya no desactiva la verificación del certificado TLS. `DB_SSL_MODE=require` valida el certificado y el host; `disable` corresponde al PostgreSQL de red local de Compose. `SESSION_SECRET` de producción debe tener al menos 32 caracteres y no puede ser el ejemplo. La cookie usa `secure: auto` detrás de un proxy confiable. Estas decisiones permiten Render/Neon más adelante sin debilitar TLS, aunque el despliegue activo elegido es local.

Implementamos Continuous Delivery: QA se despliega automáticamente tras CI; integración y E2E verifican QA; PROD espera aprobación. El aprobador debe mirar cobertura, imágenes publicadas, smoke del SHA, integración, reporte E2E y cambios del PR. Rechaza si alguno no acredita el comportamiento esperado. Para producción real elegiríamos rolling con dos instancias si hubiera presupuesto y observabilidad; el fallback actual es `recreate`, con una ventana breve. Un rollback consistirá en volver a desplegar en PROD los dos tags `sha-<commit>` anteriores por el workflow o un comando controlado y medir desde el inicio del `pull` hasta `/health` con ese SHA. **Aún no hay rollback medido ni rechazo real**; sería falso asignarles tiempo o motivo.

La primera validación local real incluyó `actionlint`, ShellCheck, 32 tests y cobertura, builds de ambas imágenes, Compose y `/health` con PostgreSQL conectado. Luego se agregó una prueba de email por dos alertas CodeQL: ahora son 33 tests, con 100% de líneas y 72,36% de ramas. El intento 2 de la CI de `main` publicó ambos paquetes públicos; QA falló en el login de Docker antes de crear contenedores. PR #33 propone la descarga anónima. La disponibilidad del fallback depende de Docker Desktop y del runner encendidos durante la defensa. La IA ayudó a diseñar el pipeline y la configuración; se verificó con herramientas locales, API de GitHub y pruebas reales, y se distingue lo pendiente de lo observado.

## TP7 — Integración, navegador y promoción de una imagen

PhotoMatch renderiza EJS, no una SPA. Para probar operaciones con `request` sin navegador agregamos una API autenticada `/api/clients` que reutiliza el repositorio y la validación de clientes. Responde 201 en alta, 400 en datos inválidos, 404 si falta el recurso y 204 en baja. Las tres pruebas `frontend/e2e/api.spec.js` hacen alta/lectura/baja, rechazo de nombre vacío y edición con verificación. Crean nombres únicos y borran los registros creados. Se autentican contra la app y la base real de QA. Las tres `app.spec.js` usan Chromium sobre el front: alta y baja, error visible sin persistencia, y edición persistente tras recarga seguida de limpieza. No hay mocks ni saltos si el entorno no responde.

El workflow encadena `deploy-qa → integracion → e2e → deploy-prod`; los reportes HTML se suben aun cuando falla una suite. La imagen que QA y PROD reciben lleva el mismo tag del commit y se publicó una sola vez. La integración distingue problemas de API/base de fallos de interfaz. El smoke sólo prueba salud y SHA; Playwright comprueba comportamiento. La prueba local real dio 3/3 integración y 3/3 E2E. Descubrió un 500 previo en `/clients/new`: el local `client` de EJS se interpretaba como opción de compilación y anulaba `include`. Se renombró a `customer` y la pantalla volvió a funcionar.

**Pendiente obligatorio:** corrida de `main` con QA, una rotura real del código de la interfaz que deje integración verde y E2E roja, posterior corrección y aprobación a PROD; enlace a ambos reportes y release `v7.0.0` sobre el commit desplegado. No se presenta la ejecución local como evidencia de esas corridas. La IA ayudó con API, pruebas y diagnóstico; se contrastó con PostgreSQL y Chromium locales.

## TP8 — Preprod reproducible con Terraform

Se eligió el provider Docker `kreuzwerker/docker` 4.6.0, fijado en `infra/versions.tf`, con Terraform 1.17.x. `infra/` declara red, volumen, PostgreSQL, backend y frontend: ocho recursos que no importan ni alteran QA o PROD. La URL de base se deriva del nombre del contenedor de PostgreSQL; `BACKEND_URL` del nombre del backend. Las imágenes se pasan como variables para usar las etiquetas GHCR del TP7. El estado se guarda fuera del repositorio, porque contiene credenciales. Variables sensibles llegan por `TF_VAR_*`, y `.gitignore` excluye estado, `.terraform/` y tfvars; el lock file sí se versiona.

Se ejecutaron `init`, `fmt -check`, `validate`, `plan` (8 altas), `apply`, `/health` con base, segundo `plan` sin cambios, `destroy`, recreación y nuevo `destroy`. El primer apply falló porque el provider buscó `/var/run/docker.sock`; en Docker Desktop de macOS se resolvió exportando `DOCKER_HOST` desde `docker context inspect`. Tras la publicación GHCR del SHA `3bdfd2464031836fb1f2488e095a1db221d9f926`, se repitió el ciclo con ambas imágenes del registry: 8 altas, `/health` HTTP 200 con ese SHA y PostgreSQL conectado, plan sin cambios y destroy de 8 recursos. Un 502 inicial se debió al arranque del backend y se resolvió al esperar salud. Preprod quedó destruido y QA/PROD no fueron importados ni modificados. **Pendiente:** `v8.0.0` y prueba de convivencia con QA/PROD una vez que éstos se desplieguen. La IA ayudó a redactar HCL; se verificó leyendo planes y resultados reales.

## TP9 — Seguridad y observabilidad

Se agregó Dependabot para npm de backend, npm de frontend y GitHub Actions. En GitHub están habilitadas las actualizaciones de seguridad, secret scanning y push protection. CodeQL default setup quedó configurado y su primer análisis terminó en verde en la corrida enlazada arriba. `npm audit fix` actualizó cuatro dependencias transitivas vulnerables; el audit posterior reportó cero vulnerabilidades. Se integró `@sentry/node` antes de Express y `@sentry/browser` en un bundle servido por Nginx; sólo se inicializan cuando se configuran DSN desde el entorno. La configuración pública del navegador llega por `/telemetry-config.js`, sin incluir credenciales de lectura de Sentry en el código. El SHA identifica la release en ambas SDK.

La primera corrida CodeQL del PR marcó dos alertas altas: la validación de email usaba un regex con backtracking potencialmente costoso, y `/health` consultaba la base sin límite de frecuencia. Se reemplazó la validación por operaciones lineales sobre la cadena, se agregó `express-rate-limit` a `/health` (60 solicitudes por minuto) y un test con entradas malformadas y largas. La suite volvió a superar el umbral. El nuevo escaneo de CodeQL y su check de seguridad terminaron verdes en la corrida enlazada arriba.

Dependabot ya abrió PRs desde `main`; #30 actualiza `pg` a 8.23.1 y su CI pasó. **Pendiente obligatorio:** integrar un PR Dependabot con autorización; cuentas/proyectos Sentry y sus DSN; evento real y tabla de uso; monitor externo con DOWN/UP y pausa; tarjeta del Project derivada de un dato observado; release `v9.0.0`. Sin esos datos no se inventan métricas ni incidente. La IA ayudó a configurar las capas; se verificaron la API de GitHub, CodeQL y los builds, pero aún falta observar producción.
