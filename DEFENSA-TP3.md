# Guía de estudio — Defensa TP3

## Enlaces que debés abrir

- Project: https://github.com/users/LautyUCC/projects/1
- Épica: https://github.com/LautyUCC/ingesoft3/issues/7
- Historia: https://github.com/LautyUCC/ingesoft3/issues/8
- Tarea de workflow: https://github.com/LautyUCC/ingesoft3/issues/9
- Tarea de artefacto: https://github.com/LautyUCC/ingesoft3/issues/10
- Bug independiente: https://github.com/LautyUCC/ingesoft3/issues/11

## Recorrido que tenés que demostrar

1. Abrir la épica y mostrar la historia como sub-issue.
2. Abrir la historia, leer “Como… quiero… para…” y explicar los cuatro criterios.
3. Mostrar sus dos tareas como sub-issues.
4. Abrir la tarea cerrada número 9.
5. Navegar desde ella al Pull Request y a sus commits.
6. Volver mediante Parent issue a la historia y luego a la épica.
7. Abrir Sprint Board, mostrar Sprint 1, Status y WIP 2.
8. Explicar por qué la historia y la segunda tarea quedan abiertas para el TP4.

## Conceptos

### Épica, historia y tarea

La épica expresa un objetivo amplio del semestre. La historia expresa valor desde una perspectiva y tiene criterios verificables. La tarea es trabajo técnico concreto para cumplir la historia.

### Criterios verificables

“El workflow corre en cada PR” se comprueba abriendo un PR y observando el run. “Un test que falla bloquea el merge” se comprueba introduciendo un fallo controlado. “El reporte queda como artefacto” se comprueba descargándolo. “Badge visible” se comprueba en README. “Que CI funcione bien” no indica qué observar ni cuándo se considera cumplido.

### Sprint

Es una ventana temporal fija para obtener un incremento y feedback. Se eligieron 14 días por equilibrio entre foco, costo de planificación y frecuencia de devolución.

### WIP

Limita trabajo empezado, no terminado. WIP 2 permite una actividad activa y otra si la primera queda esperando. Subirlo a diez ocultaría bloqueos y aumentaría cambio de contexto.

### Trazabilidad

La cadena es requerimiento → tarea → rama → commits → PR → merge → cierre automático. `Closes #9` debe estar en la descripción del PR hacia `main`; en un comentario no cierra el issue.

### Bug independiente

El bug describe un defecto de una versión previamente entregada, no trabajo faltante de una historia en curso. Por eso está al costado de la jerarquía. La convención puede variar entre equipos, pero debe ser explícita.

### GitHub Projects frente a Trello

Projects conecta directamente issues, sub-issues, PR, commits, repositorio, automatizaciones y estados. Un tablero genérico puede representar tarjetas, pero requiere mantener manualmente esa trazabilidad.

### Historia mal escrita

“Crear la tabla usuarios” es implementación, no valor observable para una persona. La historia debe expresar quién necesita qué capacidad y para qué; la tabla queda como tarea técnica.

## Archivos que estudiar

- `decisiones.md`, sección TP3.
- `.github/workflows/ci.yml`: cambio concreto que cierra la tarea.
- `README.md`: enlace al Project.
- Los cuerpos y relaciones de issues 7 a 11.

## Estado esperado al entregar

- Tarea 9 cerrada y en Done.
- Tarea 10 abierta.
- Historia 8 abierta.
- Épica 7 abierta.
- Bug 11 abierto.
- Sprint de 14 días asignado a historia y tareas.
- Board público con WIP 2.
