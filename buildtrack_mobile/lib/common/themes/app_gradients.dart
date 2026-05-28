import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:flutter/material.dart';
class AppGradients {
  AppGradients._();
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
  static const LinearGradient progressBar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryBlue, AppColors.primaryPurple],
    stops: [0.0, 1.0],
  );
  static const LinearGradient authBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.authStart, AppColors.authMid, AppColors.authEnd],
    stops: [0.0, 0.5, 1.0],
  );
  static const LinearGradient navActiveItem = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFEAE6F8), Color(0xFFDDD6F5)],
  );
}
