const { CLIENT_TYPES, COVERAGE_STATUSES, PAYMENT_STATUSES } = require('../models/constants');

function clean(value) { return typeof value === 'string' ? value.trim() : value; }
function optional(value) { const result = clean(value); return result || null; }
function validEmail(value) { return !value || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value); }

function validateClient(input) {
  const data = { name: clean(input.name), type: input.type, phone: optional(input.phone), email: optional(input.email), notes: optional(input.notes) };
  const errors = [];
  if (!data.name) errors.push('El nombre es obligatorio.');
  if (!CLIENT_TYPES.includes(data.type)) errors.push('El tipo de cliente no es válido.');
  if (!validEmail(data.email)) errors.push('El email no tiene un formato válido.');
  return { data, errors };
}

function validateCoverage(input) {
  const data = {
    event_name: clean(input.event_name), event_date: input.event_date, venue: clean(input.venue),
    client_id: Number(input.client_id), price: Number(input.price), status: input.status,
    payment_status: input.payment_status, photo_count: Number(input.photo_count),
    delivery_date: optional(input.delivery_date), notes: optional(input.notes), home_team_id:Number(input.home_team_id),away_team_id:Number(input.away_team_id),home_division_id:Number(input.home_division_id),away_division_id:Number(input.away_division_id)
  };
  const errors = [];
  if (!data.event_name) errors.push('El evento es obligatorio.');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(data.event_date || '')) errors.push('La fecha del evento es obligatoria.');
  if (!data.venue) errors.push('El lugar es obligatorio.');
  if (!Number.isInteger(data.client_id) || data.client_id < 1) errors.push('Seleccioná un cliente.');
  if (!Number.isFinite(data.price) || data.price < 0) errors.push('El precio no puede ser negativo.');
  if (!Number.isInteger(data.photo_count) || data.photo_count < 0) errors.push('La cantidad de fotos debe ser un entero no negativo.');
  if (!COVERAGE_STATUSES.includes(data.status)) errors.push('El estado no es válido.');
  if (!PAYMENT_STATUSES.includes(data.payment_status)) errors.push('El estado de pago no es válido.');
  if (data.delivery_date && data.delivery_date < data.event_date) errors.push('La entrega no puede ser anterior al evento.');
  if (data.status === 'Entregada' && !data.delivery_date) errors.push('Una cobertura entregada necesita fecha de entrega.');
  if(!data.home_team_id||!data.away_team_id||!data.home_division_id||!data.away_division_id)errors.push('Seleccioná equipo y división para ambos lados.');
  if(data.home_team_id===data.away_team_id&&data.home_division_id===data.away_division_id)errors.push('Los planteles deben ser diferentes.');
  return { data, errors };
}

function validateCoveragePlayer(input){
  const data={player_id:input.player_id?Number(input.player_id):null,first_name:clean(input.first_name),last_name:clean(input.last_name),team_id:Number(input.team_id),jersey_number:input.jersey_number===''?null:Number(input.jersey_number),photos_taken:Number(input.photos_taken),requested_photos:input.requested_photos==='on',purchase_type:input.purchase_type||'none',player_payment_status:input.player_payment_status||'Pendiente',is_additional_sale:input.is_additional_sale==='on',status:input.status,notes:optional(input.notes)};
  const errors=[]; if(!data.player_id&&(!data.first_name||!data.last_name))errors.push('Ingresá nombre y apellido o elegí un jugador existente.'); if(!Number.isInteger(data.team_id)||data.team_id<1)errors.push('Seleccioná un equipo.'); if(data.jersey_number!==null&&(!Number.isInteger(data.jersey_number)||data.jersey_number<0))errors.push('El dorsal no es válido.'); if(!Number.isInteger(data.photos_taken)||data.photos_taken<0)errors.push('Las fotos tomadas deben ser un entero no negativo.'); if(!PLAYER_STATUSES.includes(data.status))errors.push('El estado del jugador no es válido.'); if(!PAYMENT_STATUSES.includes(data.player_payment_status))errors.push('El estado de pago no es válido.'); try{Object.assign(data,require('./pricingService').calculatePlayerPurchase(data.purchase_type,data.photos_taken));}catch(e){errors.push(e.message);} return {data,errors};
}

const { PLAYER_STATUSES } = require('../models/constants');
module.exports = { validateClient, validateCoverage, validateCoveragePlayer };
