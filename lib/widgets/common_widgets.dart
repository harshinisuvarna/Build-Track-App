import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTopBar extends StatelessWidget {
  final String title;
  final IconData? leftIcon;
  final VoidCallback? onLeftTap;
  final Widget? rightWidget;
  final bool isSubScreen; 
  const AppTopBar({
    super.key,
    required this.title,
    this.leftIcon,
    this.onLeftTap,
    this.rightWidget,
    this.isSubScreen = false,
  });
  static const primaryBlue = Color(0xFF2233DD);
  static const textDark = Color(0xFF0F1724);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (leftIcon != null)
            GestureDetector(
              onTap: onLeftTap,
              child: Icon(leftIcon, color: textDark, size: 22),
            )
          else
            const SizedBox(width: 24),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: isSubScreen ? textDark : primaryBlue,
                  fontSize: isSubScreen ? 17 : 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          rightWidget ?? const SizedBox(width: 24),
        ],
      ),
    );
  }
}
