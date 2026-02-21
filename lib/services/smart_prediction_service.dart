import 'package:makhzani_app/models/product.dart';

/// كلاس لتمثيل رؤية أو توصية من الذكاء الاصطناعي
class PredictionInsight {
  final Product product;
  final String type; // 'SEASONAL', 'EXPIRY', 'RESTOCK', 'GENERAL'
  final String message; // نص التوصية (السبب)
  final int? recommendedQuantity; // الكمية المقترحة (إن وجدت)
  final double confidence; // درجة الثقة (0.0 - 1.0)

  PredictionInsight({
    required this.product,
    required this.type,
    required this.message,
    this.recommendedQuantity,
    this.confidence = 0.8,
  });
}

/// خدمة التنبؤ الذكية المتقدمة (نسخة مستقرة بدون TFLite لضمان عمل الـ APK)
class SmartPredictionService {
  /// الحصول على قائمة برؤى الذكاء الاصطناعي الشاملة
  Future<List<PredictionInsight>> getAIInsights(List<Product> products) async {
    List<PredictionInsight> insights = [];

    for (var product in products) {
      final expiryInsight = _checkExpiry(product);
      if (expiryInsight != null) {
        insights.add(expiryInsight);
      }

      final seasonalInsight = _checkSeasonalityAndDemand(product);
      if (seasonalInsight != null) {
        insights.add(seasonalInsight);
      }
    }

    insights.sort((a, b) {
      if (a.type == 'EXPIRY' && b.type != 'EXPIRY') return -1;
      if (a.type != 'EXPIRY' && b.type == 'EXPIRY') return 1;
      return 0;
    });

    return insights;
  }

  /// التنبؤ بالكمية (باستخدام الخوارزمية الهجينة الذكية)
  Future<int> getPrediction(Product product) async {
    int aiPrediction = 0;

    // حساب التوقع البرمجي (Smart Logic)
    aiPrediction = _calculateBasePrediction(product);

    // تطبيق عوامل الموسمية البرمجية (Hybrid logic)
    final seasonFactor = _getSeasonalityFactor(product);
    int finalResult = (aiPrediction * seasonFactor).round();

    return finalResult;
  }

  // ============ دوال التحليل الخاصة ============

  /// فحص تواريخ الانتهاء
  PredictionInsight? _checkExpiry(Product product) {
    if (product.details.isEmpty) return null;

    final nearExpiryBatches =
        product.details.where((d) => d.isNearExpiry).toList();
    final expiredBatches = product.details.where((d) => d.isExpired).toList();

    if (expiredBatches.isNotEmpty) {
      return PredictionInsight(
        product: product,
        type: 'EXPIRY',
        message:
            '⚠️ تنبيه حرج: يوجد ${expiredBatches.length} دفعات منتهية الصلاحية لهذا المنتج. يجب إزالتها فوراً.',
        confidence: 1.0,
      );
    }

    if (nearExpiryBatches.isNotEmpty) {
      final days = nearExpiryBatches.first.daysUntilExpiry;
      return PredictionInsight(
        product: product,
        type: 'EXPIRY',
        message:
            'تنبيه: هذا المنتج يقترب من الانتهاء (متبقي $days أيام). ينصح بعمل عروض ترويجية لتصريف المخزون.',
        confidence: 0.9,
      );
    }

    return null;
  }

  /// فحص الموسمية والطلب (المنطق البرمجي الذكي)
  PredictionInsight? _checkSeasonalityAndDemand(Product product) {
    final now = DateTime.now();
    final month = now.month;
    final name = product.name.toLowerCase();

    bool isWinter = month == 12 || month == 1 || month == 2;
    bool isSummer = month == 6 || month == 7 || month == 8;
    bool isRamadan = month == 2 || month == 3;

    if (isWinter) {
      if (name.contains('حليب') ||
          name.contains('milk') ||
          name.contains('شاي') ||
          name.contains('tea') ||
          name.contains('عدس') ||
          name.contains('lentil')) {
        final basePrediction = _calculateBasePrediction(product);
        final boostedPrediction = (basePrediction * 1.5).round();

        return PredictionInsight(
          product: product,
          type: 'SEASONAL',
          message:
              '❄️ الجو بارد! يزداد الطلب على المشروبات الساخنة والأغذية الشتوية. نقترح زيادة المخزون.',
          recommendedQuantity: boostedPrediction,
          confidence: 0.85,
        );
      }
    }

    if (isSummer) {
      if (name.contains('ماء') ||
          name.contains('water') ||
          name.contains('عصير') ||
          name.contains('juice') ||
          name.contains('ايس') ||
          name.contains('ice')) {
        final basePrediction = _calculateBasePrediction(product);
        final boostedPrediction = (basePrediction * 1.4).round();

        return PredictionInsight(
          product: product,
          type: 'SEASONAL',
          message: '☀️ موسم الصيف! يزداد استهلاك المشروبات والمرطبات.',
          recommendedQuantity: boostedPrediction,
          confidence: 0.85,
        );
      }
    }

    if (isRamadan) {
      if (name.contains('شوربة') ||
          name.contains('soup') ||
          name.contains('فيمتو') ||
          name.contains('vimto')) {
        return PredictionInsight(
          product: product,
          type: 'SEASONAL',
          message:
              '🌙 استعداداً لشهر رمضان، يتوقع طلب عالي جداً على هذا المنتج.',
          recommendedQuantity: (_calculateBasePrediction(product) * 2).round(),
          confidence: 0.9,
        );
      }
    }

    if (product.mainPrice < 5.0 && product.totalQuantity < 20) {
      return PredictionInsight(
        product: product,
        type: 'RESTOCK',
        message:
            '💡 منتج رخيص وسريع الحركة ومخزونه منخفض. يفضل طلب كمية كبيرة (توفير في الشحن).',
        recommendedQuantity: 100,
        confidence: 0.7,
      );
    }

    return null;
  }

  /// حساب التوقع الأساسي (Base Prediction)
  int _calculateBasePrediction(Product product) {
    if (product.totalQuantity == 0) return 20;
    return (product.totalQuantity * 0.5).round() + 5;
  }

  double _getSeasonalityFactor(Product product) {
    final now = DateTime.now();
    final month = now.month;
    bool isWinter = month == 12 || month == 1 || month == 2;
    if (isWinter &&
        (product.name.contains('حليب') || product.name.contains('شاي'))) {
      return 1.5;
    }
    return 1.0;
  }

  void dispose() {}
}
