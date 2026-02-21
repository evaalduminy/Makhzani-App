import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر لبناء الواجهات
import 'package:makhzani_app/screens/products_screen.dart'; // استيراد شاشة المنتجات
import 'package:makhzani_app/screens/transactions_screen.dart'; // استيراد شاشة المعاملات
import 'package:makhzani_app/screens/reports_screen.dart'; // استيراد شاشة التقارير
import 'package:makhzani_app/screens/settings_screen.dart'; // استيراد شاشة الإعدادات
import 'package:makhzani_app/screens/notifications_screen.dart'; // استيراد شاشة الإشعارات
import 'package:makhzani_app/services/database_helper.dart'; // استيراد مساعد قاعدة البيانات لجلب الإحصائيات

// الشاشة الرئيسية التي تحتوي على شريط التنقل السفلي (BottomNavigationBar) والشاشات الفرعية
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // متغير لتحديد رقم التبويب المختار حالياً (الافتراضي 0: الرئيسية)
  int _selectedIndex = 0;

  // قائمة تحتوي على الشاشات التي يتم التنقل بينها
  final List<Widget> _screens = [
    const DashboardTab(), // 0: لوحة التحكم (الرئيسية)
    const ProductsScreen(), // 1: المنتجات
    const TransactionsScreen(), // 2: المعاملات
    const ReportsScreen(), // 3: التقارير
    const SettingsScreen(), // 4: الإعدادات
  ];

  // دالة لتحديث التبويب المختار عند الضغط على أيقونة في الشريط السفلي
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // بناء واجهة المستخدم
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مخزني'), // عنوان التطبيق
        centerTitle: true, // توسيط العنوان
        elevation: 0, // إزالة الظل من الشريط العلوي لتصميم مسطح
        actions: [
          // زر الإشعارات مع شارة (Badge) حمراء لعدد الإشعارات
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none, // السماح للشارة بالخروج عن حدود الأيقونة
              children: [
                const Icon(Icons.notifications_none_rounded,
                    size: 28), // أيقونة الجرس
                // الشارة الحمراء
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red, // لون الخلفية أحمر
                      shape: BoxShape.circle, // شكل دائري
                    ),
                    child: const Text(
                      '3', // عدد الإشعارات (وهمي حالياً)
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              // الانتقال لشاشة الإشعارات عند الضغط
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8), // مسافة فارغة صغيرة
        ],
      ),
      // عرض الشاشة المختارة من القائمة بناءً على المؤشر _selectedIndex
      body: _screens[_selectedIndex],
      // شريط التنقل السفلي
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // التبويب النشط حالياً
        onTap: _onItemTapped, // الدالة التي تستدعى عند الاختيار
        type: BottomNavigationBarType.fixed, // نوع ثابت (لأكثر من 3 عناصر)
        selectedItemColor:
            Theme.of(context).colorScheme.primary, // لون العنصر المختار
        unselectedItemColor: Colors.grey, // لون العنصر غير المختار
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), // أيقونة
            label: 'الرئيسية', // نص
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'المنتجات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'المعاملات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'التقارير',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

