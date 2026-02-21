import 'package:flutter/material.dart';
import 'package:makhzani_app/utils/app_colors.dart';
import 'package:makhzani_app/services/smart_prediction_service.dart';
import 'package:makhzani_app/models/product.dart';
import 'package:makhzani_app/models/product_detail_model.dart';
import 'package:makhzani_app/models/product_unit_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex hide Border, TextSpan;
import 'dart:typed_data';

// شاشة التقارير: شاشة تفاعلية تعرض ملخصات ورسوم بيانية وتسمح بطباعة تقرير PDF
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  // استخدام Mixin لدعم الحركات (الأنيميشن) في التبويبات (Tabs)

  // متحكم التبويبات للتحويل بين (الملخص، الأكثر مبيعاً، التنبيهات)
  late TabController _tabController;

  // الفترة الزمنية المختارة للمخطط البياني (الافتراضي: أسبوعي)
  String _selectedPeriod = 'weekly';

  // بيانات المخطط البياني الافتراضية
  List<double> values = [
    1500,
    2200,
    1800,
    2400,
    1900,
    2800,
    2500
  ]; // قيم المبيعات
  List<String> _chartLabels = [
    // تسميات المحور الأفقي (الأيام)
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة'
  ];
  double maxValue = 3000; // القيمة القصوى للمحور العمودي (لتنسيق الرسم)

  // دالة التهيئة الأولية (تعمل عند فتح الشاشة)
  @override
  void initState() {
    super.initState();
    // تهيئة متحكم التبويبات ليحتوي على 3 تبويبات
    _tabController = TabController(length: 3, vsync: this);
  }

  // دالة التنظيف (تعمل عند إغلاق الشاشة)
  @override
  void dispose() {
    _tabController.dispose(); // إغلاق المتحكم لتحرير الذاكرة
    super.dispose();
  }

  // دالة لتحديث بيانات الرسم البياني عند تغيير الفترة الزمنية (يومي/أسبوعي/شهري)
  void _updatePeriod(String period) {
    setState(() {
      // إعادة بناء الواجهة بالبيانات الجديدة
      _selectedPeriod = period;
      if (period == 'daily') {
        // بيانات تجريبية لليوم
        values = [1500, 2200, 1800, 2400, 1900, 2800, 2500];
        _chartLabels = [
          'السبت',
          'الأحد',
          'الاثنين',
          'الثلاثاء',
          'الأربعاء',
          'الخميس',
          'الجمعة'
        ];
        maxValue = 3000;
      } else if (period == 'weekly') {
        // بيانات تجريبية للأسبوع (مجمعة)
        values = [15000, 18000, 14000, 20000];
        _chartLabels = [
          'الأسبوع الأول',
          'الأسبوع الثاني',
          'الأسبوع الثالث',
          'الأسبوع الرابع'
        ];
        maxValue = 22000;
      } else {
        // بيانات تجريبية للشهور
        values = [5000, 7500, 6000, 9500, 7000, 11000];
        _chartLabels = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو'];
        maxValue = 12000;
      }
    });
  }

  // بناء واجهة المستخدم الرئيسية للشاشة
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'), // عنوان الشاشة
        backgroundColor: AppColors.primary, // اللون الأساسي من ملف الألوان
        foregroundColor: Colors.white, // لون النص أبيض
        actions: [
          // زر خيارات التصدير (PDF أو Excel)
          PopupMenuButton<String>(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'تصدير التقرير',
            onSelected: (value) {
              if (value == 'pdf') {
                _printReport();
              } else if (value == 'excel') {
                _exportToExcel();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('تصدير PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('تصدير Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
        // شريط التبويبات السفلي داخل الـ AppBar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white, // لون مؤشر التبويب المختار
          labelColor: Colors.white, // لون النص المختار
          unselectedLabelColor: Colors.white70, // لون النص غير المختار
          tabs: const [
            Tab(text: 'ملخص المبيعات'),
            Tab(text: 'الأكثر مبيعاً'),
            Tab(text: 'تنبيهات المخزون'),
          ],
        ),
      ),
      // محتوى الجسم يتغير بناءً على التبويب المختار
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSalesSummaryTab(), // محتوى التبويب الأول
          _buildTopProductsTab(), // محتوى التبويب الثاني
          _buildLowStockTab(), // محتوى التبويب الثالث
        ],
      ),
    );
  }

  // --- بناء تبويب ملخص المبيعات (الواجهة التفاعلية) ---
  Widget _buildSalesSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقات إحصائية في الأعلى (إجمالي المبيعات وعدد الطلبات)
          Row(
            children: [
              Expanded(
                child: _buildStatCard('إجمالي المبيعات', '24,500 ر.ي',
                    Icons.attach_money, AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('عدد الطلبات', '142', Icons.shopping_cart,
                    AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'تحليل أداء المبيعات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // أزرار تصفية الفترة (يومي، أسبوعي، شهري)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: _buildPeriodButton('يومي', 'daily')),
                Expanded(child: _buildPeriodButton('أسبوعي', 'weekly')),
                Expanded(child: _buildPeriodButton('شهري', 'monthly')),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // المخطط البياني (CustomPaint)
          Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // تدرج لوني للخلفية
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                // ظل خفيف للبطاقة
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                  bottom: 25, left: 10, right: 10, top: 10),
              child: CustomPaint(
                // استخدام الرسام المخصص رسم المخطط
                size: const Size(double.infinity, 160),
                painter: LineChartPainter(
                  // كلاس الرسام (معرف في أسفل الملف)
                  values: values,
                  labels: _chartLabels,
                  maxValue: maxValue,
                  minValue: values.isEmpty
                      ? 0
                      : values.reduce((a, b) => a < b ? a : b),
                  lineColor: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // زر اختيار الفترة الزمنية بتنسيق خاص
  Widget _buildPeriodButton(String title, String period) {
    bool isSelected = _selectedPeriod == period; // هل هذا الزر هو المختار؟
    return GestureDetector(
      onTap: () => _updatePeriod(period), // تحديث الفترة عند الضغط
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent, // تمييز المختار باللون الأساسي
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // بطاقة إحصائية صغيرة (أيقونة + عنوان + رقم)
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- بناء تبويب المنتجات الأكثر مبيعاً ---
  Widget _buildTopProductsTab() {
    // بيانات وهمية للعرض
    final topProducts = [
      {'name': 'أرز بسمتي 5 كجم', 'sales': 145, 'revenue': '4,350'},
      {'name': 'زيت عافية 1.5 لتر', 'sales': 120, 'revenue': '3,600'},
      {'name': 'سكر ناعم 2 كجم', 'sales': 98, 'revenue': '1,960'},
      {'name': 'حليب المراعي 1 لتر', 'sales': 85, 'revenue': '850'},
      {'name': 'مكرونة الوفرة', 'sales': 76, 'revenue': '380'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topProducts.length,
      itemBuilder: (context, index) {
        final product = topProducts[index];
        final double percentage =
            (product['sales'] as int) / 145.0; // نسبة المبيعات مقارنة بالأعلى

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // مربع الترتيب (#1, #2...)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // تفاصيل المنتج
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${product['sales']} مبيعات',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // الإيراد
                  Text(
                    '${product['revenue']} ر.ي',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // شريط التقدم يوضح نسبة المبيعات بصرياً
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[100],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- بناء تبويب تنبيهات المخزون المنخفض ---
  Widget _buildLowStockTab() {
    final lowStockItems = [
      {'name': 'دقيق فاخر 1 كجم', 'stock': 2, 'min_stock': 10},
      {'name': 'صلصة طماطم', 'stock': 5, 'min_stock': 15},
      {'name': 'شاي أحمر', 'stock': 3, 'min_stock': 8},
      {'name': 'عدس أحمر', 'stock': 0, 'min_stock': 5},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lowStockItems.length,
      itemBuilder: (context, index) {
        final item = lowStockItems[index];
        final int stock = item['stock'] as int;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            // إطار أحمر إذا الكمية 0 وبرتقالي إذا منخفضة فقط
            border: Border.all(
                color:
                    stock == 0 ? Colors.red.shade200 : Colors.orange.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: stock == 0 ? Colors.red : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stock == 0
                          ? 'نفذت الكمية!'
                          : 'مخزون منخفض: $stock قطع متبقية',
                      style: TextStyle(
                        color: stock == 0 ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // زر "إعادة طلب" (مجرد شكل للعرض)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (stock == 0 ? Colors.red : Colors.orange)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'إعادة طلب',
                  style: TextStyle(
                    color: stock == 0 ? Colors.red : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============== منطق إنشاء وطباعة التقرير PDF ===================
  // هذه الدالة هي المسؤولة عن بناء ملف الـ PDF كاملاً عند الضغط على زر الطباعة
  Future<void> _printReport() async {
    // تحميل خط "Cairo" (عادي وعريض) لدعم اللغة العربية بشكل صحيح في الـ PDF
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    // إنشاء كائن المستند (PDF Document)
    final doc = pw.Document();

    // إعداد خدمة الذكاء الاصطناعي وبيانات وهمية للتجربة (يمكن استبدالها ببيانات حقيقية من قاعدة البيانات)
    final aiService = SmartPredictionService();

    // بيانات منتجات تجريبية (Dummy Data) لغرض توليد التقرير
    final dummyProducts = [
      Product(
        id: 1,
        name: 'شاي ليبتون',
        barcode: '111',
        minStockLevel: 10, // حد طلب منخفض
        details: [
          ProductDetail(productId: 1, quantity: 50, purchasePrice: 10.0)
        ],
        units: [
          ProductUnit(
              productId: 1,
              unitName: 'حبة',
              conversionFactor: 1, // 1 للوحدة الأساسية
              salePrice: 15.0,
              isBaseUnit: true)
        ],
      ), // منتج موسمي (شتاء)
      Product(
        id: 2,
        name: 'حليب نادك',
        barcode: '222',
        minStockLevel: 20,
        details: [
          ProductDetail(productId: 2, quantity: 30, purchasePrice: 3.0)
        ],
        units: [
          ProductUnit(
              productId: 2,
              unitName: 'حبة',
              conversionFactor: 1,
              salePrice: 4.0,
              isBaseUnit: true)
        ],
      ), // منتج موسمي (شتاء)
      Product(
        id: 3,
        name: 'ايس كريم',
        barcode: '333',
        minStockLevel: 10,
        details: [
          ProductDetail(productId: 3, quantity: 100, purchasePrice: 1.0)
        ],
        units: [
          ProductUnit(
              productId: 3,
              unitName: 'حبة',
              conversionFactor: 1,
              salePrice: 2.0,
              isBaseUnit: true)
        ],
      ), // منتج موسمي (صيف - لن يظهر كتوصية في الشتاء)
      Product(
        id: 4,
        name: 'بسكويت منتهي',
        barcode: '444',
        minStockLevel: 10,
        details: [
          ProductDetail(
              productId: 4,
              quantity: 5,
              purchasePrice: 1.5,
              // هذا المنتج منتهي الصلاحية (تاريخه قبل يوم)
              expiryDate: DateTime.now().subtract(const Duration(days: 1)))
        ],
      ),
    ];

    // استدعاء خدمة الذكاء الاصطناعي للحصول على التوصيات (انتهاء صلاحية، مواسم)
    final aiInsights = await aiService.getAIInsights(dummyProducts);

    // إضافة صفحة للمستند
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4, // حجم الورقة A4
        theme: pw.ThemeData.withFont(
          // تعيين الثيم والخطوط العربية
          base: font,
          bold: fontBold,
        ),
        // دالة البناء لمحتوى الصفحة
        build: (pw.Context context) {
          return [
            // Directionality لتوجيه النص من اليمين لليسار (RTL) لدعم العربية
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                children: [
                  _buildPdfHeader(), // 1. رأس الصفحة (الترويسة)
                  pw.SizedBox(height: 20),
                  _buildPdfSalesSummary(), // 2. المربع السماوي للملخص
                  pw.SizedBox(height: 20),
                  _buildPdfSalesAnalysisTable(), // 3. جدول تحليل المبيعات
                  pw.SizedBox(height: 20),
                  _buildPdfTopProducts(), // 4. جدول أفضل المنتجات
                  pw.SizedBox(height: 20),
                  // 5. جدول توصيات الذكاء الاصطناعي (يظهر فقط إذا وجدت توصيات)
                  if (aiInsights.isNotEmpty)
                    _buildPdfDetailedRecommendations(aiInsights),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // عرض معاينة الطباعة (أو الطباعة المباشرة)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name:
          'تقرير_المبيعات_والمخزون_${DateTime.now().toString().split(' ')[0]}',
    );
  }

  // ============== منطق تصدير التقرير إلى Excel ===================
  Future<void> _exportToExcel() async {
    try {
      var excel = ex.Excel.createExcel();
      ex.Sheet sheetObject = excel['التقرير العام'];
      excel.delete('Sheet1'); // حذف الورقة الافتراضية

      // 1. ترويسة التقرير
      sheetObject.cell(ex.CellIndex.indexByString("A1")).value =
          ex.TextCellValue("تقرير مخزني الشامل");
      sheetObject.cell(ex.CellIndex.indexByString("A2")).value =
          ex.TextCellValue(
              "تاريخ التقرير: ${DateTime.now().toString().split(' ')[0]}");

      // 2. ملخص المبيعات
      sheetObject.cell(ex.CellIndex.indexByString("A4")).value =
          ex.TextCellValue("الملخص التنفيذي");
      sheetObject.cell(ex.CellIndex.indexByString("A5")).value =
          ex.TextCellValue("إجمالي المبيعات");
      sheetObject.cell(ex.CellIndex.indexByString("B5")).value =
          ex.TextCellValue("24,500 ر.ي");
      sheetObject.cell(ex.CellIndex.indexByString("A6")).value =
          ex.TextCellValue("عدد الطلبات");
      sheetObject.cell(ex.CellIndex.indexByString("B6")).value =
          ex.TextCellValue("142");

      // 3. جدول أفضل المنتجات
      sheetObject.cell(ex.CellIndex.indexByString("A8")).value =
          ex.TextCellValue("المنتجات الأكثر مبيعاً");

      sheetObject.cell(ex.CellIndex.indexByString("A9")).value =
          ex.TextCellValue("المنتج");
      sheetObject.cell(ex.CellIndex.indexByString("B9")).value =
          ex.TextCellValue("الكمية المباعة");
      sheetObject.cell(ex.CellIndex.indexByString("C9")).value =
          ex.TextCellValue("الإيرادات");

      var topProducts = [
        ['حليب نادك 1 لتر', '450', '2,250'],
        ['رز بسمتي 5 كجم', '120', '4,800'],
        ['زيت طبخ 1.5 لتر', '210', '3,150'],
      ];

      for (int i = 0; i < topProducts.length; i++) {
        sheetObject.cell(ex.CellIndex.indexByString("A${10 + i}")).value =
            ex.TextCellValue(topProducts[i][0]);
        sheetObject.cell(ex.CellIndex.indexByString("B${10 + i}")).value =
            ex.TextCellValue(topProducts[i][1]);
        sheetObject.cell(ex.CellIndex.indexByString("C${10 + i}")).value =
            ex.TextCellValue(topProducts[i][2]);
      }

      // 4. تنبيهات المخزون
      int startLowStock = 12 + topProducts.length;
      sheetObject.cell(ex.CellIndex.indexByString("A$startLowStock")).value =
          ex.TextCellValue("تنبيهات المخزون المنخفض");

      var lowStockItems = [
        ['دقيق فاخر 1 كجم', '2', '10'],
        ['صلصة طماطم', '5', '15'],
        ['شاي أحمر', '3', '8'],
      ];

      for (int i = 0; i < lowStockItems.length; i++) {
        sheetObject
            .cell(ex.CellIndex.indexByString("A${startLowStock + 1 + i}"))
            .value = ex.TextCellValue(lowStockItems[i][0]);
        sheetObject
            .cell(ex.CellIndex.indexByString("B${startLowStock + 1 + i}"))
            .value = ex.TextCellValue("المتبقي: ${lowStockItems[i][1]}");
      }

      // حفظ وتصدير الملف
      var fileBytes = excel.save();
      String fileName =
          "Makhzani_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      if (fileBytes != null) {
        Uint8List bytes = Uint8List.fromList(fileBytes);
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تجهيز ملف Excel بنجاح'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Excel Export Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ أثناء تصدير Excel: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- بناء ترويسة الـ PDF (الشعار والعنوان) ---
  pw.Widget _buildPdfHeader() {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('مخزني',
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800)),
            pw.Text('تقرير المبيعات والمخزون',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.cyan700)),
          ],
        ),
        pw.SizedBox(height: 10),
        // خط فاصل سماوي مع عنوان التقرير في المنتصف
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.cyan, width: 2),
            ),
          ),
          child: pw.Center(
            child: pw.Column(
              children: [
                pw.Text('تقرير شامل للمبيعات والمخزون',
                    style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.cyan800)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'تاريخ التقرير: ${DateTime.now().toString().split(' ')[0]}',
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- بناء ملخص المبيعات في الـ PDF (المربع السماوي) ---
  pw.Widget _buildPdfSalesSummary() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.cyan50, // خلفية سماوي فاتح
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.cyan100), // حدود سماوية
      ),
      child: pw.Column(
        children: [
          // عنوان القسم مع أيقونة دائرية صغيرة
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Text('الملخص التنفيذي',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.cyan800)),
            pw.SizedBox(width: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: const pw.BoxDecoration(
                color: PdfColors.cyan800,
                shape: pw.BoxShape.circle,
              ),
            ),
          ]),
          pw.SizedBox(height: 15),
          // الصف الأول من الإحصائيات (قيمة المخزون، إجمالي المنتجات)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('قيمة المخزون', '8,665 ر.ي', PdfColors.cyan800),
              _buildMetricItem('إجمالي المنتجات', '7 منتج', PdfColors.cyan800),
            ],
          ),
          pw.SizedBox(height: 15),
          // الصف الثاني (المبيعات، الصحة)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('المبيعات', '0 منتج', PdfColors.cyan800),
              _buildMetricItem('صحة المخزون', '100.0%', PdfColors.cyan800),
            ],
          ),
        ],
      ),
    );
  }

  // --- بناء جدول تحليل المبيعات ---
  pw.Widget _buildPdfSalesAnalysisTable() {
    return pw.Column(
      children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Text('تحليل المبيعات',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.cyan800)),
          pw.SizedBox(width: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: const pw.BoxDecoration(
              color: PdfColors.cyan800,
              shape: pw.BoxShape.circle,
            ),
          ),
        ]),
        pw.SizedBox(height: 10),
        // الجدول
        pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.grey300, width: 0.5), // حدود رمادية خفيفة
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // الفترة (عرض أكبر)
              1: const pw.FlexColumnWidth(1), // المبيعات
              2: const pw.FlexColumnWidth(1), // النسبة
            },
            children: [
              // صف العناوين (Header) بخلفية سماوية
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.cyan600),
                children: [
                  _buildTableCell('الفترة', isHeader: true),
                  _buildTableCell('المبيعات (ر.ي)', isHeader: true),
                  _buildTableCell('النسبة من الإجمالي', isHeader: true),
                ],
              ),
              // صفوف البيانات
              _buildPdfSalesRow('اليوم', '0.00', '0%'),
              _buildPdfSalesRow('الأسبوع', '0.00', '0%'),
              _buildPdfSalesRow('الشهر', '0.00', '0%'),
              _buildPdfSalesRow('متوسط المبيعات اليومية', '0.00', '-'),
            ]),
      ],
    );
  }

  // دالة مساعدة لإنشاء صف في جدول المبيعات
  pw.TableRow _buildPdfSalesRow(
      String period, String sales, String percentage) {
    return pw.TableRow(
      children: [
        _buildTableCell(period),
        _buildTableCell(sales),
        _buildTableCell(percentage),
      ],
    );
  }

  // دالة مساعدة عامة لإنشاء خلية في الجدول وتنسيقها
  pw.Widget _buildTableCell(String text,
      {bool isHeader = false, PdfColor? headerColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 10,
          // الخط عريض إذا كانت header، ولون النص أبيض (أو مخصص) للرأس وأسود للبيانات
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? (headerColor ?? PdfColors.white) : PdfColors.black,
        ),
      ),
    );
  }

  // دالة مساعدة لعرض رقم وعنوان تحته (داخل المربعات)
  pw.Widget _buildMetricItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  // --- بناء جدول أفضل المنتجات ---
  pw.Widget _buildPdfTopProducts() {
    final topProducts = [
      {'name': 'حليب نادك كامل الدسم', 'qty': 150, 'rank': 1},
      {'name': 'شاي ليبتون أكياس 100 خيط', 'qty': 120, 'rank': 2},
      {'name': 'أرز بسمتي الشعلان 10 كجم', 'qty': 95, 'rank': 3},
      {'name': 'سكر الأسرة ناعم 5 كجم', 'qty': 80, 'rank': 4},
      {'name': 'زيت دوار الشمس عافية 1.5 لتر', 'qty': 65, 'rank': 5},
    ];

    return pw.Column(
      children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Text('أفضل المنتجات مبيعاً (7 Top)',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.cyan800)),
          pw.SizedBox(width: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: const pw.BoxDecoration(
              color: PdfColors.cyan800,
              shape: pw.BoxShape.circle,
            ),
          ),
        ]),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // الاسم
            1: const pw.FlexColumnWidth(1), // الكمية
            2: const pw.FlexColumnWidth(0.5), // الترتيب
          },
          children: [
            // ترويسة الجدول برتقالية
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.orange400),
              children: [
                _buildTableCell('اسم المنتج', isHeader: true),
                _buildTableCell('الكمية المباعة', isHeader: true),
                _buildTableCell('الترتيب', isHeader: true),
              ],
            ),
            // البيانات
            ...topProducts.map((p) => pw.TableRow(
                  decoration: (p['rank'] as int) % 2 == 0
                      ? const pw.BoxDecoration(color: PdfColors.grey100)
                      : null,
                  children: [
                    _buildTableCell(p['name'] as String),
                    _buildTableCell(p['qty'].toString()),
                    _buildTableCell(p['rank'].toString()),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  // --- بناء جدول توصيات الذكاء الاصطناعي (AI) ---
  pw.Widget _buildPdfDetailedRecommendations(List<PredictionInsight> insights) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'توصيات الذكاء الاصطناعي', // العنوان باللون البنفسجي
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple800,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: const pw.BoxDecoration(
                color: PdfColors.purple800,
                shape: pw.BoxShape.circle,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        // جدول التوصيات النظيف
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1), // المنتج
            1: const pw.FlexColumnWidth(3), // نص التوصية (عرض أكبر)
            2: const pw.FlexColumnWidth(0.8), // نوع التنبيه
          },
          children: [
            // ترويسة الجدول بنفسجية فاتحة مع نص غامق
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.purple100),
              children: [
                _buildTableCell('المنتج',
                    isHeader: true, headerColor: PdfColors.purple800),
                _buildTableCell('التوصية المقترحة',
                    isHeader: true, headerColor: PdfColors.purple800),
                _buildTableCell('نوع التنبيه',
                    isHeader: true, headerColor: PdfColors.purple800),
              ],
            ),
            // صفوف البيانات
            ...insights.map((insight) {
              String typeText = 'عام';
              PdfColor rowColor = PdfColors.white;

              // تحديد لون ونوع التوصية بناءً على نوعها
              if (insight.type == 'EXPIRY') {
                typeText = 'صلاحية';
                rowColor = PdfColors.red50; // خلفية حمراء فاتحة للانتهاء
              } else if (insight.type == 'SEASONAL') {
                typeText = 'موسمي';
                rowColor = PdfColors.blue50; // خلفية زرقاء فاتحة للمواسم
              } else if (insight.type == 'RESTOCK') {
                typeText = 'إعادة طلب';
                rowColor = PdfColors.orange50; // خلفية برتقالية فاتحة للمخزون
              }

              return pw.TableRow(
                decoration: pw.BoxDecoration(color: rowColor),
                children: [
                  _buildTableCell(insight.product.name, isHeader: false),
                  // نص التوصية
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      insight.message,
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  _buildTableCell(typeText, isHeader: false),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
}

// الرسام المخصص (CustomPainter) لرسم المخطط البياني في واجهة التطبيق
class LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxValue;
  final double minValue;
  final Color lineColor;

  LineChartPainter({
    required this.values,
    required this.labels,
    required this.maxValue,
    required this.minValue,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // حساب المسافات بين النقاط
    final widthStep = size.width / (values.length - 1);
    final heightRatio = size.height / (maxValue - minValue + 1);

    final path = Path();

    // رسم الخط
    for (int i = 0; i < values.length; i++) {
      final x = i * widthStep;
      final y = size.height - ((values[i] - minValue) * heightRatio);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // رسم الظل المتدرج تحت الخط
    final shadowPath = Path.from(path);
    shadowPath.lineTo(size.width, size.height);
    shadowPath.lineTo(0, size.height);
    shadowPath.close();

    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.2), // شفافية 20% في الأعلى
          lineColor.withValues(alpha: 0.0), // شفافية 0% في الأسفل
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(shadowPath, shadowPaint);

    // خصائص قلم رسم الخط الرئيسي
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // رسم النقاط (Circles)
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderDotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < values.length; i++) {
      final x = i * widthStep;
      final y = size.height - ((values[i] - minValue) * heightRatio);
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 5, borderDotPaint);

      // رسم اسم التسمية (اليوم/الشهر) أسفل كل نقطة
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontFamily: 'Cairo', // استخدام خط Cairo للتسميات
          ),
        ),
        textDirection: TextDirection.rtl, // اتجاه النص
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height + 5),
      );
    }
  }

  // هل يجب إعادة الرسم عند تغيير البيانات؟ نعم (true)
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
