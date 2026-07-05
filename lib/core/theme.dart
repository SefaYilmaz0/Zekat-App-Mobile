import 'package:flutter/material.dart';

class AppTheme {
  // Colors from Web App (Tailwind Config)
  static const Color primary = Color(0xFFEEBD2B);
  static const Color primaryDark = Color(0xFFD4A720);
  static const Color primaryLight = Color(0xFFFFF5D6);
  
  static const Color backgroundLight = Color(0xFFF8F7F6);
  static const Color backgroundDark = Color(0xFF221D10);
  
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2D2616);
  
  static const Color textMainLight = Color(0xFF3F3A2C);
  static const Color textMainDark = Color(0xFFE8E6E1); // Derived light text for dark mode
  
  static const Color textMuted = Color(0xFF858071);

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
        background: backgroundLight,
        onPrimary: textMainLight,
        onSecondary: Colors.white,
        onSurface: textMainLight,
        onBackground: textMainLight,
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
        background: backgroundDark,
        onPrimary: textMainDark,
        onSecondary: Colors.white,
        onSurface: textMainDark,
        onBackground: textMainDark,
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
