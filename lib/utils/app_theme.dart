import 'package:flutter/material.dart';

class AppTheme {
  // تعريف الثيم الفاتح
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BCD4), // Cyan
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.grey[50], // خلفية فاتحة
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF00BCD4), // Cyan
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    fontFamily: 'Cairo',
  );

  // تعريف الثيم الداكن
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BCD4),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212), // خلفية داكنة
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[850],
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    fontFamily: 'Cairo',
  );
}
