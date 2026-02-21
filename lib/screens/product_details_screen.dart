import 'package:flutter/material.dart';
import 'package:makhzani_app/services/smart_prediction_service.dart';
import 'package:makhzani_app/models/product.dart';
import 'package:makhzani_app/services/product_service.dart';
import 'package:makhzani_app/screens/edit_product_screen.dart';

/// شاشة تفاصيل المنتج مع تحليل الذكاء الاصطناعي المتقدم
/// تعرض معلومات المنتج + التنبؤ الذكي باستخدام خوارزمية هجينة
class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  // متغيرات الحالة للذكاء الاصطناعي
  int? predictedQuantity; // الكمية المتوقعة من الموديل
  bool isLoadingPrediction = true; // حالة التحميل
  SmartPredictionService? _smartPredictor; // نسخة من خدمة التنبؤ الذكية

  // المنتج الحالي (قابل للتحديث)
  late Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _getPrediction(); // بدء التنبؤ عند فتح الشاشة
  }

  /// دالة الحصول على التنبؤ الذكي من الخدمة المتقدمة
  Future<void> _getPrediction() async {
    try {
      // 1. إنشاء نسخة من خدمة التنبؤ الذكية
      _smartPredictor = SmartPredictionService();

      // 2. استدعاء التنبؤ الذكي
      // نمرر كائن المنتج مباشرة
      final prediction = await _smartPredictor!.getPrediction(_product);

      // 4. تحديث الواجهة بالنتيجة
      if (mounted) {
        setState(() {
          predictedQuantity = prediction;
          isLoadingPrediction = false;
        });
      }
    } catch (e) {
      // في حالة الخطأ، نعرض قيمة افتراضية
      debugPrint('خطأ في التنبؤ: $e');
      if (mounted) {
        setState(() {
          predictedQuantity = null;
          isLoadingPrediction = false;
        });
      }
    }
  }

  Future<void> _reloadProduct() async {
    final productService = ProductService();
    // نحتاج دالة لجلب منتج واحد في ProductService، حالياً سنستخدم البحث كحل مؤقت
    // أو نضيف دالة getProductById في الخدمة.
    // الحل الأفضل: إضافة getProductById في ProductService.
    // بما أننا لم نضيفها بعد، سنضيفها الآن.
    final updatedProduct = await productService.getProductById(_product.id!);
    if (updatedProduct != null && mounted) {
      setState(() {
        _product = updatedProduct;
      });
    }
  }

  @override
  void dispose() {
    // تحرير الذاكرة عند إغلاق الشاشة
    _smartPredictor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // استخراج بيانات المنتج مباشرة من الكائن
    final String name = _product.name;
    final double price = _product.mainPrice;
    final int quantity = _product.totalQuantity;
    final String category = _getCategoryName(_product.categoryId);
    final bool isLowStock = quantity < _product.minStockLevel;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductScreen(product: _product),
                ),
              );

              if (result == true) {
                await _reloadProduct();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('حذف المنتج'),
                  content: Text('هل أنت متأكد من حذف "${_product.name}"؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // ignore: use_build_context_synchronously
                final success =
                    await ProductService().deleteProduct(_product.id!);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم حذف ${_product.name}')),
                    );
                    Navigator.of(context).pop(); // العودة للشاشة السابقة
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('فشل حذف المنتج'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- رأس الشاشة (Header) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // أيقونة المنتج
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // اسم المنتج
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // الفئة
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- بطاقة المعلومات الأساسية ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المعلومات الأساسية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.attach_money,
                        label: 'السعر',
                        value: '$price ر.ي',
                        color: Colors.green,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.inventory_2,
                        label: 'الكمية المتوفرة',
                        value: '$quantity قطعة',
                        color: isLowStock ? Colors.red : Colors.blue,
                      ),
                      if (isLowStock) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'تنبيه: المخزون منخفض جداً!',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- بطاقة تحليل الذكاء الاصطناعي ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: colorScheme.secondary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'تحليل الذكاء الاصطناعي',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // عرض حالة التحميل أو النتيجة
                      if (isLoadingPrediction)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text(
                                  'جاري التحليل...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (predictedQuantity != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: predictedQuantity! > 20
                                  ? [
                                      Colors.green.shade50,
                                      Colors.green.shade100,
                                    ]
                                  : [
                                      Colors.orange.shade50,
                                      Colors.orange.shade100,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                predictedQuantity! > 20
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: predictedQuantity! > 20
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'الطلب المتوقع',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$predictedQuantity قطعة',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: predictedQuantity! > 20
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.grey),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'لم يتم التمكن من التنبؤ. تأكد من وجود ملفات الموديل.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),

                      // معلومات إضافية
                      Text(
                        'ℹ️ التنبؤ الذكي يجمع بين الذكاء الاصطناعي والبيانات التاريخية',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(int? id) {
    switch (id) {
      case 2:
        return 'مواد غذائية';
      case 3:
        return 'مشروبات';
      case 4:
        return 'ألبان';
      case 5:
        return 'معلبات';
      case 6:
        return 'منظفات';
      case 7:
        return 'أخرى';
      default:
        return 'عام';
    }
  }

  /// ويدجت مساعد لعرض صف معلومات
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
