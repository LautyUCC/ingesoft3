# Guía completa para la defensa P1 — TP1 a TP4

Esta guía está adaptada al repositorio público de PhotoMatch y al material oficial de la defensa P1. La defensa es individual, se realiza en tu notebook y tiene reloj: aproximadamente **6 minutos para Grupo B** o **5 minutos para Grupo A**. Vos conducís la demostración en orden TP1 → TP2 → TP3 → TP4; el profesor hace una pregunta corta por TP y otra sobre tu caso.

La nota se forma con:

- 25 % configuración técnica, corregida previamente sobre main.
- 25 % decisiones.md, leído previamente.
- 50 % defensa oral.

La regla central es: si no lo podés explicar, no lo aprobás aunque funcione.

## Enlaces que deben estar abiertos antes de tu turno

- Repositorio: https://github.com/LautyUCC/ingesoft3
- decisiones.md: https://github.com/LautyUCC/ingesoft3/blob/main/decisiones.md
- TP1 — PR del conflicto: https://github.com/LautyUCC/ingesoft3/pull/4
- TP1 — Release: https://github.com/LautyUCC/ingesoft3/releases/tag/v1.0.0
- TP2 — paquete backend: https://github.com/users/LautyUCC/packages/container/package/photomatch-backend
- TP2 — paquete frontend: https://github.com/users/LautyUCC/packages/container/package/photomatch-frontend
- TP3 — Project: https://github.com/users/LautyUCC/projects/1
- TP3 — Sprint Board: https://github.com/users/LautyUCC/projects/1/views/2
- TP3 — tarea cerrada: https://github.com/LautyUCC/ingesoft3/issues/9
- TP3 — PR trazable: https://github.com/LautyUCC/ingesoft3/pull/12
- TP4 — PR rojo y luego verde: https://github.com/LautyUCC/ingesoft3/pull/14
- TP4 — Actions: https://github.com/LautyUCC/ingesoft3/actions/workflows/ci.yml
- TP4 — Release: https://github.com/LautyUCC/ingesoft3/releases/tag/v4.0.0

## Alerta crítica antes de la defensa

Al generar esta guía, los paquetes GHCR de backend y frontend todavía figuraban como **privados**. La defensa exige que sean públicos y que docker-compose.registry.yml pueda descargarlos. Antes de presentar:

1. Abrí cada paquete.
2. Entrá a **Package settings**.
3. En **Danger Zone**, elegí **Change visibility → Public**.
4. Confirmá el nombre del paquete.
5. Probá el pull después de cerrar sesión de Docker o desde otra máquina.

También confirmá visualmente que el Sprint Board tenga límite **WIP 2** sobre la columna **In Progress**.

## Checklist del día anterior

- [ ] Formulario P1 enviado con URL del repositorio y URL del Project.
- [ ] Repositorio público.
- [ ] Project público.
- [ ] decisiones.md contiene TP1, TP2, TP3 y TP4 en main.
- [ ] No hay Pull Requests importantes abiertos.
- [ ] Tags tp1, tp2, tp3 y tp4 publicados.
- [ ] Releases v1.0.0 y v4.0.0 publicadas.
- [ ] Paquetes backend y frontend públicos.
- [ ] WIP 2 visible en el Sprint Board.
- [ ] Docker Desktop iniciado.
- [ ] Sistema levantado usando docker-compose.registry.yml.
- [ ] Los tres servicios están healthy.
- [ ] GitHub CLI autenticado como LautyUCC.
- [ ] Notebook cargada y cargador disponible.
- [ ] Guion practicado con reloj.

## Preparación técnica antes de sentarte

Parate en la entrega:

~~~powershell
cd C:\ingesoft3\entrega-tp1
~~~

Comprobá que no exista trabajo local sin guardar:

~~~powershell
wsl.exe bash -lc "cd /mnt/c/ingesoft3/entrega-tp1 && git status --short --branch"
~~~

El resultado debe ser solamente:

~~~text
## main...origin/main
~~~

