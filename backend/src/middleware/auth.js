function requireAuth(req,res,next){ if(!req.session.user){ if(req.path.startsWith('/api/'))return res.status(401).json({error:'Autenticación requerida'}); req.session.returnTo=req.originalUrl; return res.redirect('/login'); } res.locals.user=req.session.user; next(); }
module.exports={requireAuth};
