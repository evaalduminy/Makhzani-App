import 'package:flutter_test/flutter_test.dart';
import 'package:makhzani_app/services/smart_prediction_service.dart';
import 'package:makhzani_app/models/product.dart';
import 'package:makhzani_app/models/product_detail_model.dart';
import 'package:makhzani_app/models/product_unit_model.dart';

void main() {
  late SmartPredictionService service;

  setUp(() {
    service = SmartPredictionService();
  });

  group('SmartPredictionService Tests', () {
    // 1. Expiry Logic Tests
    test('Should return EXPIRY insight for expired batches', () async {
      final expiredProduct = Product(
        id: 1,
        name: 'Expired Milk',
        details: [
          ProductDetail(
            productId: 1,
            quantity: 5,
            purchasePrice: 10.0,
            expiryDate: DateTime.now().subtract(const Duration(days: 1)),
          )
        ],
      );

      final insights = await service.getAIInsights([expiredProduct]);

      expect(insights, isNotEmpty);
      expect(insights.first.type, 'EXPIRY');
      expect(insights.first.message, contains('تنبيه حرج'));
    });

    test('Should return EXPIRY insight for near-expiry batches', () async {
      final nearExpiryProduct = Product(
        id: 2,
        name: 'Near Expiry Yogurt',
        details: [
          ProductDetail(
            productId: 2,
            quantity: 10,
            purchasePrice: 5.0,
            expiryDate: DateTime.now().add(const Duration(days: 10)),
          )
        ],
      );

      final insights = await service.getAIInsights([nearExpiryProduct]);

      expect(insights, isNotEmpty);
      expect(insights.first.type, 'EXPIRY');
      expect(insights.first.message, contains('يقترب من الانتهاء'));
    });

    // 2. Restock Logic (Low Price + Low Stock)
    test('Should return RESTOCK insight for low price and low quantity items',
        () async {
      // Create a cheap product with low stock
      final cheapProduct = Product(
        id: 3,
        name: 'Cheap Water',
        minStockLevel: 50,
        units: [
          ProductUnit(
              productId: 3,
              unitName: 'Piece',
              conversionFactor: 1,
              salePrice: 1.0,
              isBaseUnit: true)
        ],
        details: [
          ProductDetail(
              productId: 3, quantity: 10, purchasePrice: 0.5) // Total qty 10
        ],
      );

      final insights = await service.getAIInsights([cheapProduct]);

      // Check if ANY insight matches RESTOCK
      final hasRestockInsight = insights.any((i) => i.type == 'RESTOCK');
      expect(hasRestockInsight, isTrue);
    });

    // 3. Seasonality Logic
    // Note: This test depends on the current actual month.
    // We will simple verify that the Service doesn't crash and returns *something* valid or empty.
    test('getPrediction returns a valid integer prediction', () async {
      final product = Product(
        name: 'Generic Item',
        details: [
          ProductDetail(productId: 4, quantity: 100, purchasePrice: 10.0)
        ],
      );

      final prediction = await service.getPrediction(product);
      expect(prediction, isA<int>());
      expect(prediction, greaterThan(0));
    });

    // 4. Sorting Logic
    test('Should prioritize EXPIRY insights over others', () async {
      final mixedProducts = [
        Product(id: 5, name: 'Expired Item', details: [
          ProductDetail(
              productId: 5,
              quantity: 5,
              purchasePrice: 10,
              expiryDate: DateTime.now().subtract(const Duration(days: 1)))
        ]),
        Product(
            id: 6,
            name: 'Cheap Item', // Triggers RESTOCK
            units: [
              ProductUnit(
                  productId: 6,
                  unitName: 'Piece',
                  conversionFactor: 1,
                  salePrice: 1.0,
                  isBaseUnit: true)
            ],
            details: [
              ProductDetail(productId: 6, quantity: 10, purchasePrice: 10)
            ]),
      ];

      final insights = await service.getAIInsights(mixedProducts);

      expect(insights.length, greaterThanOrEqualTo(2));
      expect(insights.first.type, 'EXPIRY'); // Expiry must be first
    });
  });
}
