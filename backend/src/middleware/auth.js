function requireAuth(req,res,next){ if(!req.session.user){ req.session.returnTo=req.originalUrl; return res.redirect('/login'); } res.locals.user=req.session.user; next(); }
module.exports={requireAuth};
