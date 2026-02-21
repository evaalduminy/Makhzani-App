import 'package:flutter_test/flutter_test.dart';
import 'package:makhzani_app/models/product.dart';
import 'package:makhzani_app/models/product_detail_model.dart';

void main() {
  group('ProductDetail Tests', () {
    test('isExpired returns true for past dates', () {
      final detail = ProductDetail(
        productId: 1,
        quantity: 10,
        purchasePrice: 10.0,
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(detail.isExpired, isTrue);
    });

    test('isExpired returns false for future dates', () {
      final detail = ProductDetail(
        productId: 1,
        quantity: 10,
        purchasePrice: 10.0,
        expiryDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(detail.isExpired, isFalse);
    });

    test('isNearExpiry returns true for dates within 30 days', () {
      final detail = ProductDetail(
        productId: 1,
        quantity: 10,
        purchasePrice: 10.0,
        expiryDate: DateTime.now().add(const Duration(days: 15)),
      );
      expect(detail.isNearExpiry, isTrue);
    });

    test('isNearExpiry returns false for dates > 30 days', () {
      final detail = ProductDetail(
        productId: 1,
        quantity: 10,
        purchasePrice: 10.0,
        expiryDate: DateTime.now().add(const Duration(days: 40)),
      );
      expect(detail.isNearExpiry, isFalse);
    });
  });

  group('Product Tests', () {
    test('totalQuantity sums up all batch quantities', () {
      final product = Product(
        name: 'Test Product',
        details: [
          ProductDetail(productId: 1, quantity: 10, purchasePrice: 5.0),
          ProductDetail(productId: 1, quantity: 20, purchasePrice: 5.0),
        ],
      );
      expect(product.totalQuantity, 30);
    });

    test('isLowStock returns true when totalQuantity < minStockLevel', () {
      final product = Product(
        name: 'Low Stock Product',
        minStockLevel: 10,
        details: [
          ProductDetail(productId: 1, quantity: 5, purchasePrice: 5.0),
        ],
      );
      expect(product.isLowStock, isTrue);
    });

    test('isLowStock returns false when totalQuantity >= minStockLevel', () {
      final product = Product(
        name: 'Safe Stock Product',
        minStockLevel: 10,
        details: [
          ProductDetail(productId: 1, quantity: 15, purchasePrice: 5.0),
        ],
      );
      expect(product.isLowStock, isFalse);
    });

    test('nearestExpiryDate returns the closest date', () {
      final now = DateTime.now();
      final product = Product(
        name: 'Expiry Product',
        details: [
          ProductDetail(
              productId: 1,
              quantity: 10,
              purchasePrice: 5.0,
              expiryDate: now.add(const Duration(days: 100))),
          ProductDetail(
              productId: 1,
              quantity: 10,
              purchasePrice: 5.0,
              expiryDate: now.add(const Duration(days: 10))),
        ],
      );
      expect(
          product.nearestExpiryDate!
              .difference(now.add(const Duration(days: 10)))
              .inDays,
          0);
    });
  });
}
