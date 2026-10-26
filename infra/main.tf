resource "docker_network" "preprod" {
  name = "photomatch-preprod"
}

resource "docker_volume" "db" {
  name = "photomatch-preprod-data"
}

resource "docker_image" "postgres" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

resource "docker_image" "backend" {
  name         = var.backend_image
  keep_locally = true
}

resource "docker_image" "frontend" {
  name         = var.frontend_image
  keep_locally = true
}

resource "docker_container" "db" {
  name    = "photomatch-preprod-db"
  image   = docker_image.postgres.image_id
  restart = "unless-stopped"
  env = [
    "POSTGRES_DB=photomatch",
    "POSTGRES_USER=photomatch",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]
  networks_advanced {
    name = docker_network.preprod.name
  }
  volumes {
    volume_name    = docker_volume.db.name
    container_path = "/var/lib/postgresql/data"
  }
}

resource "docker_container" "backend" {
  name    = "photomatch-preprod-backend"
  image   = docker_image.backend.image_id
  restart = "unless-stopped"
  env = [
    "PORT=3000",
    "DB_SSL_MODE=disable",
    "DATABASE_URL=postgresql://photomatch:${var.db_password}@${docker_container.db.name}:5432/photomatch",
    "SESSION_SECRET=${var.session_secret}",
    "ADMIN_EMAIL=${var.admin_email}",
    "ADMIN_PASSWORD=${var.admin_password}",
    "DEPLOY_ENV=preprod",
    "SENTRY_DSN=${var.sentry_dsn}",
    "SENTRY_BROWSER_DSN=${var.sentry_browser_dsn}",
  ]
  networks_advanced {
    name = docker_network.preprod.name
  }
  depends_on = [docker_container.db]
}

resource "docker_container" "frontend" {
  name    = "photomatch-preprod-frontend"
  image   = docker_image.frontend.image_id
  restart = "unless-stopped"
  env = [
    "PORT=80",
    "DNS_RESOLVER=127.0.0.11",
    "BACKEND_URL=http://${docker_container.backend.name}:3000",
  ]
  networks_advanced {
    name = docker_network.preprod.name
  }
  ports {
    internal = 80
    external = var.frontend_port
  }
  depends_on = [docker_container.backend]
}
