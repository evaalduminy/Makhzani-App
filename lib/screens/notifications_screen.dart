import 'package:flutter/material.dart';
import 'package:makhzani_app/services/database_helper.dart';
import 'package:makhzani_app/services/smart_prediction_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // 1. تحميل الإشعارات الثابتة (تجريبية)
    final List<Map<String, dynamic>> initialNotifications = [
      {
        'title': 'تمت عملية بيع جديدة',
        'body': 'فاتورة رقم #1023 بقيمة 150 ر.س',
        'time': 'منذ 30 دقيقة',
        'type': 'success',
      },
      {
        'title': 'تحديث النظام',
        'body': 'تم تحديث التطبيق إلى النسخة 1.0.2 بنجاح.',
        'time': 'أمس',
        'type': 'info',
      },
    ];

    try {
      // 2. جلب المنتجات لتحليلها
      final dbHelper = DatabaseHelper();
      final products = await dbHelper.getAllProducts();

      // 3. تحليل المنتجات بالذكاء الاصطناعي
      final smartService = SmartPredictionService();
      final aiInsights = await smartService.getAIInsights(products);

      // 4. تحويل الرؤى إلى إشعارات
      for (var insight in aiInsights) {
        String title;
        String type;

        switch (insight.type) {
          case 'EXPIRY':
            title = '⚠️ تنبيه انتهاء صلاحية (${insight.product.name})';
            type = 'alert';
            break;
          case 'SEASONAL':
            title = '❄️ توصية موسمية (${insight.product.name})';
            type = 'recommendation';
            break;
          case 'RESTOCK':
            title = '💡 فرصة شراء (${insight.product.name})';
            type = 'recommendation';
            break;
          default:
            title = 'تنبيه ذكي';
            type = 'info';
        }

        initialNotifications.insert(0, {
          // إضافة في الأعلى
          'title': title,
          'body': insight.message,
          'time': 'الآن', // لأن التحليل لحظي
          'type': type,
        });
      }
    } catch (e) {
      debugPrint('Error loading AI notifications: $e');
    }

    if (mounted) {
      setState(() {
        _notifications = initialNotifications;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات والتوصيات'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد إشعارات حالياً',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationCard(context, notification);
                  },
                ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, Map<String, dynamic> notification) {
    Color iconColor;
    IconData iconData;
    Color bgColor;

    switch (notification['type']) {
      case 'alert':
        iconColor = Colors.red;
        iconData = Icons.warning_amber_rounded;
        bgColor = Colors.red.shade50;
        break;
      case 'success':
        iconColor = Colors.green;
        iconData = Icons.check_circle_outline;
        bgColor = Colors.green.shade50;
        break;
      case 'recommendation':
        iconColor = Colors.purple; // لون مميز للتوصيات الذكية
        iconData = Icons.auto_awesome;
        bgColor = Colors.purple.shade50;
        break;
      case 'info':
      default:
        iconColor = const Color(0xFF00BCD4); // Cyan
        iconData = Icons.info_outline;
        bgColor = const Color(0xFFE0F7FA); // Cyan 50
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          notification['title']!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['body']!,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            Text(
              notification['time']!,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
