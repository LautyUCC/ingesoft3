# Guía de estudio — Defensa TP2

## Archivos que hay que estudiar

1. `docker-compose.yml`: servicios, variables, volumen, red, puertos, dependencias y salud.
2. `backend/Dockerfile`: stages, caché, tests, dependencias productivas, usuario y CMD.
3. `backend/.dockerignore`: contexto de build versus contenido de imagen.
4. `frontend/Dockerfile`: armado de assets y runtime Nginx.
5. `frontend/nginx.conf`: CSS, reverse proxy y nombre `backend`.
6. `frontend/.dockerignore`: exclusiones del contexto frontal.
7. `.env.example` y `.gitignore`: variables documentadas versus secretos.
8. `docker-compose.registry.yml`: diferencia entre `build:` e `image:`.
9. `backend/src/app.js` y `backend/src/routes/index.js`: arranque y `/health`.
10. `backend/src/config/database.js`: conexión mediante `DATABASE_URL`.
11. `backend/src/db/schema.sql`: datos persistentes.
12. `backend/test/validationService.test.js`: reglas que justifican elegir la app.
13. `decisiones.md`: elecciones, problemas y verificación de IA.
14. `evidencias.md`: pruebas realizadas y cómo repetirlas.

## Respuestas que debés dominar

### Imagen versus contenedor

La imagen es una plantilla inmutable por capas. El contenedor es una instancia ejecutable, con proceso, red y capa escribible efímera.

### Por qué multi-stage

Permite usar herramientas en etapas intermedias sin copiarlas a producción. El backend final excluye tests y dependencias de desarrollo; el frontend final contiene Nginx, configuración y assets.

### Por qué Node aparece en varias etapas

Node es interpretado y no tiene una pareja SDK/runtime como .NET. La etapa final sigue necesitando Node, pero no necesita Supertest, tests ni caché de npm.

### CMD versus ENTRYPOINT

`ENTRYPOINT` fija el ejecutable principal. `CMD` aporta argumentos predeterminados o, usado solo, un comando reemplazable. PhotoMatch usa `CMD ["node", "src/app.js"]`.

### Cómo se encuentran los servicios

Compose crea DNS interno. El backend resuelve `db` y Nginx resuelve `backend`. `localhost` dentro de un contenedor apunta al mismo contenedor.

### Por qué PostgreSQL no publica 5432

Solo el backend lo necesita. Mantenerlo en la red interna reduce exposición y evita conflictos con el host.

### Por qué depends_on no alcanza

Un proceso iniciado puede no estar listo. `pg_isready` comprueba PostgreSQL y `/health` comprueba Express; `service_healthy` espera disponibilidad real.

### Dónde persisten los datos

En `photomatch_data`, montado sobre `/var/lib/postgresql/data`. Borrar contenedores no borra el volumen; `down -v` sí.

### Por qué .env no se sube

Contiene secretos del entorno. `.env.example` solo documenta nombres y valores reemplazables.

### Por qué hay frontend si EJS renderiza en backend

La consigna admite plantillas de servidor. Express genera HTML; Nginx es la entrada desplegable que sirve CSS y hace proxy. No se afirma que exista una SPA.

### Compose local versus registry

El local usa `build:`; el de registry usa `image:` para descargar artefactos `v0.1.0`. Así otra máquina ejecuta sin compilar.

## Demostración sugerida

```bash
git clone https://github.com/LautyUCC/ingesoft3.git demo-tp2
cd demo-tp2
cp .env.example .env
docker compose up -d
docker compose ps
curl http://localhost:3000/health
docker compose down
```

Explicá primero la arquitectura y después recorré archivos. Relacioná cada configuración con el problema que resuelve.
