import 'package:flutter/foundation.dart';
import '../models/stock_transaction_model.dart';
import '../models/invoice_model.dart';
import '../models/product_detail_model.dart';
import 'database_helper.dart';

/// خدمة المعاملات المالية والمخزنية
/// Transaction Service - Handles Sales, Purchases, and Stock adjustments
class TransactionService {
  final _dbHelper = DatabaseHelper();

  // ============ معالجة المبيعات (Sales Processing) ============

  /// إتمام عملية بيع
  /// تقوم بإنشاء الفاتورة وتحديث المخزون (FEFO) تلقائياً
  Future<bool> processSale(Invoice invoice) async {
    try {
      if (invoice.items.isEmpty) throw Exception('الفاتورة فارغة');

      // التحقق من توفر الكميات قبل البدء (Extra Validation Layer)
      // ملاحظة: DatabaseHelper يقوم بمعالجة الخصم، لكن التحقق هنا مفيد للواجهة

      final invoiceId = await _dbHelper.processSale(invoice);
      return invoiceId > 0;
    } catch (e) {
      debugPrint('Error processing sale: $e');
      return false;
    }
  }

  // ============ سجل الحركات (Transaction History) ============

  /// جلب أحدث الحركات (بيع، شراء، تعديل)
  Future<List<StockTransaction>> getRecentTransactions(int limit) async {
    // حالياً نجلب كل الحركات ونفلترها (يمكن تحسينها بـ Limit في الـ SQL لاحقاً)
    final all = await getAllTransactions();
    return all.take(limit).toList();
  }

  /// جلب جميع الحركات
  // ملاحظة: نحتاج دالة عامة في DatabaseHelper لجلب كل الحركات،
  // حالياً سنستخدم الحركات المرتبطة بالمنتجات، او سنضيف دالة جديدة.
  // للتبسيط، سنعتمد على getTransactionsByDateRange لفترة طويلة
  Future<List<StockTransaction>> getAllTransactions() async {
    final start = DateTime(2020); // تاريخ قديم
    final end = DateTime.now().add(const Duration(days: 1));
    return await _dbHelper.getTransactionsByDateRange(start, end);
  }

  /// جلب الحركات خلال فترة معينة
  Future<List<StockTransaction>> getTransactionsByDate(
      DateTime start, DateTime end) async {
    return await _dbHelper.getTransactionsByDateRange(start, end);
  }

  // ============ التقارير المالية المبسطة (Basic Financials) ============

  /// حساب إجمالي المبيعات لليوم
  Future<double> getDailySalesTotal(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _dbHelper.getSalesTotal(start, end);
  }

  /// حساب إجمالي المبيعات للأسبوع
  Future<double> getWeeklySalesTotal(DateTime date) async {
    // تحديد بداية الأسبوع (السبت مثلاً)
    final start = date.subtract(Duration(days: date.weekday % 7));
    final end = start.add(const Duration(days: 7));
    return _dbHelper.getSalesTotal(start, end);
  }

  /// حساب إجمالي المبيعات للشهر
  Future<double> getMonthlySalesTotal(DateTime date) async {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 1);
    return _dbHelper.getSalesTotal(start, end);
  }

  /// جلب بيانات المبيعات الشهرية لآخر [months] أشهر
  Future<List<double>> getMonthlySalesHistory(int months) async {
    final List<double> history = [];
    final now = DateTime.now();
    for (int i = months - 1; i >= 0; i--) {
      // حساب الشهر
      final date = DateTime(now.year, now.month - i, 1);
      final total = await getMonthlySalesTotal(date);
      history.add(total);
    }
    return history;
  }

  /// تسجيل عملية شراء (توريد)
  Future<bool> recordPurchase(ProductDetail newBatch) async {
    try {
      final batchId = await _dbHelper.insertProductDetail(newBatch);
      if (batchId > 0) {
        final transaction = StockTransaction(
          productId: newBatch.productId,
          productDetailId: batchId,
          type: StockTransactionType.purchase,
          quantity: newBatch.quantity,
          transactionDate: DateTime.now(),
          notes: 'Purchase / توريد جديد',
        );
        await _dbHelper.insertStockTransaction(transaction);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error recording purchase: $e');
      return false;
    }
  }

  /// تسجيل حركة تعديل مخزون (تلف، جرد، إلخ)
  Future<bool> recordAdjustment(StockTransaction transaction) async {
    try {
      if (transaction.type == StockTransactionType.purchase ||
          transaction.type == StockTransactionType.sale) {
        throw ArgumentError(
            'Use recordPurchase or processSale for these types');
      }

      final id = await _dbHelper.insertStockTransaction(transaction);
      return id > 0;
    } catch (e) {
      debugPrint('Error recording adjustment: $e');
      return false;
    }
  }

  /// جلب سجل المعاملات مع تفاصيل المنتج (للعرض في الواجهة)
  Future<List<Map<String, dynamic>>> getAllTransactionsWithDetails() async {
    try {
      final db = await _dbHelper.database;
      return await db.rawQuery('''
        SELECT 
          st.id,
          st.type,
          st.quantity,
          st.transaction_date,
          st.notes,
          p.name as product_name,
          p.barcode,
          c.name as category_name
        FROM StockTransactions st
        LEFT JOIN Products p ON st.product_id = p.id
        LEFT JOIN Categories c ON p.category_id = c.id
        ORDER BY st.transaction_date DESC
        LIMIT 100
      ''');
    } catch (e) {
      debugPrint('Error loading transaction history: $e');
      return [];
    }
  }

  /// جلب سجل المبيعات اليومية (آخر X أيام)
  Future<List<double>> getDailySalesHistory(int days) async {
    try {
      final List<double> salesData = [];
      final now = DateTime.now();

      for (int i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final total = await _dbHelper.getSalesTotal(dayStart, dayEnd);
        salesData.add(total);
      }

      return salesData;
    } catch (e) {
      debugPrint('Error fetching daily sales history: $e');
      return List.filled(days, 0.0);
    }
  }

  /// جلب سجل المبيعات الأسبوعية (آخر X أسابيع)
  Future<List<double>> getWeeklySalesHistory(int weeks) async {
    try {
      final List<double> salesData = [];
      final now = DateTime.now();

      for (int i = weeks - 1; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: (i + 1) * 7));
        final weekEnd = weekStart.add(const Duration(days: 7));

        final total = await _dbHelper.getSalesTotal(weekStart, weekEnd);
        salesData.add(total);
      }

      return salesData;
    } catch (e) {
      debugPrint('Error fetching weekly sales history: $e');
      return List.filled(weeks, 0.0);
    }
  }
}
