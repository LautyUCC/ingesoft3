# Evidencias — TP1

> Las capturas se incorporan únicamente después de ejecutar cada comprobación real. No se utilizan imágenes simuladas. Antes de entregar, reemplazar cada pendiente por la captura correspondiente y una breve explicación de lo observado.

## 1. Push directo a `main` rechazado

**Estado:** pendiente de configurar la regla de protección y ejecutar la prueba.

Captura requerida: terminal mostrando que GitHub rechaza un `git push origin main` realizado sin Pull Request.

Justificación: demuestra que la protección también se aplica al administrador y que el proceso no depende de recordar voluntariamente la regla.

## 2. Pull Request con conflicto

**Estado:** pendiente de crear y publicar las dos ramas de conflicto.

Captura requerida: página del segundo Pull Request indicando que no puede integrarse automáticamente.

Justificación: demuestra que dos ramas realizaron cambios incompatibles sobre la misma región del archivo.

## 3. Marcadores del conflicto

**Estado:** pendiente de resolver el conflicto real.

Captura requerida: archivo durante la resolución, mostrando los marcadores `<<<<<<<`, `=======` y `>>>>>>>` antes de eliminarlos.

Justificación: permite identificar las dos versiones que Git no pudo reconciliar y documenta la resolución manual.

## 4. Release publicada

**Estado:** pendiente de completar los PR y crear `v1.0.0`.

Captura requerida: página de Releases mostrando la Release `v1.0.0`, su tag y sus notas.

Justificación: demuestra que el estado entregado quedó identificado y es recuperable.

