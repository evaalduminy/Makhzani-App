/// نموذج بيانات جهات الاتصال (العملاء والموردين)
/// يتم دمج العملاء والموردين في جدول واحد للمرونة
class Contact {
  final int? id; // معرّف جهة الاتصال
  final String name; // الاسم
  final String? phone; // رقم الهاتف
  final ContactType type; // النوع (عميل أو مورد)
  final double balance; // الرصيد (موجب = له علينا، سالب = لنا عليه)

  Contact({
    this.id,
    required this.name,
    this.phone,
    required this.type,
    this.balance = 0.0,
  });

  /// تحويل من Map (قادم من قاعدة البيانات)
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      type: ContactType.fromString(map['type'] as String),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// تحويل إلى Map (للحفظ في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type.toString(),
      'balance': balance,
    };
  }

  /// نسخ الكائن مع تعديل بعض الحقول
  Contact copyWith({
    int? id,
    String? name,
    String? phone,
    ContactType? type,
    double? balance,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      balance: balance ?? this.balance,
    );
  }

  /// هل هذه الجهة عليها دين؟
  bool get hasDebt => balance > 0;

  /// هل هذه الجهة لها رصيد؟
  bool get hasCredit => balance < 0;

  @override
  String toString() =>
      'Contact(id: $id, name: $name, type: $type, balance: $balance)';
}

/// أنواع جهات الاتصال
enum ContactType {
  customer, // عميل
  supplier; // مورد

  @override
  String toString() {
    switch (this) {
      case ContactType.customer:
        return 'CUSTOMER';
      case ContactType.supplier:
        return 'SUPPLIER';
    }
  }

  /// تحويل من String إلى Enum
  static ContactType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CUSTOMER':
        return ContactType.customer;
      case 'SUPPLIER':
        return ContactType.supplier;
      default:
        throw ArgumentError('Invalid contact type: $value');
    }
  }

  /// الاسم بالعربية
  String get arabicName {
    switch (this) {
      case ContactType.customer:
        return 'عميل';
      case ContactType.supplier:
        return 'مورد';
    }
  }
}
