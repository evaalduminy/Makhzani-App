/// نموذج بيانات حركات المخزون
/// يسجل كل حركة (بيع، شراء، تلف) على المنتجات
class StockTransaction {
  final int? id; // معرّف الحركة
  final int productId; // معرّف المنتج
  final int? productDetailId; // معرّف الدفعة المتأثرة (لضبط FEFO)
  final StockTransactionType type; // نوع الحركة (بيع، شراء، تلف)
  final int quantity; // الكمية (موجبة للشراء، سالبة للبيع/التلف)
  final DateTime transactionDate; // تاريخ الحركة
  final int? userId; // معرّف الموظف الذي قام بالحركة
  final String? notes; // ملاحظات إضافية

  StockTransaction({
    this.id,
    required this.productId,
    this.productDetailId,
    required this.type,
    required this.quantity,
    required this.transactionDate,
    this.userId,
    this.notes,
  });

  /// تحويل من Map (قادم من قاعدة البيانات)
  factory StockTransaction.fromMap(Map<String, dynamic> map) {
    return StockTransaction(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      productDetailId: map['product_detail_id'] as int?,
      type: StockTransactionType.fromString(map['type'] as String),
      quantity: map['quantity'] as int,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      userId: map['user_id'] as int?,
      notes: map['notes'] as String?,
    );
  }

  /// تحويل إلى Map (للحفظ في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_detail_id': productDetailId,
      'type': type.toString(),
      'quantity': quantity,
      'transaction_date': transactionDate.toIso8601String(),
      'user_id': userId,
      'notes': notes,
    };
  }

  /// نسخ الكائن مع تعديل بعض الحقول
  StockTransaction copyWith({
    int? id,
    int? productId,
    int? productDetailId,
    StockTransactionType? type,
    int? quantity,
    DateTime? transactionDate,
    int? userId,
    String? notes,
  }) {
    return StockTransaction(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productDetailId: productDetailId ?? this.productDetailId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      transactionDate: transactionDate ?? this.transactionDate,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'StockTransaction(id: $id, type: $type, quantity: $quantity, date: $transactionDate)';
}

/// أنواع حركات المخزون
enum StockTransactionType {
  sale, // بيع
  purchase, // شراء
  spoilage, // تلف
  adjustment; // تعديل يدوي

  @override
  String toString() {
    switch (this) {
      case StockTransactionType.sale:
        return 'SALE';
      case StockTransactionType.purchase:
        return 'PURCHASE';
      case StockTransactionType.spoilage:
        return 'SPOILAGE';
      case StockTransactionType.adjustment:
        return 'ADJUSTMENT';
    }
  }

  /// تحويل من String إلى Enum
  static StockTransactionType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SALE':
        return StockTransactionType.sale;
      case 'PURCHASE':
        return StockTransactionType.purchase;
      case 'SPOILAGE':
        return StockTransactionType.spoilage;
      case 'ADJUSTMENT':
        return StockTransactionType.adjustment;
      default:
        throw ArgumentError('Invalid transaction type: $value');
    }
  }

  /// الاسم بالعربية
  String get arabicName {
    switch (this) {
      case StockTransactionType.sale:
        return 'بيع';
      case StockTransactionType.purchase:
        return 'شراء';
      case StockTransactionType.spoilage:
        return 'تلف';
      case StockTransactionType.adjustment:
        return 'تعديل';
    }
  }
}
