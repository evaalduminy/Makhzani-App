/// نموذج بيانات سجل توقعات الذكاء الاصطناعي
/// يُستخدم لمراقبة دقة التوقعات ومقارنتها بالمبيعات الفعلية
class PredictionHistory {
  final int? id; // معرّف السجل
  final int productId; // معرّف المنتج
  final DateTime predictionDate; // تاريخ التوقع
  final double predictedValue; // القيمة المتوقعة (الكمية المتوقع بيعها)
  final double? actualValue; // القيمة الفعلية (الكمية المباعة فعلياً)
  final double? accuracyRate; // نسبة الدقة (%)

  PredictionHistory({
    this.id,
    required this.productId,
    required this.predictionDate,
    required this.predictedValue,
    this.actualValue,
    this.accuracyRate,
  });

  /// تحويل من Map (قادم من قاعدة البيانات)
  factory PredictionHistory.fromMap(Map<String, dynamic> map) {
    return PredictionHistory(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      predictionDate: DateTime.parse(map['prediction_date'] as String),
      predictedValue: (map['predicted_value'] as num).toDouble(),
      actualValue: (map['actual_value'] as num?)?.toDouble(),
      accuracyRate: (map['accuracy_rate'] as num?)?.toDouble(),
    );
  }

  /// تحويل إلى Map (للحفظ في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'prediction_date': predictionDate.toIso8601String(),
      'predicted_value': predictedValue,
      'actual_value': actualValue,
      'accuracy_rate': accuracyRate,
    };
  }

  /// نسخ الكائن مع تعديل بعض الحقول
  PredictionHistory copyWith({
    int? id,
    int? productId,
    DateTime? predictionDate,
    double? predictedValue,
    double? actualValue,
    double? accuracyRate,
  }) {
    return PredictionHistory(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      predictionDate: predictionDate ?? this.predictionDate,
      predictedValue: predictedValue ?? this.predictedValue,
      actualValue: actualValue ?? this.actualValue,
      accuracyRate: accuracyRate ?? this.accuracyRate,
    );
  }

  /// حساب نسبة الدقة تلقائياً
  /// الدقة = 100 - (|الفرق| / القيمة المتوقعة * 100)
  double? calculateAccuracy() {
    if (actualValue == null || predictedValue == 0) return null;

    final difference = (predictedValue - actualValue!).abs();
    final accuracy = 100 - (difference / predictedValue * 100);

    // التأكد من أن الدقة بين 0 و 100
    return accuracy.clamp(0.0, 100.0);
  }

  /// هل التوقع كان دقيقاً؟ (دقة أكثر من 80%)
  bool get isAccurate {
    final accuracy = accuracyRate ?? calculateAccuracy();
    if (accuracy == null) return false;
    return accuracy >= 80.0;
  }

  @override
  String toString() =>
      'PredictionHistory(id: $id, productId: $productId, predicted: $predictedValue, actual: $actualValue, accuracy: $accuracyRate%)';
}
