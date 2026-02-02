import 'package:flutter/material.dart';

/// ثيم التطبيق - App Theme
class AppTheme {
  // ألوان التطبيق
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  /// الثيم الفاتح للتطبيق
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',

      // مخطط الألوان
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
      ),

      // لون الخلفية
      scaffoldBackgroundColor: backgroundColor,

      // شريط التطبيق
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // البطاقات
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
      ),

      // الأزرار العائمة
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // حقول الإدخال
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade500),
      ),

      // القوائم
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: textSecondary,
        ),
      ),

      // الحوارات
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),

      // شريط التنقل السفلي
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
        unselectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
      ),

      // الرقائق
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade200,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // شريط القصاصات
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentTextStyle: const TextStyle(fontFamily: 'Cairo'),
      ),

      // التبويبات
      tabBarTheme: const TabBarThemeData(
        labelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontFamily: 'Cairo'),
      ),

      // النص
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'Cairo'),
        bodyMedium: TextStyle(fontFamily: 'Cairo'),
        bodySmall: TextStyle(fontFamily: 'Cairo'),
        labelLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        labelMedium: TextStyle(fontFamily: 'Cairo'),
        labelSmall: TextStyle(fontFamily: 'Cairo'),
      ),
    );
  }
}