Creá o actualizá el archivo local de variables:

~~~powershell
Copy-Item .env.example .env -Force
~~~

Editá .env y usá valores locales conocidos. Después levantá **la variante de registry**, no la variante que construye:

~~~powershell
docker compose -f docker-compose.registry.yml pull
docker compose -f docker-compose.registry.yml up -d
docker compose -f docker-compose.registry.yml ps
~~~

En la columna IMAGE deben aparecer:

~~~text
ghcr.io/lautyucc/photomatch-backend:v0.1.0
ghcr.io/lautyucc/photomatch-frontend:v0.1.0
postgres:16-alpine
~~~

Los servicios deben quedar healthy. No levantes el sistema desde cero durante la defensa: tiene que estar funcionando antes de sentarte.

## Guion cronometrado

Objetivo sugerido para Grupo B, 6 minutos:

- TP1: 55 segundos.
- TP2: 70 segundos.
- TP3: 60 segundos.
- TP4: 95 segundos.
- Pregunta sobre tu caso y margen: 80 segundos.

Para Grupo A reducí cada recorrido y apuntá a terminar los cuatro TP en unos 4 minutos.

---

# TP1 — Git colaborativo

## Qué tenés que mostrar

### Paso 1 — Push directo rechazado

Antes de hacerlo, verificá que estés en main y que el árbol esté limpio:

~~~powershell
wsl.exe bash -lc "cd /mnt/c/ingesoft3/entrega-tp1 && git switch main && git pull && git status --short"
~~~

Usá un commit vacío para no modificar archivos reales:

~~~powershell
wsl.exe bash -lc "cd /mnt/c/ingesoft3/entrega-tp1 && git commit --allow-empty -m 'demo: comprobar proteccion de main' && git push origin main"
~~~

GitHub debe responder que la rama está protegida y que los cambios deben entrar mediante Pull Request.

Después de mostrar el rechazo, descartá únicamente ese commit vacío:

~~~powershell
wsl.exe bash -lc "cd /mnt/c/ingesoft3/entrega-tp1 && git reset --hard origin/main"
~~~

Ejecutá el reset solamente si git status estaba limpio y el único commit local era el commit vacío de demostración.

### Paso 2 — Conflicto, tag y Release

Abrí el PR #4 y mostrale al profesor:

- Las dos ramas que cambiaron la misma línea.
- El commit donde aparecieron y se resolvieron los marcadores.
- El título final que combinó ambas propuestas.

Después abrí la Release v1.0.0 y explicá que el tag identifica un commit exacto y la Release publica ese estado con notas.

## Qué decir

“main está protegida para que el proceso no dependa de acordarnos de cumplirlo. Ni el administrador puede pushear directamente. Todo cambio entra por PR, deja diff y conversación, y se verifica antes de integrarse.”

“Git no resolvió el conflicto porque dos ramas reemplazaron la misma línea de formas distintas. El algoritmo detecta dos resultados incompatibles, pero no conoce la intención correcta; la resolución requiere una decisión humana.”

## Archivos para revisar

- decisiones.md, sección TP1.
- evidencias.md, sección TP1.
- .gitignore.
- README.md.

## Conceptos que tenés que dominar

- Una rama es un puntero móvil a un commit.
- Un commit es un snapshot enlazado a su padre.
- fetch descarga referencias; pull descarga e integra.
- Un PR propone integrar una rama y permite revisar el diff.
- Un conflicto no significa que Git esté roto: significa que no puede elegir una intención.
- v1.0.0 representa versión mayor 1, funcionalidades 0 y correcciones 0.
- Un tag apunta a un commit; una Release agrega publicación y notas.

## Preguntas probables

### ¿Por qué proteger main si trabajan con confianza?

Porque la protección evita errores accidentales, estandariza el proceso y conserva trazabilidad. La confianza no reemplaza controles reproducibles.

### ¿Por qué el merge de GitHub no aparecía localmente?

