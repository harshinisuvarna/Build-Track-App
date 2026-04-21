import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTopBar extends StatelessWidget {
  final String title;
  final Widget? rightWidget;
  const AppTopBar({super.key, required this.title, this.rightWidget});
  static const primaryBlue = Color(0xFF2233DD);
  static const textDark = Color(0xFF0F1724);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: primaryBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          rightWidget ?? const SizedBox(width: 24),
        ],
      ),
    );
  }
}
