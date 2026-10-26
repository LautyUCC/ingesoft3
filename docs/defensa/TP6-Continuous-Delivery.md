# Guía de Estudio y Defensa — TP6: Continuous Delivery (CD) y Ambientes Aislados
**Materia:** Ingeniería de Software III — Universidad Católica de Córdoba (UCC)  
**Ciclo Lectivo:** 2026  
**Alumno:** Lautaro Alejo Vallino (Legajo: 2301009) — Comisión 2  
**Aplicación:** PhotoMatch (Gestión de coberturas fotográficas deportivas)  
**Release asociada:** `v6.0.0`

---

## A. Introducción Conceptual

### 1. Continuous Delivery vs. Continuous Deployment
Uno de los conceptos nucleares de la materia es distinguir con precisión matemática qué separa a la Entrega Continua del Despliegue Continuo:

- **Integración Continua (CI):** Práctica en la que cada desarrollador integra código frecuentemente a una rama troncal (`main`). Cada commit dispara validación estática, compilación, ejecución de tests unitarios y cálculo de cobertura. Su objetivo es detectar incompatibilidades en minutos.
- **Entrega Continua (Continuous Delivery - CD):** Extensión de la CI donde cada cambio integrado que pasa las pruebas se empaqueta de forma inmutable y queda **listo para ser puesto en producción en cualquier momento**. El paso final hacia producción está protegido por una **decisión humana o gate de negocio** (aprobación manual).
- **Despliegue Continuo (Continuous Deployment):** Todo cambio que supera la batería automatizada de pruebas se promueve **automáticamente a producción sin intervención humana**.

En PhotoMatch implementamos estrictamente **Continuous Delivery**: el pasaje al ambiente de QA es automático tras pasar CI y publicación, pero la promoción a Producción requiere la aprobación explícita del responsable técnico mediante las *Environment Protection Rules* de GitHub.

### 2. Principio "Build Once, Deploy Many" (Construir una vez, desplegar muchas)
Un anti-patrón clásico en pipelines novatos es compilar o construir la imagen Docker en QA, y luego volver a ejecutar `docker build` cuando se decide desplegar a Producción. 
¿Por qué es peligroso? Porque entre una construcción y otra pueden cambiar dependencias remotas (`npm install`), hashes de paquetes base del sistema operativo o variables de tiempo de compilación. El artefacto que se prueba en QA **no sería el mismo** que se ejecuta en Producción.

En PhotoMatch respetamos el principio a ultranza:
1. `build-backend` y `build-frontend` construyen las imágenes Docker una única vez y las empaquetan en archivos `.tar` temporales como artefactos de GitHub Actions.
2. El job `publish` toma exactamente esos archivos `.tar`, los carga en el daemon y los publica en GitHub Packages (GHCR) con la etiqueta inmutable `sha-<COMMIT_SHA>`.
3. Los jobs `deploy-qa` y `deploy-prod` consumen **exactamente el mismo tag SHA de GHCR**, garantizando paridad binaria total entre ambos ambientes.

### 3. Aislamiento de Ambientes: QA vs. Producción
Tener ambientes aislados previene que pruebas funcionales, cargas de datos de prueba o errores de desarrollo impacten en los datos reales de los clientes:
- **Redes aisladas:** Contenedores en redes Docker independientes (`photomatch-qa-net` vs `photomatch-prod-net`).
- **Persistencia separada:** Volúmenes de base de datos PostgreSQL independientes (`photomatch-qa-db-data` vs `photomatch-prod-db-data`).
- **Puertos de acceso diferenciados:** QA atiende en `http://127.0.0.1:3001` y Producción en `http://127.0.0.1:3002`.
- **Secretos independientes:** `SESSION_SECRET`, `POSTGRES_PASSWORD` y credenciales administrativas gestionados en GitHub Environments con alcance restringido.

---

## B. Estado Inicial de PhotoMatch antes del TP6

