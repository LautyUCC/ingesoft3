# Ingeniería de Software III — Portfolio DevOps

Repositorio personal de LautyUCC para construir, de forma incremental, el sistema de entrega de la aplicación del semestre.

## TP1 — Git colaborativo

El primer trabajo práctico configura el proceso con el que los cambios ingresan al repositorio:

1. cada modificación se desarrolla en una rama corta;
2. la rama se integra mediante un Pull Request;
3. `main` permanece protegida contra pushes directos;
4. las entregas quedan identificadas mediante tags y releases.

La explicación de las decisiones está en [`decisiones.md`](decisiones.md) y el registro de comprobaciones en [`evidencias.md`](evidencias.md).

La protección de `main` fue comprobada intentando un push directo antes de integrar este cambio mediante Pull Request.

## Convenciones del repositorio

- Rama estable: `main`.
- Estrategia: GitHub Flow.
- Ramas de trabajo: `docs/<descripcion>` o `feature/<descripcion>`.
- Integración: Pull Request hacia `main`.
- Versión del TP1: `v1.0.0`.
- Snapshot académico: `tp1`.

## TP2 — PhotoMatch contenerizado

PhotoMatch administra coberturas fotográficas deportivas. Usa Node.js 22, Express, vistas EJS y PostgreSQL 16.

Arquitectura:

    Navegador
       v
    frontend (Nginx :80) --CSS y proxy--> backend (Express :3000)
                                                  v
                                          db (PostgreSQL)
                                                  v
                                         photomatch_data

Las vistas se renderizan en el servidor con EJS. Nginx sirve assets estáticos y reenvía solicitudes dinámicas a Express. PostgreSQL solo es accesible dentro de la red de Compose.

### Arranque desde una máquina limpia

Requisitos: Git y Docker con Compose.

    git clone https://github.com/LautyUCC/ingesoft3.git
    cd ingesoft3
    cp .env.example .env
    docker compose up -d --build

En PowerShell, usá `Copy-Item .env.example .env`. Reemplazá las claves de ejemplo y abrí http://localhost:3000. El usuario inicial utiliza `ADMIN_EMAIL` y `ADMIN_PASSWORD` del archivo local.

`docker compose down` conserva la base; `docker compose down -v` elimina también el volumen.

### Usar las imágenes publicadas

    cp .env.example .env
    docker compose -f docker-compose.registry.yml pull
    docker compose -f docker-compose.registry.yml up -d

- `ghcr.io/lautyucc/photomatch-backend:v0.1.0`
- `ghcr.io/lautyucc/photomatch-frontend:v0.1.0`

### Pruebas

    docker build --target test -t photomatch-backend:test ./backend

El stage de pruebas ejecuta once casos. El endpoint `GET /health` sostiene el healthcheck del backend.

### Archivos principales

    backend/       Dockerfile, .dockerignore, app y tests
    frontend/      Dockerfile, .dockerignore, nginx.conf y CSS
    docker-compose.yml
    docker-compose.registry.yml
    .env.example

## TP3 — Planificación y trazabilidad

La planificación pública de PhotoMatch vive en el [GitHub Project PhotoMatch - Pipeline DevOps 2026](https://github.com/users/LautyUCC/projects/1). Incluye la épica del semestre, una historia de integración continua, sus dos tareas, un bug independiente, Sprint 1 y trazabilidad desde una tarea hasta su Pull Request y commits.
