/// نموذج بيانات التصنيفات
/// يدعم التصنيفات الهرمية (شجرة) عبر parent_id
class Category {
  final int? id; // معرّف التصنيف (null للتصنيفات الجديدة)
  final String name; // اسم التصنيف (مثال: "ألبان", "مواد غذائية")
  final int? parentId; // معرّف التصنيف الأب (null للتصنيفات الرئيسية)

  Category({this.id, required this.name, this.parentId});

  /// تحويل من Map (قادم من قاعدة البيانات)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentId: map['parent_id'] as int?,
    );
  }

  /// تحويل إلى Map (للحفظ في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'parent_id': parentId};
  }

  /// نسخ الكائن مع تعديل بعض الحقول
  Category copyWith({int? id, String? name, int? parentId}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, parentId: $parentId)';
}
