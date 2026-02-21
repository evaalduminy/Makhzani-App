"""
سكريبت تدريب نموذج التنبؤ بالطلب
يقوم بإنشاء موديل TensorFlow Lite للاستخدام في تطبيق Flutter
"""

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.preprocessing import StandardScaler
import json
import os

print("🚀 بدء تدريب نموذج التنبؤ بالطلب...")

# 1. إنشاء بيانات تدريب وهمية (يمكن استبدالها ببيانات حقيقية)
np.random.seed(42)
print("📊 إنشاء بيانات التدريب...")

# محاكاة 500 عملية بيع
data = {
    'price': np.random.randint(500, 25000, 500),        # السعر: 500-25000 ريال
    'day_of_week': np.random.randint(1, 8, 500),        # يوم الأسبوع: 1-7
    'month': np.random.randint(1, 13, 500),             # الشهر: 1-12
    'quantity': np.random.randint(5, 150, 500)          # الكمية: 5-150 قطعة
}
df = pd.DataFrame(data)

print(f"✅ تم إنشاء {len(df)} سجل تدريب")

# 2. فصل المدخلات (X) والمخرجات (y)
X = df[['price', 'day_of_week', 'month']].values
y = df['quantity'].values

# 3. التطبيع (Normalization)
print("🔄 تطبيع البيانات...")
scaler_X = StandardScaler()
scaler_y = StandardScaler()

X_scaled = scaler_X.fit_transform(X)
y_scaled = scaler_y.fit_transform(y.reshape(-1, 1))

# 4. بناء الشبكة العصبية
print("🧠 بناء الشبكة العصبية...")
model = tf.keras.Sequential([
    tf.keras.layers.Dense(16, activation='relu', input_shape=(3,)),
    tf.keras.layers.Dense(8, activation='relu'),
    tf.keras.layers.Dense(1)
])

model.compile(
    optimizer='adam',
    loss='mse',
    metrics=['mae']
)

print("📚 بدء التدريب...")
history = model.fit(
    X_scaled, 
    y_scaled, 
    epochs=50, 
    batch_size=32, 
    validation_split=0.2,
    verbose=1
)

# 5. تقييم الموديل
print("\n📈 تقييم الموديل...")
loss, mae = model.evaluate(X_scaled, y_scaled, verbose=0)
print(f"✅ MAE (متوسط الخطأ المطلق): {mae:.4f}")
print(f"✅ Loss: {loss:.4f}")

# 6. حفظ الموديل بصيغة TFLite
print("\n💾 تحويل الموديل إلى TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# إنشاء المجلد إذا لم يكن موجوداً
os.makedirs('assets/ml', exist_ok=True)

# حفظ الموديل
with open('assets/ml/demand_model.tflite', 'wb') as f:
    f.write(tflite_model)

model_size = len(tflite_model) / 1024  # بالكيلوبايت
print(f"✅ تم حفظ الموديل: assets/ml/demand_model.tflite ({model_size:.2f} KB)")

# 7. حفظ معاملات التطبيع
print("💾 حفظ معاملات التطبيع...")
scaler_params = {
    'price_mean': float(scaler_X.mean_[0]),
    'price_std': float(scaler_X.scale_[0]),
    'day_mean': float(scaler_X.mean_[1]),
    'day_std': float(scaler_X.scale_[1]),
    'month_mean': float(scaler_X.mean_[2]),
    'month_std': float(scaler_X.scale_[2]),
    'quantity_mean': float(scaler_y.mean_[0]),
    'quantity_std': float(scaler_y.scale_[0])
}

with open('assets/ml/scaler_params.json', 'w', encoding='utf-8') as f:
    json.dump(scaler_params, f, indent=2, ensure_ascii=False)

print("✅ تم حفظ المعاملات: assets/ml/scaler_params.json")

# 8. اختبار التنبؤ
print("\n🧪 اختبار التنبؤ...")
test_input = np.array([[5000, 3, 6]])  # سعر 5000، يوم الأربعاء، شهر يونيو
test_scaled = scaler_X.transform(test_input)
prediction_scaled = model.predict(test_scaled, verbose=0)
prediction = scaler_y.inverse_transform(prediction_scaled)

print(f"📊 مثال: منتج بسعر 5000 ريال → الطلب المتوقع: {int(prediction[0][0])} قطعة")

print("\n" + "="*60)
print("🎉 تم إنشاء الموديل بنجاح!")
print("="*60)
print("\n📋 الخطوات التالية:")
print("1. تأكد من وجود الملفات في assets/ml/")
print("2. شغّل: flutter clean")
print("3. شغّل: flutter pub get")
print("4. شغّل: flutter run")
print("\n✨ استمتع بالتنبؤات الذكية في تطبيقك!")
