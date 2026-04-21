import 'package:buildtrack_mobile/controller/nav_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});
  static const primaryBlue = Color(0xFF2233DD);
  static const textGray = Color(0xFF7B8A9E);
  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, nav, 0, Icons.home_rounded, 'HOME'),
              _navItem(
                context,
                nav,
                1,
                Icons.architecture_outlined,
                'PROJECTS',
              ),
              _entryButton(context, nav),
              _navItem(
                context,
                nav,
                3,
                Icons.inventory_2_outlined,
                'INVENTORY',
              ),
              _navItem(context, nav, 4, Icons.bar_chart_outlined, 'REPORTS'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    NavController nav,
    int index,
    IconData icon,
    String label,
  ) {
    final isActive = nav.index == index;
    return GestureDetector(
      onTap: () => nav.setIndex(index, context),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? primaryBlue : textGray),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isActive ? primaryBlue : textGray,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryButton(BuildContext context, NavController nav) {
    final isActive = nav.index == 2;
    return GestureDetector(
      onTap: () => nav.setIndex(2, context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 3),
          Text(
            'ENTRY',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isActive ? primaryBlue : textGray,
            ),
          ),
        ],
      ),
    );
  }
}
