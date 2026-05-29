import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFFF8F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const sidebar = Color(0xFF1A1A2E);
  static const sidebarDark = Color(0xFF16213E);
  static const border = Color(0xFFE8EAED);
  static const border2 = Color(0xFFD1D5DB);
  static const text = Color(0xFF111827);
  static const text2 = Color(0xFF6B7280);
  static const text3 = Color(0xFF9CA3AF);
  static const accent = Color(0xFFE8534A);
  static const gold = Color(0xFFF59E0B);
  static const green = Color(0xFF10B981);
  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const orange = Color(0xFFF97316);
  static const red = Color(0xFFEF4444);
  static const sidebarText = Color(0xB3FFFFFF);
  static const sidebarActive = Color(0x26FFFFFF);

  static Color statusColor(String status) => switch (status) {
    'free' => green,
    'occupied' => red,
    'reserved' => orange,
    'awaitingBill' => blue,
    'cleared' => text3,
    _ => text3,
  };

  static Color orderStatusColor(String status) => switch (status) {
    'confirmed' => blue,
    'preparing' => orange,
    'ready' => green,
    'billed' => green,
    'cancelled' => red,
    'served' => purple,
    _ => text3,
  };
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      surface: AppColors.surface,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 0),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
    ),
  );
}