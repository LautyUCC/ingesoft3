# Guía de Estudio y Defensa — TP7: Contenedores, Pruebas de Integración y E2E
**Materia:** Ingeniería de Software III — Universidad Católica de Córdoba (UCC)  
**Ciclo Lectivo:** 2026  
**Alumno:** Lautaro Alejo Vallino (Legajo: 2301009) — Comisión 2  
**Aplicación:** PhotoMatch (Gestión de coberturas fotográficas deportivas)  
**Release asociada:** `v7.0.0`

---

## A. Introducción Conceptual

### 1. Pruebas de Integración vs. Pruebas End-to-End (E2E)
En la pirámide de testing, una vez garantizada la lógica unitaria en el TP5, es indispensable validar los niveles superiores:

- **Pruebas de Integración (API Testing):**
  - **Objetivo:** Verificar la comunicación real entre subsistemas desacoplados (Frontend/Backend Express $\leftrightarrow$ Base de Datos PostgreSQL) sin la sobrecarga ni la fragilidad de renderizar una interfaz gráfica.
  - **Mecanismo:** En PhotoMatch usamos el contexto de peticiones de Playwright (`request`). Se ejecutan llamadas HTTP reales contra `/api/clients`, validando códigos de estado, esquemas JSON y persistencia en la base de datos de QA.
  - **Velocidad:** Muy rápidas (3 pruebas se ejecutan en ~1,5 segundos).
- **Pruebas End-to-End (E2E):**
  - **Objetivo:** Simular la experiencia de un usuario real interactuando con la aplicación mediante un navegador web automatizado.
  - **Mecanismo:** Playwright levanta una instancia headless de Chromium, navega la interfaz web de PhotoMatch (`http://127.0.0.1:3001`), completa formularios, hace clics en botones, verifica redirecciones y valida que los cambios se reflejen visualmente en el DOM.
  - **Velocidad y fragilidad:** Más lentas (~15-30 segundos) y sensibles a cambios en el DOM y tiempos de renderizado.

### 2. ¿Por qué Playwright y no Selenium o Cypress?
- **Protocolo DevTools directo:** A diferencia de Selenium (que usa el protocolo WebDriver con intermediarios que provocan lentitud y desincronización), Playwright se comunica directamente con el motor del navegador mediante WebSocket y Chrome DevTools Protocol (CDP).
- **Auto-waiting integrado:** Playwright espera automáticamente a que los elementos del DOM sean visibles, interactuables y estables antes de ejecutar cualquier acción (`click()`, `fill()`), eliminando los `sleep()` arbitrarios que generan *flakiness*.
- **Aislamiento por Browser Context:** Cada prueba corre en un contexto de navegador aislado con sus propias cookies y almacenamiento local, sin interferencias cruzadas.

### 3. El Mecanismo del Gate E2E Rojo (Quality Gate Funcional)
Un pipeline de Continuous Delivery maduro debe ser capaz de discriminar la causa raíz de un fallo:
- Si falla la API $\rightarrow$ Falla la integración.
- Si la API y la base funcionan pero la interfaz gráfica está rota $\rightarrow$ La integración pasa pero **E2E falla en rojo**, impidiendo que el defecto llegue a Producción.

En PhotoMatch encadenamos estrictamente en `.github/workflows/ci.yml`:
$$\text{deploy-qa} \longrightarrow \text{integracion} \longrightarrow \text{e2e} \longrightarrow \text{deploy-prod}$$
Dado que `deploy-prod` tiene `needs: e2e`, si la suite E2E falla, el job de producción **se omite automáticamente y ni siquiera solicita aprobación humana**.

---

## B. Estado Inicial de PhotoMatch antes del TP7

Antes del TP7, PhotoMatch:
- Solo poseía pruebas unitarias en memoria (`backend/test/*.test.js`).
- No existía ninguna prueba automatizada que validara la interacción con la base de datos PostgreSQL real.
- No existían pruebas de interfaz que confirmaran que un usuario pudiera iniciar sesión y registrar clientes.
- El formulario HTML de clientes (`backend/src/views/clients/form.ejs`) tenía un bug oculto: usaba la variable `client` en EJS, la cual colisionaba con las opciones internas del compilador de EJS y provocaba errores HTTP 500 al renderizar.

