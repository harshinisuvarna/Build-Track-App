import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/controller/nav_controller.dart';
import 'package:flutter/material.dart';
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

  static const _primaryBlue = AppColors.primary;
  static const _textDark    = AppColors.textDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            // â”€â”€ Left side â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            leftIcon != null
                ? Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: onLeftTap,
                      child: Padding(
                        padding: const EdgeInsets.all(10), // 44px total target
                        child: Icon(leftIcon, color: _textDark, size: 24),
                      ),
                    ),
                  )
                : const SizedBox(width: 44),

            // â”€â”€ Centre: title fills remaining space, text centred â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSubScreen ? _textDark : _primaryBlue,
                  fontSize: isSubScreen ? 17 : 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // â”€â”€ Right side â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            IntrinsicWidth(
              child: rightWidget ?? const SizedBox(width: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// AppBottomNav
// Single source of truth for bottom navigation across all main screens.
// Reads and writes NavController via Provider.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  static const _primaryBlue = AppColors.primary;
  static const _textGray    = AppColors.textLight;

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _navItem(context, nav, 0, Icons.home_rounded, 'HOME'),
              _navItem(
                  context, nav, 1, Icons.architecture_outlined, 'PROJECTS'),
              _entryButton(context, nav),
              _navItem(
                  context, nav, 3, Icons.inventory_2_outlined, 'INVENTORY'),
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
    return InkWell(
      onTap: () => nav.setIndex(index, context),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive ? _primaryBlue : _textGray,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isActive ? _primaryBlue : _textGray,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entryButton(BuildContext context, NavController nav) {
    final isActive = nav.index == 2;
    return InkWell(
      onTap: () => nav.setIndex(2, context),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryButton,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withValues(alpha: 0.4),
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
              color: isActive ? _primaryBlue : _textGray,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
