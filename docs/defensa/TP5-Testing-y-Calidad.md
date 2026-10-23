# Guía de Estudio y Defensa — TP5: Testing Automatizado y Quality Gates
**Materia:** Ingeniería de Software III — Universidad Católica de Córdoba (UCC)  
**Ciclo Lectivo:** 2026  
**Alumno:** Lautaro Alejo Vallino (Legajo: 2301009) — Comisión 2  
**Aplicación:** PhotoMatch (Gestión de coberturas fotográficas deportivas)  
**Release asociada:** `v5.0.0`

---

## A. Introducción Conceptual

### 1. La pirámide de testing
En la ingeniería de software moderna, no todas las pruebas tienen el mismo costo, velocidad ni nivel de aislamiento. La **pirámide de testing** (popularizada por Mike Cohn y Martin Fowler) organiza las estrategias de prueba en tres niveles fundamentales:

```
                  / \
                 /   \
                / E2E \       <-- Pocos, lentos, frágiles, caros (Punta)
               /-------\
              / Integr. \     <-- Cantidad media, tocan BD/APIs (Medio)
             /-----------\
            /  Unit Tests \   <-- Muchos, rápidos, milisegundos, aislados (Base)
           /---------------\
```

1. **Base — Pruebas Unitarias (Unit Tests):**
   - **Propósito:** Evalúan unidades atómicas e independientes de lógica pura (funciones, métodos o clases) sin tocar recursos externos como bases de datos, redes o sistema de archivos.
   - **Características:** Se ejecutan en milisegundos (en PhotoMatch, 32 pruebas corren en 87 ms).
   - **Diagnóstico:** Si falla un test unitario, el fallo apunta exactamente a la línea y la regla de negocio que se rompió.
   - **Anti-patrón (*Ice Cream Cone* / Pirámide Invertida):** Ocurre cuando un equipo desarrolla casi exclusivamente pruebas E2E e ignora las unitarias. El resultado son suites lentas (horas), frágiles ante cambios menores de interfaz (*flaky tests*) e incapaces de aislar la causa raíz del error.

2. **Medio — Pruebas de Integración:**
   - **Propósito:** Verifican que múltiples componentes colaboren correctamente (ej. el backend Express comunicándose con la base de datos PostgreSQL real). Se abordan en el TP7.

3. **Punta — Pruebas End-to-End (E2E):**
   - **Propósito:** Validan los flujos críticos de la aplicación desde la perspectiva del usuario final a través de un navegador automatizado (Playwright). Se implementan en el TP7 sobre el entorno desplegado en QA.

---

### 2. Anatomía de un Unit Test: Patrón AAA (Arrange - Act - Assert)
El patrón AAA es el estándar de la industria para estructurar pruebas unitarias legibles y mantenibles:

- **Arrange (Preparar):** Inicializa el contexto, los datos de entrada, las variables requeridas y los dobles de riesgo (mocks/stubs).
- **Act (Ejecutar):** Invoca la única acción o función específica bajo prueba.
- **Assert (Verificar):** Comprueba que los resultados obtenidos y los efectos colaterales coincidan exactamente con la expectativa de la regla de negocio.

```javascript
test('pricingService - calculatePlayerPurchase parametrizado', () => {
  // Arrange: preparar datos de entrada y salida esperada
  const type = 'pack6';
  const photosTaken = 10;
  const expectedPrice = 15000;

  // Act: ejecutar la acción bajo prueba
  const result = calculatePlayerPurchase(type, photosTaken);

  // Assert: verificar el resultado
  assert.equal(result.agreed_price, expectedPrice);
  assert.equal(result.photos_purchased, 6);
});
```

#### Reglas de diseño de pruebas:
1. **Un comportamiento por prueba:** Cada test debe verificar un único aspecto de la regla.
2. **Nombres descriptivos con regla de negocio:** El nombre del test debe actuar como diagnóstico cuando el pipeline falle a la madrugada.
3. **Determinismo:** Un test debe arrojar siempre el mismo resultado dadas las mismas entradas. Nunca debe depender de llamadas horarias (`Date.now()`), aleatorias (`Math.random()`) ni de servicios externos.

---

### 3. Dobles de prueba (Test Doubles): Stubs vs Mocks vs Fakes
El aislamiento exige que una prueba unitaria no acceda a recursos externos. Para ello se sustituyen las dependencias por dobles de riesgo:

