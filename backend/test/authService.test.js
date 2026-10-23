const test = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcryptjs');
const { authenticate } = require('../src/services/authService');

test('authService - autenticación exitosa con mock de repositorio (AAA)', async () => {
  // Arrange: preparar el doble de riesgo (mock) y los datos de prueba
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

  // Act: ejecutar la acción bajo prueba pasando el repositorio mockeado
  const result = await authenticate('  FOTOGRAFO@photomatch.com  ', plainPassword, mockUserRepo);

  // Assert: verificar tanto el resultado como la interacción con el mock
  assert.equal(calls.length, 1, 'El mock del repositorio debió ser invocado exactamente una vez');
  assert.equal(calls[0], 'fotografo@photomatch.com', 'El email debió normalizarse a minúsculas y sin espacios');
  assert.deepEqual(result, {
    id: 'usr-42',
    name: 'Fotógrafo Principal',
    email: 'fotografo@photomatch.com',
    role: 'admin'
  }, 'Debe retornar los datos del usuario sanitizados (sin password_hash)');
});

test('authService - rechaza cuando el usuario no existe en el repositorio (Mock)', async () => {
  // Arrange
  let calledWith = null;
  const mockUserRepo = {
    findByEmail: async (email) => {
      calledWith = email;
      return null;
    }
  };

  // Act
  const result = await authenticate('inexistente@photomatch.com', 'cualquier-clave', mockUserRepo);

  // Assert
  assert.equal(calledWith, 'inexistente@photomatch.com');
  assert.equal(result, null, 'Debe retornar null ante usuario inexistente');
});

test('authService - rechaza cuando la contraseña es incorrecta (Mock)', async () => {
  // Arrange
  const passwordHash = bcrypt.hashSync('clave-correcta', 4);
  const mockUserRepo = {
    findByEmail: async () => ({
      id: 'usr-99',
      name: 'Cliente',
      email: 'cliente@photomatch.com',
      role: 'user',
      password_hash: passwordHash
    })
  };

  // Act
  const result = await authenticate('cliente@photomatch.com', 'clave-erronea', mockUserRepo);

  // Assert
  assert.equal(result, null, 'Debe retornar null ante contraseña inválida');
});

test('authService - rechaza input inválido o vacío sin consultar el repositorio (Borde)', async () => {
  // Arrange: mock que falla si es llamado para verificar que el corte es temprano
  const mockUserRepo = {
    findByEmail: async () => {
      assert.fail('El repositorio no debería ser consultado si el email es nulo o vacío');
    }
  };

  // Act & Assert
  const resNull = await authenticate(null, 'pass', mockUserRepo);
  const resEmpty = await authenticate('   ', 'pass', mockUserRepo);

  assert.equal(resNull, null);
  assert.equal(resEmpty, null);
});

test('authService - rechaza usuario corrupto sin hash de contraseña (Borde)', async () => {
  // Arrange
  const mockUserRepo = {
    findByEmail: async () => ({
      id: 'usr-bad',
      name: 'Incompleto',
      email: 'incompleto@photomatch.com',
      role: 'user',
      password_hash: null
    })
  };

  // Act
  const result = await authenticate('incompleto@photomatch.com', 'pass', mockUserRepo);

  // Assert
  assert.equal(result, null, 'Debe retornar null si el registro carece de password_hash');
});
