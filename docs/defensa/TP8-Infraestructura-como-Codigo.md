# Guía de Estudio y Defensa — TP8: Infraestructura como Código (IaC) con Terraform
**Materia:** Ingeniería de Software III — Universidad Católica de Córdoba (UCC)  
**Ciclo Lectivo:** 2026  
**Alumno:** Lautaro Alejo Vallino (Legajo: 2301009) — Comisión 2  
**Aplicación:** PhotoMatch (Gestión de coberturas fotográficas deportivas)  
**Release asociada:** `v8.0.0`

---

## A. Introducción Conceptual

### 1. Paradigma Declarativo vs. Imperativo
- **Enfoque Imperativo (Scripts Bash / CLI):** Se describe *cómo* alcanzar el estado paso a paso (`docker run ...`, `docker network create ...`). Si el script se ejecuta dos veces, falla por colisiones de nombres o crea recursos duplicados a menos que se escriba lógica defensiva compleja.
- **Enfoque Declarativo (Terraform / HCL):** Se define *cuál es el estado deseado* de la infraestructura. El motor de Terraform compara la declaración con el estado real registrado y calcula el grafo de dependencias y el plan mínimo de mutación necesario para converger al estado declarado.

### 2. Gestión de Estado (`terraform.tfstate`) y Drift
- **Archivo de Estado:** Terraform almacena el mapeo entre los identificadores declarados en HCL y los IDs de los recursos aprovisionados en el proveedor (Docker, AWS, etc.). 
- **Drift (Desviación):** Ocurre cuando un operador modifica o elimina un recurso manualmente fuera de Terraform. En la siguiente ejecución de `terraform plan`, Terraform detecta la discrepancia comparando el estado real del proveedor con el estado deseado y planifica la reconciliación.
- **Seguridad del Estado:** El archivo de estado contiene en texto claro los valores asignados a variables sensibles (`db_password`, cadenas de conexión). Por este motivo, **nunca se versiona en Git** (está expresamente excluido en `.gitignore`).

### 3. Principio de Idempotencia
La idempotencia es la propiedad fundamental de la IaC: ejecutar `terraform apply` $N$ veces consecutivas sobre una configuración que ya convergió debe producir **exactamente el mismo resultado** con cero modificaciones adicionales (`0 to add, 0 to change, 0 to destroy`).

---

## B. Estado Inicial de PhotoMatch antes del TP8

Antes de abordar el TP8:
- Los ambientes de QA y Producción se gestionaban mediante Docker Compose (`deploy/compose.yml`).
- No existía ninguna definición declarativa formal de infraestructura bajo la herramienta estándar de la industria (Terraform).
- No se disponía de un tercer ambiente efímero (*preprod*) que pudiera nacer, verificarse y destruirse a demanda frente al docente sin afectar la operación continua de QA y Producción.

---

## C. Implementación Paso a Paso

### 1. Estructura Modular en `infra/`
Se creó la carpeta `infra/` con los siguientes archivos desacoplados:
- `versions.tf`: Fija la versión mínima de Terraform (`>= 1.5.0`, corriendo `v1.17.0`) y el proveedor oficial de Docker (`kreuzwerker/docker` versión `~> 4.6.0`).
- `variables.tf`: Declara las entradas parametrizables: imágenes GHCR inmutables (`backend_image`, `frontend_image`), credenciales marcadas con `sensitive = true` (`db_password`, `session_secret`, `admin_password`) y el puerto web externo (`frontend_port = 3003`).
- `main.tf`: Declara los 8 recursos interconectados de preproducción.
- `outputs.tf`: Expone la URL accesible `http://127.0.0.1:3003` y la URL interna de red.

### 2. Declaración de los 8 Recursos en `main.tf`
1. `docker_network.preprod`: Red aislada `photomatch-preprod` tipo bridge.
2. `docker_volume.db`: Volumen de almacenamiento persistente `photomatch-preprod-data`.
3. `docker_image.postgres`: Imagen `postgres:16-alpine`.
4. `docker_image.backend`: Imagen GHCR inmutable `ghcr.io/lautyucc/photomatch-backend:sha-<COMMIT>`.
5. `docker_image.frontend`: Imagen GHCR inmutable `ghcr.io/lautyucc/photomatch-frontend:sha-<COMMIT>`.
6. `docker_container.db`: Contenedor PostgreSQL 16 con credenciales seguras y volumen montado.
7. `docker_container.backend`: Contenedor Express conectado a la red `preprod`, con inyección de secretos e inicialización dependiente de la base (`depends_on = [docker_container.db]`).
8. `docker_container.frontend`: Contenedor Nginx mapeado al puerto 3003 y vinculado dinámicamente al backend.