| Tipo de Doble | Propósito Principal | ¿Verifica Interacción? | Ejemplo en PhotoMatch |
|---|---|:---:|---|
| **Dummy** | Objeto de relleno para completar parámetros requeridos; nunca se usa en la lógica. | No | Un string vacío o token que no interviene en el cálculo. |
| **Stub** | Devuelve respuestas fijas preprogramadas ante llamadas ("si te piden el usuario X, devolvé este objeto"). Provee datos indirectos. | No | Simular que un usuario existe devolviendo un objeto fijo sin importar el email. |
| **Mock** | Objeto preprogramado que registra llamadas y sobre el cual **el test verifica la interacción** (cantidad de invocaciones, argumentos exactos, orden). | **Sí (mediante Assert)** | Verificar que `findByEmail` fue invocado **exactamente 1 vez** con el email normalizado `'fotografo@photomatch.com'`. |
| **Spy** | Doble que envuelve una función real registrando qué parámetros recibió para consultarlo luego. | Opcional | Registrar cuántas veces se ejecutó una función de log. |
| **Fake** | Implementación simplificada pero completamente funcional de la interfaz (en memoria). | No | Un repositorio de usuarios en memoria basado en un `Map` en lugar de PostgreSQL. |

> **Diferencia clave para la defensa:** La diferencia fundamental entre un Stub y un Mock no radica en el objeto en sí, sino en el **Assert**. Si la prueba solo valida el valor de retorno de la función bajo prueba, usó un Stub. Si la prueba valida cómo y con qué datos fue invocada la dependencia externa, usó un **Mock**.

---

### 4. Code Coverage: Métricas, Alcance y Límites
El análisis de cobertura mide la proporción de código ejecutado durante la suite de pruebas:

1. **Line Coverage (Cobertura de Líneas):** Porcentaje de líneas de código fuente que fueron ejecutadas al menos una vez durante los tests.
2. **Branch Coverage (Cobertura de Ramas):** Porcentaje de caminos lógicos alternativos evaluados. Cada estructura condicional (`if`, `switch`, operador ternario `? :`, cortocircuito `&&`, `||`, coalescencia `??`) bifurca el flujo en dos o más ramas. Branch coverage es una métrica mucho más rigurosa y honesta que Line coverage.

#### Ley de Goodhart y el límite del coverage:
> *"Cuando una métrica se convierte en un objetivo, deja de ser una buena métrica."* (Marilyn Strathern / Charles Goodhart).

**La cobertura mide ejecución, no verificación.** Un conjunto de pruebas puede ejecutar el 100% de las líneas de una aplicación y no tener ni un solo `assert`, logrando 100% de cobertura sin comprobar absolutamente ningún comportamiento:

```javascript
test('Falsa confianza: 100% de cobertura sin verificacion', () => {
  // Ejecuta todo el servicio de cálculo de precios...
  calculatePlayerPurchase('pack6', 12);
  // No hay ningún assert. Si la función devuelve NaN, null o un precio erróneo, el test pasa igual.
});
```

Por lo tanto:
- **Cobertura baja:** Es una señal inequívoca y confiable de peligro (hay código que nunca se ejecuta y donde se ocultan bugs).
- **Cobertura alta:** NO es garantía de corrección ni de ausencia de errores. Indica simplemente que el código fue ejercitado.

---

### 5. Quality Gates en CI/CD
Un **Quality Gate** (puerta de calidad) es una condición contractual verificada automáticamente en el pipeline de integración continua que **bloquea la promoción o integración de código** (merge a `main`) si no se cumplen los estándares mínimos definidos por el equipo.

En el TP4, el gate verificaba únicamente la **compilación y empaquetado** de los Dockerfiles. En el TP5, el gate evoluciona para verificar **calidad lógica**: el pipeline rompe y bloquea el PR si los tests fallan o si la cobertura de líneas o ramas cae por debajo del umbral establecido.

---

## B. Estado Inicial de PhotoMatch antes del TP5

Antes de abordar el TP5:
1. **Suite de pruebas incipiente:** Solo existía un archivo de pruebas (`backend/test/validationService.test.js`) con 11 tests básicos de validación de esquemas.
2. **Acoplamiento de persistencia:** `authService.js` requería directamente a nivel de módulo `userRepository.js`, el cual ejecuta queries nativas de PostgreSQL con el pool `pg`. Era imposible testear la lógica de autenticación de forma unitaria sin una base de datos activa levantada en el puerto 5432.
3. **Reglas de negocio no testeadas:** `pricingService.js` (catálogo de packs fotográficos, precios y liquidación de coberturas `isCounted`) carecía de tests unitarios, parametrizados y casos de borde.
4. **Pipeline sin verificación de tests:** `.github/workflows/ci.yml` ejecutaba exclusivamente la construcción de imágenes Docker (`docker/build-push-action` con `push: false`). Si alguien subía una función con errores de lógica o tests rotos, el pipeline se ponía en verde con total impunidad.
5. **Sin medición ni umbral de cobertura:** No existía ninguna herramienta de coverage instalada (`c8`) ni reporte visible en los Pull Requests.
6. **Arquitectura del frontend:** Nginx sirve CSS estático y actúa como reverse proxy hacia Express 5 con plantillas EJS renderizadas en el servidor. No existe una Single Page Application (SPA) ni JavaScript cliente, por lo que los unit tests de frontend no aplican según la regla explícita de la cátedra (§1605).