Al finalizar el TP5, PhotoMatch contaba con:
- Una batería de pruebas unitarias con cobertura (≥80% líneas, ≥70% ramas).
- Un workflow de CI (`ci.yml`) que solo corría `npm test` sobre el backend.
- Sin contenedorización formal del frontend (Nginx no existía en el repo).
- Sin publicación de artefactos en registros de contenedores (GHCR).
- Sin pipeline de despliegue automatizado. Desplegar implicaba ejecutar scripts manuales en la máquina local sin control de versiones del artefacto ejecutado.
- Sin concepto de ambientes QA y Producción diferenciados.

---

## C. Implementación Paso a Paso

### 1. Contenedorización y Arquitectura de Despliegue
- Se creó el `Dockerfile` de producción del frontend basado en `nginx:alpine`, incorporando el archivo de configuración `frontend/default.conf.template` que actúa como reverse proxy hacia el backend y resuelve DNS dinámico en Docker.
- Se parametrizó el `Dockerfile` del backend para aceptar el argumento de construcción `COMMIT_SHA` y exponerlo en el endpoint `/health`.
- Se diseñó el manifiesto `deploy/compose.yml` que orquesta frontend, backend y PostgreSQL con soporte para variables de entorno por ambiente.

### 2. Separación de Responsabilidades en el Pipeline (`.github/workflows/ci.yml`)
El workflow se reestructuró en 5 etapas claramente desacopladas:
1. `build-backend`: Ejecuta `npm ci`, corre el Quality Gate de cobertura con `c8`, construye la imagen Docker y sube el `.tar` como artefacto.
2. `build-frontend`: Construye la imagen Docker del frontend con Nginx y sube el `.tar`.
3. `publish`: Se ejecuta solo en pushes a `main` tras completarse ambos builds. Descarga ambos `.tar`, inicia sesión en GHCR y publica con tag `sha-${{ github.sha }}`.
4. `deploy-qa`: Se ejecuta en el self-hosted runner local (`photomatch-local`). Descarga las imágenes de GHCR, recrea los contenedores de QA en el puerto 3001 y ejecuta `scripts/smoke.sh`.
5. `deploy-prod`: Requiere aprobación humana mediante el environment `production`. Descarga las mismas imágenes y recrea Producción en el puerto 3002.

### 3. Resolución de Desafíos Técnicos Reales
- **Desafío del Llavero (macOS Keychain) en Runner no interactivo:**
  El runner local corre como un servicio daemon de macOS (`launchd`). Al invocar `docker login` o `docker-compose pull`, Docker intentaba consultar interactivamente el llavero del sistema operativo, colgando la ejecución indefinidamente.
  - *Solución:* Se implementó en `scripts/deploy-local.sh` el uso de una configuración temporal de Docker (`DOCKER_CONFIG=$(mktemp -d)`) que fuerza modo anónimo para consultar los paquetes que configuramos como públicos en GHCR, y se utilizó la imagen precargada de PostgreSQL (`postgres:16-alpine`) sin consultar Docker Hub.
- **Optimización de Caché npm en Runner Propio:**
  El runner local ya conserva en disco la caché de npm. Mantener `cache: npm` en GitHub Actions provocaba la compresión y subida redundante de 687 MB a los servidores de GitHub en cada ejecución. Se eliminó esa directiva en los jobs del runner local, reduciendo el tiempo de pipeline en más de 4 minutos.

---

## D. Explicación del Código Central

### 1. Pipeline de Despliegue (`.github/workflows/ci.yml`)
```yaml
deploy-prod:
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  needs: e2e
  runs-on: [self-hosted, photomatch]
  environment: production
  permissions:
    contents: read
    packages: read
  steps:
    - uses: actions/checkout@v4
    - name: Promover las mismas imágenes a producción
      env:
        DEPLOY_ENV: prod
        APP_PORT: '3002'
        POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}
        SESSION_SECRET: ${{ secrets.SESSION_SECRET }}
        ADMIN_PASSWORD: ${{ secrets.ADMIN_PASSWORD }}
        ADMIN_EMAIL: ${{ vars.ADMIN_EMAIL }}
        COMMIT_SHA: ${{ github.sha }}
      run: bash scripts/deploy-local.sh
    - name: Smoke producción
      env:
        FRONTEND_URL: ${{ vars.FRONTEND_URL }}
        COMMIT_SHA: ${{ github.sha }}
      run: bash scripts/smoke.sh
```
*Análisis técnico:*
- `environment: production`: Activa la regla de protección configurada en el repositorio. GitHub pausa el workflow y notifica al revisor autorizado (`LautyUCC`). El job no se asigna al runner hasta que se apruebe.
- `needs: e2e`: Garantiza que producción nunca se desplegará si las pruebas de integración o E2E fallan en QA.
- `COMMIT_SHA`: Pasa el hash exacto del commit para que `scripts/deploy-local.sh` descargue esa etiqueta de GHCR.

