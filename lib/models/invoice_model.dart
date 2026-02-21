import 'invoice_item_model.dart';

/// نموذج بيانات الفواتير (البيع والشراء)
class Invoice {
  final int? id; // معرّف الفاتورة
  final String invoiceNumber; // رقم الفاتورة (فريد)
  final InvoiceType type; // النوع (بيع أو شراء)
  final DateTime date; // تاريخ الفاتورة
  final double totalAmount; // الإجمالي الكلي
  final double paidAmount; // المبلغ المدفوع
  final double remainingAmount; // المتبقي (دين)
  final int? contactId; // معرّف العميل/المورد
  final int? userId; // معرّف البائع/المشتري
  final InvoiceStatus status; // حالة الفاتورة
  final List<InvoiceItem> items; // محتويات الفاتورة

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.type,
    required this.date,
    required this.totalAmount,
    this.paidAmount = 0.0,
    double? remainingAmount,
    this.contactId,
    this.userId,
    this.status = InvoiceStatus.pending,
    this.items = const [],
  }) : remainingAmount = remainingAmount ?? (totalAmount - paidAmount);

  /// تحويل من Map (قادم من قاعدة البيانات)
  factory Invoice.fromMap(
    Map<String, dynamic> map, {
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      type: InvoiceType.fromString(map['type'] as String),
      date: DateTime.parse(map['date'] as String),
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remaining_amount'] as num?)?.toDouble(),
      contactId: map['contact_id'] as int?,
      userId: map['user_id'] as int?,
      status: InvoiceStatus.fromString(map['status'] as String),
      items: items ?? [],
    );
  }

  /// تحويل إلى Map (للحفظ في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'type': type.toString(),
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'contact_id': contactId,
      'user_id': userId,
      'status': status.toString(),
    };
  }

  /// نسخ الكائن مع تعديل بعض الحقول
  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    InvoiceType? type,
    DateTime? date,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    int? contactId,
    int? userId,
    InvoiceStatus? status,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      type: type ?? this.type,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      contactId: contactId ?? this.contactId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }

  /// هل الفاتورة مدفوعة بالكامل؟
  bool get isFullyPaid => remainingAmount <= 0;

  /// هل الفاتورة غير مدفوعة؟
  bool get isUnpaid => paidAmount == 0;

  @override
  String toString() =>
      'Invoice(id: $id, number: $invoiceNumber, type: $type, total: $totalAmount, status: $status)';
}

/// أنواع الفواتير
enum InvoiceType {
  sale, // فاتورة بيع
  purchase; // فاتورة شراء

  @override
  String toString() {
    switch (this) {
      case InvoiceType.sale:
        return 'SALE';
      case InvoiceType.purchase:
        return 'PURCHASE';
    }
  }

  static InvoiceType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SALE':
        return InvoiceType.sale;
      case 'PURCHASE':
        return InvoiceType.purchase;
      default:
        throw ArgumentError('Invalid invoice type: $value');
    }
  }

  String get arabicName {
    switch (this) {
      case InvoiceType.sale:
        return 'بيع';
      case InvoiceType.purchase:
        return 'شراء';
    }
  }
}

/// حالات الفاتورة
enum InvoiceStatus {
  pending, // معلقة
  completed, // مكتملة
  cancelled; // ملغاة

  @override
  String toString() {
    switch (this) {
      case InvoiceStatus.pending:
        return 'PENDING';
      case InvoiceStatus.completed:
        return 'COMPLETED';
      case InvoiceStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static InvoiceStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return InvoiceStatus.pending;
      case 'COMPLETED':
        return InvoiceStatus.completed;
      case 'CANCELLED':
        return InvoiceStatus.cancelled;
      default:
        throw ArgumentError('Invalid invoice status: $value');
    }
  }

  String get arabicName {
    switch (this) {
      case InvoiceStatus.pending:
        return 'معلقة';
      case InvoiceStatus.completed:
        return 'مكتملة';
      case InvoiceStatus.cancelled:
        return 'ملغاة';
    }
  }
}
