/**
 * Servicio de fidelización y descuentos promocionales para PhotoMatch.
 * Permite categorizar clientes y aplicar bonificaciones sobre coberturas contratadas.
 */

const LOYALTY_TIERS = {
  BRONZE: { name: 'Bronce', discountPercent: 0, minCoverages: 0 },
  SILVER: { name: 'Plata', discountPercent: 5, minCoverages: 5 },
  GOLD: { name: 'Oro', discountPercent: 10, minCoverages: 15 },
  PLATINUM: { name: 'Platino', discountPercent: 20, minCoverages: 30 }
};

function calculateLoyaltyTier(completedCoverages, totalSpent) {
  if (completedCoverages < 0 || totalSpent < 0) {
    throw new Error('Los valores de coberturas y gasto deben ser no negativos.');
  }

  if (completedCoverages >= LOYALTY_TIERS.PLATINUM.minCoverages || totalSpent >= 500000) {
    return LOYALTY_TIERS.PLATINUM;
  }
  if (completedCoverages >= LOYALTY_TIERS.GOLD.minCoverages || totalSpent >= 250000) {
    return LOYALTY_TIERS.GOLD;
  }
  if (completedCoverages >= LOYALTY_TIERS.SILVER.minCoverages || totalSpent >= 100000) {
    return LOYALTY_TIERS.SILVER;
  }
  return LOYALTY_TIERS.BRONZE;
}

function applyPromotionalDiscount(basePrice, promoCode, tier) {
  if (basePrice <= 0) return 0;
  let discount = tier ? tier.discountPercent : 0;

  if (promoCode === 'TORNEO2026') {
    discount = Math.max(discount, 15);
  } else if (promoCode === 'INICIO_TEMPORADA') {
    discount += 5;
  }

  const finalDiscount = Math.min(discount, 30);
  return Math.round(basePrice * (1 - finalDiscount / 100));
}

module.exports = {
  LOYALTY_TIERS,
  calculateLoyaltyTier,
  applyPromotionalDiscount
};
