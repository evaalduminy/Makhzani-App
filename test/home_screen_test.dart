import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:makhzani_app/home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for sqflite to allow database calls in tests if needed
  // This might be needed if ProductsScreen is loaded
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('HomeScreen UI Verification', (WidgetTester tester) async {
    // Build HomeScreen
    await tester.pumpWidget(const MaterialApp(
      home: HomeScreen(),
    ));

    // 1. Verify AppBar
    expect(find.text('مخزني'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    // 2. Verify BottomNavigationBar
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('المنتجات'), findsOneWidget);
    expect(find.text('المعاملات'), findsOneWidget);
    expect(find.text('التقارير'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);

    // 3. Verify Initial Body (DashboardTab)
    // DashboardTab has "ملخص اليوم" text
    expect(find.text('ملخص اليوم'), findsOneWidget);
    // And static stats
    expect(find.text('إجمالي المبيعات'), findsOneWidget);
    expect(find.text('1,250 ر.س'), findsOneWidget);
    expect(find.text('تنبيهات المخزون'), findsOneWidget);
    expect(find.text('5 منتجات'), findsOneWidget);

    // 4. Verify Navigation to Products Tab
    // Tap on "المنتجات"
    await tester.tap(find.text('المنتجات'));
    await tester.pumpAndSettle();

    // Verify that we are on the Products screen
    // ProductsScreen has an AppBar with title 'المخزون'
    expect(find.text('المخزون'), findsOneWidget);

    // Note: Since ProductsScreen loads data from DB, it might show loading indicator or empty state
    // depending on the DB state. Since we are using FFI with likely an empty in-memory DB or similar,
    // it might show "لا توجد منتجات" or just load.
    // Let's check for the FloatingActionButton which is always there
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
