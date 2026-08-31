const pricing=require('../config/pricing');
function calculatePlayerPurchase(type,photosTaken){const product=pricing.products[type];if(!product)throw new Error('Tipo de compra inválido.');if(type!=='none'&&photosTaken===0)throw new Error('No se puede vender si no hay fotos disponibles.');if(type==='pack6'&&photosTaken<6)throw new Error('Se necesitan al menos 6 fotos para vender el pack.');return {purchase_type:type,photos_purchased:product.quantity==='all'?photosTaken:product.quantity,agreed_price:product.price,purchased_photos:type!=='none'};}
function isCounted(player,teamSale){return player.purchase_type!=='none'&&(!teamSale||player.is_additional_sale);}
module.exports={pricing,calculatePlayerPurchase,isCounted};
