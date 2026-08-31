const bcrypt = require('bcryptjs');
const users = require('../repositories/userRepository');
async function authenticate(email,password){ const user=await users.findByEmail((email||'').trim().toLowerCase()); if(!user || !await bcrypt.compare(password||'',user.password_hash)) return null; return {id:user.id,name:user.name,email:user.email,role:user.role}; }
module.exports={authenticate};