---

## C. Implementación Paso a Paso

### 1. Refactor de `authService.js` (Inversión de Dependencias)
Para permitir pruebas con dobles sin base de datos, desacoplamos el repositorio de datos de la función de autenticación, permitiendo inyectar un repositorio simulado:

```javascript
// backend/src/services/authService.js
const bcrypt = require('bcryptjs');
const users = require('../repositories/userRepository');

async function authenticate(email, password, userRepo = users) {
  const normalizedEmail = (email || '').trim().toLowerCase();
  if (!normalizedEmail) return null;

  const user = await userRepo.findByEmail(normalizedEmail);
  if (!user || !user.password_hash) return null;

  const passwordMatches = await bcrypt.compare(password || '', user.password_hash);
  if (!passwordMatches) return null;

  return { id: user.id, name: user.name, email: user.email, role: user.role };
}
```

### 2. Implementación de `authService.test.js` con Mock Obligatorio
Creamos 5 pruebas unitarias con estructura AAA estricta y dobles de riesgo:
- Test 1 (Mock): Autenticación exitosa verificando resultado sanitizado y que `mockUserRepo.findByEmail` fue invocado 1 vez con el email normalizado.
- Test 2 (Mock): Usuario inexistente en repositorio.
- Test 3 (Mock): Contraseña errónea.
- Test 4 (Borde): Input nulo o vacío (retorna null temprano sin invocar al repositorio).
- Test 5 (Borde): Registro corrupto en base de datos sin hash de contraseña.

### 3. Implementación de `pricingService.test.js` con Parametrización
Implementamos 16 pruebas unitarias:
- 8 casos parametrizados recorriendo la matriz de productos (`none`, `single`, `pack6`, `all`).
- 3 casos de error y borde: producto desconocido, venta con 0 fotos disponibles, y el borde estricto de pack de 6 (5 fotos rechaza, 6 fotos acepta).
- 5 casos parametrizados para la regla de negocio `isCounted` (ventas individuales vs cuota global de equipo).

### 4. Configuración de Cobertura con `c8`
Instalamos `c8` (`npm install -D c8`) e instrumentamos la configuración en `backend/.c8rc.json`:
- Inclusión: `src/services/**` (lógica pura de la app).
- Exclusiones justificadas: `src/app.js` (cableado y arranque), `src/db/**` (conexión SQL), `src/repositories/**` (SQL crudo para integración), `src/controllers/**` y `src/routes/**` (transporte HTTP y renderizado de vistas).
- Umbral estricto: Líneas **80%**, Ramas **70%**, Funciones **80%**, Sentencias **80%**.

### 5. Extensión de `.github/workflows/ci.yml` (Quality Gate)
Agregamos al job `build-backend`:
1. `actions/setup-node@v4` con Node 22 y caché de `npm`.
2. `npm ci` para instalar dependencias limpias.
3. `npm run test:check-coverage` (`c8 --check-coverage node --test`): ejecuta los tests y evalúa los umbrales. Si no se alcanza el umbral, finaliza con código de error `exit 1`.
4. Resumen Markdown inyectado en `$GITHUB_STEP_SUMMARY`.
5. Publicación del directorio `coverage/` como artefacto descargable (`actions/upload-artifact@v4`).
6. Paso posterior de construcción de imagen Docker (solo se ejecuta si el quality gate está en verde).

---

## D. Explicación Detallada del Código

### 1. Inyección de Dependencias y Normalización en `authService.js`
```javascript
// Archivo: backend/src/services/authService.js
// Función: authenticate(email, password, userRepo = users)
```
- **Entrada:** `email` (string), `password` (string), `userRepo` (objeto opcional con método `findByEmail`, por defecto el módulo real).
- **Salida:** Objeto sanitizado `{ id, name, email, role }` si las credenciales son válidas, o `null` si fallan.
- **Manejo de errores y normalización:** `(email || '').trim().toLowerCase()` previene excepciones por valores nulos o indefinidos y normaliza el input para evitar duplicidades por mayúsculas o espacios accidentales.
- **Corte temprano:** Si `normalizedEmail` es vacío, la función retorna `null` inmediatamente sin realizar llamadas asíncronas ni consultar la base de datos.
- **Seguridad:** Si el usuario no existe o no tiene `password_hash`, retorna `null`. La comparación de contraseña usa `bcrypt.compare`, protegiendo la aplicación contra ataques de timing (timing attacks). El objeto retornado omite explícitamente `password_hash` para evitar fugas de información hacia la sesión o vistas.

