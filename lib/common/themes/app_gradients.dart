import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:flutter/material.dart';

/// All gradient definitions for the Nurofin design system.
///
/// NEVER define a gradient inline in a widget file.
/// Always reference this class.
class AppGradients {
  AppGradients._();

  /// Blue → Purple → Light-Blue — used for primary action buttons.
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.primaryBlue,
      AppColors.primaryPurple,
      AppColors.primaryLightBlue,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Blue → Purple — used for progress bar fills.
  static const LinearGradient progressBar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryBlue, AppColors.primaryPurple],
    stops: [0.0, 1.0],
  );

  /// Diagonal lavender sweep — used on auth / login screens.
  static const LinearGradient authBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.authStart, AppColors.authMid, AppColors.authEnd],
    stops: [0.0, 0.5, 1.0],
  );

  /// Soft left-to-right highlight — used for the active nav item background.
  static const LinearGradient navActiveItem = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFEAE6F8), Color(0xFFDDD6F5)],
  );
}
