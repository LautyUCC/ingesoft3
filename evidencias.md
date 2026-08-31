# Evidencias — TP1

> Todas las comprobaciones indicadas abajo fueron ejecutadas sobre el repositorio real. Los enlaces permiten inspeccionar los Pull Requests públicos. Antes de presentar, se pueden agregar capturas de estas mismas pantallas si la cátedra exige que la evidencia quede embebida como imagen.

## 1. Push directo a `main` rechazado

**Estado:** comprobado el 31 de agosto de 2026.

Se activó la protección de `main`, incluyendo su aplicación al administrador, y se intentó publicar directamente el commit `b3be9ea`. GitHub respondió:

```text
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: - Changes must be made through a pull request.
! [remote rejected] main -> main (protected branch hook declined)
```

El mismo commit fue conservado en una rama e integrado correctamente mediante el [Pull Request #2](https://github.com/LautyUCC/ingesoft3/pull/2).

Justificación: demuestra que la protección también se aplica al administrador y que el proceso no depende de recordar voluntariamente la regla.

## 2. Pull Request con conflicto

**Estado:** comprobado en el [Pull Request #4](https://github.com/LautyUCC/ingesoft3/pull/4).

Las ramas `docs/titulo-version-a` y `docs/titulo-version-b` partieron del mismo commit y reemplazaron de forma diferente la primera línea de `README.md`. Después de integrar la versión A mediante el [Pull Request #3](https://github.com/LautyUCC/ingesoft3/pull/3), GitHub informó para el PR #4:

```json
{"mergeStateStatus":"DIRTY","mergeable":"CONFLICTING"}
```

Justificación: demuestra que dos ramas realizaron cambios incompatibles sobre la misma región del archivo.

## 3. Marcadores del conflicto

**Estado:** comprobado y resuelto en el commit `3079286`.

Al mezclar `origin/main` en la rama B aparecieron estos marcadores:

```text
<<<<<<< HEAD
# Portfolio DevOps — Ingeniería de Software III
=======
# Ingeniería de Software III — Entrega personal
>>>>>>> origin/main
```

La resolución manual combinó la intención de ambas propuestas:

```text
# Ingeniería de Software III — Portfolio DevOps
```

Justificación: permite identificar las dos versiones que Git no pudo reconciliar y documenta la resolución manual.

## 4. Release publicada

**Estado:** publicada como [Release v1.0.0](https://github.com/LautyUCC/ingesoft3/releases/tag/v1.0.0).

La Release identifica el estado final del TP1 e incluye notas sobre la protección de `main`, los Pull Requests, el conflicto resuelto y la documentación entregada.

Justificación: demuestra que el estado entregado quedó identificado y es recuperable.
