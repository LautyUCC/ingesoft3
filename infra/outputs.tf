output "frontend_url" {
  value = "http://127.0.0.1:${docker_container.frontend.ports[0].external}"
}

output "backend_url_internal" {
  value = "http://${docker_container.backend.name}:3000"
}