// تبويب لوحة التحكم (الرئيسية) - يعرض إحصائيات سريعة
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // متغيرات لتخزين الإحصائيات المحملة من قاعدة البيانات
  int _totalProducts = 0; // إجمالي عدد المنتجات
  double _inventoryValue = 0.0; // القيمة المالية الإجمالية للمخزون
  int _lowStockProducts = 0; // عدد المنتجات قريبة النفاذ
  bool _isLoading = true; // حالة التحميل

  // عند بدء التشغيل، نستدعي دالة تحميل البيانات
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // دالة لجلب البيانات من قاعدة البيانات المحلية (Sqflite)
  Future<void> _loadDashboardData() async {
    try {
      final db = DatabaseHelper(); // الاتصال بقاعدة البيانات
      final products = await db.getAllProducts(); // جلب كل المنتجات

      double totalValue = 0.0;
      // حساب القيمة الإجمالية (سعر * كمية لكل منتج)
      for (var product in products) {
        totalValue += product.totalQuantity * product.mainPrice;
      }

      // تحديث الحالة لعرض الأرقام الجديدة
      setState(() {
        _totalProducts = products.length;
        _inventoryValue = totalValue;
        // حساب المنتجات التي كميتها أقل من أو تساوي حد الطلب
        _lowStockProducts =
            products.where((p) => p.totalQuantity <= p.minStockLevel).length;
        _isLoading = false; // انتهاء التحميل
      });
    } catch (e) {
      // في حالة الخطأ نوقف التحميل فقط
      setState(() {
        _isLoading = false;
      });
    }
  }

  // بناء واجهة لوحة التحكم
  @override
  Widget build(BuildContext context) {
    // إذا كان جاري التحميل، نعرض دائرة تحميل في المنتصف
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      // لجعل الشاشة قابلة للتمرير
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لوحة التحكم',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          // صف الإحصائيات العلوية (3 بطاقات ملونة)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'إجمالي المنتجات',
                  value: '$_totalProducts',
                  color: const Color(0xFF00BCD4), // لون سماوي
                  icon: Icons.inventory_2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'قيمة المخزون',
                  value:
                      'ريال ${_inventoryValue.toStringAsFixed(0)}', // بدون فواصل عشرية
                  color: const Color(0xFF2196F3), // لون أزرق
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'مبيعات الشهر',
                  value: 'ريال 0', // قيمة ثابتة حالياً
                  color: const Color(0xFFFF9800), // لون برتقالي
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // قسم تنبيهات المخزون
          Text(
            'تنبيهات المخزون المنخفض',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          // بطاقة التنبيه (تتغير بناءً على عدد المنتجات المنخفضة)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50, // خلفية خضراء فاتحة
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _lowStockProducts == 0
                        ? 'جميع المنتجات في مستوى آمن'
                        : '$_lowStockProducts منتجات تحتاج إعادة طلب', // رسالة ديناميكية
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // قسم الإجراءات السريعة (اختصارات للشاشات الأخرى)
          Text(
            'إجراءات سريعة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          // صفين من الأزرار الكبيرة
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  label: 'المنتجات',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    // الوصول لـ State الشاشة الأم وتغيير التبويب
                    final homeState =
                        context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?._onItemTapped(1); // انتقال للتبويب 1
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  label: 'المعاملات',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF4CAF50),
                  onTap: () {
                    final homeState =
                        context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?._onItemTapped(2); // انتقال للتبويب 2
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  label: 'التقارير',
                  icon: Icons.assessment_outlined,
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    final homeState =
                        context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?._onItemTapped(3); // انتقال للتبويب 3
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  label: 'الإعدادات',
                  icon: Icons.settings_outlined,
                  color: const Color(0xFF9E9E9E),
                  onTap: () {
                    final homeState =
                        context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?._onItemTapped(4); // انتقال للتبويب 4
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // مخطط الأرباح الشهرية
          _buildMonthlyProfitsLineChart(),
        ],
      ),
    );
  }

  // ويدجت لبناء بطاقة إحصائية ملونة
  Widget _buildStatCard({
    required String title, // العنوان
    required String value, // القيمة
    required Color color, // لون الخلفية
    required IconData icon, // الأيقونة
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white, // نص أبيض للتباين
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ويدجت لبناء بطاقات الإجراء السريع (زر كبير مع أيقونة)
  Widget _buildQuickActionCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap, // الدالة المنفذة عند الضغط
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت تغليف لمخطط الأرباح الشهرية
  Widget _buildMonthlyProfitsLineChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأرباح الشهرية',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // تدرج لوني خفيف
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF00BCD4).withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.only(bottom: 25, left: 10, right: 10, top: 10),
            child: CustomPaint(
              // رسم المخطط
              size: const Size(double.infinity, 160),
              painter: _MonthlyProfitsChartPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

// الرسام المخصص لمخطط الأرباح الشهرية (شبيه بالمستخدم في التقارير)
class _MonthlyProfitsChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // بيانات ثابتة للأرباح (للعرض فقط)
    final values = [5000.0, 7500.0, 6000.0, 9500.0, 7000.0, 11000.0];
    final labels = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو'];

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);

    final widthStep = size.width / (values.length - 1);
    final heightRatio = size.height / (maxValue - minValue + 1);

    final path = Path();
    final lineColor = const Color(0xFF00BCD4); // لون الخط

    for (int i = 0; i < values.length; i++) {
      final x = i * widthStep;
      final y = size.height - ((values[i] - minValue) * heightRatio);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // تعبئة الظل المتدرج
    final shadowPath = Path.from(path);
    shadowPath.lineTo(size.width, size.height);
    shadowPath.lineTo(0, size.height);
    shadowPath.close();

    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.2),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(shadowPath, shadowPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // رسم النقاط فوق الخط
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

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontFamily: 'Cairo', // استخدام خط مخصص
          ),
        ),
        textDirection: TextDirection.rtl,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height + 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