### 2. El Test con Mock en `authService.test.js`
```javascript
// Archivo: backend/test/authService.test.js
test('authService - autenticación exitosa con mock de repositorio (AAA)', async () => {
  // Arrange
  const plainPassword = 'passwordSegura123!';
  const passwordHash = bcrypt.hashSync(plainPassword, 4);
  const fakeUser = {
    id: 'usr-42',
    name: 'Fotógrafo Principal',
    email: 'fotografo@photomatch.com',
    role: 'admin',
    password_hash: passwordHash
  };

  const calls = [];
  const mockUserRepo = {
    findByEmail: async (email) => {
      calls.push(email);
      return fakeUser;
    }
  };

  // Act
  const result = await authenticate('  FOTOGRAFO@photomatch.com  ', plainPassword, mockUserRepo);

  // Assert
  assert.equal(calls.length, 1, 'El mock debió ser invocado exactamente una vez');
  assert.equal(calls[0], 'fotografo@photomatch.com', 'Debe consultar con el email normalizado');
  assert.deepEqual(result, {
    id: 'usr-42',
    name: 'Fotógrafo Principal',
    email: 'fotografo@photomatch.com',
    role: 'admin'
  });
});
```
- **Por qué se escribió así:** En lugar de depender de una librería externa pesada, creamos un mock explícito mediante un objeto literal que registra en un arreglo `calls` los argumentos recibidos.
- **Qué verifica el assert:** No solo valida que la función devuelva al usuario sanitizado; valida la **interacción**: que el repositorio haya sido llamado una sola vez y que el email recibido haya sido normalizado a minúsculas y sin espacios antes de la consulta.

### 3. Reglas de Liquidación en `pricingService.js`
```javascript
// Archivo: backend/src/services/pricingService.js
function isCounted(player, teamSale) {
  return player.purchase_type !== 'none' && (!teamSale || player.is_additional_sale);
}
```
- **Regla de negocio:** Cuando un organizador contrata una "cobertura de equipo" (`teamSale = true`), el precio global cubre las fotos del plantel. Las ventas a jugadores individuales no deben sumarse a la liquidación salvo que se hayan marcado explícitamente como venta adicional (`player.is_additional_sale = true`). En cambio, si no hubo venta de equipo (`teamSale = false`), cada venta individual cuenta. Si el jugador no compró nada (`purchase_type === 'none'`), nunca cuenta.
- **Sensibilidad a cambios:** Si cambiamos `!teamSale` por `teamSale`, o `&&` por `||`, la suite de tests se pone inmediatamente en rojo (tests parametrizados en `pricingService.test.js`).

---

## E. Decisiones de Ingeniería y Alternativas Evaluadas

### 1. Runner de Pruebas: `node:test` vs Vitest / Jest
- **Alternativas:** Jest, Vitest, Mocha + Chai.
- **Decisión:** Utilizar `node:test` y `node:assert/strict`, el framework nativo integrado en Node.js (disponible desde Node 18/20).
- **Ventajas:** Cero dependencias externas adicionales, arranque instantáneo (87 ms para 32 tests), compatible nativamente con ESM y CommonJS sin transpilación Babel ni TypeScript.
- **Desventajas:** Menos utilidades auxiliares que Jest para mocking global de módulos en disco.
- **Qué pasaría con otra alternativa:** Jest requiere transformar código, descarga cientos de subdependencias y añade varios segundos de arranque en los pipelines de GitHub Actions.

### 2. Instrumentación de Cobertura: `c8` vs Istanbul / nyc
- **Alternativas:** `nyc` (Istanbul tradicional).
- **Decisión:** Utilizar `c8` (`c8 --check-coverage`).
- **Ventajas:** Utiliza la instrumentación nativa del motor V8 de Node.js. No altera el código fuente en disco ni requiere compilación intermedia, midiendo con precisión exacta tanto líneas como bifurcaciones de código real.
- **Consecuencias:** Integración directa con `node --test` y capacidad de fallar el pipeline mediante exit code 1 cuando no se alcanza el umbral.

