import 'product_detail_model.dart';
import 'product_unit_model.dart';

/// نموذج بيانات المنتج - النسخة المحدثة
/// يدعم الدفعات المتعددة، الوحدات المتعددة، وحقول الذكاء الاصطناعي
class Product {
  final int? id; // معرّف المنتج (null للمنتجات الجديدة)
  final String name; // اسم المنتج
  final String? barcode; // الباركود (فريد)
  final int? categoryId; // معرّف التصنيف
  final String? imagePath; // مسار صورة المنتج
  final int minStockLevel; // حد الطلب (الحد الأدنى للمخزون)
  final String? description; // وصف المنتج

  // حقول الذكاء الاصطناعي
  final double? predictedDemand; // التوقع العام للطلب
  final String? stockStatus; // حالة المخزون (آمن/خطر)
  final DateTime? lastPredictionDate; // تاريخ آخر توقع

  // البيانات المرتبطة (Relationships)
  final List<ProductDetail> details; // الدفعات (Batches)
  final List<ProductUnit> units; // الوحدات (كرتون، حبة، إلخ)

  Product({
    this.id,
    required this.name,
    this.barcode,
    this.categoryId,
    this.imagePath,
    this.minStockLevel = 10,
    this.description,
    this.predictedDemand,
    this.stockStatus,
    this.lastPredictionDate,
    this.details = const [],
    this.units = const [],
  });

  /// تحويل من Map (قادم من قاعدة البيانات)
  factory Product.fromMap(
    Map<String, dynamic> map, {
    List<ProductDetail>? details,
    List<ProductUnit>? units,
  }) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      categoryId: map['category_id'] as int?,
      imagePath: map['image_path'] as String?,
      minStockLevel: map['min_stock_level'] as int? ?? 10,
      description: map['description'] as String?,
      predictedDemand: (map['predicted_demand'] as num?)?.toDouble(),
      stockStatus: map['stock_status'] as String?,
      lastPredictionDate: map['last_prediction_date'] != null
          ? DateTime.parse(map['last_prediction_date'] as String)
          : null,
      details: details ?? [],
      units: units ?? [],
    );
  }

  /// تحويل إلى Map (للحفظ في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category_id': categoryId,
      'image_path': imagePath,
      'min_stock_level': minStockLevel,
      'description': description,
      'predicted_demand': predictedDemand,
      'stock_status': stockStatus,
      'last_prediction_date': lastPredictionDate?.toIso8601String(),
    };
  }

  /// نسخ الكائن مع تعديل بعض الحقول
  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    int? categoryId,
    String? imagePath,
    int? minStockLevel,
    String? description,
    double? predictedDemand,
    String? stockStatus,
    DateTime? lastPredictionDate,
    List<ProductDetail>? details,
    List<ProductUnit>? units,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      imagePath: imagePath ?? this.imagePath,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      description: description ?? this.description,
      predictedDemand: predictedDemand ?? this.predictedDemand,
      stockStatus: stockStatus ?? this.stockStatus,
      lastPredictionDate: lastPredictionDate ?? this.lastPredictionDate,
      details: details ?? this.details,
      units: units ?? this.units,
    );
  }

  // ============ دوال مساعدة (Helper Getters) ============

  /// الكمية الإجمالية (مجموع كل الدفعات)
  /// يُستخدم بدلاً من currentStock القديم
  int get totalQuantity {
    return details.fold(0, (sum, detail) => sum + detail.quantity);
  }

  /// السعر الأساسي (سعر الوحدة الأساسية)
  /// يُستخدم بدلاً من price القديم
  double get mainPrice {
    // البحث عن الوحدة الأساسية
    final baseUnit = units.firstWhere(
      (unit) => unit.isBaseUnit,
      orElse: () => units.isNotEmpty
          ? units.first
          : ProductUnit(
              productId: id ?? 0,
              unitName: 'قطعة',
              conversionFactor: 1,
              salePrice: 0.0,
              isBaseUnit: true,
            ),
    );
    return baseUnit.salePrice;
  }

  /// اسم الوحدة الأساسية
  String get unitName {
    final baseUnit = units.firstWhere(
      (unit) => unit.isBaseUnit,
      orElse: () => units.isNotEmpty
          ? units.first
          : ProductUnit(
              productId: id ?? 0,
              unitName: 'قطعة',
              conversionFactor: 1,
              salePrice: 0.0,
              isBaseUnit: true,
            ),
    );
    return baseUnit.unitName;
  }

  /// أقرب تاريخ صلاحية من بين جميع الدفعات
  DateTime? get nearestExpiryDate {
    if (details.isEmpty) return null;

    final validDates = details
        .where((d) => d.expiryDate != null)
        .map((d) => d.expiryDate!)
        .toList();

    if (validDates.isEmpty) return null;

    validDates.sort();
    return validDates.first;
  }

  /// هل المنتج تحت حد الطلب؟
  bool get isLowStock {
    return totalQuantity < minStockLevel;
  }

  /// هل المنتج نفذ من المخزون؟
  bool get isOutOfStock {
    return totalQuantity == 0;
  }

  /// عدد الدفعات المنتهية الصلاحية
  int get expiredBatchesCount {
    return details.where((d) => d.isExpired).length;
  }

  /// عدد الدفعات القريبة من الانتهاء
  int get nearExpiryBatchesCount {
    return details.where((d) => d.isNearExpiry).length;
  }

  /// الكمية الصالحة (غير المنتهية)
  int get validQuantity {
    return details
        .where((d) => !d.isExpired)
        .fold(0, (sum, detail) => sum + detail.quantity);
  }

  @override
  String toString() =>
      'Product(id: $id, name: $name, totalQty: $totalQuantity, price: $mainPrice, batches: ${details.length}, units: ${units.length})';
}
