import 'package:flutter/material.dart';

/// YessFish App Theme - Ocean Theme
/// Matching the current PHP app's ocean-inspired color palette
class AppTheme {
  // Ocean Color Palette
  static const Color ocean50 = Color(0xFFF0F7FF);
  static const Color ocean100 = Color(0xFFE0EFFF);
  static const Color ocean200 = Color(0xFFBADBFF);
  static const Color ocean300 = Color(0xFF7CBEFF);
  static const Color ocean400 = Color(0xFF369DFF);
  static const Color ocean500 = Color(0xFF0D84FF);
  static const Color ocean600 = Color(0xFF0066FF);
  static const Color ocean700 = Color(0xFF0052E0);
  static const Color ocean800 = Color(0xFF0642B5);
  static const Color ocean900 = Color(0xFF0A3A8E);

  // Neutral Colors
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Coral (Accent) Colors
  static const Color coral50 = Color(0xFFFFF1F2);
  static const Color coral100 = Color(0xFFFFE4E6);
  static const Color coral200 = Color(0xFFFECDD3);
  static const Color coral300 = Color(0xFFFDA4AF);
  static const Color coral400 = Color(0xFFFB7185);
  static const Color coral500 = Color(0xFFF43F5E);
  static const Color coral600 = Color(0xFFE11D48);
  static const Color coral700 = Color(0xFFBE123C);
  static const Color coral800 = Color(0xFF9F1239);
  static const Color coral900 = Color(0xFF881337);

  // Success/Error/Warning Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  /// Light Theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: ocean600,
        onPrimary: Colors.white,
        primaryContainer: ocean100,
        onPrimaryContainer: ocean900,

        secondary: coral500,
        onSecondary: Colors.white,
        secondaryContainer: coral100,
        onSecondaryContainer: coral900,

        tertiary: Color(0xFF10B981), // Success green
        onTertiary: Colors.white,

        error: error,
        onError: Colors.white,

        surface: neutral50,
        onSurface: neutral900,
        surfaceContainerHighest: neutral100,

        outline: neutral300,
        outlineVariant: neutral200,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: ocean600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        surfaceTintColor: ocean50,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ocean600,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ocean600,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ocean600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: ocean600,
        unselectedItemColor: neutral400,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ocean600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: ocean100,
        selectedColor: ocean600,
        labelStyle: const TextStyle(
          color: ocean700,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: neutral200,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: neutral700,
        size: 24,
      ),
    );
  }

  /// Dark Theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: ocean400,
        onPrimary: neutral900,
        primaryContainer: ocean700,
        onPrimaryContainer: ocean100,

        secondary: coral400,
        onSecondary: neutral900,
        secondaryContainer: coral700,
        onSecondaryContainer: coral100,

        tertiary: Color(0xFF34D399), // Success green (lighter for dark mode)
        onTertiary: neutral900,

        error: Color(0xFFF87171), // Lighter error for dark mode
        onError: neutral900,

        surface: neutral900,
        onSurface: neutral50,
        surfaceContainerHighest: neutral800,

        outline: neutral600,
        outlineVariant: neutral700,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: neutral900,
        foregroundColor: neutral50,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: neutral800,
        surfaceTintColor: ocean900,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ocean600,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ocean400,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutral800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutral700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ocean400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: neutral900,
        selectedItemColor: ocean400,
        unselectedItemColor: neutral500,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ocean600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: ocean800,
        selectedColor: ocean600,
        labelStyle: const TextStyle(
          color: ocean200,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: neutral700,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: neutral300,
        size: 24,
      ),
    );
  }
}