---

## C. Implementación Paso a Paso

### 1. Diseño de la Suite de Integración (`frontend/e2e/api.spec.js`)
Se implementaron 3 pruebas exhaustivas contra la API REST `/api/clients`:
1. *Alta, lectura y baja:* Crea un cliente con nombre único (`Cliente API <timestamp>`), consulta `/api/clients/:id`, valida datos y lo elimina.
2. *Rechazo de datos inválidos:* Intenta crear un cliente con nombre vacío y valida que la API retorne HTTP 400 y mensaje de error.
3. *Edición y persistencia:* Crea un cliente, actualiza su teléfono y notas vía PUT, y comprueba que los cambios persistan en PostgreSQL.

### 2. Diseño de la Suite E2E de Navegador (`frontend/e2e/app.spec.js`)
Se implementaron 3 flujos de usuario completos con Chromium:
1. *Flujo completo de alta y baja por UI:* Inicia sesión como administrador en `/login`, navega a `/clients/new`, llena el formulario, lo envía, verifica la fila en la tabla de clientes y luego lo elimina.
2. *Validación de errores en el formulario:* Intenta enviar el formulario con datos inválidos y verifica la alerta de error en la página.
3. *Edición persistente:* Modifica los datos de un cliente existente, recarga la página y confirma visualmente que la actualización perdura.

