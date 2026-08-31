const coverages=require('../repositories/coverageRepository');const sales=require('../repositories/salesRepository');
async function show(req,res){res.render('dashboard',{title:'Dashboard',stats:await coverages.dashboard(),financials:await sales.dashboardFinancials()});}
module.exports={show};