### 2. Script de Despliegue Idempotente (`scripts/deploy-local.sh`)
```bash
# Aislamiento de Docker Config para evitar interacción con el llavero de macOS
TMP_DOCKER_CONFIG=$(mktemp -d)
trap 'rm -rf "$TMP_DOCKER_CONFIG"' EXIT

echo "Descargando imágenes verificadas desde GHCR..."
DOCKER_CONFIG="$TMP_DOCKER_CONFIG" docker pull "ghcr.io/lautyucc/photomatch-backend:sha-$COMMIT_SHA"
DOCKER_CONFIG="$TMP_DOCKER_CONFIG" docker pull "ghcr.io/lautyucc/photomatch-frontend:sha-$COMMIT_SHA"

# Recreación con Compose sin recompilar
docker-compose -p "photomatch-$DEPLOY_ENV" -f deploy/compose.yml up -d --pull never --remove-orphans
```
*Análisis técnico:*
- Usa `trap` para limpiar el directorio temporal al finalizar el script, incluso ante errores.
- `--pull never`: Obliga a Compose a utilizar estrictamente las imágenes que acabamos de descargar y verificar, impidiendo que Compose intente descargas adicionales o acceda a credenciales interactivas.

### 3. Smoke Test de Validación Post-Despliegue (`scripts/smoke.sh`)
```bash
for i in $(seq 1 30); do
  RES=$(curl -s "http://127.0.0.1:$APP_PORT/health" || true)
  STATUS=$(echo "$RES" | jq -r '.status // empty')
  COMMIT=$(echo "$RES" | jq -r '.commit // empty')
  DB=$(echo "$RES" | jq -r '.database // empty')
  
  if [ "$STATUS" = "ok" ] && [ "$COMMIT" = "$COMMIT_SHA" ] && [ "$DB" = "connected" ]; then
    echo "Smoke test superado con éxito en el intento $i."
    exit 0
  fi
  sleep 2
done
echo "Smoke test falló: el ambiente no alcanzó el estado esperado."
exit 1
```
*Análisis técnico:*
- Implementa un sondeo con reintentos exponenciales/lineales (hasta 60 segundos).
- No solo valida que devuelva HTTP 200, sino que inspecciona el JSON: confirma que la base de datos esté efectivamente conectada (`database: connected`) y que el commit desplegado coincida exactamente con el commit del pipeline (`commit: $COMMIT_SHA`).

---

## E. Decisiones de Ingeniería y Trade-offs

| Decisión Tomada | Alternativa Descartada | Justificación Técnica | Desventajas / Limitaciones |
|---|---|---|---|
| **Fallback Local Plan C con Self-Hosted Runner** | Despliegue en Render / Neon gratuitos | Los planes gratuitos de Render suspenden servicios tras inactividad (*cold starts* de 50 s) y Neon limita conexiones poolers. El runner local garantiza disponibilidad inmediata para la mesa de examen y ejecución determinista. | Exige mantener la máquina de desarrollo encendida durante la evaluación. |
| **Separación de Build y Publish con Artefactos `.tar`** | Construir y publicar directamente en el job de build | El principio de calidad exige que nada se publique en el registro hasta que la totalidad de las pruebas unitarias y umbrales de cobertura hayan sido superados. | Consume tiempo de transferencia de artefactos en GitHub (~20 s). |
| **Aprobación Manual con GitHub Environments** | Despliegue continuo directo a producción | Exigencia pedagógica de Continuous Delivery: el pase a producción es un acto de negocio supervisado. | Introduce latencia humana entre la validación técnica y la disponibilidad final. |
| **Estrategia de Rollback por redespliegue del tag anterior** | Blue/Green Deployment con balanceador de carga activo | Blue/Green duplica recursos. El retorno real a un SHA anterior se comprobó, pero **no** se cronometró el ciclo completo hasta `/health` y DB sana. | `recreate` implica una ventana de indisponibilidad; su duración total sigue pendiente de medir. |

