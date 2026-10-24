import 'package:flutter/material.dart';

/// Palette: the official, sober look of the Syrian borders authority's site
/// (deep green-black, gold markers, silver titles) with MIDTRANS blue for the
/// MIDTRANS actions. The authority's emblem and logo appear with its written permission.
class AppColors {
  static const ground = Color(0xFF0B2523);
  static const surface = Color(0xFF13302E);
  static const bar = Color(0xFF1B3533);
  static const line = Color(0xFF2E4A47);
  static const gold = Color(0xFFB9A67D);
  static const goldText = Color(0xFFD9C9A0);
  static const text = Color(0xFFE8ECEB);
  static const muted = Color(0xFFA9B8B5);
  static const midtransBlue = Color(0xFF007DC5);
  static const warn = Color(0xFFE9B872);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: AppColors.ground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.ground,
      secondary: AppColors.midtransBlue,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      outline: AppColors.line,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bar,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.bar,
      indicatorColor: AppColors.gold.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.goldText, width: 1.6)),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.line)),
    ),
    dividerColor: AppColors.line,
  );
}

/// Code style: tabular digits, read left to right even in Arabic.
const codeStyle = TextStyle(fontFamily: 'Cairo', fontFeatures: [FontFeature.tabularFigures()], fontWeight: FontWeight.w700, color: AppColors.goldText, letterSpacing: 0.5);
