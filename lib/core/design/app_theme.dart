import 'package:flutter/material.dart';

abstract final class CscColors {
  static const white = Color(0xFFFFFFFF);
  static const cloud = Color(0xFFF7F9FC);
  static const purple = Color(0xFFF1ECFF);
  static const lilac = Color(0xFFEDE7F6);
  static const pink = Color(0xFFFCEAF3);
  static const blue = Color(0xFFE7F3FF);
  static const gold = Color(0xFFFFF4D9);
  static const ink = Color(0xFF121826);
  static const secondary = Color(0xFF334155);
  static const muted = Color(0xFF52677C);
  static const border = Color(0xFFDFE7EF);
  static const accent = Color(0xFF6D4AFF);
}

abstract final class CscSpacing {
  static const xs = 6.0;
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class CscRadius {
  static const card = 24.0;
  static const control = 16.0;
  static const pill = 999.0;
}

ThemeData buildCscTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: CscColors.accent,
    brightness: Brightness.light,
    primary: CscColors.ink,
    secondary: CscColors.accent,
    surface: CscColors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: CscColors.cloud,
    fontFamily: 'Poppins',
    textTheme: const TextTheme().apply(
      fontFamily: 'Poppins',
      bodyColor: CscColors.ink,
      displayColor: CscColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: CscColors.cloud,
      foregroundColor: CscColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: CscColors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CscRadius.card),
        side: const BorderSide(color: CscColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CscColors.ink,
        foregroundColor: CscColors.white,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CscRadius.control),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CscColors.ink,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        side: const BorderSide(color: CscColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CscRadius.control),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CscColors.white,
      indicatorColor: CscColors.purple,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? CscColors.ink : CscColors.muted,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
      height: 74,
    ),
    dividerColor: CscColors.border,
    visualDensity: VisualDensity.standard,
  );
}
