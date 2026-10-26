#!/usr/bin/env bash
set -euo pipefail

: "${DEPLOY_ENV:?Falta nombre del entorno}"
: "${COMMIT_SHA:?Falta SHA del commit}"
: "${APP_PORT:?Falta puerto del frontend}"
: "${POSTGRES_PASSWORD:?Falta clave DB}"
: "${SESSION_SECRET:?Falta secreto de sesión}"
: "${ADMIN_EMAIL:?Falta email admin}"
: "${ADMIN_PASSWORD:?Falta clave admin}"

case "$DEPLOY_ENV" in qa|prod) ;; *) echo 'Entorno inválido' >&2; exit 1 ;; esac
case "$COMMIT_SHA" in *[!0-9a-f]*|'') echo 'SHA inválido' >&2; exit 1 ;; esac

export BACKEND_IMAGE="ghcr.io/lautyucc/photomatch-backend:sha-$COMMIT_SHA"
export FRONTEND_IMAGE="ghcr.io/lautyucc/photomatch-frontend:sha-$COMMIT_SHA"

docker_config_dir="$(mktemp -d)"
trap 'rm -rf "$docker_config_dir"' EXIT
printf '{"auths":{}}\n' > "$docker_config_dir/config.json"
export DOCKER_CONFIG="$docker_config_dir"

echo "Desplegando $DEPLOY_ENV desde $BACKEND_IMAGE y $FRONTEND_IMAGE"
docker compose -p "photomatch-$DEPLOY_ENV" -f deploy/compose.yml pull
docker compose -p "photomatch-$DEPLOY_ENV" -f deploy/compose.yml up -d --wait --no-build
