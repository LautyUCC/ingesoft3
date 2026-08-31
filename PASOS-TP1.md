# Procedimiento del TP1 y justificación

Este documento describe el orden de ejecución. Los comandos se corren desde `C:\ingesoft3\entrega-tp1`; en este equipo se usa Git mediante WSL.

## 1. Publicar la base mediante un Pull Request

```bash
git switch --orphan docs/entrega-inicial
git add .
git commit -m "docs: preparar entrega inicial del TP1"
git push -u origin docs/entrega-inicial
```

Como el repositorio remoto comienza vacío, en GitHub se abre un PR desde `docs/entrega-inicial` y se establece `main` como rama base. Esta primera integración crea la rama estable dejando registro del cambio inicial.

## 2. Proteger `main`

En GitHub: **Settings → Branches o Rules → Rulesets → New branch ruleset**.

Configurar el patrón `main` con:

- requerir Pull Request antes de integrar;
- impedir actualizaciones directas;
- aplicar la regla también al administrador, sin bypass;
- mantener el ruleset activo.

La justificación es que una política técnica resulta reproducible y auditable. Una convención escrita no impide accidentalmente un push directo.

## 3. Probar el rechazo

Después de que `main` exista y esté protegida:

```bash
git switch main
git pull
printf "\nPrueba temporal de protección.\n" >> README.md
git add README.md
git commit -m "test: comprobar protección de main"
git push origin main
```

El push debe fallar. Se captura la salida para `evidencias.md`. Luego el cambio se conserva en una rama y se revierte localmente en `main` sin borrar el commit:

```bash
git switch -c docs/prueba-proteccion
git switch main
git reset --hard origin/main
```

El `reset` de este procedimiento solo se ejecuta después de comprobar que el commit quedó referenciado por `docs/prueba-proteccion`.

## 4. Crear un PR normal

Se publica `docs/prueba-proteccion` y se abre un Pull Request. Antes de integrarlo conviene reemplazar la línea temporal por una mejora real del README. El PR permite revisar exactamente qué entrará en `main`.

## 5. Provocar el conflicto

Desde el mismo commit de `main`, crear dos ramas que cambien de manera distinta la misma línea del README:

```bash
git switch main
git pull
git switch -c docs/titulo-version-a
# Cambiar el título del README por la versión A
git add README.md
git commit -m "docs: definir título versión A"
git push -u origin docs/titulo-version-a

git switch main
git switch -c docs/titulo-version-b
# Cambiar exactamente el mismo título por la versión B
git add README.md
git commit -m "docs: definir título versión B"
git push -u origin docs/titulo-version-b
```

Se abre y fusiona primero el PR de la versión A. Al abrir el PR de la versión B, GitHub debe informar el conflicto. Esto ocurre porque las dos ramas reemplazan la misma línea y Git desconoce cuál expresa la intención final.

## 6. Resolver el conflicto

Actualizar la rama B con `main`:

```bash
git switch docs/titulo-version-b
git fetch origin
git merge origin/main
```

Antes de editar se capturan los marcadores para `evidencias.md`. Luego se elige un título final, se eliminan los marcadores y se completa la resolución:

```bash
git add README.md
git commit -m "docs: resolver conflicto de título"
git push
```

El PR quedará integrable. La resolución debe poder justificarse como una decisión humana, no como una selección automática.

## 7. Completar documentos mediante PR

Actualizar `decisiones.md` con los problemas reales y `evidencias.md` con las cuatro capturas. Hacerlo en una rama y fusionarlo mediante PR, porque la consigna exige que incluso los archivos de entrega respeten el flujo.

## 8. Etiquetar y publicar la entrega

Con todos los PR fusionados:

```bash
git switch main
git pull
git tag -a v1.0.0 -m "Primera entrega: Git colaborativo"
git push origin v1.0.0
git tag -a tp1 -m "TP1 cerrado"
git push origin tp1
```

En GitHub se crea una Release a partir de `v1.0.0`, indicando que incluye protección de `main`, integración mediante PR, resolución documentada de conflicto y archivos de decisiones y evidencias.

## 9. Control final

- Repositorio público.
- `main` protegida sin bypass.
- Push directo rechazado y documentado.
- Al menos dos PR fusionados.
- Un PR con conflicto resuelto.
- `decisiones.md` completo.
- `evidencias.md` con cuatro capturas reales.
- Tags `v1.0.0` y `tp1` sobre el commit final.
- Release `v1.0.0` publicada.
- Capacidad de explicar cada decisión durante la defensa.
