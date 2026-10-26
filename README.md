# Ingeniería de Software III — Portfolio DevOps

[![CI](https://github.com/LautyUCC/ingesoft3/actions/workflows/ci.yml/badge.svg)](https://github.com/LautyUCC/ingesoft3/actions/workflows/ci.yml)

Repositorio personal de LautyUCC para construir, de forma incremental, el sistema de entrega de la aplicación del semestre.

## P2: entrega y pruebas

La continuación de TP6–TP9 usa el fallback local permitido por la cátedra. GitHub Actions construye ambas imágenes, exige que los dos jobs pasen y publica los archivos de imagen sin reconstruirlos. Un runner propio con etiquetas `self-hosted` y `photomatch` despliega QA en `http://127.0.0.1:3001` y PROD en `http://127.0.0.1:3002`; cada entorno tiene volumen y red PostgreSQL separados. El environment `production` exige aprobación. Docker Desktop y el runner deben estar encendidos para que el pipeline y las URLs funcionen.

Para revisar las pruebas localmente: `cd backend && npm ci && npm run test:check-coverage`; `docker build -t photomatch-backend:local ./backend` y `docker build -t photomatch-frontend:local ./frontend`. Las suites Playwright viven en `frontend/e2e/` y necesitan una instancia real de PhotoMatch más `API_BASE_URL`, `E2E_BASE_URL`, `E2E_EMAIL` y `E2E_PASSWORD`; `npm ci`, `npx playwright install chromium`, `npm run test:integration` y `npm run test:e2e`. No se saltean si el entorno no responde.

`infra/` declara un preprod aislado con Terraform y provider Docker. Se usa Terraform 1.17.x, `DOCKER_HOST` del contexto Docker y las variables `TF_VAR_backend_image`, `TF_VAR_frontend_image`, `TF_VAR_db_password`, `TF_VAR_session_secret` y `TF_VAR_admin_password`. El estado se configura fuera del repositorio con `terraform init -backend-config="path=$HOME/.local/share/photomatch-tfstate/preprod.tfstate"`. `terraform apply` crea preprod en `http://127.0.0.1:3003`; `terraform destroy` elimina sólo esos recursos. Para la entrega deben indicarse los dos tags `sha-<commit>` de GHCR, no imágenes locales de prueba.

El estado real, los enlaces existentes y las evidencias que faltan están en [ESTADO-P2.md](ESTADO-P2.md) y [decisiones.md](decisiones.md). No se considera cerrado ningún TP6–TP9 hasta comprobar la corrida y release correspondientes.

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

## TP4 — Integración continua

El workflow `.github/workflows/ci.yml` se ejecuta en cada Pull Request hacia `main` y después de cada push a `main`. Los jobs `build-backend` y `build-frontend` construyen en paralelo las imágenes definidas en TP2, usando Buildx y cache de capas con scopes separados.

La preparación completa para presentar los cuatro trabajos está en [GUIA-DEFENSA-P1.md](GUIA-DEFENSA-P1.md).
