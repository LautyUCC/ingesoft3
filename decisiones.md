# Decisiones técnicas

## TP1 — Git colaborativo

### Flujo de trabajo elegido

Se utiliza GitHub Flow porque el proyecto mantiene una única rama estable (`main`) y los cambios son pequeños e incrementales. Cada cambio se realiza en una rama corta y entra mediante un Pull Request. Esto permite revisar el diff, conservar una conversación asociada al cambio y detectar problemas antes de modificar la versión estable.

La protección de `main` no se basa en la confianza entre integrantes. Su propósito es convertir el proceso acordado en una regla verificable: evita cambios accidentales, obliga a integrar mediante PR y deja trazabilidad entre la intención, la revisión y los commits.

### Conflicto de merge

El conflicto se provoca modificando la misma línea del `README.md` de manera diferente en dos ramas creadas desde el mismo punto. Después de integrar la primera rama, Git no puede elegir automáticamente cuál de las dos versiones representa la intención correcta. Ambas modificaciones son válidas desde el punto de vista del algoritmo, pero son incompatibles entre sí; la decisión requiere contexto humano.

El conflicto podría haberse evitado coordinando el trabajo para que las ramas modificaran líneas o archivos diferentes, integrando ramas más pequeñas con mayor frecuencia o actualizando la segunda rama con `main` antes de abrir su PR. Actualizarla antes no elimina necesariamente el conflicto, pero permite resolverlo temprano en la rama de trabajo y no durante la integración final.

### Versionado

La primera entrega se identifica como `v1.0.0`. De acuerdo con versionado semántico, el primer número representa cambios incompatibles, el segundo funcionalidades compatibles y el tercero correcciones compatibles. En este TP el tag funciona como una referencia inmutable al estado presentado. Además se crea el tag `tp1`, solicitado por la cátedra para localizar el snapshot académico del trabajo.

### Problemas encontrados y soluciones

- El repositorio personal estaba vacío. Se creó una estructura mínima para que el historial del semestre comience en este TP.
- El cliente Git de Windows no podía usar HTTPS debido a una política que bloqueaba su biblioteca `libcurl`. Se utilizó Git dentro de WSL sobre la misma carpeta de trabajo.
- El directorio donde estaban las consignas también contenía cambios locales de PhotoMatch. Para no mezclarlos ni perderlos, la entrega se clonó en `C:\ingesoft3\entrega-tp1` y esos cambios quedaron intactos.
- Las evidencias de rechazo, conflicto y Release no se inventan: se incorporan después de ejecutar cada operación real en GitHub.

### Uso de inteligencia artificial

Se utilizó un asistente de IA para preparar la estructura inicial, redactar una primera versión de la documentación y explicar el modelo de ramas, conflictos y versionado. La verificación se realiza contrastando el documento con la consigna oficial, ejecutando los comandos sobre el repositorio real y comprobando en GitHub que la protección rechace el push, que el PR muestre el conflicto y que los tags y la Release apunten al commit correcto. El contenido será revisado y comprendido antes de la defensa oral.

