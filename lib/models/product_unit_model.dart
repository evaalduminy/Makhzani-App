/// نموذج بيانات وحدات المنتج
/// يدعم وحدات بيع متعددة (كرتون، حبة، علبة، إلخ)
class ProductUnit {
  final int? id; // معرّف الوحدة
  final int productId; // معرّف المنتج
  final String unitName; // اسم الوحدة (مثال: "كرتون", "حبة", "علبة")
  final int
  conversionFactor; // معامل التحويل للوحدة الأساسية (مثال: كرتون = 24 حبة)
  final double salePrice; // سعر البيع لهذه الوحدة
  final bool isBaseUnit; // هل هذه هي الوحدة الأساسية؟ (يجب أن تكون واحدة فقط)

  ProductUnit({
    this.id,
    required this.productId,
    required this.unitName,
    required this.conversionFactor,
    required this.salePrice,
    this.isBaseUnit = false,
  });

  /// تحويل من Map (قادم من قاعدة البيانات)
  factory ProductUnit.fromMap(Map<String, dynamic> map) {
    return ProductUnit(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      unitName: map['unit_name'] as String,
      conversionFactor: map['conversion_factor'] as int,
      salePrice: (map['sale_price'] as num).toDouble(),
      isBaseUnit: (map['is_base_unit'] as int) == 1,
    );
  }

  /// تحويل إلى Map (للحفظ في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'unit_name': unitName,
      'conversion_factor': conversionFactor,
      'sale_price': salePrice,
      'is_base_unit': isBaseUnit ? 1 : 0,
    };
  }

  /// نسخ الكائن مع تعديل بعض الحقول
  ProductUnit copyWith({
    int? id,
    int? productId,
    String? unitName,
    int? conversionFactor,
    double? salePrice,
    bool? isBaseUnit,
  }) {
    return ProductUnit(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      unitName: unitName ?? this.unitName,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      salePrice: salePrice ?? this.salePrice,
      isBaseUnit: isBaseUnit ?? this.isBaseUnit,
    );
  }

  /// حساب السعر للوحدة الأساسية
  /// مثال: إذا كان سعر الكرتون 240 ريال والكرتون = 24 حبة
  /// فإن سعر الحبة = 240 / 24 = 10 ريال
  double get pricePerBaseUnit {
    return salePrice / conversionFactor;
  }

  @override
  String toString() =>
      'ProductUnit(id: $id, unitName: $unitName, salePrice: $salePrice, isBase: $isBaseUnit)';
}