### 3. Calibración del Umbral de Cobertura (80% Líneas / 70% Ramas)
- **Alternativas:** Exigir 100% o conformarse con un 50%.
- **Decisión:** Fijar 80% en líneas y 70% en ramas sobre la lógica de negocio (`src/services/**`).
- **Justificación:** Nuestra medición real actual es de **100% en líneas y 70.58% en ramas**. Fijar el umbral en 80% y 70% ancla el contrato de calidad en la realidad del proyecto: protege la suite contra regresiones y garantiza que cualquier código nuevo que se agregue sin tests rompa el pipeline de inmediato.
- **Qué haría falta para subir ramas a 85%:** Se deberían escribir tests específicos para los casos de error defensivos en `validationService.js` (líneas 30, 31, 34 y 40), donde se validan estados desconocidos o IDs faltantes que en producción ya están restringidos por los selects de la interfaz EJS.

### 4. Exclusiones de Cobertura
- **Decisión:** Excluir `src/app.js`, `src/db/`, `src/controllers/`, `src/routes/` y `src/views/`.
- **Justificación según la cátedra (§2.4):**
  - `src/app.js` es el archivo de arranque y cableado de Express; si está mal, la aplicación no levanta y se detecta al iniciar.
  - `src/db/` inicializa la conexión PostgreSQL e inyecta tablas; probar eso de forma unitaria requeriría una base de datos real, convirtiéndolo en un test de integración.
  - `src/controllers/` y `src/routes/` manejan el transporte HTTP y llamadas a vistas EJS.
  - Excluir infraestructura y arranque no es trampa: es **medir lo que importa** (la lógica de negocio pura).

### 5. Excepción de Pruebas Unitarias de Frontend
- **Decisión:** Formalizar la excepción de pruebas unitarias en `frontend/` en `decisiones.md`.
- **Justificación oficial (§1605 y §1631 de la consigna):** PhotoMatch posee un frontend basado en Nginx que sirve hojas de estilo estáticas y delega el renderizado dinámico a Express con plantillas EJS en el backend. No existe código JavaScript cliente ni SPA. La cátedra estipula expresamente que en arquitecturas sin frontend de cliente separado, los 4 unit tests de front no aplican y las tres técnicas (mock, parametrizado y error) se concentran y evalúan íntegramente en el backend.

---

## F. Pruebas y Evidencias Reales del TP5

### Resumen de la Suite Implementada:
- **Total de pruebas:** 32 pruebas unitarias.
- **Tiempo de ejecución:** 87 ms.
- **Cobertura alcanzada:**
  - Sentencias (Statements): 100% (86/86)
  - Ramas (Branches): 70.58% (48/68)
  - Funciones (Functions): 100% (9/9)
  - Líneas (Lines): 100% (86/86)

### Evidencias de Pipeline y Pull Requests:

