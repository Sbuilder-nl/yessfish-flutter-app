import 'package:flutter/material.dart';
import 'config.dart';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.teal, primary: AppColors.teal);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy, foregroundColor: Colors.white, elevation: 0, centerTitle: false,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18), textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.teal,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16), textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        side: const BorderSide(color: Color(0xFFCBD5E1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.teal, textStyle: const TextStyle(fontWeight: FontWeight.w600)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.teal, foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bg, side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating, backgroundColor: AppColors.navy,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFEDF2F4), thickness: 1),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.teal),
    cardTheme: CardThemeData(
      elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
    ),
  );
}
