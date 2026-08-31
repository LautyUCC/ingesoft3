# Ingeniería de Software III — Trabajos prácticos

Repositorio personal de LautyUCC para construir, de forma incremental, el sistema de entrega de la aplicación del semestre.

## TP1 — Git colaborativo

El primer trabajo práctico configura el proceso con el que los cambios ingresan al repositorio:

1. cada modificación se desarrolla en una rama corta;
2. la rama se integra mediante un Pull Request;
3. `main` permanece protegida contra pushes directos;
4. las entregas quedan identificadas mediante tags y releases.

La explicación de las decisiones está en [`decisiones.md`](decisiones.md) y el registro de comprobaciones en [`evidencias.md`](evidencias.md).

## Convenciones del repositorio

- Rama estable: `main`.
- Estrategia: GitHub Flow.
- Ramas de trabajo: `docs/<descripcion>` o `feature/<descripcion>`.
- Integración: Pull Request hacia `main`.
- Versión del TP1: `v1.0.0`.
- Snapshot académico: `tp1`.

