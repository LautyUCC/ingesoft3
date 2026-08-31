const auth = require('../services/authService');
function showLogin(req,res){ if(req.session.user) return res.redirect('/'); res.render('auth/login',{title:'Iniciar sesión',error:null}); }
async function login(req,res){ const user=await auth.authenticate(req.body.email,req.body.password); if(!user) return res.status(401).render('auth/login',{title:'Iniciar sesión',error:'Email o contraseña incorrectos.'}); req.session.user=user; const target=req.session.returnTo||'/'; delete req.session.returnTo; res.redirect(target); }
function logout(req,res,next){ req.session.destroy(err=>err?next(err):res.redirect('/login')); }
module.exports={showLogin,login,logout};
