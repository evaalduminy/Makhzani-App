import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية لبناء واجهة المستخدم (Widgets)
import 'package:flutter/services.dart'; // للتحكم في مدخلات المستخدم ومنع الرموز غير المرغوبة
import 'package:makhzani_app/models/product.dart'; // استيراد نموذج بيانات المنتج (لإنشاء كائن منتج جديد)
import 'package:makhzani_app/models/product_detail_model.dart'; // استيراد نموذج تفاصيل المنتج (لإدارة الدفعات وتواريخ الصلاحية)
import 'package:makhzani_app/models/product_unit_model.dart'; // استيراد نموذج وحدات المنتج (لإدارة وحدات البيع كالقطعة والكرتون)
import 'dart:io'; // للتعامل مع ملفات الصور
import 'package:image_picker/image_picker.dart'; // لاختيار الصور من المعرض أو الكاميرا
import 'package:mobile_scanner/mobile_scanner.dart'; // ماسح الباركود الحديث
import 'package:makhzani_app/services/product_service.dart'; // استيراد خدمة المنتجات للتعامل مع قاعدة البيانات (حفظ المنتج)

// تعريف الشاشة كـ StatefulWidget لأنها تحتوي على بيانات تتغير (مثل النصوص المدخلة، التاريخ، حالة التحميل)
class AddProductScreen extends StatefulWidget {
  const AddProductScreen(
      {super.key}); // البناء الأساسي للكلاس، يقبل مفتاح تعريف (Key) اختياري

  @override
  State<AddProductScreen> createState() =>
      _AddProductScreenState(); // إنشاء حالة الشاشة (State) التي تحتوي على المنطق
}

// كلاس الحالة (State) الذي يحتوي على المتغيرات والمنطق الخاص بالشاشة
class _AddProductScreenState extends State<AddProductScreen> {
  // مفتاح فريد لنموذج الإدخال (Form) للتحقق من صحة البيانات (Validation)
  final _formKey = GlobalKey<FormState>();

  // إنشاء نسخة من خدمة المنتجات لاستدعاء دالة الحفظ لاحقاً
  final _productService = ProductService();

  // متغير لتحديد حالة التحميل (يظهر مؤشر تحميل عند الحفظ لمنع تكرار الضغط)
  bool _isLoading = false;

  // --- متغيرات الصور ---
  File? _imageFile; // لتخزين ملف الصورة المختار
  final ImagePicker _picker = ImagePicker(); // كائن التقاط الصور

  // --- تعريف متحكمات النصوص (Controllers) لحفظ المدخلات من الحقول ---

  // متحكم لاسم المنتج
  final _nameController = TextEditingController();
  // متحكم للباركود
  final _barcodeController = TextEditingController();
  // متحكم للوصف
  final _descriptionController = TextEditingController();

  // المتغير الذي يحمل القيمة المختارة من قائمة التصنيفات (الافتراضي: 'عام')
  String _selectedCategory = 'عام';

  // --- معلومات الدفعة الأولية (Initial Batch) ---
  // متحكم للكمية الأولية
  final _quantityController = TextEditingController();
  // متحكم لسعر الشراء (التكلفة)
  final _purchasePriceController = TextEditingController();
  // متغير لتخزين تاريخ انتهاء الصلاحية (يمكن أن يكون فارغاً null للمنتجات التي لا تنتهي)
  DateTime? _expiryDate;

  // --- معلومات البيع ---
  // متحكم لسعر البيع
  final _sellingPriceController = TextEditingController();

  // قائمة أسماء التصنيفات المتاحة للعرض في القائمة المنسدلة (Dropdown)
  final List<String> _categories = [
    'عام',
    'مواد غذائية',
    'مشروبات',
    'ألبان',
    'معلبات',
    'منظفات',
    'أخرى',
  ];

