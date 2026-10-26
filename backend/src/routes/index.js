const router=require('express').Router(); const pool=require('../config/database'); const auth=require('../controllers/authController'); const dashboard=require('../controllers/dashboardController'); const client=require('../controllers/clientController'); const apiClient=require('../controllers/apiClientController'); const coverage=require('../controllers/coverageController'); const player=require('../controllers/playerController'); const roster=require('../controllers/rosterController'); const sales=require('../controllers/salesController'); const {requireAuth}=require('../middleware/auth');
router.get('/health', async (req,res)=>{
  try {
    await pool.query('SELECT 1');
    res.status(200).json({
      status: 'ok',
      version: process.env.APP_VERSION || '1.0.0',
      commit: process.env.COMMIT_SHA || 'unknown',
      database: 'connected'
    });
  } catch (err) {
    res.status(503).json({
      status: 'error',
      message: 'Base de datos no disponible',
      error: err.message
    });
  }
});
router.get('/telemetry-config.js',(req,res)=>{
  res.set('Cache-Control','no-store');
  res.type('application/javascript').send(
    `window.PHOTOMATCH_SENTRY_DSN=${JSON.stringify(process.env.SENTRY_BROWSER_DSN || '')};`+
    `window.PHOTOMATCH_COMMIT_SHA=${JSON.stringify(process.env.COMMIT_SHA || 'unknown')};`
  );
});
router.get('/login',auth.showLogin); router.post('/login',auth.login); router.post('/logout',auth.logout);
router.use(requireAuth); router.get('/',dashboard.show);
router.get('/api/clients',apiClient.list); router.post('/api/clients',apiClient.create); router.get('/api/clients/:id',apiClient.show); router.put('/api/clients/:id',apiClient.update); router.delete('/api/clients/:id',apiClient.remove);
router.get('/clients',client.list); router.get('/clients/new',client.newForm); router.post('/clients',client.create); router.get('/clients/:id/edit',client.editForm); router.put('/clients/:id',client.update); router.delete('/clients/:id',client.remove);
router.get('/coverages',coverage.list); router.get('/coverages/new',coverage.newForm); router.post('/coverages',coverage.create); router.get('/coverages/:id',coverage.detail); router.get('/coverages/:id/edit',coverage.editForm); router.put('/coverages/:id',coverage.update); router.delete('/coverages/:id',coverage.remove);
router.get('/coverages/:coverageId/players/new',player.newForm); router.post('/coverages/:coverageId/players',player.create); router.get('/coverage-players/:id/edit',player.editForm); router.put('/coverage-players/:id',player.update); router.post('/coverage-players/:id/quick',player.quick); router.delete('/coverage-players/:id',player.remove);
router.post('/coverages/:coverageId/teams/:teamId/sale',sales.saveTeamSale);router.delete('/coverages/:coverageId/teams/:teamId/sale',sales.removeTeamSale);
router.get('/rosters',roster.index);router.post('/rosters',roster.add);router.post('/rosters/:id/toggle',roster.toggle);router.delete('/rosters/:id',roster.remove);router.get('/players/:id',roster.playerHistory);
router.post('/teams',roster.addTeam);router.post('/divisions',roster.addDivision);
module.exports=router;
