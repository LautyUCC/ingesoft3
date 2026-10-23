const test = require('node:test');
const assert = require('node:assert/strict');
const { calculatePlayerPurchase, isCounted } = require('../src/services/pricingService');

// ============================================================================
// Regla 2: Catálogo de productos y cálculo de compras (Parametrizado con AAA)
// ============================================================================
const validPurchaseCases = [
  {
    type: 'none',
    photosTaken: 0,
    expectedQty: 0,
    expectedPrice: 0,
    expectedPurchased: false,
    description: 'none con 0 fotos no compra nada y precio 0'
  },
  {
    type: 'none',
    photosTaken: 25,
    expectedQty: 0,
    expectedPrice: 0,
    expectedPurchased: false,
    description: 'none con fotos disponibles ignora las fotos y precio 0'
  },
  {
    type: 'single',
    photosTaken: 1,
    expectedQty: 1,
    expectedPrice: 4000,
    expectedPurchased: true,
    description: 'single con 1 foto calcula 1 foto a $4000'
  },
  {
    type: 'single',
    photosTaken: 30,
    expectedQty: 1,
    expectedPrice: 4000,
    expectedPurchased: true,
    description: 'single con 30 fotos calcula 1 foto a $4000'
  },
  {
    type: 'pack6',
    photosTaken: 6,
    expectedQty: 6,
    expectedPrice: 15000,
    expectedPurchased: true,
    description: 'pack6 en el límite exacto de 6 fotos calcula 6 fotos a $15000'
  },
  {
    type: 'pack6',
    photosTaken: 45,
    expectedQty: 6,
    expectedPrice: 15000,
    expectedPurchased: true,
    description: 'pack6 con fotos de sobra calcula 6 fotos a $15000'
  },
  {
    type: 'all',
    photosTaken: 1,
    expectedQty: 1,
    expectedPrice: 25000,
    expectedPurchased: true,
    description: 'all con 1 foto calcula 1 foto a precio plano $25000'
  },
  {
    type: 'all',
    photosTaken: 78,
    expectedQty: 78,
    expectedPrice: 25000,
    expectedPurchased: true,
    description: 'all con 78 fotos calcula 78 fotos a precio plano $25000'
  }
];

validPurchaseCases.forEach((tc) => {
  test(`pricingService - calculatePlayerPurchase parametrizado: ${tc.description}`, () => {
    // Arrange: datos preparados desde la matriz de prueba (tc)
    const { type, photosTaken, expectedQty, expectedPrice, expectedPurchased } = tc;

    // Act: invocar la función de cálculo
    const result = calculatePlayerPurchase(type, photosTaken);

    // Assert: verificar las propiedades resultantes
    assert.equal(result.purchase_type, type);
    assert.equal(result.photos_purchased, expectedQty);
    assert.equal(result.agreed_price, expectedPrice);
    assert.equal(result.purchased_photos, expectedPurchased);
  });
});

// ============================================================================
// Casos de borde y errores en calculatePlayerPurchase
// ============================================================================
test('pricingService - rechaza tipo de producto desconocido (Error)', () => {
  // Arrange
  const invalidType = 'pack10_inexistente';

  // Act & Assert
  assert.throws(
    () => calculatePlayerPurchase(invalidType, 10),
    /Tipo de compra inválido\./
  );
});

test('pricingService - rechaza compra con 0 fotos disponibles (Error/Borde)', () => {
  // Arrange
  const emptyPhotos = 0;

  // Act & Assert
  assert.throws(
    () => calculatePlayerPurchase('single', emptyPhotos),
    /No se puede vender si no hay fotos disponibles\./
  );
  assert.throws(
    () => calculatePlayerPurchase('all', emptyPhotos),
    /No se puede vender si no hay fotos disponibles\./
  );
});

test('pricingService - pack6 rechaza con 5 fotos pero acepta con 6 (Borde estricto)', () => {
  // Arrange & Act & Assert
  // Borde inferior inválido: 5 fotos debe fallar
  assert.throws(
    () => calculatePlayerPurchase('pack6', 5),
    /Se necesitan al menos 6 fotos para vender el pack\./
  );

  // Borde exacto: 6 fotos debe pasar sin excepción
  assert.doesNotThrow(() => calculatePlayerPurchase('pack6', 6));
});

// ============================================================================
// Regla 3: isCounted (Venta individual vs Cobertura de Equipo) (Parametrizado con AAA)
// ============================================================================
const isCountedCases = [
  {
    player: { purchase_type: 'none', is_additional_sale: false },
    teamSale: false,
    expected: false,
    desc: 'jugador sin compra (none) nunca suma en liquidación'
  },
  {
    player: { purchase_type: 'none', is_additional_sale: true },
    teamSale: true,
    expected: false,
    desc: 'jugador sin compra (none) no suma aun con flag adicional'
  },
  {
    player: { purchase_type: 'single', is_additional_sale: false },
    teamSale: false,
    expected: true,
    desc: 'cobertura sin teamSale: cada venta individual suma'
  },
  {
    player: { purchase_type: 'pack6', is_additional_sale: false },
    teamSale: true,
    expected: false,
    desc: 'cobertura con teamSale: venta de jugador está absorbida por la cuota del equipo'
  },
  {
    player: { purchase_type: 'pack6', is_additional_sale: true },
    teamSale: true,
    expected: true,
    desc: 'cobertura con teamSale: venta marcada como adicional SÍ suma en liquidación'
  }
];

isCountedCases.forEach((tc) => {
  test(`pricingService - isCounted parametrizado: ${tc.desc}`, () => {
    // Arrange
    const { player, teamSale, expected } = tc;

    // Act
    const actual = isCounted(player, teamSale);

    // Assert
    assert.equal(actual, expected);
  });
});
