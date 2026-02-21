import 'package:flutter/foundation.dart' hide Category;
import '../models/product.dart';
import '../models/product_detail_model.dart';
import '../models/product_unit_model.dart';
import 'database_helper.dart';

/// خدمة إدارة المنتجات - الوسيط بين الواجهات وقاعدة البيانات
/// Product Service - Mediator between UI and Database
class ProductService {
  final _dbHelper = DatabaseHelper();

  // ============ عمليات القراءة (Read Operations) ============

  /// جلب جميع المنتجات مع تفاصيلها
  Future<List<Product>> getAllProducts() async {
    try {
      return await _dbHelper.getAllProducts();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  /// البحث عن المنتجات بالاسم أو الباركود
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return getAllProducts();
    return await _dbHelper.searchProducts(query);
  }

  /// جلب المنتجات التي وصلت للحد الأدنى (نواقص)
  Future<List<Product>> getLowStockProducts() async {
    return await _dbHelper.getLowStockProducts();
  }

  /// جلب الدفعات القريبة من الانتهاء
  /// [days] : عدد الايام القادمة للتحقق (افتراضياً 30 يوم)
  Future<List<ProductDetail>> getExpiringBatches({int days = 30}) async {
    return await _dbHelper.getExpiringBatches(days);
  }

  // ============ عمليات الكتابة (Write Operations) ============

  /// إضافة منتج جديد
  Future<bool> addProduct(Product product) async {
    try {
      // التحقق من صحة البيانات
      if (product.name.isEmpty) throw Exception('اسم المنتج مطلوب');

      final id = await _dbHelper.insertProduct(product);
      return id > 0;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    }
  }

  /// تحديث بيانات منتج
  Future<bool> updateProduct(Product product) async {
    try {
      if (product.id == null) return false;
      final rows = await _dbHelper.updateProduct(product);
      return rows > 0;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  /// تحديث وحدة قياس
  Future<bool> updateProductUnit(ProductUnit unit) async {
    try {
      final rows = await _dbHelper.updateProductUnit(unit);
      return rows > 0;
    } catch (e) {
      debugPrint('Error updating unit: $e');
      return false;
    }
  }

  /// حذف منتج
  Future<bool> deleteProduct(int id) async {
    try {
      final rows = await _dbHelper.deleteProduct(id);
      return rows > 0;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  // ============ إدارة التفاصيل والوحدات (Details & Units) ============

  /// إضافة دفعة (Batch) جديدة للمنتج
  Future<bool> addProductBatch(ProductDetail batch) async {
    try {
      if (batch.quantity < 0) throw Exception('الكمية لا يمكن أن تكون سالبة');
      final id = await _dbHelper.insertProductDetail(batch);
      return id > 0;
    } catch (e) {
      debugPrint('Error adding batch: $e');
      return false;
    }
  }

  /// إضافة وحدة قياس (Unit) للمنتج
  Future<bool> addProductUnit(ProductUnit unit) async {
    try {
      final id = await _dbHelper.insertProductUnit(unit);
      return id > 0;
    } catch (e) {
      debugPrint('Error adding unit: $e');
      return false;
    }
  }

  // ============ عمليات مركبة (Compound Operations) ============

  /// إنشاء منتج كامل مع الدفعة الأولى والوحدة الأساسية
  Future<bool> createFullProduct({
    required Product product,
    required ProductDetail? initialBatch,
    required ProductUnit? initialUnit,
  }) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      try {
        // 1. إضافة المنتج
        final productId = await txn.insert('Products', product.toMap());
        if (productId == 0) throw Exception('فشل في إضافة المنتج');

        // 2. إضافة الدفعة الأولى (إن وجدت)
        if (initialBatch != null) {
          final batch = initialBatch.copyWith(productId: productId);
          await txn.insert('ProductDetails', batch.toMap());
        }

        // 3. إضافة الوحدة الأساسية (إن وجدت)
        if (initialUnit != null) {
          final unit = initialUnit.copyWith(productId: productId);
          await txn.insert('ProductUnits', unit.toMap());
        }

        return true;
      } catch (e) {
        debugPrint('Transaction failed: $e');
        return false; // سيتم التراجع عن الـ transaction تلقائياً عند حدوث خطأ
      }
    });
  }

  /// جلب منتج حسب المعرف
  Future<Product?> getProductById(int id) async {
    try {
      return await _dbHelper.getProduct(id);
    } catch (e) {
      debugPrint('Error getting product: $e');
      return null;
    }
  }
}