---

## F. Pruebas y Evidencias Reales

1. **Evidencia de Rechazo de Gate de Producción:**
   - **Ejecución:** [CI Run 40277582164](https://github.com/LautyUCC/ingesoft3/actions/runs/40277582164)
   - **Actor:** `LautyUCC`
   - **Motivo registrado:** *"QA, integración y E2E pasan, pero se difiere la promoción hasta revisar rollback y observabilidad de producción"*.
   - **Resultado:** El job `deploy-prod` quedó formalmente rechazado, la corrida terminó en fallo controlado y Producción **no fue tocada**.
2. **Evidencia de Aprobación de Gate de Producción:**
   - **Ejecución:** [CI Run 40284305415](https://github.com/LautyUCC/ingesoft3/actions/runs/40284305415)
   - **Actor:** `LautyUCC`
   - **Resultado:** Aprobado. Job `deploy-prod` ejecutó el despliegue del commit `1caea7ce1e19d4b2b84676ec8a35686f6e26f2e3` y smoke test pasó 100%.
3. **Medición Real del Tiempo de Rollback:**
   - En Producción se ejecutó la reversión controlada de `99f83ef` al SHA anterior `dde81a8`.
   - **7,42 segundos** miden solo desde la creación del backend anterior hasta el inicio del frontend anterior: no incluyen el `pull` ni la verificación de `/health`/PostgreSQL. **No son el tiempo total del rollback PROD.**
   - En QA sí se midió un ciclo completo con verificación de `/health`: **20,16 segundos**; no sustituye la medición de PROD, que sigue pendiente.
4. **Release Oficial:**
   - Etiqueta Git y [Release v6.0.0](https://github.com/LautyUCC/ingesoft3/releases/tag/v6.0.0) publicada en GitHub.

---

## G. Preparación para la Defensa Oral

### Preguntas Frecuentes de la Cátedra

1. **¿Cuál es la diferencia fundamental entre Continuous Delivery y Continuous Deployment?**  
   *Respuesta:* En Continuous Delivery el software está siempre en un estado desplegable pero la promoción a producción requiere una decisión explícita (gate humano). En Continuous Deployment, cada commit que pasa los tests se despliega automáticamente a producción sin intervención manual.

2. **¿Por qué las imágenes se construyen en el job de build y se publican en un job separado?**  
   *Respuesta:* Para respetar el principio de fail-fast y no ensuciar el registry. Si las pruebas unitarias o la cobertura fallan, no debemos publicar un artefacto defectuoso. El job `publish` solo corre si `build-backend` y `build-frontend` completaron exitosamente.

3. **¿Cómo garantizan que la versión desplegada en Producción sea idéntica a la probada en QA?**  
   *Respuesta:* Mediante inmutabilidad de imágenes en GHCR. Se etiquetan con el hash SHA del commit (`sha-<COMMIT>`). En QA y en PROD se despliega exactamente el mismo digest de imagen; nunca se vuelve a hacer `docker build`.

4. **¿Qué sucede si el smoke test falla después del despliegue?**  
   *Respuesta:* El script `smoke.sh` retorna código de salida 1, lo que hace fallar el paso de GitHub Actions. Esto alerta inmediatamente al equipo y detiene el pipeline, permitiendo disparar el rollback al SHA anterior.

5. **¿Cómo se protegen los secretos de producción para que no sean leídos en QA?**  
   *Respuesta:* Usamos GitHub Environments (`qa` y `production`). Cada ambiente tiene sus propias variables y secrets configurados con permisos de acceso restringidos.

6. **¿Por qué el runner local corre como servicio daemon y qué problema provocó?**  
   *Respuesta:* Corre con `launchd` para estar disponible permanentemente sin depender de una terminal abierta. El problema fue que no tenía acceso al llavero de sesión de macOS para almacenar credenciales Docker, lo que resolvimos forzando configuración anónima para paquetes públicos y precargando la imagen de PostgreSQL.

7. **¿Cómo midieron el tiempo de rollback?**  
   *Respuesta:* En QA medimos 20,16 s desde el inicio del despliegue hasta `/health` con DB y SHA anterior. En PROD comprobamos el retorno real, pero solo tenemos 7,42 s de recreación parcial; falta medir con un único reloj desde el inicio del `pull` hasta `/health` con DB y SHA anterior. No atribuyo esos 7,42 s al rollback completo.

8. **¿Dónde se evidencia en su repositorio que un gate de producción fue rechazado?**  
   *Respuesta:* En la corrida de GitHub Actions #40277582164, accesible en la pestaña Actions y auditable vía GitHub API en `/actions/runs/40277582164/approvals`.

### Las 3 Preguntas Más Difíciles

9. **¿Qué sucedería con la base de datos de producción durante un rollback si el commit revertido aplicó una migración destructiva (ej. borró una columna)?**  
   *Respuesta:* Un rollback de contenedores solo revierte el código de la aplicación, no el estado de los datos. Para mitigar esto, se debe seguir el patrón de migraciones expand/contract (hacer cambios retrocompatibles en dos fases). En PhotoMatch, el volumen de datos es persistente y externo al ciclo de vida del contenedor, por lo que los datos no se destruyen al recrear la aplicación.

10. **Si el runner local pierde conexión a Internet en medio de un despliegue a producción, ¿en qué estado queda el clúster?**  
    *Respuesta:* Dado que usamos `docker pull` previo a `docker-compose up`, si la red cae durante la descarga de la imagen, el script aborta por `set -e` antes de tocar los contenedores en ejecución. Producción sigue corriendo intacta con la versión previa.

11. **¿Por qué eligieron un healthcheck en `/health` que consulta la base de datos en lugar de solo responder 200 OK estático?**  
    *Respuesta:* Un endpoint que responde 200 sin consultar dependencias es un *shallow healthcheck*: la app puede responder HTTP pero estar completamente rota para los usuarios si la base de datos se cayó. Nuestro endpoint ejecuta `SELECT 1` sobre PostgreSQL; si la base falla, devuelve HTTP 503 con `database: disconnected`.

---

## H. Resumen Final de Estudio

### Conceptos Clave
- **Continuous Delivery:** Automatización integral con gate humano final a producción.
- **Inmutabilidad:** Imágenes etiquetadas por SHA construidas una sola vez.
- **Aislamiento:** QA (:3001) y PROD (:3002) con redes, volúmenes y puertos disjuntos.
- **Smoke Testing:** Verificación activa post-despliegue de salud y versión.

### Pitch Oral de 2 Minutos
> *"En TP6 construimos las imágenes una sola vez y publicamos por SHA después de ambos gates de build. GitHub Actions despliega QA automáticamente en Docker local y PROD solo tras aprobación humana. La corrida 40277582164 conserva un rechazo con motivo y la 40284305415 una aprobación con smoke verde. Volvimos de verdad PROD a un SHA anterior conservando PostgreSQL; los 7,42 s documentados son solo recreación parcial y aún falta medir la recuperación completa hasta `/health` con SHA y DB sana."*

### Checklist para la Demostración en Vivo
- [ ] Mostrar en GitHub Actions la separación de jobs: `build`, `publish`, `deploy-qa` y `deploy-prod`.
- [ ] Mostrar la corrida rechazada (CI 40277582164) con el comentario de rechazo.
- [ ] Mostrar la corrida aprobada (CI 40284305415) con la promoción verde.
- [ ] Ejecutar `curl -s http://127.0.0.1:3001/health` en vivo (QA: 200 OK, DB connected).
- [ ] Ejecutar `curl -s http://127.0.0.1:3002/health` en vivo (PROD: 200 OK, DB connected).
- [ ] Mostrar en Docker Desktop los dos grupos de contenedores independientes (`photomatch-qa` y `photomatch-prod`).
- [ ] Explicar el script `scripts/deploy-local.sh` y cómo resuelve la descarga anónima sin interacción con el llavero.
