/// نموذج بيانات تفاصيل المنتج (الدفعات - Batches)
/// كل دفعة لها تاريخ صلاحية وكمية منفصلة
/// يُستخدم لتطبيق FEFO (First Expired First Out)
class ProductDetail {
  final int? id; // معرّف الدفعة
  final int productId; // معرّف المنتج الأساسي
  final DateTime?
  expiryDate; // تاريخ انتهاء الصلاحية (null للمنتجات بدون صلاحية)
  final int quantity; // الكمية المتوفرة من هذه الدفعة
  final double purchasePrice; // سعر الشراء لهذه الدفعة
  final int? supplierId; // معرّف المورد (اختياري)

  ProductDetail({
    this.id,
    required this.productId,
    this.expiryDate,
    required this.quantity,
    required this.purchasePrice,
    this.supplierId,
  });

  /// تحويل من Map (قادم من قاعدة البيانات)
  factory ProductDetail.fromMap(Map<String, dynamic> map) {
    return ProductDetail(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      quantity: map['quantity'] as int,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      supplierId: map['supplier_id'] as int?,
    );
  }

  /// تحويل إلى Map (للحفظ في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'expiry_date': expiryDate?.toIso8601String(),
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'supplier_id': supplierId,
    };
  }

  /// نسخ الكائن مع تعديل بعض الحقول
  ProductDetail copyWith({
    int? id,
    int? productId,
    DateTime? expiryDate,
    int? quantity,
    double? purchasePrice,
    int? supplierId,
  }) {
    return ProductDetail(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      supplierId: supplierId ?? this.supplierId,
    );
  }

  /// هل هذه الدفعة منتهية الصلاحية؟
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// عدد الأيام المتبقية حتى انتهاء الصلاحية
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// هل هذه الدفعة قريبة من الانتهاء؟ (أقل من 30 يوم)
  bool get isNearExpiry {
    final days = daysUntilExpiry;
    if (days == null) return false;
    return days > 0 && days <= 30;
  }

  @override
  String toString() =>
      'ProductDetail(id: $id, productId: $productId, quantity: $quantity, expiryDate: $expiryDate)';
}
