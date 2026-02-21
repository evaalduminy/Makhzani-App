import 'dart:convert';

import 'package:crypto/crypto.dart';

/// فئة مساعدة للعمليات الأمنية
/// تحتوي على دوال للتشفير والحماية
class SecurityUtils {
  /// دالة لتشفير كلمة المرور باستخدام خوارزمية SHA-256
  /// [password]: كلمة المرور الأصلية (النصيّة)
  /// ترجع: كلمة المرور المشفرة (Hex String)
  static String hashPassword(String password) {
    // 1. تحويل النص إلى بايتات (Bytes)
    var bytes = utf8.encode(password);

    // 2. تطبيق خوارزمية التشفير SHA-256
    // SHA-256 هي خوارزمية باتجاه واحد (One-way)، أي لا يمكن استرجاع النص الأصلي منها بسهولة
    var digest = sha256.convert(bytes);

    // 3. إرجاع النتيجة كنص
    return digest.toString();
  }
}
