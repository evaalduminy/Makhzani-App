/// نموذج بيانات محتويات الفاتورة
/// كل سطر في الفاتورة يمثل منتج واحد
class InvoiceItem {
  final int? id; // معرّف السطر
  final int invoiceId; // معرّف الفاتورة
  final int productId; // معرّف المنتج
  final int? productDetailId; // معرّف الدفعة المباعة (للـ FEFO)
  final int? unitId; // معرّف الوحدة المباعة (كرتون، حبة، إلخ)
  final int quantity; // الكمية
  final double unitPrice; // سعر الوحدة
  final double totalPrice; // الإجمالي (quantity * unitPrice)

  InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    this.productDetailId,
    this.unitId,
    required this.quantity,
    required this.unitPrice,
    double? totalPrice,
  }) : totalPrice = totalPrice ?? (quantity * unitPrice);

  /// تحويل من Map (قادم من قاعدة البيانات)
  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int,
      productId: map['product_id'] as int,
      productDetailId: map['product_detail_id'] as int?,
      unitId: map['unit_id'] as int?,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num?)?.toDouble(),
    );
  }

  /// تحويل إلى Map (للحفظ في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'product_detail_id': productDetailId,
      'unit_id': unitId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  /// نسخ الكائن مع تعديل بعض الحقول
  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    int? productDetailId,
    int? unitId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productDetailId: productDetailId ?? this.productDetailId,
      unitId: unitId ?? this.unitId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  String toString() =>
      'InvoiceItem(id: $id, productId: $productId, quantity: $quantity, total: $totalPrice)';
}
