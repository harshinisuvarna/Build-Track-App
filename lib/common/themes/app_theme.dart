import 'package:buildtrack_mobile/common/themes/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global ThemeData + design-system constants for the Nurofin UI.
///
/// All existing screens reference [AppTheme.heading1], [AppTheme.primary], etc.
/// Those constants are kept intact below so zero screens break.
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
  static const Color primary      = AppColors.primaryBlue;
  static const Color primaryLight = AppColors.primaryLightBlue;
  static const Color secondary    = AppColors.primaryPurple;
  static const Color surface      = AppColors.cardBg;
  static const Color background   = AppColors.bgBase1;
  static const Color success      = AppColors.success;
  static const Color warning      = AppColors.warning;
  static const Color error        = AppColors.error;
  static const Color info         = AppColors.info;
  static const Color textDark     = AppColors.textPrimary;
  static const Color textMedium   = AppColors.textMedium;
  static const Color textLight    = AppColors.textSecondary;
  static const Color border       = AppColors.cardBorder;
  static const Color divider      = AppColors.divider;

  // ── Shadows ───────────────────────────────────────────────────────────────
  static const List<BoxShadow> cardShadows = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // ── Background gradient (kept for legacy; prefer NurofinBackground) ───────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bgBase1, AppColors.bgBase3, AppColors.bgBase4],
  );

  // ── Card decoration ───────────────────────────────────────────────────────
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: AppColors.cardBorder, width: 0.5),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0F6C5CE7),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );

  // ── Typography (legacy tokens — kept so existing screens compile) ─────────
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
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
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      primary: AppColors.primaryBlue,
      secondary: AppColors.primaryPurple,
      surface: AppColors.cardBg,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 0,
    ),
    dividerColor: AppColors.divider,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),
  );
}