### 3. Resolución de Desafíos de Conectividad en macOS
- **Socket de Docker Desktop:** En macOS, el daemon de Docker no escucha por defecto en el socket tradicional de Linux `/var/run/docker.sock`. Se resolvió exportando `DOCKER_HOST` a partir de `docker context inspect --format '{{.Endpoints.docker.Host}}'`.
- **Restricción de Longitud de SESSION_SECRET:** La aplicación exige en producción que `SESSION_SECRET` posea al menos 32 caracteres aleatorios. Se parametrizó una clave criptográfica de 38 caracteres para evitar excepciones fatales en el arranque.

---

## D. Explicación del Código Central

### 1. Interconexión Declarativa y Derivación Dinámica (`infra/main.tf`)
```hcl
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
    "DEPLOY_ENV=preprod"
  ]
  networks_advanced {
    name = docker_network.preprod.name
  }
  depends_on = [docker_container.db]
}
```
*Análisis técnico:*
- `DATABASE_URL`: No hardcodea nombres de hosts. Se deriva directamente del atributo `${docker_container.db.name}`. Si el nombre del contenedor de la base cambia, Terraform reconstruye la cadena y la inyecta automáticamente.
- `depends_on`: Modela el grafo de dependencias para asegurar que la base de datos se inicie antes que el backend.

### 2. Gestión de Secretos sin Exposición (`infra/variables.tf`)
```hcl
variable "db_password" {
  type        = string
  sensitive   = true
  description = "Contraseña de la base de datos de preproducción"
}
```
*Análisis técnico:*
- La bandera `sensitive = true` instruye al CLI de Terraform a redactar los valores en los logs de salida (`(sensitive value)`), impidiendo fugas accidentales de credenciales en terminales o grabaciones de pantalla.

---

## E. Decisiones de Ingeniería y Trade-offs

| Decisión Tomada | Alternativa Descartada | Justificación Técnica | Desventajas / Limitaciones |
|---|---|---|---|
| **Provider `kreuzwerker/docker` fijado en 4.6.0** | Provider AWS / DigitalOcean / Cloud | Permite aprovisionar recursos locales idénticos a los de la nube sin costos económicos ni requerir tarjetas de crédito para la defensa universitaria. | Limitado al host donde corre el daemon de Docker. |
| **Aislamiento Total en Puerto 3003** | Sobrescribir QA en puerto 3001 | Permite validar la coexistencia pacífica de tres ambientes (QA 3001, PROD 3002 y PREPROD 3003) sin interferencias. | Requiere recursos adicionales de CPU y memoria en el host. |
| **Variables Inyectadas vía `TF_VAR_*` / CLI** | Archivo `terraform.tfvars` versionado | Versionar secretos en Git viola las buenas prácticas de DevSecOps. | Requiere pasar variables explícitas al ejecutar comandos. |

---

## F. Pruebas y Evidencias Reales

1. **Verificación de Validación y Formato:**
   - `terraform fmt -check` $\rightarrow$ Formato HCL canónico.
   - `terraform validate` $\rightarrow$ `Success! The configuration is valid.`
2. **Ciclo de Vida Completo Verificado:**
   - `terraform plan` $\rightarrow$ 8 recursos por agregar (`Plan: 8 to add, 0 to change, 0 to destroy`).
   - `terraform apply` $\rightarrow$ 8 recursos creados exitosamente.
   - Endpoint `/health` verificado en vivo:
     ```bash
     $ curl -s http://127.0.0.1:3003/health
     {"status":"ok","version":"1.0.0","commit":"1caea7ce1e19d4b2b84676ec8a35686f6e26f2e3","database":"connected"}
     ```
3. **Demostración de Coexistencia Pacífica Simultánea:**
   - QA (`:3001`): 200 OK con DB conectada.
   - PROD (`:3002`): 200 OK con DB conectada.
   - PREPROD (`:3003`): 200 OK con DB conectada.
4. **Demostración de Idempotencia:**
   - Segundo `terraform plan` $\rightarrow$ `No changes. Your infrastructure matches the configuration.`
5. **Destrucción Limpia:**
   - `terraform destroy` $\rightarrow$ `Destroy complete! Resources: 8 destroyed.`
   - Verificación posterior: QA (`:3001`) y PROD (`:3002`) continuaron respondiendo 200 OK sin inmutarse.
