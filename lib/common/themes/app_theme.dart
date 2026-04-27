import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // ── Radius ────────────────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // ── Color shorthands (all delegate to AppColors) ──────────────────────────
  static const Color primary      = AppColors.primary;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color secondary    = AppColors.primaryLight; // lighter brand accent
  static const Color surface      = AppColors.cardBg;
  static const Color background   = AppColors.gradientStart;
  static const Color success      = AppColors.success;
  static const Color warning      = AppColors.warning;
  static const Color error        = AppColors.error;
  static const Color info         = AppColors.info;
  static const Color textDark     = AppColors.textDark;
  static const Color textMedium   = AppColors.textMedium;
  static const Color textLight    = AppColors.textLight;
  static const Color border       = AppColors.border;
  static const Color divider      = AppColors.divider;

  // ── Shadows ───────────────────────────────────────────────────────────────
  static const List<BoxShadow> cardShadows = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // ── Background gradient ───────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gradientStart, AppColors.gradientMid, AppColors.gradientEnd],
  );

  // ── Card decoration ───────────────────────────────────────────────────────
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: AppColors.border, width: 0.5),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0F6C5CE7),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );

  // ── Typography ────────────────────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
    letterSpacing: 0.3,
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.primary,
    textTheme: GoogleFonts.interTextTheme(),
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: AppColors.gradientStart,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cardBg,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
        letterSpacing: -0.3,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 0,
    ),
  );
}
