/// نموذج بيانات المستخدمين (الموظفين)
/// يُستخدم لإدارة الصلاحيات وتسجيل الدخول
class User {
  final int? id; // معرّف المستخدم
  final String fullName; // الاسم الكامل
  final String username; // اسم المستخدم (للدخول)
  final String passwordHash; // كلمة المرور المشفرة
  final String? securityQuestion; // سؤال الأمان (جديد)
  final String? securityAnswer; // إجابة سؤال الأمان (جديد)
  final bool isActive; // هل الحساب نشط؟

  User({
    this.id,
    required this.fullName,
    required this.username,
    required this.passwordHash,
    this.securityQuestion,
    this.securityAnswer,
    this.isActive = true,
  });

  /// تحويل من Map (قادم من قاعدة البيانات)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      securityQuestion: map['security_question'] as String?,
      securityAnswer: map['security_answer'] as String?,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  /// تحويل إلى Map (للحفظ في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'password_hash': passwordHash,
      'security_question': securityQuestion,
      'security_answer': securityAnswer,
      'is_active': isActive ? 1 : 0,
    };
  }

  /// نسخ الكائن مع تعديل بعض الحقول
  User copyWith({
    int? id,
    String? fullName,
    String? username,
    String? passwordHash,
    String? securityQuestion,
    String? securityAnswer,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswer: securityAnswer ?? this.securityAnswer,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'User(id: $id, username: $username, fullName: $fullName, active: $isActive)';
}
