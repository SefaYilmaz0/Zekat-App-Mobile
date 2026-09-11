import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary Gold / Amber
  static const Color primary = Color(0xFFF3A712);
  static const Color primaryDark = Color(0xFFD97706);
  static const Color primaryLight = Color(0xFFFEF3C7);
  static const Color primaryMuted = Color(0xFFFFFBEB);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF8F7F6);
  static const Color backgroundDark = Color(0xFF1E1B18);

  // Surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2A2418);

  // Borders
  static const Color borderLight = Color(0xFFEFECE6);
  static const Color borderDark = Color(0x26FFFFFF);

  // Text
  static const Color textMainLight = Color(0xFF3F3A2C);
  static const Color textMainDark = Color(0xFFE8E6E1);
  static const Color textMuted = Color(0xFF858071);
  static const Color textSubtle = Color(0xFFA8A29E);

  // Status & Categories
  static const Color debtRed = Color(0xFFEF4444);
  static const Color debtRedBgLight = Color(0xFFFEF2F2);
  static const Color debtRedBgDark = Color(0xFF3F1C1C);

  static const Color green = Color(0xFF10B981);
  static const Color greenLight = Color(0xFFD1FAE5);

  static const Color blue = Color(0xFF3B82F6);
  static const Color blueLight = Color(0xFFDBEAFE);
}

class AppTheme {
  // Colors from Web App & AppTokens
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color primaryLight = AppColors.primaryLight;
  
  static const Color backgroundLight = AppColors.backgroundLight;
  static const Color backgroundDark = AppColors.backgroundDark;
  
  static const Color surfaceLight = AppColors.surfaceLight;
  static const Color surfaceDark = AppColors.surfaceDark;
  
  static const Color textMainLight = AppColors.textMainLight;
  static const Color textMainDark = AppColors.textMainDark;
  
  static const Color textMuted = AppColors.textMuted;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: surfaceLight,
        onPrimary: textMainLight,
        onSecondary: Colors.white,
        onSurface: textMainLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: textMainLight,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryDark,
        unselectedItemColor: textMuted,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textMainLight, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textMainLight),
        bodyMedium: TextStyle(color: textMainLight),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryDark,
        surface: surfaceDark,
        onPrimary: textMainDark,
        onSecondary: Colors.white,
        onSurface: textMainDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textMainDark,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textMainDark, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textMainDark),
        bodyMedium: TextStyle(color: textMainDark),
      ),
    );
  }
}

