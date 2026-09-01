# Guía de estudio — Defensa TP4

## Qué revisar

1. `.github/workflows/ci.yml`: triggers, jobs, runners, actions y cache.
2. `backend/Dockerfile` y `frontend/Dockerfile`: contratos construidos por CI.
3. `README.md`: badge enlazado a Actions.
4. `decisiones.md`, sección TP4.
5. Protección de `main`: PR, administradores, strict y dos checks.
6. PR de demostración: corrida roja, commit de arreglo, corrida verde y merge.
7. Segunda corrida: capas marcadas `CACHED`.

## Preguntas esenciales

### ¿Qué es integración continua?

Es integrar cambios pequeños y frecuentes a una rama compartida, verificándolos automáticamente y corrigiendo fallos rápido. Puede haber CI con controles manuales, aunque escala mal. También puede existir un pipeline sin CI si corre tarde o no condiciona las integraciones.

### push versus pull_request

`pull_request` verifica antes del merge y produce los checks del gate. `push` a `main` verifica el resultado integrado y alimenta el badge. En un PR GitHub prueba una referencia de merge temporal.

### ¿Por qué jobs paralelos?

Backend y frontend tienen contextos independientes. Cada job recibe su propio runner, sistema de archivos y Docker; no comparten memoria, archivos ni imágenes.

### ¿Qué queda después de una corrida?

Los runners y sus imágenes desaparecen. Persisten logs, metadatos y capas exportadas al cache. No se publica una imagen porque `push` vale `false`.

### Cache versus artefacto

El cache acelera trabajo futuro y puede borrarse sin afectar corrección. Un artefacto es una salida identificable conservada para consumo o entrega. El cache no es una release.

### ¿Por qué construir con Dockerfile?

CI verifica exactamente la receta desplegable y evita dos definiciones de build que puedan divergir.

### ¿Qué significa strict?

La rama debe estar actualizada con `main`; un check verde ejecutado contra una base anterior ya no alcanza.

### ¿Qué exige main?

Pull Request y los checks `build-backend` y `build-frontend` en verde, incluso para el administrador.

### ¿Qué migra a Azure?

Sobreviven triggers, jobs, agentes, pasos, cache y gates. Cambian sintaxis, nombres de tareas, almacenamiento y branch policies.

## Demostración

1. Abrir el badge y el historial de Actions.
2. Mostrar que los dos jobs se superponen.
3. Buscar `CACHED` en una segunda corrida.
4. Recorrer el PR rojo–verde y sus dos commits.
5. Mostrar strict y checks requeridos en la protección.