Porque el repositorio local no se actualiza automáticamente. Hace falta fetch o pull para traer la nueva referencia remota y actualizar la rama local.

### ¿Cómo se evitaba el conflicto?

Coordinando zonas de cambio, trabajando con ramas pequeñas, integrando más seguido o actualizando la rama antes. Actualizar antes no garantiza que desaparezca, pero permite resolverlo temprano.

---

# TP2 — Docker y Compose

## Qué tenés que mostrar

### Paso 1 — Sistema levantado desde registry

Ejecutá:

~~~powershell
docker compose -f docker-compose.registry.yml ps
~~~

Señalá:

- IMAGE contiene tus dos imágenes ghcr.io versionadas.
- PostgreSQL está healthy.
- Backend y frontend están healthy.
- El frontend publica el puerto 3000.
- PostgreSQL no publica 5432 hacia el host.

### Paso 2 — Secretos

En GitHub mostrale:

- .env.example existe.
- .env no existe en el repositorio.
- .gitignore contiene .env.

Explicá que .env.example documenta nombres y valores reemplazables; .env contiene configuración local y secretos.

### Paso 3 — Volumen

Ejecutá:

~~~powershell
docker volume ls
~~~

Mostrá photomatch_data y explicá que PostgreSQL guarda allí /var/lib/postgresql/data.

## Arquitectura que debés explicar

~~~text
Navegador
   |
   v
frontend Nginx :80
   |-- sirve CSS
   |-- proxy HTTP
   v
backend Express :3000
   |
   v
db PostgreSQL :5432
   |
   v
volumen photomatch_data
~~~

PhotoMatch usa EJS renderizado en servidor. Nginx no es una SPA: funciona como entrada HTTP, sirve assets y reenvía las rutas dinámicas hacia Express.

## Archivos para revisar

- docker-compose.yml.
- docker-compose.registry.yml.
- .env.example.
- .gitignore.
- backend/Dockerfile.
- backend/.dockerignore.
- frontend/Dockerfile.
- frontend/.dockerignore.
- frontend/nginx.conf.
- backend/src/config/database.js.
- backend/src/routes/index.js, endpoint /health.
- backend/src/db/schema.sql.
- decisiones.md, sección TP2.
- evidencias.md, sección TP2.
- DEFENSA-TP2.md.

## Conceptos que tenés que dominar

### Imagen versus contenedor

La imagen es una plantilla inmutable por capas. El contenedor es una instancia ejecutable, con proceso, red y capa escribible efímera.

### Multi-stage

El backend separa dependencias completas, tests, dependencias productivas y runtime. La imagen final excluye tests, Supertest y cache de npm. El frontend ensambla assets en una etapa y usa Nginx como runtime final.

### Comunicación

Compose crea una red y DNS interno. El backend usa db como host; Nginx usa backend. localhost dentro de un contenedor significa ese mismo contenedor.

### depends_on y healthcheck

depends_on sin condición solo ordena el arranque. No demuestra que el proceso acepte tráfico. pg_isready comprueba PostgreSQL y /health comprueba Express.

### Persistencia

docker compose down elimina contenedores y red, pero conserva el volumen. down -v también elimina los datos.

### CMD y ENTRYPOINT

ENTRYPOINT fija el ejecutable principal. CMD define argumentos por defecto o, usado solo, un comando reemplazable. El backend usa CMD para ejecutar Node.

## Pregunta particular de tu arquitectura

### ¿Por qué hay dos imágenes si EJS renderiza las páginas en backend?

Porque la presentación usa plantillas de servidor, algo permitido por la consigna. Express genera HTML y Nginx es la capa frontal desplegable que sirve CSS y realiza reverse proxy. No afirmamos que sea una SPA ni que sean microservicios.

---

# TP3 — Planificación y trazabilidad

## Qué tenés que mostrar

Empezá desde la tarea cerrada #9, no desde la portada del Project.