6. **Release Oficial:**
   - Etiqueta Git y [Release v8.0.0](https://github.com/LautyUCC/ingesoft3/releases/tag/v8.0.0) publicada en GitHub.

---

## G. Preparación para la Defensa Oral

### Preguntas Frecuentes de la Cátedra

1. **¿Qué es Infraestructura como Código y qué problemas resuelve?**  
   *Respuesta:* IaC es la práctica de gestionar y aprovisionar infraestructura informática a través de archivos de definición legibles por máquina, en lugar de configuraciones físicas o herramientas de configuración interactiva. Resuelve el problema del "drift" de configuración, la falta de reproducibilidad y los errores humanos en despliegues manuales.

2. **¿Dónde se almacena el archivo de estado de Terraform y por qué es crítico?**  
   *Respuesta:* En `terraform.tfstate`. Es crítico porque mapea los recursos declarados con los IDs del proveedor real. Debe excluirse de Git porque contiene secretos en texto plano, y en producción en la nube se almacena en un backend remoto con cifrado y locking (ej. AWS S3 + DynamoDB).

3. **¿Qué significa que un plan muestre `(known after apply)`?**  
   *Respuesta:* Indica valores que no pueden calcularse de forma estática antes de la ejecución porque dependen de identificadores generados dinámicamente por el proveedor durante la creación del recurso (por ejemplo, el ID del contenedor o su IP asignada).

4. **¿Por qué preproducción no interfiere con QA ni con Producción?**  
   *Respuesta:* Porque declara su propia red bridge (`photomatch-preprod`), su propio volumen Docker (`photomatch-preprod-data`) y mapea un puerto externo diferente (`3003`).

5. **¿Qué es el "Drift" y cómo lo detecta Terraform?**  
   *Respuesta:* Es la divergencia entre el estado real de la infraestructura y el estado declarado en el código. Terraform lo detecta durante el comando `terraform plan` o `terraform refresh`, consultando la API del proveedor y comparando contra el estado almacenado.

6. **¿Cómo se demostró la idempotencia en su entrega?**  
   *Respuesta:* Tras ejecutar `terraform apply` y alcanzar el estado de preproducción deseado, ejecutamos un segundo `terraform plan` que devolvió textualmente: *"No changes. Your infrastructure matches the configuration"*.

### Las 3 Preguntas Más Difíciles

7. **¿Qué diferencia existe entre Terraform y herramientas de gestión de configuración como Ansible o Puppet?**  
   *Respuesta:* Terraform es una herramienta de aprovisionamiento declarativa e inmutable orientada a crear la infraestructura base (redes, volúmenes, contenedores, servidores). Ansible es una herramienta de gestión de configuración imperativa orientada a configurar software dentro de servidores ya existentes.

8. **¿Qué pasaría si dos miembros del equipo ejecutan `terraform apply` al mismo tiempo?**  
   *Respuesta:* Se produciría una condición de carrera sobre el archivo de estado, provocando corrupción de datos o creación de recursos huérfanos. Para evitarlo se utiliza *State Locking*, un mecanismo que bloquea el estado durante las operaciones de escritura (en entornos locales se bloquea automáticamente; en la nube se usa DynamoDB o Consul).

9. **¿Por qué fijaron la versión del provider en `versions.tf` (`~> 4.6.0`)?**  
   *Respuesta:* Para garantizar determinismo en el aprovisionamiento. Si no se fija la versión, una actualización mayor del proveedor (con cambios disruptivos en los argumentos de HCL) podría romper el pipeline o alterar el comportamiento de los contenedores sin previo aviso.

---

## H. Resumen Final de Estudio

- **Declarativo:** Definimos el estado final deseado, Terraform gestiona el grafo de dependencias.
- **Idempotencia:** Múltiples aplicaciones sucesivas producen cero cambios colaterales.
- **Ciclo de vida:** `init` $\rightarrow$ `plan` (8 altas) $\rightarrow$ `apply` (:3003) $\rightarrow$ `destroy` (8 bajas).
- **Pitch de 2 minutos:** _"En el TP8 aplicamos Infraestructura como Código a PhotoMatch utilizando Terraform 1.17 con el provider de Docker. Desarrollamos un módulo completo en infra/ que declara de forma reproducible 8 recursos: red aislada, volumen persistente, imágenes inmutables de GHCR y contenedores enlazados dinámicamente. Demostramos el ciclo de vida completo: levantamos el ambiente preprod en el puerto 3003 verificando 200 OK con PostgreSQL, demostramos estricta idempotencia y convivencia simultánea con QA y Producción, y finalizamos con la destrucción limpia de los recursos sin afectar la operación continua del sistema."_
