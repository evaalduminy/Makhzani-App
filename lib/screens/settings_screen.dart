import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:makhzani_app/services/app_settings_service.dart';
import 'package:makhzani_app/login_screen.dart';
import 'package:makhzani_app/screens/categories_management_screen.dart';
import 'package:makhzani_app/services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettingsService>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ... (User Card - No changes needed usually, but could check colors for dark mode)
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor, // Dynamic card color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            // ... (User info content)
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor:
                        const Color(0xFF00BCD4).withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF00BCD4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.username, // عرض اسم المستخدم المسجل
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // ... (Keep existing badge)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA), // Cyan 50
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'صلاحيات كاملة',
                          style: TextStyle(
                            color: Color(0xFF006064), // Cyan 900
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ... (Data Management Card - update color)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text('إدارة البيانات',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.category_rounded,
                  iconColor: Colors.purple,
                  title: 'إدارة التصنيفات',
                  subtitle: 'إضافة وتعديل تصنيفات المنتجات',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const CategoriesManagementScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  icon: Icons.cloud_upload_rounded,
                  iconColor: const Color(0xFF00BCD4),
                  title: 'نسخ احتياطي (محاكاة)',
                  subtitle: 'حفظ نسخة آمنة من البيانات',
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('جاري إنشاء نسخة احتياطية... ⏳')),
                    );
                    await Future.delayed(const Duration(seconds: 2));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم الحفظ بنجاح في المستندات ✅'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: Colors.red,
                  title: 'حذف جميع البيانات',
                  subtitle: 'تصفير قاعدة البيانات (للمطورين)',
                  onTap: () {
                    _confirmResetDatabase();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // إعدادات التطبيق (Here is the implementation scope)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text('إعدادات التطبيق',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: Colors.orange),
                  ),
                  title: const Text('الإشعارات'),
                  subtitle: const Text('تفعيل التنبيهات الذكية'),
                  trailing: Switch(
                    value: settings.areNotificationsEnabled, // متصل بالخدمة
                    activeColor: const Color(0xFF00BCD4),
                    onChanged: (value) {
                      settings.toggleNotifications(value); // تغيير الحالة
                    },
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.dark_mode_rounded,
                        color: Colors.indigo),
                  ),
                  title: const Text('الوضع الليلي'),
                  subtitle: const Text('تفعيل الثيم الداكن'),
                  trailing: Switch(
                    value: settings.isDarkMode, // متصل بالخدمة
                    activeColor: const Color(0xFF00BCD4),
                    onChanged: (value) {
                      settings.toggleDarkMode(value); // تغيير الثيم فوراً
                    },
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_rounded, color: Colors.red),
                  ),
                  title: const Text('حد تنبيه المخزون'),
                  subtitle: const Text('الافتراضي: 10 قطع'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showStockLevelDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // حول التطبيق
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text('حول التطبيق',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: Colors.teal),
                  title: Text('الإصدار'),
                  subtitle: Text('1.0.0'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded,
                      color: Colors.green),
                  title: const Text('المساعدة والدعم'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    _showHelpDialog();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // زر تسجيل الخروج
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade100),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Makhzani App v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showStockLevelDialog() {
    final controller = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل حد التنبيه'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'الحد الأدنى للمخزون',
            border: OutlineInputBorder(),
            suffixText: 'قطعة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تحديث الحد إلى ${controller.text} قطعة'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعدة والدعم'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تطبيق مخزني',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'نظام إدارة المخزون الذكي',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 16),
              Text(
                'المميزات:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• إدارة المنتجات والمخزون'),
              Text('• تتبع المعاملات'),
              Text('• تقارير وإحصائيات'),
              Text('• إدارة الموردين والعملاء'),
              Text('• تنبيهات المخزون المنخفض'),
              SizedBox(height: 16),
              Text(
                'للدعم الفني:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('البريد الإلكتروني: support@makhzani.com'),
              Text('الهاتف: +967 123 456 789'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق الـ dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _confirmResetDatabase() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف جميع البيانات؟'),
        content: const Text(
            'هذا الإجراء سيقوم بحذف جميع المنتجات والمعاملات ولا يمكن التراجع عنه. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper().resetDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('تم تصفير قاعدة البيانات بنجاح')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
