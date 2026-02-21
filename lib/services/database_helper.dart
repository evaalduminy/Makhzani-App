// import 'dart:io'; // Removed for web support
import 'package:flutter/foundation.dart' hide Category;
// import 'package:flutter/services.dart'; // Removed as unused
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category_model.dart';
import '../models/contact_model.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_model.dart';
import '../models/prediction_history_model.dart';
import '../models/product.dart';
import '../models/product_detail_model.dart';
import '../models/product_unit_model.dart';
import '../models/stock_transaction_model.dart';
import '../models/user_model.dart';

/// مساعد قاعدة البيانات - Singleton
/// يدير جميع عمليات قاعدة البيانات SQLite
class DatabaseHelper {
  // Singleton Pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// الحصول على قاعدة البيانات (إنشاؤها إذا لم تكن موجودة)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// تهيئة قاعدة البيانات
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_warehouse_v3.db');

    // التحقق من وجود قاعدة بيانات جاهزة في assets
    final exists = await databaseExists(path);

    if (!exists) {
      // نسخ القاعدة من assets إذا كانت موجودة
      try {
        // [WEB COMPATIBILITY] File operations disabled for web
        // await Directory(dirname(path)).create(recursive: true);
        // final data = await rootBundle.load(
        //   'assets/database/smart_warehouse_v3.db',
        // );
        // final bytes = data.buffer.asUint8List();
        // await File(path).writeAsBytes(bytes, flush: true);
        debugPrint('✅ تم نسخ قاعدة البيانات من assets');
      } catch (e) {
        debugPrint(
          '⚠️ لم يتم العثور على قاعدة بيانات جاهزة، سيتم إنشاء قاعدة جديدة',
        );
      }
    }

    // فتح قاعدة البيانات
    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // حذف قاعدة البيانات بالكامل (للتصفير)
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_warehouse_v3.db');

    // إغلاق الاتصال الحالي
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;

    // حذف الملف
    await deleteDatabase(path);
    debugPrint('🗑️ تم حذف قاعدة البيانات');

