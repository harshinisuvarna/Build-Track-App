import 'dart:ui' as ui;

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:flutter/material.dart';
class NurofinBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final baseGradient = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      [
        AppColors.bgBase1, // #D8D4F0
        AppColors.bgBase2, // #CAC3ED
        AppColors.bgBase3, // #D2CBF0
        AppColors.bgBase4, // #E8E4F8
      ],
      [0.0, 0.3, 0.65, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = baseGradient);

    // Alignment(0.55, -0.3) → pixel center
    final center2 = Offset(
      size.width * (0.55 + 1) / 2,
      size.height * (-0.3 + 1) / 2,
    );
    final radius2 = size.longestSide * 0.75;
    final glow2 = ui.Gradient.radial(
      center2,
      radius2,
      [
        AppColors.bgGlow1.withValues(alpha: 0.55), // #FFFFFF @ 0.55
        const Color(0xFFEEEAFF).withValues(alpha: 0.30),
        const Color(0xFFD8D0F5).withValues(alpha: 0.0),
      ],
      [0.0, 0.45, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = glow2);

    // Alignment(-0.9, -0.85)
    final center3 = Offset(
      size.width * (-0.9 + 1) / 2,
      size.height * (-0.85 + 1) / 2,
    );
    final radius3 = size.longestSide * 0.70;
    final glow3 = ui.Gradient.radial(
      center3,
      radius3,
      [
        AppColors.bgGlow2.withValues(alpha: 0.45), // #9B8FE8 @ 0.45
        const Color(0xFFB5AAEE).withValues(alpha: 0.20),
        const Color(0xFFD0CAF5).withValues(alpha: 0.0),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = glow3);

    // Alignment(0.85, 0.9)
    final center4 = Offset(
      size.width * (0.85 + 1) / 2,
      size.height * (0.9 + 1) / 2,
    );
    final radius4 = size.longestSide * 0.65;
    final glow4 = ui.Gradient.radial(
      center4,
      radius4,
      [
        AppColors.bgGlow3.withValues(alpha: 0.40), // #CFB8F0 @ 0.40
        const Color(0xFFDDD0F5).withValues(alpha: 0.15),
        const Color(0xFFEDE8FF).withValues(alpha: 0.0),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = glow4);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class NurofinBackground extends StatelessWidget {
  const NurofinBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NurofinBackgroundPainter(),
      child: child,
    );
  }
}
