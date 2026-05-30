import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Dark backgrounds
  static const bg = Color(0xFF0D0D0D);
  static const surface = Color(0xFF161616);
  static const surface2 = Color(0xFF1E1E1E);
  static const surface3 = Color(0xFF252525);

  // Sidebar
  static const sidebar = Color(0xFF111111);
  static const sidebarText = Color(0xFF6B7280);
  static const sidebarActive = Color(0xFF1A1A1A);

  // Borders
  static const border = Color(0xFF2A2A2A);
  static const border2 = Color(0xFF333333);

  // Text
  static const text = Color(0xFFF5F5F5);
  static const text2 = Color(0xFF9CA3AF);
  static const text3 = Color(0xFF6B7280);

  // Accent — neon green + yellow
  static const accent = Color(0xFFAAF255);       // neon green-yellow
  static const accentDim = Color(0xFF1A2B0A);
  static const accentText = Color(0xFF0D0D0D);

  // Semantic
  static const green = Color(0xFF4ADE80);
  static const greenDim = Color(0xFF0D2010);
  static const yellow = Color(0xFFFACC15);
  static const yellowDim = Color(0xFF1F1A00);
  static const blue = Color(0xFF60A5FA);
  static const blueDim = Color(0xFF0A1628);
  static const purple = Color(0xFFA78BFA);
  static const purpleDim = Color(0xFF160D28);
  static const orange = Color(0xFFFB923C);
  static const orangeDim = Color(0xFF201000);
  static const red = Color(0xFFF87171);
  static const redDim = Color(0xFF200A0A);
  static const gold = Color(0xFFFBBF24);

  static Color statusColor(String status) => switch (status) {
    'free' => green,
    'occupied' => red,
    'reserved' => yellow,
    'awaitingBill' => blue,
    'cleared' => text3,
    _ => text3,
  };

  static Color statusBgColor(String status) => switch (status) {
    'free' => greenDim,
    'occupied' => redDim,
    'reserved' => yellowDim,
    'awaitingBill' => blueDim,
    'cleared' => surface2,
    _ => surface2,
  };

  static Color orderStatusColor(String status) => switch (status) {
    'confirmed' => blue,
    'preparing' => orange,
    'ready' => green,
    'billed' => accent,
    'cancelled' => red,
    'served' => purple,
    _ => text3,
  };

  static Color orderStatusBgColor(String status) => switch (status) {
    'confirmed' => blueDim,
    'preparing' => orangeDim,
    'ready' => greenDim,
    'billed' => accentDim,
    'cancelled' => redDim,
    'served' => purpleDim,
    _ => surface2,
  };
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.border, thickness: 1, space: 0),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      elevation: 0,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.accent,
      thumbColor: AppColors.accent,
      inactiveTrackColor: AppColors.surface3,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.surface2),
      ),
    ),
  );
}