  // دالة تُستدعى عند إغلاق الشاشة لتنظيف الذاكرة (إغلاق المتحكمات)
  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  // دالة لإظهار نافذة اختيار التاريخ (Date Picker) عند الضغط على حقل التاريخ
  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, // سياق الشاشة الحالي
      initialDate: DateTime.now().add(
          const Duration(days: 30)), // التاريخ الافتراضي (بعد 30 يوم من الآن)
      firstDate: DateTime.now(), // أقل تاريخ مسموح (اليوم)
      lastDate: DateTime.now()
          .add(const Duration(days: 365 * 5)), // أقصى تاريخ مسموح (بعد 5 سنوات)
    );
    // إذا قام المستخدم باختيار تاريخ (ولم يضغط إلغاء) وكان مختلفاً عن الحالي
    if (picked != null && picked != _expiryDate) {
      setState(() {
        // تحديث الواجهة لعرض التاريخ الجديد
        _expiryDate = picked;
      });
    }
  }

  // --- دالة مسح الباركود بالكاميرا ---
  Future<void> _scanBarcode() async {
    try {
      // فتح شاشة المسح
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('مسح الباركود'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            body: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first;
                  if (barcode.rawValue != null) {
                    Navigator.pop(context, barcode.rawValue);
                  }
                }
              },
            ),
          ),
        ),
      );

      // إذا تم مسح باركود، ضعه في الحقل
      if (result != null && mounted) {
        setState(() {
          _barcodeController.text = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في تشغيل الماسح الضوئي: $e')),
        );
      }
    }
  }

  // --- دالة اختيار صورة ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600, // تقليل حجم الصورة لتوفير المساحة
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // --- نافذة اختيار مصدر الصورة ---
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'إضافة صورة للمنتج',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // زر الكاميرا
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                  child: const Column(
                    children: [
                      Icon(Icons.camera_alt, size: 50, color: Colors.blue),
                      Text('الكاميرا'),
                    ],
                  ),
                ),
                // زر المعرض
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                  child: const Column(
                    children: [
                      Icon(Icons.photo_library, size: 50, color: Colors.purple),
                      Text('المعرض'), // المعرض
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // الدالة الرئيسية لحفظ المنتج في قاعدة البيانات
  Future<void> _saveProduct() async {
    // التحقق من صحة المدخلات (هل الحقول المطلوبة ممتلئة؟)
    if (!_formKey.currentState!.validate()) return; // إذا كانت غير صالحة، توقف

    setState(
        () => _isLoading = true); // بدء حالة التحميل (إظهار الدائرة الدوارة)

    try {
      // 1. تحويل اسم التصنيف المختار إلى رقم معرّف (ID) ليتم حفظه في قاعدة البيانات
      int catId = 1; // الافتراضي: عام
      switch (_selectedCategory) {
        case 'مواد غذائية':
          catId = 2;
          break;
        case 'مشروبات':
          catId = 3;
          break;
        case 'ألبان':
          catId = 4;
          break;
        case 'معلبات':
          catId = 5;
          break;
        case 'منظفات':
          catId = 6;
          break;
        case 'أخرى':
          catId = 7;
          break;
      }

      // 2. إنشاء كائن المنتج (Product Object) بالبيانات الأساسية
      final product = Product(
        name: _nameController.text, // الاسم من الحقل
        categoryId: catId, // رقم التصنيف
        barcode: _barcodeController.text.isEmpty
            ? null
            : _barcodeController.text, // الباركود (أو null إذا فارغ)
        description: _descriptionController.text, // الوصف
        minStockLevel: 5, // حد الطلب الافتراضي (يمكن تغييره لاحقاً)
        imagePath: _imageFile?.path, // مسار الصورة (إذا وجدت)
      );

      // إنشاء كائن تفاصيل المنتج (الدفعة الأولى) إذا أدخل المستخدم كمية
      ProductDetail? initialBatch;
      if (_quantityController.text.isNotEmpty) {
        initialBatch = ProductDetail(
          productId: 0, // سيتم تعيينه تلقائياً بواسطة الخدمة بعد إنشاء المنتج
          expiryDate: _expiryDate, // تاريخ الانتهاء المختار
          quantity:
              int.parse(_quantityController.text), // تحويل النص إلى رقم صحيح
          purchasePrice: _purchasePriceController.text.isNotEmpty
              ? double.parse(
                  _purchasePriceController.text) // تحويل النص إلى رقم عشري
              : 0.0, // صفر إذا لم يدخل المستخدم سعر شراء
        );
      }

      // إنشاء كائن وحدة المنتج (الوحدة الأساسية) إذا أدخل المستخدم سعر بيع
      ProductUnit? initialUnit;
      if (_sellingPriceController.text.isNotEmpty) {
        initialUnit = ProductUnit(
          productId: 0, // سيتم تعيينه تلقائياً
          unitName: 'حبة', // اسم الوحدة الافتراضي
          conversionFactor: 1, // معامل التحويل (1 للوحدة الأساسية)
          salePrice: double.parse(_sellingPriceController.text), // سعر البيع
          isBaseUnit: true, // تحديد أن هذه هي الوحدة الأساسية
        );
      }

      // 3. استدعاء الخدمة لحفظ المنتج مع الدفعة والوحدة في عملية واحدة
      final success = await _productService.createFullProduct(
        product: product,
        initialBatch: initialBatch,
        initialUnit: initialUnit,
      );

      if (!success) {
        throw Exception(
            'فشل في حفظ المنتج'); // إذا عادت الخدمة بـ false نرفع خطأ
      }

      // إذا نجحت العملية والواجهة لا تزال معروضة
      if (mounted) {
        // عرض رسالة نجاح أسفل الشاشة (SnackBar)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إضافة المنتج بنجاح')));
        // إغلاق الشاشة والعودة للقائمة السابقة مع إرسال القيمة true لتحديث القائمة
        Navigator.pop(context, true);
      }
    } catch (e) {
      // في حالة حدوث خطأ
      debugPrint('Error saving product: $e'); // طباعة الخطأ في الكونسول للمبرمج
      if (mounted) {
        // عرض رسالة خطأ للمستخدم باللون الأحمر
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // في النهاية (سواء نجح أو فشل)، نوقف حالة التحميل
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- دالة بناء الواجهة الرسومية (UI) ---
  @override
  Widget build(BuildContext context) {
    // الوصول لبيانات الثيم (الألوان والخطوط) الحالية في التطبيق
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // الشريط العلوي (App Bar)
      appBar: AppBar(
        title: const Text('إضافة منتج جديد'), // عنوان الشاشة
        backgroundColor: colorScheme.primary, // لون الخلفية (الأساسي)
        foregroundColor:
            colorScheme.onPrimary, // لون النص والأيقونات (المعاكس للأساسي)
      ),
      // جسم الشاشة (Body)
      body: Form(
        // تغليف المحتوى بـ Form للتحقق من المدخلات
        key: _formKey, // ربط المفتاح للتحقق
        child: SingleChildScrollView(
          // لجعل الشاشة قابلة للتمرير في حالة كانت العناصر كثيرة
          padding:
              const EdgeInsets.all(16), // مسافة داخلية (Padding) من جميع الجهات
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .start, // محاذاة العناصر للبداية (اليمين في العربية)
            children: [
              // --- قسم المعلومات الأساسية ---
              _buildSectionTitle('معلومات المنتج الأساسية'), // عنوان فرعي مخصص
              const SizedBox(height: 16), // مسافة فارغة رأسية

              // --- منطقة اختيار الصورة ---
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'صورة',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // حقل إدخال اسم المنتج
              TextFormField(
                controller: _nameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(
                      r'[a-zA-Z\s\u0621-\u064A\u0671-\u06D3\u06FB-\u06FE]')),
                  FilteringTextInputFormatter.deny(
                      RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم المنتج';
                  }
                  if (RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]')
                      .hasMatch(value)) {
                    return 'اسم المنتج يجب أن يحتوي على حروف فقط';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // قائمة منسدلة لاختيار التصنيف
              DropdownButtonFormField<String>(
                value: _selectedCategory, // القيمة الحالية المختارة
                decoration: const InputDecoration(
                  labelText: 'التصنيف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                // تحويل قائمة الأسماء إلى عناصر قائمة منسدلة (DropdownMenuItem)
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                // عند تغيير الاختيار، نحدث القيمة في المتغير
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // حقل إدخال الباركود (اختياري)
              TextFormField(
                controller: _barcodeController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'الباركود (اختياري)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.red),
                    onPressed: _scanBarcode,
                    tooltip: 'مسح الباركود بالكاميرا',
                  ),
                ),
                keyboardType: TextInputType.visiblePassword,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(
                      RegExp(r'[\u0600-\u06FF]')), // منع العربية تماماً
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
                      return 'الباركود لا يقبل الحروف العربية';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- قسم المخزون والسعر ---
              _buildSectionTitle('المخزون والسعر (الدفعة الأولى)'),
              const SizedBox(height: 16),

              // صف (Row) ليحتوي على حقلين بجانب بعضهما
              Row(
                children: [
                  // Expanded لجعل الحقل يأخذ المساحة المتاحة بالتساوي
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'الكمية *',
                        hintText: 'مثال: 10',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      // لوحة مفاتيح رقمية فقط (بدون كسور)
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: false),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 16), // مسافة افقية بين الحقلين

                  // حقل سعر البيع
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'سعر البيع *',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        suffixText: 'ر.ي', // نص ثابت يظهر كلاحقة (العملة)
                      ),
                      // لوحة مفاتيح رقمية مع كسور عشرية
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // صف آخر لسعر الشراء وتاريخ الانتهاء
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(
                        labelText: 'سعر الشراء (التكلفة)',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money_off),
                        suffixText: 'ر.ي',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // حقل تاريخ الانتهاء (قابل للضغط لفتح التقويم)
                  Expanded(
                    child: InkWell(
                      // InkWell يضيف تأثير التموج عند الضغط
                      onTap: _selectExpiryDate, // استدعاء دالة اختيار التاريخ
                      child: InputDecorator(
                        // InputDecorator ليعطي الشكل مثل حقول الإدخال الأخرى
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الانتهاء',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          // عرض نص "اختياري" أو التاريخ المنسق إذا تم اختياره
                          _expiryDate == null
                              ? 'اختياري'
                              : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- زر الحفظ ---
              SizedBox(
                width: double.infinity, // عرض كامل
                height: 50, // ارتفاع محدد للزر
                child: ElevatedButton(
                  // إذا كان جاري التحميل، نعطل الزر (null)، وإلا ننفذ الحفظ
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary, // لون الخلفية
                    foregroundColor: colorScheme.onPrimary, // لون النص
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // حواف دائرية
                    ),
                  ),
                  // عرض مبدل: إما دائرة تحميل أو نص "حفظ المنتج"
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'حفظ المنتج',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة صغيرة لبناء عناوين الأقسام بشكل موحد وتكرار أقل للكود
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context)
                .colorScheme
                .primary, // استخدام اللون الأساسي من الثيم
          ),
        ),
        const Divider(), // خط فاصل أفقي
      ],
    );
  }
}