1. Mostrá que la tarea está Closed y Done.
2. Abrí el PR #12 que la cerró.
3. Mostrá el commit que agregó .github/workflows/ci.yml.
4. Volvé a la tarea y abrí su Parent issue: historia #8.
5. Leé el formato “Como desarrollador quiero… para…”.
6. Mostrá sus cuatro criterios de aceptación.
7. Subí desde la historia a la épica #7.
8. Abrí Sprint Board y señalá Sprint 1 y WIP 2.

La cadena completa es:

~~~text
Épica #7
  └── Historia #8
        ├── Tarea #9 cerrada
        │     └── PR #12
        │           └── commit 16c3b42
        └── Tarea #10 abierta

Bug #11 independiente
~~~

## Qué decir

“La épica expresa el objetivo amplio del semestre. La historia expresa valor y tiene criterios verificables. Las tareas son trabajo técnico concreto. El PR #12 incluye Closes #9 en la descripción; al mergearse contra main, GitHub cerró la tarea y el workflow del Project la movió a Done.”

## Archivos y pantallas para revisar

- Project público.
- Sprint Board.
- Issues #7, #8, #9, #10 y #11.
- PR #12.
- .github/workflows/ci.yml.
- decisiones.md, sección TP3.
- DEFENSA-TP3.md.

## Conceptos que tenés que dominar

### Criterios verificables

“Que CI funcione bien” no sirve porque no define una observación. “El workflow corre en cada PR a main” sí puede comprobarse abriendo un PR.

### Sprint

Se eligieron 14 días porque equilibran foco, costo de planificación y frecuencia de feedback.

### WIP 2

Una persona más una tarea adicional. Permite avanzar cuando algo espera revisión sin empezar diez actividades. Si nunca se alcanza, probablemente está demasiado alto.

### Historia mal escrita

“Como desarrollador quiero crear la tabla usuarios” es una tarea técnica disfrazada: describe implementación y no valor para un usuario. Una mejor historia sería: “Como administrador quiero registrar usuarios para que cada integrante acceda de forma segura”; crear la tabla sería tarea hija.

### Bug independiente

Representa un defecto encontrado sobre algo ya entregado. No cuelga de la historia porque no era trabajo planificado de esa historia. Es una convención del proceso, no una limitación técnica de GitHub.

### strict versus trazabilidad

No mezcles conceptos: strict pertenece al gate del TP4. La trazabilidad del TP3 conecta planificación, issue, PR y commit.

---

# TP4 — CI y gate

## Qué tenés que mostrar

### Paso 1 — PR rojo y bloqueado

Abrí el PR #14 y seleccioná el primer commit:

~~~text
280b6c5 demo: romper el build del backend a propósito
~~~

Mostrá:

- build-backend rojo.
- build-frontend verde.
- Estado BLOCKED o merge deshabilitado.
- Log donde npm ci falla por la dependencia inválida.

### Paso 2 — Fix y verde

Mostrá el segundo commit:

~~~text
9813cf2 fix: quitar dependencia invalida de la demo
~~~

Después mostrale que:

- build-backend quedó verde.
- build-frontend quedó verde.
- El PR pudo mergearse.

### Paso 3 — Jobs, cache y badge

Abrí Actions y una corrida del workflow. Mostrá que build-backend y build-frontend comienzan aproximadamente al mismo tiempo.

En la corrida 33457072238, buscá CACHED:

- Backend reutilizó seis capas.
- Frontend reutilizó cuatro capas.
- Ambos importaron manifests de cache GHA diferentes.

Volvé al README y mostrá el badge. Hacé clic para demostrar que enlaza al historial de Actions.

## Archivos para revisar

- .github/workflows/ci.yml.
- backend/Dockerfile.
- frontend/Dockerfile.
- README.md.
- decisiones.md, sección TP4.
- DEFENSA-TP4.md.
- PR #13, implementación.
- PR #14, demostración.

## Conceptos que tenés que dominar

### Integración continua

Es integrar cambios pequeños y frecuentes con verificación rápida. Un pipeline es automatización; solo contribuye a CI si acompaña integraciones frecuentes y feedback rápido.