### 3. Ejecución de la Demostración del Gate E2E Rojo
Para certificar el gate ante la cátedra:
1. Se creó el **PR #37**, introduciendo deliberadamente una rotura exclusivamente en el formulario HTML (`action="/clients/blocked-demo"`), dejando intacta la API `/api/clients`.
2. Se fusionó a `main` y se ejecutó la corrida de **[CI 40283556436](https://github.com/LautyUCC/ingesoft3/actions/runs/40283556436)**:
   - `integracion`: **3/3 PASAN (Verde)**.
   - `e2e`: **3/3 FALLAN (Rojo)** por error 404 al enviar el formulario.
   - `deploy-prod`: **OMITIDO / BLOQUEADO**. Producción permaneció 100% protegida en el SHA anterior.
3. Se creó el **PR #39**, restaurando la ruta a `/clients`.
4. Se fusionó a `main` y se ejecutó la corrida de **[CI 40284305415](https://github.com/LautyUCC/ingesoft3/actions/runs/40284305415)**:
   - Integración y E2E pasaron **3/3 verdes**.
   - Se aprobó el gate humano y Producción se desplegó exitosamente en commit `1caea7c`.

---

## D. Explicación del Código Central

### 1. Suite de Integración API (`frontend/e2e/api.spec.js`)
```javascript
test('API: crear, leer y eliminar un cliente real', async ({ request }) => {
  const uniqueName = `Cliente API ${Date.now()}`;
  
  // 1. Crear cliente contra QA
  const createRes = await request.post(`${API_BASE}/api/clients`, {
    data: { name: uniqueName, type: 'Club', email: 'api@test.com' }
  });
  expect(createRes.status()).toBe(201);
  const created = await createRes.json();
  
  // 2. Verificar persistencia en base de datos
  const getRes = await request.get(`${API_BASE}/api/clients/${created.id}`);
  expect(getRes.status()).toBe(200);
  expect((await getRes.json()).name).toBe(uniqueName);
  
  // 3. Limpieza garantizada
  const delRes = await request.delete(`${API_BASE}/api/clients/${created.id}`);
  expect(delRes.status()).toBe(204);
});
```
*Análisis técnico:*
- La prueba es completamente autónoma: crea sus propios datos con marcas de tiempo únicas para evitar colisiones en la base de datos y se encarga de su propia limpieza (*teardown*).

### 2. Suite E2E con Navegador (`frontend/e2e/app.spec.js`)
```javascript
test('E2E: flujo completo de creación de cliente por formulario web', async ({ page }) => {
  await page.goto(`${BASE_URL}/login`);
  await page.fill('input[name="email"]', process.env.ADMIN_EMAIL);
  await page.fill('input[name="password"]', process.env.ADMIN_PASSWORD);
  await page.click('button[type="submit"]');
  
  await page.goto(`${BASE_URL}/clients/new`);
  await page.fill('input[name="name"]', 'Club Atlético Playwright');
  await page.selectOption('select[name="type"]', 'Club');
  await page.click('button:has-text("Guardar cliente")');
  
  // Validación visual en el DOM
  await expect(page.locator('table')).toContainText('Club Atlético Playwright');
});
```
*Análisis técnico:*
- Utiliza selectores resilientes (`name`, texto visible) y aserciones asíncronas de Playwright (`await expect(...)`) que reintentan automáticamente hasta que el DOM se actualice.

---

## E. Decisiones de Ingeniería y Trade-offs

| Decisión Tomada | Alternativa Descartada | Justificación Técnica | Desventajas / Limitaciones |
|---|---|---|---|
| **Playwright como herramienta única de Integración y E2E** | Jest + Supertest para API y Cypress para navegador | Playwright ofrece el contexto `request` para HTTP y automatización de Chromium en la misma herramienta, reduciendo dependencias y unificando reportes. | Exige instalar navegadores en el runner (`npx playwright install chromium`). |
| **Pruebas contra Ambiente Desplegado en QA** | Pruebas contra servidor efímero en memoria | El objetivo pedagógico del TP7 es verificar la aplicación en su entorno real de contenedores y redes antes de llegar a Producción. | Si QA tarda en levantar, la suite debe esperar el smoke test. |
| **Limpieza de Datos en la Misma Prueba** | Truncar la base de datos completa post-ejecución | Truncar la base destruye los datos semilla (usuarios administradores) y rompería la concurrencia. Cada test genera un ID único y lo elimina puntualmente. | Si una prueba falla antes del `delete`, puede quedar un registro huérfano. |

---

## F. Pruebas y Evidencias Reales

1. **Evidencia del Gate E2E Rojo en GitHub Actions:**
   - **Pull Request:** [PR #37](https://github.com/LautyUCC/ingesoft3/pull/37)
   - **Ejecución CI:** [CI Run 40283556436](https://github.com/LautyUCC/ingesoft3/actions/runs/40283556436)
   - **Resultados:** `integracion` 3/3 verde (26s); `e2e` 3/3 rojo (2m 08s); `deploy-prod` **bloqueado y omitido**.
   - **Aislamiento verificado en vivo:**
     - QA (`:3001`): Desplegó commit defectuoso `43e730b`.
     - PROD (`:3002`): **Permaneció intacto** en el commit sano `43f142e`.
2. **Evidencia de Recuperación y Promoción Verde:**
   - **Pull Request:** [PR #39](https://github.com/LautyUCC/ingesoft3/pull/39)
   - **Ejecución CI:** [CI Run 40284305415](https://github.com/LautyUCC/ingesoft3/actions/runs/40284305415)
   - **Resultados:** `integracion` 3/3 verde; `e2e` 3/3 verde; `deploy-prod` ejecutado con éxito tras aprobación humana en commit `1caea7ce1e19d4b2b84676ec8a35686f6e26f2e3`.
3. **Release Oficial:**
   - Etiqueta Git y [Release v7.0.0](https://github.com/LautyUCC/ingesoft3/releases/tag/v7.0.0) publicada en GitHub.

---

## G. Preparación para la Defensa Oral

### Preguntas Frecuentes de la Cátedra

1. **¿Qué diferencia conceptual existe entre una prueba de integración y una prueba E2E en su implementación?**  
   *Respuesta:* Las pruebas de integración (`api.spec.js`) validan la lógica de negocio y la persistencia en PostgreSQL invocando la API REST mediante HTTP directo, sin navegador. Las pruebas E2E (`app.spec.js`) controlan un navegador Chromium real, completando formularios e interactuando con el DOM para certificar la experiencia de usuario.

2. **¿Por qué la suite de integración pasó en verde durante el PR #37 si el formulario estaba roto?**  
   *Respuesta:* Porque el cambio defectuoso del PR #37 se introdujo deliberadamente en el atributo `action` del formulario HTML en EJS (`/clients/blocked-demo`). La API REST en `/api/clients` y el controlador siguieron operando perfectamente. Esto demostró la capacidad del pipeline de aislar capas de error.

3. **¿Cómo impidió el pipeline que el fallo E2E rompiera la producción?**  
   *Respuesta:* En `.github/workflows/ci.yml`, el job `deploy-prod` declara la directiva `needs: e2e`. Al fallar el job `e2e`, GitHub Actions evalúa que la dependencia no se cumplió y cancela/omite automáticamente el despliegue a producción.

4. **¿Por qué no utilizaron mocks en las pruebas de integración?**  
   *Respuesta:* Porque un test de integración con mocks de base de datos se convierte en un test unitario encubierto. El objetivo del TP7 es verificar que la conexión TCP a PostgreSQL, los tipos de datos y las restricciones de integridad relacional funcionen en el contenedor real de QA.

5. **¿Qué artefactos se generan cuando falla una prueba E2E?**  
   *Respuesta:* Playwright genera trazas completas de ejecución (*traces*), capturas de pantalla (*screenshots*) en el momento exacto del fallo y grabaciones en video, las cuales se suben automáticamente como artefacto zip (`playwright-report-e2e`) en GitHub Actions.

6. **¿Dónde puedo ver en su repositorio la evidencia de que producción se bloqueó por E2E?**  
   *Respuesta:* En la corrida de GitHub Actions #40283556436. Allí se observa que el job `e2e` tiene una cruz roja y el job `deploy-prod` figura en gris con estado *Skipped*.

### Las 3 Preguntas Más Difíciles

7. **¿Cómo mitigan el problema de los *flaky tests* (pruebas intermitentes) en las pruebas E2E de navegador?**  
   *Respuesta:* Eliminando esperas fijas (`sleep`) y aprovechando el *actionability checking* de Playwright, que espera que los elementos estén visibles y estables antes de interactuar. Además, se configuran reintentos automáticos (`retries: 2` en CI) y cada prueba crea registros con identificadores únicos para evitar condiciones de carrera en la base de datos.

8. **¿Qué ventaja técnica ofrece Playwright sobre Selenium WebDriver para la ejecución en pipelines de CI?**  
   *Respuesta:* Playwright se comunica directamente con el navegador a través de WebSockets usando Chrome DevTools Protocol, eliminando el proceso intermedio del WebDriver. Esto permite capturar eventos de red, manipular cookies en tiempo real y ejecutar pruebas hasta cuatro veces más rápido.

9. **Si las pruebas de integración y E2E escriben en la misma base de datos de QA, ¿cómo evitan la corrupción de datos entre ejecuciones concurrentes?**  
   *Respuesta:* Generando nombres y datos con prefijos temporales únicos (`Cliente API ${Date.now()}`) y ejecutando limpieza garantizada en bloques `afterAll` o al final de cada test. Adicionalmente, las pruebas se configuran para correr en modo secuencial (`workers: 1`) en CI para garantizar determinismo sobre la base de datos local.

---

## H. Resumen Final de Estudio

- **Integración:** Pruebas de API contra QA y PostgreSQL sin navegador (~1,5 s).
- **E2E:** Pruebas de interfaz completas con Chromium headless simulando usuarios reales (~30 s).
- **Gate E2E Rojo:** Demostración real donde la UI rota bloqueó la promoción a Producción (CI 40283556436).
- **Pitch de 2 minutos:** _"En el TP7 implementamos la cima de la pirámide de calidad de PhotoMatch: pruebas de integración de API y pruebas E2E de navegador con Playwright contra el ambiente desplegado en QA. Demostramos el funcionamiento del Quality Gate funcional: introdujimos una rotura en el formulario HTML que mantuvo la integración en verde pero rompió la suite E2E, bloqueando automáticamente el despliegue a producción y preservando intacto el ambiente productivo. Luego integramos la corrección, recuperamos el 100% verde y promovimos a producción con la release v7.0.0."_
