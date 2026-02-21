import 'package:flutter/material.dart';

/// كلاس `AppColors`
/// هذا الملف هو "مصدر الحقيقة" (Source of Truth) لجميع الألوان المستخدمة في التطبيق.
/// الهدف منه ضمان وتوحيد الهوية البصرية (Visual Identity) للتطبيق بحيث تكون الألوان متسقة في جميع الشاشات.
/// بدلاً من كتابة `Color(0xFF...)` بشكل متكرر وتشتيت الألوان، نستخدم `AppColors.primary` مثلاً.
/// هذا يسهل عملية تغيير "Theme" التطبيق كاملاً من مكان واحد فقط.
class AppColors {
  // ================== الألوان الأساسية (Brand Colors) ==================

  /// اللون الأساسي للتطبيق (Cyan / سماوي)
  /// يستخدم في:
  /// - شريط التطبيق (AppBar)
  /// - الأزرار الرئيسية
  /// - الأيقونات النشطة في شريط التنقل
  static const Color primary = Color(0xFF00BCD4);

  /// اللون الثانوي (Blue / أزرق)
  /// يستخدم في:
  /// - الرسوم البيانية (Charts) في التقارير
  /// - الروابط أو الأزرار الثانوية
  /// - تمييز العناصر التفاعلية الفرعية
  static const Color secondary = Color(0xFF1E88E5);

  // ================== ألوان الحالات (Semantic Colors) ==================

  /// لون النجاح أو الحالة الجيدة (Green / أخضر)
  /// يستخدم للإشارة إلى:
  /// - توفر المخزون (In Stock)
  /// - اكتمال عملية بنجاح
  /// - زيادة في الأرباح
  static const Color success = Color(0xFF66BB6A);

  /// لون التحذير (Orange / برتقالي)
  /// يستخدم للإشارة إلى:
  /// - اقتراب نفاذ المخزون
  /// - تنبيهات انتهاء الصلاحية القريبة
  /// - إجراءات تحتاج انتباه المستخدم
  static const Color warning = Color(0xFFFF9800);

  /// لون الخطر أو الخطأ (Red / أحمر)
  /// يستخدم للإشارة إلى:
  /// - نفاذ المخزون (Out of Stock)
  /// - انتهاء الصلاحية
  /// - رسائل الخطأ عند الإدخال
  /// - حذف العناصر
  static const Color danger = Color(0xFFEF5350);

  // ================== الألوان المحايدة (Neutrals) ==================

  /// لون الخلفية العام للشاشات (Light Gray / رمادي فاتح جداً)
  /// يستخدم في `Scaffold background` لإعطاء مظهر نظيف وبراق
  static const Color background = Color(0xFFF5F5F5);

  /// لون السطح (White / أبيض)
  /// يستخدم كخلفية للبطاقات (Cards) والقوائم (Lists) لتمييزها عن الخلفية الرمادية
  static const Color surface = Color(0xFFFFFFFF);

  /// لون النص الأساسي (Dark Gray / رمادي غامق)
  /// يستخدم للعناوين والنصوص المهمة لضمان مقروئية عالية (Contrast)
  static const Color textPrimary = Color(0xFF263238);

  /// لون النص الثانوي (Medium Gray / رمادي متوسط)
  /// يستخدم للنصوص التوضيحية، التواريخ، والعناوين الفرعية
  static const Color textSecondary = Color(0xFF78909C);

  // ================== تدرجات مشتقة (Color Variations) ==================

  // درجات أفتح وأغمق من اللون الأساسي للاستخدام في التدرجات أو حالات الضغط (Hover/Press)
  static const Color primaryLight = Color(0xFF4DD0E1);
  static const Color primaryDark = Color(0xFF00ACC1);

  // درجات أفتح وأغمق من اللون الثانوي
  static const Color secondaryLight = Color(0xFF42A5F5);
  static const Color secondaryDark = Color(0xFF1976D2);

  // ================== عناصر واجهة المستخدم (UI Elements) ==================

  /// لون الفواصل والخطوط الرفيعة بين العناصر
  static const Color divider = Color(0xFFE0E0E0);

  /// لون العناصر غير المفعلة (Disabled) مثل الأزرار التي لا يمكن الضغط عليها
  static const Color disabled = Color(0xFFBDBDBD);

  /// لون النصوص التلميحية (Hint Text) داخل حقول الإدخال
  static const Color hint = Color(0xFF9E9E9E);

  // ================== التدرجات اللونية (Gradients) ==================

  /// تدرج لوني أساسي (من السماوي الفاتح للغامق)
  /// يعطي جمالية وحداثة للأزرار والخلفيات المميزة
  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      primaryDark,
    ],
  );

  /// تدرج لوني ثانوي (من الأزرق الفاتح للغامق)
  static LinearGradient secondaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      secondary,
      secondaryDark,
    ],
  );
}
