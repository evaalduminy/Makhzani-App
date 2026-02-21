import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import '../models/category_model.dart' as model;
import '../models/product.dart';
import '../models/product_unit_model.dart';
import '../models/product_detail_model.dart';
import 'dart:math';

class SeedData {
  final _dbHelper = DatabaseHelper();
  final Random _random = Random();

  Future<void> seedAll() async {
    try {
      debugPrint('🌱 بدء إضافة بيانات غذائية متنوعة...');

      // 1. إضافة تصنيفات "مواد غذائية" فقط
      final foodCategories = [
        'بقوليات وحبوب',
        'زيوت ودهون',
        'معلبات',
        'ألبان وأجبان',
        'مشروبات وعصائر',
        'بهارات وتوابل',
        'مخبوزات'
      ];

      for (var catName in foodCategories) {
        await _dbHelper.insertCategory(model.Category(name: catName));
      }

      final allCats = await _dbHelper.getCategories();

      // قوائم المنتجات الغذائية للتنوع
      final productsData = [
        {
          'name': 'أرز بسمتي هندي 5كجم',
          'cat': 'بقوليات وحبوب',
          'price': 4500.0,
          'cost': 3800.0
        },
        {
          'name': 'سكر الأسرة 2كجم',
          'cat': 'بقوليات وحبوب',
          'price': 1200.0,
          'cost': 950.0
        },
        {
          'name': 'دقيق فوم فاخر 1كجم',
          'cat': 'بقوليات وحبوب',
          'price': 350.0,
          'cost': 220.0
        },
        {
          'name': 'عدس أحمر مجروش',
          'cat': 'بقوليات وحبوب',
          'price': 600.0,
          'cost': 450.0
        },
        {
          'name': 'زيت عافية ذرة 1.5لتر',
          'cat': 'زيوت ودهون',
          'price': 1800.0,
          'cost': 1400.0
        },
        {
          'name': 'سمن فارم أصلي',
          'cat': 'زيوت ودهون',
          'price': 3200.0,
          'cost': 2600.0
        },
        {
          'name': 'زيت زيتون بكر ممتاز',
          'cat': 'زيوت ودهون',
          'price': 2500.0,
          'cost': 1900.0
        },
        {
          'name': 'تونا قودي خفيف',
          'cat': 'معلبات',
          'price': 450.0,
          'cost': 320.0
        },
        {
          'name': 'فول مدمس حدائق كاليفورنيا',
          'cat': 'معلبات',
          'price': 250.0,
          'cost': 180.0
        },
        {
          'name': 'صلصة طماطم السعودية',
          'cat': 'معلبات',
          'price': 150.0,
          'cost': 110.0
        },
        {
          'name': 'حليب طويل الأجل لتر',
          'cat': 'ألبان وأجبان',
          'price': 450.0,
          'cost': 350.0
        },
        {
          'name': 'جبنة كرافت شيدر',
          'cat': 'ألبان وأجبان',
          'price': 850.0,
          'cost': 600.0
        },
        {
          'name': 'لبن طازج نادك',
          'cat': 'ألبان وأجبان',
          'price': 550.0,
          'cost': 400.0
        },
        {
          'name': 'شاي ليبتون 100 خيط',
          'cat': 'مشروبات وعصائر',
          'price': 1100.0,
          'cost': 850.0
        },
        {
          'name': 'قهوة هرري يمني',
          'cat': 'مشروبات وعصائر',
          'price': 3500.0,
          'cost': 2800.0
        },
        {
          'name': 'عصير برتقال طبيعي',
          'cat': 'مشروبات وعصائر',
          'price': 300.0,
          'cost': 210.0
        },
        {
          'name': 'ملح ساسا ناعم',
          'cat': 'بهارات وتوابل',
          'price': 100.0,
          'cost': 60.0
        },
        {
          'name': 'فلفل أسود مطحون',
          'cat': 'بهارات وتوابل',
          'price': 400.0,
          'cost': 280.0
        },
        {
          'name': 'بهارات مشكلة 250جم',
          'cat': 'بهارات وتوابل',
          'price': 650.0,
          'cost': 480.0
        },
        {
          'name': 'مكرونة الوفرة 400جم',
          'cat': 'بقوليات وحبوب',
          'price': 200.0,
          'cost': 140.0
        },
      ];

      for (var pInfo in productsData) {
        final catId = allCats.firstWhere((c) => c.name == pInfo['cat']).id!;

        final product = Product(
          name: pInfo['name'] as String,
          barcode: '${100000000 + _random.nextInt(900000000)}',
          categoryId: catId,
          minStockLevel: 10 + _random.nextInt(20),
        );

        final productId = await _dbHelper.insertProduct(product);

        // إضافة الوحدة الأساسية
        await _dbHelper.insertProductUnit(ProductUnit(
          productId: productId,
          unitName: 'حبة',
          conversionFactor: 1,
          salePrice: pInfo['price'] as double,
          isBaseUnit: true,
        ));

        // إضافة كمية عشوائية وتاريخ انتهاء عشوائي (للذكاء والانتهاء)
        // بعضها منتهي، بعضها قريب، وبعضها سليم جداً
        int randStatus = _random.nextInt(10);
        DateTime expiry;
        if (randStatus == 0) {
          expiry = DateTime.now()
              .subtract(Duration(days: _random.nextInt(30))); // منتهي
        } else if (randStatus == 1) {
          expiry = DateTime.now()
              .add(Duration(days: _random.nextInt(15))); // حرج جداً
        } else {
          expiry = DateTime.now()
              .add(Duration(days: 90 + _random.nextInt(300))); // سليم
        }

        await _dbHelper.insertProductDetail(ProductDetail(
          productId: productId,
          quantity: _random.nextInt(100), // كمية عشوائية لاختبار حد الطلب
          purchasePrice: pInfo['cost'] as double,
          expiryDate: expiry,
        ));
      }

      debugPrint(
          '✅ تم حقن قاعدة البيانات بـ ${productsData.length} منتج غذائي متنوع');
    } catch (e) {
      debugPrint('❌ خطأ أثناء إضافة البيانات الغذائية: $e');
    }
  }
}
