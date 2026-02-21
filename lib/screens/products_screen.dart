import 'package:flutter/material.dart'; // استيراد فلاتر للواجهات
import 'package:makhzani_app/models/product.dart'; // نموذج المنتج
import 'package:makhzani_app/screens/product_details_screen.dart'; // شاشة تفاصيل المنتج
import 'package:makhzani_app/screens/add_product_screen.dart'; // شاشة إضافة منتج
import 'package:makhzani_app/services/product_service.dart'; // خدمة إدارة المنتجات (قواعد البيانات)

// شاشة عرض قائمة المنتجات (المخزون)
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // قائمة المنتجات الأصلية (كل المنتجات المحملة من قاعدة البيانات)
  List<Product> _allProducts = [];
  // قائمة المنتجات المعروضة حالياً (تتغير عند البحث)
  List<Product> _foundProducts = [];
  bool _isLoading = true; // حالة التحميل

  @override
  void initState() {
    super.initState();
    _loadProducts(); // تحميل البيانات فور فتح الشاشة
  }

  // --- دالة تحميل المنتجات من قاعدة البيانات ---
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true); // بدء التحميل
    try {
      final productService = ProductService();
      // جلب جميع المنتجات
      final products = await productService.getAllProducts();

      if (mounted) {
        setState(() {
          _allProducts = products; // حفظ النسخة الأصلية
          _foundProducts = products; // عرض الكل في البداية
          _isLoading = false; // انتهاء التحميل
        });
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- دالة البحث والتصفية ---
  // تستدعى عند تغيير النص في حقل البحث
  void _runFilter(String enteredKeyword) {
    List<Product> results = [];
    if (enteredKeyword.isEmpty) {
      // إذا كان البحث فارغاً، نعرض كل المنتجات
      results = _allProducts;
    } else {
      // تصفية القائمة بناءً على اسم المنتج (تجاهل حالة الأحرف LowerCase)
      results = _allProducts
          .where(
            (product) => product.name.toLowerCase().contains(
                  enteredKeyword.toLowerCase(),
                ),
          )
          .toList();
    }
    // تحديث الواجهة بالنتائج الجديدة
    setState(() {
      _foundProducts = results;
    });
  }

  // بناء واجهة المستخدم
  @override
  Widget build(BuildContext context) {
    // الحصول على ألوان الثيم الحالي للاتساق
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50], // لون خلفية للصفحة (رمادي فاتح جداً)
      appBar: AppBar(
        title: const Text('المخزون'), // عنوان الصفحة
        centerTitle: true,
        backgroundColor: colorScheme.primary, // لون كحلي
        foregroundColor: colorScheme.onPrimary, // نص أبيض
        elevation: 0, // إزالة الظل
        actions: [
          // زر تحديث يدوي
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts, // إعادة تحميل البيانات
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. شريط البحث ---
            TextField(
              onChanged: (value) =>
                  _runFilter(value), // تشغيل الفلتر عند الكتابة
              decoration: InputDecoration(
                labelText: 'بحث عن منتج...',
                // أيقونة البحث بلون التطبيق الأساسي
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: Icon(Icons.filter_list, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // بدون حدود ظاهرة
                ),
                filled: true, // تفعيل لون التعبئة
                fillColor: Colors.white, // لون التعبئة أبيض
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- 2. عرض القائمة ---
            Expanded(
              // ليأخذ المساحة المتبقية من الشاشة
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator()) // دائرة تحميل
                  : _foundProducts.isNotEmpty
                      // RefreshIndicator يسمح بالسحب للأسفل للتحديث (Pull-to-Refresh)
                      ? RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: ListView.builder(
                            itemCount: _foundProducts.length,
                            itemBuilder: (context, index) {
                              final product = _foundProducts[index];
                              final int quantity = product.totalQuantity;
                              // تحديد هل المخزون منخفض؟
                              final bool isLowStock =
                                  quantity < product.minStockLevel;

                              // Dismissible: يتيح سحب العنصر للحذف
                              return Dismissible(
                                key: Key(product.id.toString()), // مفتاح فريد
                                // الخلفية التي تظهر عند السحب (حمراء مع أيقونة سلة مهملات)
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                direction: DismissDirection
                                    .endToStart, // السحب لليسار فقط
                                // الحوار التأكيدي قبل الحذف
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('حذف المنتج'),
                                      content: Text(
                                        'هل أنت متأكد من حذف "${product.name}"؟',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx)
                                              .pop(false), // إلغاء
                                          child: const Text('إلغاء'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx)
                                              .pop(true), // تأكيد
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('حذف'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                // تنفيذ الحذف الفعلي بعد التأكيد
                                onDismissed: (direction) async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  // حذف من قاعدة البيانات
                                  await ProductService()
                                      .deleteProduct(product.id!);
                                  // عرض رسالة نجاح
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('تم حذف ${product.name}'),
                                      ),
                                    );
                                  }
                                  _loadProducts(); // تحديث القائمة
                                },
                                // البطاقة المعروضة في القائمة
                                child: Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 2, // ظل خفيف
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    // أيقونة دائرية بها الحرف الأول من الاسم
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      child: Text(
                                        product.name.isNotEmpty
                                            ? product.name[0]
                                            : '?',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // اسم المنتج
                                    title: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // سعر البيع الأساسي
                                    subtitle: Text(
                                      '${product.mainPrice} ر.ي',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    // الكمية على اليسار
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '$quantity',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                // تلوين باللون الأحمر إذا كانت الكمية منخفضة
                                                color: isLowStock
                                                    ? Colors.red
                                                    : Colors.black,
                                              ),
                                            ),
                                            // عرض أيقونة تحذير صغيرة إذا المخزون منخفض
                                            if (isLowStock) ...[
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                            ],
                                          ],
                                        ),
                                        const Text(
                                          'قطعة',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // عند الضغط على العنصر، نذهب للتفاصيل
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductDetailsScreen(
                                            product: product,
                                          ),
                                        ),
                                      );
                                      // عند العودة، نحدث القائمة لاحتمالية تغيير البيانات
                                      _loadProducts();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Text(
                            'لا توجد منتجات', // حالة القائمة الفارغة
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
            ),
          ],
        ),
      ),
      // --- زر الدائرة العائم للإضافة ---
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // الانتقال لشاشة إضافة منتج جديد
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );

          // إذا تم إضافة منتج (عاد بـ true) نحدث القائمة
          if (result == true) {
            _loadProducts();
          }
        },
        backgroundColor: colorScheme.secondary, // لون برتقالي مميز للزر
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