### Triggers

pull_request verifica antes del merge y produce los checks. push a main verifica el resultado integrado y alimenta el badge.

### Paralelismo

Los jobs no declaran needs, por lo que pueden correr simultáneamente. Cada job obtiene su propio runner, filesystem y Docker; no comparten imágenes ni archivos.

### Cache

type=gha guarda capas en GitHub. mode=max incluye capas intermedias. scope=backend y scope=frontend evitan que los jobs sobrescriban el mismo estante.

Si desaparece el cache, el build tarda más pero sigue siendo correcto.

### Dockerfile como contrato

El pipeline construye la misma receta que se desplegará. Ejecutar comandos distintos en CI crearía dos definiciones que podrían divergir.

### Gate

main requiere PR y dos checks: build-backend y build-frontend. strict true obliga a actualizar la rama con el main actual antes del merge.

### Por qué se rompió package.json

PhotoMatch usa Node interpretado. Un error en un archivo JavaScript puede no ejecutarse durante docker build. Agregar una dependencia inválida sí rompe npm ci durante la construcción y demuestra que el gate actúa.

---

# decisiones.md — contenido que debés saber defender

## TP1

- Por qué Git no resolvió el conflicto.
- Cómo podía prevenirse o detectarse antes.
- Problemas encontrados.
- Uso de IA y verificación.

## TP2

- Por qué se eligió PhotoMatch.
- Por qué hay etapas múltiples.
- Cómo se encuentran servicios.
- depends_on versus healthcheck.
- Persistencia y secretos.
- Problemas y uso de IA.

## TP3

- Sprint de 14 días y justificación.
- WIP 2 y justificación.
- Diagnóstico de la historia mal escrita.
- Problemas y uso de IA.

## TP4

- Dos jobs y paralelismo.
- Capas cacheadas y scopes.
- Qué ocurre sin cache.
- Por qué se usan Dockerfiles.
- Problemas y uso de IA.

# Preguntas posibles sobre tu caso

El profesor puede elegir algo concreto de tu repositorio o decisiones.md. Prepará especialmente:

1. ¿Por qué PhotoMatch es monolito modular y no microservicios?
2. ¿Por qué se duplican los CSS en backend y frontend?
3. ¿Por qué las sesiones están en memoria y qué limitación produce?
4. ¿Qué hace init.js y por qué debe ser idempotente?
5. ¿Por qué PostgreSQL no publica puerto?
6. ¿Por qué Node usa varias etapas si no compila?
7. ¿Qué parte realizó la IA y cómo comprobaste que funciona?
8. ¿Por qué el PR #14 tiene dos commits que se cancelan?
9. ¿Por qué el TP4 no ejecuta los once tests todavía?
10. ¿Qué cambiarías antes de usar PhotoMatch en producción?

# Errores que te pueden hacer perder tiempo

- Llegar con Docker detenido.
- Levantar docker-compose.yml y mostrar imágenes locales entrega-tp1-backend en lugar de GHCR.
- Tener paquetes GHCR privados.
- Tener .env commiteado.
- Mostrar el repositorio como URL del Project.
- Empezar TP3 desde la épica y perder tiempo buscando el PR.
- Abrir un PR distinto al #14 para TP4.
- Explicar que cache y artefacto son lo mismo.
- Decir que depends_on espera disponibilidad sin mencionar healthcheck.
- Afirmar que Nginx es una SPA.
- Ejecutar el push de TP1 con cambios locales sin guardar.
- Intentar arreglar algo durante la defensa: el reloj no se detiene.

# Ensayo final

Practicá tres veces:

1. Sin reloj, entendiendo cada movimiento.
2. Con reloj y leyendo esta guía solo si te trabás.
3. Con reloj, sin leer, y pidiéndole a otra persona que te interrumpa con una pregunta.

La meta no es recitar definiciones: es navegar tu repo, señalar evidencia y explicar por qué cada pieza existe.
