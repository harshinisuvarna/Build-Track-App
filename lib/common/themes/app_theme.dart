import 'package:flutter/material.dart';

/// Central design system — colors, typography, and ThemeData.
/// No business logic. Import this file wherever UI tokens are needed.
class AppTheme {
  AppTheme._(); // prevent instantiation

  // ── Color Palette ──────────────────────────────────────────────────────────
  static const Color background  = Color(0xFFF5F7FB);
  static const Color primary     = Color(0xFF1E3A8A);
  static const Color secondary   = Color(0xFF3B82F6);
  static const Color surface     = Color(0xFFFFFFFF);

  static const Color textDark    = Color(0xFF0F172A);
  static const Color textMedium  = Color(0xFF475569);
  static const Color textLight   = Color(0xFF94A3B8);

  static const Color success     = Color(0xFF22C55E);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color error       = Color(0xFFEF4444);

  static const Color divider     = Color(0xFFE2E8F0);
  static const Color cardShadow  = Color(0x14000000); // 8 % black

  // ── Radii ─────────────────────────────────────────────────────────────────
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 24.0;

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ── Text Styles ───────────────────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textDark,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: textDark,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textDark,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textMedium,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textLight,
    letterSpacing: 0.2,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: textLight,
    letterSpacing: 0.8,
  );

  // ── Card Shadow ───────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadows => const [
    BoxShadow(
      color: cardShadow,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surface,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: primary,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: divider, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: divider, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: secondary, width: 1.8),
      ),
      labelStyle: body,
      hintStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        color: textLight,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: divider,
      thickness: 1,
      space: 1,
    ),
  );
}
