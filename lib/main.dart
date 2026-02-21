import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'package:makhzani_app/services/database_helper.dart';
import 'package:makhzani_app/services/seed_data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:provider/provider.dart';
import 'package:makhzani_app/services/app_settings_service.dart';
import 'package:makhzani_app/screens/splash_screen.dart';
import 'package:makhzani_app/utils/app_theme.dart';

void main() async {
  // تهيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة بيانات التاريخ والوقت (مهم جداً للمكتبة intl)
  await initializeDateFormatting();

  // تهيئة sqflite لجميع المنصات (بما في ذلك الويب)
  if (kIsWeb) {
    // Web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    // Desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // تهيئة قاعدة البيانات (تمكينها لجميع المنصات الآن)
  try {
    await _initializeDatabase();
  } catch (e) {
    debugPrint('Failed to initialize database: $e');
  }

  // تشغيل التطبيق مع مزود الإعدادات
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettingsService(),
      child: const MyApp(),
    ),
  );
}

/// تهيئة قاعدة البيانات وإضافة البيانات التجريبية
Future<void> _initializeDatabase() async {
  try {
    debugPrint('🔧 تهيئة قاعدة البيانات...');

    final db = DatabaseHelper();
    await db.database; // إنشاء/فتح القاعدة

    // إضافة البيانات التجريبية الشاملة فوق البيانات الحالية
    debugPrint('📦 إضافة بيانات تجريبية (المنتهية والموسمية)...');
    final seeder = SeedData();
    await seeder.seedAll();

    final products = await db.getAllProducts();
    debugPrint('✅ القاعدة تحتوي الآن على ${products.length} منتج');
  } catch (e) {
    debugPrint('❌ خطأ في تهيئة القاعدة: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // الاستماع لتغييرات الإعدادات
    final settings = Provider.of<AppSettingsService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مخزني',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme, // ربط الثيم الداكن
      themeMode: settings.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light, // التبديل بناء على الإعدادات
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'), // اللغة العربية
        Locale('en', 'US'), // اللغة الإنجليزية
      ],
      locale: const Locale('ar', 'AE'), // إجبار التطبيق على العربية
      home: const SplashScreen(),
    );
  }
}
