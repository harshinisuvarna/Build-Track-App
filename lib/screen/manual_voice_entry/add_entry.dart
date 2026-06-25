import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/controller/role_manager.dart';

class AddEntryScreen extends StatelessWidget {
  const AddEntryScreen({super.key});
  static const primaryBlue = AppColors.primary;
  static const purple = AppColors.primary;
  static const bgColor = AppColors.gradientStart;
  static const textDark = AppColors.textDark;
  static const textGray = AppColors.textLight;
  List<Map<String, dynamic>> get _entries {
    final items = <Map<String, dynamic>>[];

    if (RoleManager.canManageExpenses) {
      items.add({
        'icon': Icons.category,
        'title': 'Material',
        'subtitle':
            'Log concrete, steel, lumber, or site-specific procurement items.',
        'type': 'material',
      });
    }

    if (RoleManager.canAddEntries) {
      items.add({
        'icon': Icons.people,
        'title': 'Labour',
        'subtitle':
            'Track crew hours, specialized trade performance, and site presence.',
        'type': 'labour',
      });
    }

    if (RoleManager.canManageEquipmentMaster) {
      items.add({
        'icon': Icons.precision_manufacturing,
        'title': 'Equipment',
        'subtitle':
            'Record heavy machinery runtime, fuel logs, and maintenance events.',
        'type': 'equipment',
      });
    }

    return items;
  }

  void _navigateToContext(BuildContext context, String type) {
    Navigator.pushNamed(
      context,
      '/execution-context',
      arguments: {'type': type},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Add Entry',
              leftIcon: Navigator.canPop(context) ? Icons.arrow_back : null,
              onLeftTap: Navigator.canPop(context)
                  ? () => Navigator.pop(context)
                  : null,
              rightWidget: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: const ProfileAvatar(radius: 18),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'What are you\nadding?',
                      style: AppTheme.heading1.copyWith(
                        fontSize: 30,
                        letterSpacing: -0.6,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the entry type to log for the current shift.',
                      style: AppTheme.body.copyWith(color: textGray),
                    ),
                    const SizedBox(height: 24),

                    // ── Entry Type Cards ────────────────────────────────────
                    const AppSectionHeader(title: 'Entry Type'),
                    ...List.generate(
                      _entries.length,
                      (i) => _entryCard(context, i),
                    ),
                    // Quick Actions section removed — Daily Progress Update
                    // is now accessible directly from the Execution Tracker
                    // in Project Detail via the activity row action button.
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _entryCard(BuildContext context, int index) {
    final entry = _entries[index];
    final String type = entry['type'] as String;

    final Map<String, Color> iconColors = {
      'material': primaryBlue,
      'labour': primaryBlue,
      'equipment': primaryBlue,
    };
    final Map<String, Color> iconBgColors = {
      'material': primaryBlue.withValues(alpha: 0.1),
      'labour': primaryBlue.withValues(alpha: 0.1),
      'equipment': primaryBlue.withValues(alpha: 0.1),
    };
    final Color iconColor = iconColors[type] ?? primaryBlue;
    final Color iconBg = iconBgColors[type] ?? const Color(0xFFF0F2F8);

    return AppCard(
      onTap: () => _navigateToContext(context, type),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(entry['icon'] as IconData, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['title'] as String,
                  style: AppTheme.heading3.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  entry['subtitle'] as String,
                  style: AppTheme.body.copyWith(
                    color: textGray,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: textGray.withValues(alpha: 0.5),
            size: 20,
          ),
        ],
      ),
    );
  }
}