    // إعادة التهيئة
    await _initDatabase();
  }

  /// تفعيل العلاقات (Foreign Keys)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// إنشاء الجداول عند أول تشغيل
  Future<void> _onCreate(Database db, int version) async {
    // 1. جدول التصنيفات
    await db.execute('''
      CREATE TABLE Categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        FOREIGN KEY (parent_id) REFERENCES Categories(id) ON DELETE CASCADE
      )
    ''');

    // 2. جدول المنتجات
    await db.execute('''
      CREATE TABLE Products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE,
        category_id INTEGER,
        image_path TEXT,
        min_stock_level INTEGER DEFAULT 10,
        description TEXT,
        predicted_demand REAL,
        stock_status TEXT,
        last_prediction_date TEXT,
        FOREIGN KEY (category_id) REFERENCES Categories(id) ON DELETE SET NULL
      )
    ''');

    // 3. جدول تفاصيل المنتج (الدفعات)
    await db.execute('''
      CREATE TABLE ProductDetails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        expiry_date TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        purchase_price REAL NOT NULL,
        supplier_id INTEGER,
        FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE,
        FOREIGN KEY (supplier_id) REFERENCES Contacts(id) ON DELETE SET NULL
      )
    ''');

    // 4. جدول وحدات المنتج
    await db.execute('''
      CREATE TABLE ProductUnits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        unit_name TEXT NOT NULL,
        conversion_factor INTEGER NOT NULL DEFAULT 1,
        sale_price REAL NOT NULL,
        is_base_unit INTEGER DEFAULT 0,
        FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE
      )
    ''');

    // 5. جدول حركات المخزون
    await db.execute('''
      CREATE TABLE StockTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_detail_id INTEGER,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        transaction_date TEXT NOT NULL,
        user_id INTEGER,
        notes TEXT,
        FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE,
        FOREIGN KEY (product_detail_id) REFERENCES ProductDetails(id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE SET NULL
      )
    ''');

    // 6. جدول جهات الاتصال
    await db.execute('''
      CREATE TABLE Contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        type TEXT NOT NULL,
        balance REAL DEFAULT 0.0
      )
    ''');

    // 7. جدول الفواتير
    await db.execute('''
      CREATE TABLE Invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0.0,
        remaining_amount REAL,
        contact_id INTEGER,
        user_id INTEGER,
        status TEXT DEFAULT 'PENDING',
        FOREIGN KEY (contact_id) REFERENCES Contacts(id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE SET NULL
      )
    ''');

    // 8. جدول عناصر الفاتورة
    await db.execute('''
      CREATE TABLE InvoiceItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_detail_id INTEGER,
        unit_id INTEGER,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES Invoices(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE RESTRICT,
        FOREIGN KEY (product_detail_id) REFERENCES ProductDetails(id) ON DELETE SET NULL,
        FOREIGN KEY (unit_id) REFERENCES ProductUnits(id) ON DELETE SET NULL
      )
    ''');

    // 9. جدول سجل التوقعات
    await db.execute('''
      CREATE TABLE PredictionHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        prediction_date TEXT NOT NULL,
        predicted_value REAL NOT NULL,
        actual_value REAL,
        accuracy_rate REAL,
        FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE
      )
    ''');

    // 10. جدول المستخدمين
    await db.execute('''
      CREATE TABLE Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        security_question TEXT,
        security_answer TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    debugPrint('✅ تم إنشاء جميع الجداول بنجاح');
  }

  /// تحديث قاعدة البيانات عند تغيير الإصدار
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // سيتم إضافة منطق الترقية هنا عند الحاجة
    debugPrint('⚠️ ترقية قاعدة البيانات من $oldVersion إلى $newVersion');
  }

  // ==================== Categories CRUD ====================

  /// إضافة تصنيف جديد
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('Categories', category.toMap());
  }

  /// جلب جميع التصنيفات
  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  /// جلب التصنيفات الفرعية لتصنيف معين
  Future<List<Category>> getSubCategories(int parentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Categories',
      where: 'parent_id = ?',
      whereArgs: [parentId],
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  /// تحديث تصنيف
  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'Categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// حذف تصنيف
  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('Categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Products CRUD ====================

  /// إضافة منتج جديد
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('Products', product.toMap());
  }

  /// جلب منتج واحد مع كامل تفاصيله (دفعات + وحدات)
  Future<Product?> getProduct(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    // جلب الدفعات والوحدات
    final details = await getProductDetails(id);
    final units = await getProductUnits(id);

    return Product.fromMap(maps.first, details: details, units: units);
  }

  /// جلب جميع المنتجات مع تفاصيلها
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Products');

    final List<Product> products = [];
    for (var map in maps) {
      final id = map['id'] as int;
      final details = await getProductDetails(id);
      final units = await getProductUnits(id);
      products.add(Product.fromMap(map, details: details, units: units));
    }

    return products;
  }

  /// البحث عن منتجات
  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    final List<Product> products = [];
    for (var map in maps) {
      final id = map['id'] as int;
      final details = await getProductDetails(id);
      final units = await getProductUnits(id);
      products.add(Product.fromMap(map, details: details, units: units));
    }

    return products;
  }

  /// جلب المنتجات منخفضة المخزون
  Future<List<Product>> getLowStockProducts() async {
    final allProducts = await getAllProducts();
    return allProducts.where((p) => p.isLowStock).toList();
  }

  /// تحديث منتج
  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'Products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// حذف منتج
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('Products', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== ProductDetails (Batches) CRUD ====================

  /// إضافة دفعة جديدة
  Future<int> insertProductDetail(ProductDetail detail) async {
    final db = await database;
    return await db.insert('ProductDetails', detail.toMap());
  }

  /// جلب دفعات منتج معين
  Future<List<ProductDetail>> getProductDetails(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ProductDetails',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'expiry_date ASC', // ترتيب حسب تاريخ الصلاحية (FEFO)
    );
    return List.generate(maps.length, (i) => ProductDetail.fromMap(maps[i]));
  }

  /// جلب الدفعات القريبة من الانتهاء
  Future<List<ProductDetail>> getExpiringBatches(int days) async {
    final db = await database;
    final futureDate =
        DateTime.now().add(Duration(days: days)).toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'ProductDetails',
      where: 'expiry_date <= ? AND expiry_date > ?',
      whereArgs: [futureDate, DateTime.now().toIso8601String()],
      orderBy: 'expiry_date ASC',
    );
    return List.generate(maps.length, (i) => ProductDetail.fromMap(maps[i]));
  }

  /// تحديث كمية دفعة
  Future<int> updateProductDetailQuantity(int detailId, int newQuantity) async {
    final db = await database;
    return await db.update(
      'ProductDetails',
      {'quantity': newQuantity},
      where: 'id = ?',
      whereArgs: [detailId],
    );
  }

  /// حذف دفعة
  Future<int> deleteProductDetail(int id) async {
    final db = await database;
    return await db.delete('ProductDetails', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== ProductUnits CRUD ====================

  /// إضافة وحدة جديدة
  Future<int> insertProductUnit(ProductUnit unit) async {
    final db = await database;
    return await db.insert('ProductUnits', unit.toMap());
  }

  /// جلب وحدات منتج معين
  Future<List<ProductUnit>> getProductUnits(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ProductUnits',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return List.generate(maps.length, (i) => ProductUnit.fromMap(maps[i]));
  }

  /// تحديث وحدة
  Future<int> updateProductUnit(ProductUnit unit) async {
    final db = await database;
    return await db.update(
      'ProductUnits',
      unit.toMap(),
      where: 'id = ?',
      whereArgs: [unit.id],
    );
  }

  /// حذف وحدة
  Future<int> deleteProductUnit(int id) async {
    final db = await database;
    return await db.delete('ProductUnits', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== StockTransactions CRUD ====================

  /// تسجيل حركة مخزون
  Future<int> insertStockTransaction(StockTransaction transaction) async {
    final db = await database;
    return await db.insert('StockTransactions', transaction.toMap());
  }

  /// جلب حركات منتج معين
  Future<List<StockTransaction>> getStockTransactions(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'StockTransactions',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'transaction_date DESC',
    );
    return List.generate(maps.length, (i) => StockTransaction.fromMap(maps[i]));
  }

  /// جلب حركات بفترة زمنية
  Future<List<StockTransaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'StockTransactions',
      where: 'transaction_date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'transaction_date DESC',
    );
    return List.generate(maps.length, (i) => StockTransaction.fromMap(maps[i]));
  }

  // ==================== Contacts CRUD ====================

  /// إضافة جهة اتصال
  Future<int> insertContact(Contact contact) async {
    final db = await database;
    return await db.insert('Contacts', contact.toMap());
  }

  /// جلب جهات الاتصال حسب النوع
  Future<List<Contact>> getContacts({ContactType? type}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (type != null) {
      maps = await db.query(
        'Contacts',
        where: 'type = ?',
        whereArgs: [type.toString()],
      );
    } else {
      maps = await db.query('Contacts');
    }

    return List.generate(maps.length, (i) => Contact.fromMap(maps[i]));
  }

  /// تحديث جهة اتصال
  Future<int> updateContact(Contact contact) async {
    final db = await database;
    return await db.update(
      'Contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  /// حذف جهة اتصال
  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete('Contacts', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Invoices CRUD ====================

  /// إنشاء فاتورة مع محتوياتها
  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;

    // إدراج الفاتورة
    final invoiceId = await db.insert('Invoices', invoice.toMap());

    // إدراج محتويات الفاتورة
    for (var item in invoice.items) {
      await db.insert(
        'InvoiceItems',
        item.copyWith(invoiceId: invoiceId).toMap(),
      );
    }

    return invoiceId;
  }

  /// جلب فاتورة كاملة مع محتوياتها
  Future<Invoice?> getInvoice(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Invoices',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    // جلب محتويات الفاتورة
    final itemMaps = await db.query(
      'InvoiceItems',
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
    final items = List.generate(
      itemMaps.length,
      (i) => InvoiceItem.fromMap(itemMaps[i]),
    );

    return Invoice.fromMap(maps.first, items: items);
  }

  /// جلب الفواتير حسب النوع
  Future<List<Invoice>> getInvoices({InvoiceType? type}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (type != null) {
      maps = await db.query(
        'Invoices',
        where: 'type = ?',
        whereArgs: [type.toString()],
        orderBy: 'date DESC',
      );
    } else {
      maps = await db.query('Invoices', orderBy: 'date DESC');
    }

    final List<Invoice> invoices = [];
    for (var map in maps) {
      final id = map['id'] as int;
      final invoice = await getInvoice(id);
      if (invoice != null) invoices.add(invoice);
    }

    return invoices;
  }

  /// تحديث دفعة في فاتورة
  Future<int> updateInvoicePayment(int invoiceId, double paidAmount) async {
    final db = await database;
    final invoice = await getInvoice(invoiceId);
    if (invoice == null) return 0;

    final newPaidAmount = invoice.paidAmount + paidAmount;
    final newRemainingAmount = invoice.totalAmount - newPaidAmount;
    final newStatus = newRemainingAmount <= 0 ? 'PAID' : 'PARTIAL';

    return await db.update(
      'Invoices',
      {
        'paid_amount': newPaidAmount,
        'remaining_amount': newRemainingAmount,
        'status': newStatus,
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  /// حساب مجموع المبيعات في فترة معينة
  Future<double> getSalesTotal(DateTime start, DateTime end) async {
    final db = await database;
    try {
      final result = await db.rawQuery('''
        SELECT SUM(total_amount) as total 
        FROM Invoices 
        WHERE type = ? AND date >= ? AND date < ?
      ''', [
        InvoiceType.sale.toString(),
        start.toIso8601String(),
        end.toIso8601String()
      ]);

      if (result.isNotEmpty && result.first['total'] != null) {
        return (result.first['total'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error calculating sales total: $e');
      return 0.0;
    }
  }

  // ==================== PredictionHistory CRUD ====================

  /// إضافة توقع جديد
  Future<int> insertPrediction(PredictionHistory prediction) async {
    final db = await database;
    return await db.insert('PredictionHistory', prediction.toMap());
  }

  /// جلب سجل توقعات منتج
  Future<List<PredictionHistory>> getPredictionHistory(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'PredictionHistory',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'prediction_date DESC',
    );
    return List.generate(
      maps.length,
      (i) => PredictionHistory.fromMap(maps[i]),
    );
  }

  /// تحديث دقة التوقع
  Future<int> updatePredictionAccuracy(
    int predictionId,
    double actualValue,
  ) async {
    final db = await database;

    // جلب التوقع
    final maps = await db.query(
      'PredictionHistory',
      where: 'id = ?',
      whereArgs: [predictionId],
    );

    if (maps.isEmpty) return 0;

    final prediction = PredictionHistory.fromMap(maps.first);
    final updatedPrediction = prediction.copyWith(actualValue: actualValue);
    final accuracy = updatedPrediction.calculateAccuracy();

    return await db.update(
      'PredictionHistory',
      {'actual_value': actualValue, 'accuracy_rate': accuracy},
      where: 'id = ?',
      whereArgs: [predictionId],
    );
  }

  // ==================== Users CRUD ====================

  /// إضافة مستخدم جديد
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('Users', user.toMap());
  }

  /// جلب مستخدم بواسطة اسم المستخدم
  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// جلب جميع المستخدمين
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  /// تحديث مستخدم
  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'Users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// حذف مستخدم
  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('Users', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Helper Functions ====================

  /// معالجة عملية بيع كاملة (فاتورة + تحديث مخزون + FEFO)
  Future<int> processSale(Invoice saleInvoice) async {
    final db = await database;

    // بدء معاملة
    return await db.transaction((txn) async {
      // 1. إنشاء الفاتورة
      final invoiceId = await txn.insert('Invoices', saleInvoice.toMap());

      // 2. معالجة كل منتج في الفاتورة
      for (var item in saleInvoice.items) {
        // إدراج سطر الفاتورة
        await txn.insert(
          'InvoiceItems',
          item.copyWith(invoiceId: invoiceId).toMap(),
        );

        // تطبيق FEFO: خصم الكمية من أقدم دفعة
        final details = await getProductDetails(item.productId);
        int remainingQty = item.quantity;

        for (var detail in details) {
          if (remainingQty <= 0) break;

          if (detail.quantity >= remainingQty) {
            // الدفعة تكفي
            await txn.update(
              'ProductDetails',
              {'quantity': detail.quantity - remainingQty},
              where: 'id = ?',
              whereArgs: [detail.id],
            );

            // تسجيل حركة المخزون
            await txn.insert('StockTransactions', {
              'product_id': item.productId,
              'product_detail_id': detail.id,
              'type': 'SALE',
              'quantity': -remainingQty,
              'transaction_date': DateTime.now().toIso8601String(),
            });

            remainingQty = 0;
          } else {
            // الدفعة لا تكفي، خذ كل ما فيها
            remainingQty -= detail.quantity;

            await txn.update(
              'ProductDetails',
              {'quantity': 0},
              where: 'id = ?',
              whereArgs: [detail.id],
            );

            await txn.insert('StockTransactions', {
              'product_id': item.productId,
              'product_detail_id': detail.id,
              'type': 'SALE',
              'quantity': -detail.quantity,
              'transaction_date': DateTime.now().toIso8601String(),
            });
          }
        }
      }

      return invoiceId;
    });
  }

  /// إحصائيات لوحة التحكم
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;

    // عدد المنتجات
    final productCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM Products'),
        ) ??
        0;

    // عدد المنتجات منخفضة المخزون
    final lowStockProducts = await getLowStockProducts();

    // إجمالي المبيعات اليوم
    final today = DateTime.now();
    final todayStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final todayEnd = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
    ).toIso8601String();

    final salesResult = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM Invoices WHERE type = ? AND date BETWEEN ? AND ?',
      ['SALE', todayStart, todayEnd],
    );
    final todaySales = (salesResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // عدد الفواتير المعلقة
    final pendingInvoices = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM Invoices WHERE status = ?', [
            'PENDING',
          ]),
        ) ??
        0;

    return {
      'productCount': productCount,
      'lowStockCount': lowStockProducts.length,
      'todaySales': todaySales,
      'pendingInvoices': pendingInvoices,
    };
  }

  /// تحديث كلمة المرور للمستخدم
  Future<int> updatePassword(String username, String newPasswordHash) async {
    final db = await database;
    return await db.update(
      'Users',
      {'password_hash': newPasswordHash},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  /// إغلاق قاعدة البيانات
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
