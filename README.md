# 📦 تطبيق مخزني (Makhzani App)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TensorFlow-%23FF6F00.svg?style=for-the-badge&logo=TensorFlow&logoColor=white)

**نظام إدارة مخزون ذكي متكامل يعتمد على تقنيات الذكاء الاصطناعي لتحسين كفاءة العمليات التجارية.**

---

## 🌟 المميزات الرئيسية (Core Features)

### 1. 🧪 التنبؤ الذكي بالطلب (AI Demand Prediction)

يستخدم التطبيق محرك ذكاء اصطناعي هجين (Hybrid AI) يعتمد على:

- **تحليل السلوك:** التنبؤ بالكميات المطلوبة بناءً على السعر، اليوم، والشهر.
- **خوارزمية هجينة:** دمج مخرجات **TensorFlow Lite** مع البيانات التاريخية للمبيعات (70% AI / 30% Historical) لضمان دقة عالية وتجاوز مشكلة "البداية الباردة" للمنتجات الجديدة.

### 2. 📊 إدارة المخزون المتقدمة

- متابعة المنتجات، الفئات، والموردين.
- نظام تنبيهات للمخزون المنخفض والمنتجات منتهية الصلاحية.
- دعم كامل لماسح الباركود (Barcode Scanner) لإضافة وبيع المنتجات بسرعة.

### 3. 💸 الإدارة المالية والتقارير

- حساب الأرباح والخسائر بشكل تلقائي.
- توليد تقارير احترافية بصيغة **PDF**.
- تصدير البيانات والبيانات المالية إلى ملفات **Excel**.
- لوحة بيانات (Dashboard) توضح حركة المبيعات وتوقعات النمو.

### 4. 📱 تجربة مستخدم عصرية

- دعم كامل للغتين العربية والإنجليزية (مع واجهة RTL).
- وضع ليلي (Dark Mode) ووضع نهاري (Light Mode) مريح للعين.
- واجهات سريعة وسلسة مبنية باستخدام Flutter.

---

## 🛠 التكنولوجيا المستخدمة (Tech Stack)

- **Frontend:** Flutter (Dart)
- **Database:** SQLite (Local Persistence)
- **AI/ML:** TensorFlow Lite (TFLite) & Scikit-learn (للتدريب)
- **State Management:** Provider
- **Reporting:** PDF & Printing library + Excel package
- **Integration:** Mobile Scanner (Barcode reading)

---

## 🚀 بدء التشغيل (Getting Started)

### المتطلبات الأساسية

- Flutter SDK (>=3.0.0)
- Python (لتدريب الموديل - اختياري)

### الخطوات

1. قم بتحميل المستودع:
   ```bash
   git clone https://github.com/YOUR_USERNAME/makhzani_app.git
   ```
2. تثبيت المكتبات:
   ```bash
   flutter pub get
   ```
3. (اختياري) تدريب موديل الذكاء الاصطناعي:
   ```bash
   pip install tensorflow numpy pandas scikit-learn
   python train_demand_model.py
   ```
4. تشغيل التطبيق:
   ```bash
   flutter run
   ```

---

## 📂 هيكلية المشروع (Project Structure)

- `lib/services/demand_predictor.dart`: إدارة عمليات التنبؤ والموديل.
- `lib/services/database_helper.dart`: المحرك الأساسي لقاعدة البيانات المحلية.
- `lib/screens/`: تحتوي على جميع واجهات المستخدم (المخزون، البيع، التقارير).
- `train_demand_model.py`: سكريبت Python لتدريب الشبكة العصبية وتحويلها إلى TFLite.

---

## 👤 المطور

تم تطوير هذا المشروع كنموذج لنظام إدارة ذكي يجمع بين سهولة الاستخدام وقوة تحليل البيانات.

---

## 📜 الترخيص

هذا المشروع متاح للاستخدام التعليمي والتطوير البرمجي.