1. **Pull Request 1 (El ciclo Rojo → Corrección → Verde → Merge):**
   - **PR en GitHub:** [#16 — feat(calidad): suite de pruebas unitarias y freno por cobertura en CI](https://github.com/LautyUCC/ingesoft3/pull/16)
   - **Commit 1 (Rojo por umbral):** `0f0f718`
     - Resultado: Pipeline falló en el check obligatorio `build-backend` en el step *Ejecutar tests unitarios y verificar umbral de cobertura (Quality Gate)*.
     - Detalle del log: `ERROR: Coverage for lines (55.81%) does not meet global threshold (80%)`, `ERROR: Coverage for branches (59.61%) does not meet global threshold (70%)`. Los 11 tests existentes pasaron, pero el build se rompió por calidad.
     - **URL de la corrida roja:** [Run #39985482676](https://github.com/LautyUCC/ingesoft3/actions/runs/39985482676)
   - **Commit 2 (Verde):** `e4790fd`
     - Corrección: Incorporación de `authService.test.js` y `pricingService.test.js`.
     - Resultado: 32 tests pasando, 100% líneas, 70.58% ramas. Pipeline completamente en verde.
     - **URL de la corrida verde:** [Run #39985690914](https://github.com/LautyUCC/ingesoft3/actions/runs/39985690914)
     - Artefacto generado: `backend-coverage-report` descargable y Step Summary publicado.

2. **Pull Request 2 (El freno permanente abierto hasta la defensa):**
   - **Rama:** `demo/tp5-gate-bloqueado`
   - **PR en GitHub:** PR abierto contra `main` introduciendo un nuevo servicio de negocio (`discountService.js`) sin cobertura suficiente.
   - **Estado:** Abierto y con el required check `build-backend` en rojo para inspección en vivo por la mesa evaluadora.

---

## G. Preparación para la Defensa Oral

### 10 Preguntas Clave y Respuestas Técnicas

#### 1. ¿Por qué la pirámide de testing tiene esa forma? ¿Qué sucede si se invierte?
**Respuesta:** Tiene base ancha y punta angosta porque el costo financiero, la velocidad de ejecución y la fragilidad varían radicalmente entre niveles. Los unit tests son rápidos (milisegundos), baratos y aíslan con precisión quirúrgica el fallo. Los tests E2E son lentos, costosos de mantener y propensos a falsos positivos por latencia o cambios menores en el DOM. Si se invierte (el anti-patrón *Ice Cream Cone*), el pipeline tarda horas en correr, los desarrolladores ignoran los fallos intermitentes y es imposible determinar qué línea provocó la rotura sin depurar manualmente.

#### 2. Mostrame un test tuyo y señalá el Arrange, el Act y el Assert. ¿Por qué el nombre del test importa?
**Respuesta:** En `backend/test/authService.test.js`, en el test `authService - autenticación exitosa con mock de repositorio (AAA)`:
- **Arrange:** Creo el usuario ficticio con `password_hash` precalculado con bcrypt y preparo el mock `mockUserRepo` con el método `findByEmail`.
- **Act:** Invoco `await authenticate('  FOTOGRAFO@photomatch.com  ', plainPassword, mockUserRepo)`.
- **Assert:** Verifico que el resultado sea el usuario sanitizado sin hash, que `mockUserRepo` haya sido llamado una sola vez y que el email haya sido transformado a `'fotografo@photomatch.com'`.
El nombre importa porque cuando el pipeline falla a las 3 AM o en un servidor headless sin debugger, el nombre del test es el primer y más rápido diagnóstico para el equipo.

#### 3. ¿Qué diferencia hay entre un mock y un stub? Mostrame tu test con mock: ¿qué dependencia reemplazaste y qué verifica el assert?
**Respuesta:** Un stub suministra datos prefabricados para que el código bajo prueba pueda ejecutarse, pero el test no verifica qué hizo la función con el stub. Un mock es un doble sobre el cual el test verifica activamente la interacción: llamadas recibidas, cantidad de veces y argumentos. En mi test de `authService.js`, reemplacé la dependencia externa `userRepository` (que se conecta a PostgreSQL) por un doble. El assert verifica no solo el retorno, sino que `userRepo.findByEmail` fue invocado con el email limpio en minúsculas y sin espacios.

#### 4. Si tuviste que refactorizar para poder inyectar la dependencia, ¿qué cambiaste y por qué no se podía testear antes?
**Respuesta:** Originalmente `authService.js` requería a nivel superior `const users = require('../repositories/userRepository')` y usaba directamente esa variable cerrada en el scope. No se podía testear sin una base de datos PostgreSQL real conectada. Apliqué inversión de dependencias: la función `authenticate` ahora recibe un tercer argumento opcional `userRepo = users`. En producción sigue usando el repositorio por defecto de forma transparente, pero en pruebas unitarias podemos pasarle un doble en memoria.

#### 5. Line coverage vs Branch coverage: ¿cuál puede mentirte más y por qué?
**Respuesta:** Line coverage miente mucho más. Una sola línea puede contener una condición compleja como `if (esSocio || tieneDescuento)`. Ejecutar el test con `esSocio = true` ejecuta la línea completa otorgando 100% de line coverage, pero la rama de `tieneDescuento` jamás fue evaluada. Branch coverage es la métrica más honesta porque audita si se recorrieron todos los caminos posibles de cada bifurcación lógica.

#### 6. Tu cobertura es alta: ¿eso prueba que tu código funciona?
**Respuesta:** No. Cobertura mide código ejecutado, no código verificado. Un test puede invocar una función sin ningún `assert` y la herramienta computará 100% de cobertura de líneas, a pesar de que la función retorne datos erróneos o corruptos. Cobertura alta con tests deficientes es falsa confianza medida con precisión matemática.

#### 7. ¿Por qué elegiste un umbral de 80% en líneas y 70% en ramas? ¿Qué pasaría si mañana lo subís a 95%?
**Respuesta:** Elegí esos valores porque están anclados en la realidad de nuestra aplicación: nuestra suite alcanza 100% en líneas y 70.58% en ramas sobre la lógica de negocio (`src/services/`). Fijar 70% en ramas permite que el pipeline esté en verde hoy pero rompa de inmediato ante cualquier código nuevo que entre sin pruebas. Si mañana lo subiera a 95%, el build se rompería inmediatamente porque nos faltan cubrir ramas defensivas secundarias en `validationService.js` (como estados no contemplados), obligando al equipo a escribir pruebas artificiales solo para satisfacer la métrica (Ley de Goodhart).

#### 8. ¿Qué es un quality gate? ¿Dónde está configurado el tuyo y cómo frena un merge?
**Respuesta:** Un quality gate es una barrera automatizada que bloquea la integración de código si no cumple condiciones de calidad contractuales. En nuestro repositorio, `main` tiene habilitada la regla de branch protection con `strict: true`, `enforce_admins: true` y el required status check `build-backend`. En el workflow `ci.yml`, el step `npm run test:check-coverage` ejecuta `c8 --check-coverage`. Si la cobertura no alcanza el umbral, `c8` finaliza con código de error 1, el job `build-backend` falla, GitHub marca el required check en rojo y el botón de merge queda completamente deshabilitado.

#### 9. Mostrame el Pull Request que quedó bloqueado. Compilaba bien y los tests pasaban todos: ¿por qué no se podía mergear?
**Respuesta:** Es el Pull Request de demostración. Al inspeccionar los logs de Actions, se observa que los tests compilan y se ejecutan con 0 fallos (exit code 0 en los tests), pero el step de cobertura de `c8` detectó que la cobertura total cayó por debajo del 80% en líneas o 70% en ramas debido a código nuevo agregado sin tests. El gate de calidad impidió integrar deuda técnica a `main`.

#### 10. ¿Por qué tu frontend no tiene tests unitarios en este TP?
**Respuesta:** Porque PhotoMatch utiliza una arquitectura monolítica con renderizado en servidor (SSR) mediante Express y plantillas EJS, con Nginx como proxy inverso y servidor de assets estáticos (CSS). No contiene lógica de negocio en el cliente ni una aplicación SPA (como React o Vue). De acuerdo con el reglamento y la consigna oficial del TP5 (§1605 y §1631), cuando no existe frontend desacoplado con lógica cliente, los 4 unit tests de frontend no aplican y las tres técnicas (parametrizado, borde y mock) se concentran y evalúan al 100% en el backend.

---

### Las 3 Preguntas Más Difíciles de la Defensa

#### 🔴 Pregunta Difícil 1:
> *"Tenés 100% de line coverage en `src/services/`. ¿Cómo podrías demostrar científicamente si tus tests son realmente buenos o si solo son tests que ejecutan código sin verificar adecuadamente?"*

**Respuesta para defender:**
> "Para evaluar la calidad intrínseca de los tests más allá de la cobertura, la técnica adecuada es el **Mutation Testing (Pruebas de Mutación)**, utilizando herramientas como **Stryker**. El Mutation Testing introduce pequeñas alteraciones deliberadas en el código fuente de producción llamadas *mutantes* (por ejemplo, cambia un operador `>` por `>=`, invierte un booleano `true` por `false`, o reemplaza un `+` por `-`). Luego corre la suite de pruebas. Si algún test falla, el mutante es **eliminado (*killed*)**, lo que demuestra que la suite detectó el error. Si todos los tests siguen pasando, el mutante **sobrevive (*survived*)**, lo que expone que el test estaba cubriendo esa línea de forma superficial y sin un assert que verifique esa regla específica."

#### 🔴 Pregunta Difícil 2:
> *"En tu función `isCounted(player, teamSale)`, si un desarrollador por error cambia `!teamSale` por `teamSale`, ¿cuál de tus tests falla y por qué?"*

**Respuesta para defender:**
> "Falla inmediatamente el test parametrizado de `pricingService.test.js` en el caso `cobertura sin teamSale: cada venta individual suma`. En ese escenario, `teamSale` es `false`, por lo que `!teamSale` evalúa a `true` y la función debe retornar `true`. Si alguien invierte la condición a `teamSale`, la expresión evaluará a `false`, el assert `assert.equal(actual, expected)` recibirá `false` en lugar de `true` y la suite romperá inmediatamente el build."

#### 🔴 Pregunta Difícil 3:
> *"Dos de tus tres guardianes de `main` son automáticos (el build del contenedor y el quality gate de tests con cobertura). ¿Qué tipos de problemas NINGUNO de ellos puede detectar jamás? ¿Qué podría revisar un agente de IA y qué queda exclusivamente para un humano?"*

**Respuesta para defender:**
> "Ninguno de los guardianes automáticos puede detectar **errores de comprensión de los requerimientos de negocio**. Si el cliente pidió que el Pack de 6 fotos costara \$15.000 pero el desarrollador interpretó que costaba \$12.000 y escribió el código y los tests con \$12.000, tanto el build como la cobertura darán 100% en verde, pero la aplicación estará cobrando un precio comercialmente erróneo.  
> Un **agente de IA** sí puede asistir comparando el texto de la especificación funcional o historia de usuario contra las reglas codificadas para encontrar discrepancias semánticas, detectar vulnerabilidades de seguridad sutiles o sugerir casos de borde no contemplados.  
> Sin embargo, **la decisión final de valor, la aprobación de riesgos en producción y la validación de si el producto satisface la necesidad estratégica del negocio** sigue siendo una responsabilidad exclusivamente humana."

---

## H. Resumen Final de Estudio

### Conceptos Fundamentales a Dominar
1. **Pirámide de testing:** Base unitaria (muchos, rápidos, aislados), integración (medios, colaboran componentes), E2E (pocos, flujo de usuario real).
2. **Patrón AAA:** Arrange (preparar), Act (ejecutar), Assert (verificar).
3. **Mocks:** Dobles que verifican interacciones y llamadas, a diferencia de los stubs que solo proveen datos.
4. **Line vs Branch coverage:** Líneas ejecutadas vs caminos condicionales evaluados.
5. **Quality Gate:** Condición obligatoria en CI que frena el merge ante degradación de calidad.
6. **Inversión de Dependencias:** Pasar la dependencia desde afuera (parámetro o constructor) para desacoplar el diseño y permitir pruebas unitarias.

### Pitch Oral del TP5 (2 Minutos Reloj)
> "En el TP5 convertimos la calidad de PhotoMatch en un contrato medido y exigido automáticamente por el pipeline.  
> Partimos de una aplicación que solo tenía 11 tests de validación y un CI que compilaba contenedores pero no probaba comportamiento. Para solucionar esto, primero refactorizamos el servicio de autenticación aplicando inversión de dependencias, lo que nos permitió aislar la base de datos PostgreSQL y escribir pruebas unitarias con dobles de riesgo (mocks) verificando la interacción y normalización de credenciales.  
> Extendimos la suite a 32 pruebas unitarias cubriendo 6 reglas críticas de negocio, incluyendo catálogo de productos parametrizados, liquidación de coberturas y casos de borde.  
> Integramos `c8` en el pipeline y establecimos un Quality Gate estricto con umbrales de 80% en líneas y 70% en ramas sobre la lógica de negocio. Para demostrar el funcionamiento del freno, ejecutamos dos Pull Requests: el PR #16, que demostró el ciclo completo de fallo por cobertura (55% de líneas), corrección con nuevos tests y merge exitoso al alcanzar 100% de líneas y 70.58% de ramas; y el PR #17, que permanece abierto y bloqueado en rojo hasta la defensa oral para comprobar en vivo que ningún cambio sin pruebas puede integrarse a `main`."

### Glosario Técnico
- **AAA:** Arrange, Act, Assert.
- **Branch Coverage:** Porcentaje de bifurcaciones lógicas ejercitadas.
- **c8:** Herramienta de cobertura para Node.js basada en el motor V8.
- **Flaky Test:** Prueba no determinista que a veces pasa y a veces falla sin cambios de código.
- **Inversión de Dependencias (DI):** Principio de diseño donde los módulos de alto nivel no dependen de módulos de bajo nivel, sino de abstracciones o dependencias inyectadas.
- **Mock:** Objeto simulado que registra llamadas y permite verificar interacciones en el assert.
- **Quality Gate:** Regla de control de calidad automatizada que frena la promoción de software.
- **Stub:** Objeto simulado que responde con valores preprogramados sin verificar llamadas.
- **Step Summary:** Mecanismo de GitHub Actions para renderizar reportes Markdown enriquecidos en el resumen del workflow.

### Checklist para la Demostración en Vivo
- [ ] Abrir el repositorio en GitHub y mostrar la rama `main` y las releases.
- [ ] Mostrar el archivo `decisiones.md` con la sección del TP5 y sus enlaces directos.
- [ ] Mostrar el PR #16 (mergeado): señalar el primer commit en rojo por umbral (55.81% < 80%) y el segundo commit en verde (100% líneas, 70.58% ramas).
- [ ] Mostrar la corrida de Actions [#39985690914](https://github.com/LautyUCC/ingesoft3/actions/runs/39985690914): abrir el Step Summary y mostrar la tabla de cobertura y el artefacto descargable.
- [ ] Mostrar el PR bloqueado (abierto y en rojo): señalar el botón de merge bloqueado y el required check `build-backend` fallando por cobertura.
- [ ] Mostrar en VS Code `backend/src/services/authService.js` explicando la inyección de `userRepo` y en `authService.test.js` el mock y sus asserts.
- [ ] Correr en la terminal local `cd backend && npm run test:check-coverage` para mostrar los 32 tests pasando en menos de 100 ms y la tabla de `c8`.
