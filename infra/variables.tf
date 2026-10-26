variable "backend_image" {
  description = "Imagen GHCR inmutable del backend (sha-<commit> de TP7)"
  type        = string
}

variable "frontend_image" {
  description = "Imagen GHCR inmutable del frontend (mismo commit)"
  type        = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "session_secret" {
  type      = string
  sensitive = true
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "admin_email" {
  type    = string
  default = "admin@photomatch.local"
}

variable "sentry_dsn" {
  type      = string
  sensitive = true
  default   = ""
}

variable "sentry_browser_dsn" {
  type      = string
  sensitive = true
  default   = ""
}

variable "frontend_port" {
  type    = number
  default = 3003
}
