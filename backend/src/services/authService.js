const bcrypt = require('bcryptjs');
const users = require('../repositories/userRepository');

/**
 * Autentica un usuario contra el repositorio de credenciales.
 * Admite inyección de dependencias para aislar la capa de persistencia en pruebas unitarias.
 *
 * @param {string} email - Correo electrónico del usuario
 * @param {string} password - Contraseña en texto plano
 * @param {object} [userRepo=users] - Repositorio de acceso a datos (mockeable en tests)
 * @returns {Promise<{id: string, name: string, email: string, role: string}|null>}
 */
async function authenticate(email, password, userRepo = users) {
  const normalizedEmail = (email || '').trim().toLowerCase();
  if (!normalizedEmail) {
    return null;
  }

  const user = await userRepo.findByEmail(normalizedEmail);
  if (!user || !user.password_hash) {
    return null;
  }

  const passwordMatches = await bcrypt.compare(password || '', user.password_hash);
  if (!passwordMatches) {
    return null;
  }

  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role
  };
}

module.exports = { authenticate };
