import 'package:flutter/material.dart';

/// كلاس `TimelineAxisPainter`
/// هو رسام مخصص (CustomPainter) يستخدم لرسم محور زمني (Time Axis) أسفل المخططات البيانية.
/// يقوم برسم خط أفقي، ومجموعة من النقاط (Dots) تمثل الفترات الزمنية، وتسميات (Labels) تحت كل نقطة.
class TimelineAxisPainter extends CustomPainter {
  /// قائمة النصوص التي ستظهر تحت المحور (مثلاً: يناير، فبراير، ...)
  final List<String> labels;

  /// لون الخط والنقاط
  final Color lineColor;

  TimelineAxisPainter({
    required this.labels,
    required this.lineColor,
  });

  // دالة الرسم الرئيسية التي يستدعيها النظام
  @override
  void paint(Canvas canvas, Size size) {
    // إعداد قلم الرسم للخط الرئيسي
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // إعداد فرشاة تعبئة النقاط (لون أبيض في المنتصف)
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // إعداد حدود النقاط (نفس لون الخط)
    final dotBorderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // حساب المسافة الأفقية بين كل نقطة والأخرى بناءً على عرض الشاشة وعدد العناصر
    final double widthStep = size.width / (labels.length - 1);
    final double y = 10; // الموقع الرأسي للخط (10 بكسل من الأعلى)

    // 1. رسم الخط الأفقي الرئيسي من البداية للنهاية
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    // 2. المرور على كل عنصر ورسم النقطة والنص الخاص به
    for (int i = 0; i < labels.length; i++) {
      final x = i * widthStep; // حساب الموقع الأفقي لهذه النقطة

      // أ. رسم دائرة بيضاء تعبئة
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      // ب. رسم حدود الدائرة (إطار)
      canvas.drawCircle(Offset(x, y), 5, dotBorderPaint);

      // ج. رسم النص (Label)
      final textSpan = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.rtl, // اتجاه النص للعربية
        textAlign: TextAlign.center,
      );

      textPainter.layout(); // حساب أبعاد النص
      // رسم النص بحيث يكون في المنتصف تماماً تحت النقطة
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), y + 10), // 10 بكسل تحت النقطة
      );
    }
  }

  // هل يجب إعادة الرسم؟ نعم دائماً عند التحديث لضمان دقة العرض
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
