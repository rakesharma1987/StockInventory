import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF2E7D32); // green - "stock" branding
  static const Color danger = Color(0xFFC62828);
  static const Color warning = Color(0xFFF9A825);

  static ThemeData light() {
    final base = ColorScheme.fromSeed(seedColor: primary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: base.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: base.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
