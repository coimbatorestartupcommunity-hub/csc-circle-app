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

class CscPalette extends ThemeExtension<CscPalette> {
  const CscPalette({
    required this.canvas,
    required this.surface,
    required this.ink,
    required this.secondary,
    required this.muted,
    required this.border,
    required this.accent,
    required this.lavender,
    required this.pink,
    required this.blue,
    required this.gold,
    required this.goldInk,
    required this.inverseSurface,
    required this.inverseInk,
  });

  final Color canvas;
  final Color surface;
  final Color ink;
  final Color secondary;
  final Color muted;
  final Color border;
  final Color accent;
  final Color lavender;
  final Color pink;
  final Color blue;
  final Color gold;
  final Color goldInk;
  final Color inverseSurface;
  final Color inverseInk;

  static const light = CscPalette(
    canvas: Color(0xFFF7F9FC),
    surface: Colors.white,
    ink: Color(0xFF121826),
    secondary: Color(0xFF334155),
    muted: Color(0xFF52677C),
    border: Color(0xFFDFE7EF),
    accent: Color(0xFF6D4AFF),
    lavender: Color(0xFFF1ECFF),
    pink: Color(0xFFFCEAF3),
    blue: Color(0xFFE7F3FF),
    gold: Color(0xFFFFF4D9),
    goldInk: Color(0xFF33270D),
    inverseSurface: Color(0xFF121826),
    inverseInk: Colors.white,
  );

  static const dark = CscPalette(
    canvas: Color(0xFF11131B),
    surface: Color(0xFF1A1D28),
    ink: Color(0xFFF5F2FF),
    secondary: Color(0xFFD4D0E1),
    muted: Color(0xFFB5B1C5),
    border: Color(0xFF343746),
    accent: Color(0xFFB9A6FF),
    lavender: Color(0xFF29243A),
    pink: Color(0xFF33232F),
    blue: Color(0xFF202D3B),
    gold: Color(0xFF342B1D),
    goldInk: Color(0xFFFFE8B1),
    inverseSurface: Color(0xFFEDE8FA),
    inverseInk: Color(0xFF171521),
  );

  static CscPalette of(BuildContext context) =>
      Theme.of(context).extension<CscPalette>() ?? light;

  @override
  CscPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? ink,
    Color? secondary,
    Color? muted,
    Color? border,
    Color? accent,
    Color? lavender,
    Color? pink,
    Color? blue,
    Color? gold,
    Color? goldInk,
    Color? inverseSurface,
    Color? inverseInk,
  }) => CscPalette(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    ink: ink ?? this.ink,
    secondary: secondary ?? this.secondary,
    muted: muted ?? this.muted,
    border: border ?? this.border,
    accent: accent ?? this.accent,
    lavender: lavender ?? this.lavender,
    pink: pink ?? this.pink,
    blue: blue ?? this.blue,
    gold: gold ?? this.gold,
    goldInk: goldInk ?? this.goldInk,
    inverseSurface: inverseSurface ?? this.inverseSurface,
    inverseInk: inverseInk ?? this.inverseInk,
  );

  @override
  CscPalette lerp(ThemeExtension<CscPalette>? other, double t) {
    if (other is! CscPalette) return this;
    return CscPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      lavender: Color.lerp(lavender, other.lavender, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldInk: Color.lerp(goldInk, other.goldInk, t)!,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t)!,
      inverseInk: Color.lerp(inverseInk, other.inverseInk, t)!,
    );
  }
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

ThemeData buildCscTheme({Brightness brightness = Brightness.light}) {
  final palette = brightness == Brightness.dark
      ? CscPalette.dark
      : CscPalette.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: CscColors.accent,
    brightness: brightness,
    primary: palette.ink,
    secondary: palette.accent,
    surface: palette.surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.canvas,
    fontFamily: 'Poppins',
    textTheme: TextTheme().apply(
      fontFamily: 'Poppins',
      bodyColor: palette.ink,
      displayColor: palette.ink,
    ),
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: palette.canvas,
      foregroundColor: palette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CscRadius.card),
        side: BorderSide(color: palette.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.ink,
        foregroundColor: palette.inverseInk,
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
        foregroundColor: palette.ink,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CscRadius.control),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.lavender,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? palette.ink : palette.muted,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
      height: 74,
    ),
    dividerColor: palette.border,
    visualDensity: VisualDensity.standard,
  );
}
