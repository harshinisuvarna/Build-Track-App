import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/inventory_provider.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const primaryBlue = AppColors.primary;
  static const bgColor = AppColors.gradientStart;
  static const textDark = AppColors.textDark;
  static const textGray = AppColors.textLight;

  @override
  Widget build(BuildContext context) {
    // Watch the entire provider to access both alerts and loading state
    final inventoryProvider = context.watch<InventoryProvider>();
    final alerts = inventoryProvider.lowStockAlerts;
    final isLoading = inventoryProvider.isLoading;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Notifications',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today',
                          style: AppTheme.heading2.copyWith(color: textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isLoading
                                ? '...'
                                : '${alerts.isNotEmpty ? alerts.length : "NO"} ALERTS',
                            style: AppTheme.label.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // --- Dynamic UI Alert Generation with Loading State ---
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: CircularProgressIndicator(color: primaryBlue),
                        ),
                      )
                    else if (inventoryProvider.error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Failed to load notifications",
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              inventoryProvider.error,
                              style: const TextStyle(
                                color: textGray,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (alerts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "All inventory levels are looking healthy! 🎉",
                          style: TextStyle(color: textGray, fontSize: 14),
                        ),
                      )
                    else
                      ...alerts.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _dynamicInventoryWarningCard(
                            title: 'Low Stock: ${item.name}',
                            body:
                                'Only ${item.closingStock} ${item.unit} remaining (Threshold: ${item.threshold}). Re-order is recommended to avoid site delays.',
                            onTap: () {
                              final pId =
                                  context
                                      .read<ProjectProvider>()
                                      .selectedProject
                                      ?.id ??
                                  '';
                              Navigator.pushNamed(
                                context,
                                '/logs',
                                arguments: {
                                  'type': item.category,
                                  'name': item.name,
                                  'projectId': pId,
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dynamicInventoryWarningCard({
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: const Border(
            left: BorderSide(color: Colors.orange, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.06),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EE),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                Text(
                  'Just now',
                  style: AppTheme.caption.copyWith(color: textGray),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'INVENTORY WARNING',
                  style: AppTheme.label.copyWith(
                    color: Colors.orange,
                    fontSize: 10,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: AppTheme.heading3.copyWith(color: textDark, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: AppTheme.body.copyWith(color: textGray, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
