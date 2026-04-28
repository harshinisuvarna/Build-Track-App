import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:flutter/material.dart';

class AddEntryScreen extends StatelessWidget {
  const AddEntryScreen({super.key});

  static const primaryBlue = AppColors.primary;
  static const purple      = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;

  static const List<Map<String, dynamic>> _entries = [
    {
      'icon': Icons.category,
      'title': 'Material',
      'subtitle': 'Log concrete, steel, lumber, or site-specific procurement items.',
      'type': 'material',
    },
    {
      'icon': Icons.people,
      'title': 'Labour',
      'subtitle': 'Track crew hours, specialized trade performance, and site presence.',
      'type': 'labour',
    },
    {
      'icon': Icons.precision_manufacturing,
      'title': 'Equipment',
      'subtitle': 'Record heavy machinery runtime, fuel logs, and maintenance events.',
      'type': 'equipment',
    },
  ];

  void _showEntryOptions(BuildContext context, String type) {
    const Map<String, String> voiceRoutes = {
      'material': '/review-material',
      'labour': '/review-labour',
      'equipment': '/review-equipment',
    };
    const Map<String, String> manualRoutes = {
      'material': '/add-material',
      'labour': '/add-labour',
      'equipment': '/add-equipment',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text('How do you want to add?',
                  style: AppTheme.heading2.copyWith(color: textDark)),
              const SizedBox(height: 6),
              Text(
                'Adding ${type[0].toUpperCase()}${type.substring(1)} entry',
                style: AppTheme.body.copyWith(color: textGray),
              ),
              const SizedBox(height: 20),
              _bottomSheetOption(
                icon: Icons.mic,
                iconColor: primaryBlue,
                iconBg: const Color(0xFFEEF0FF),
                title: 'Use Voice',
                subtitle: 'Speak and let AI capture the details',
                onTap: () {
                  Navigator.pop(ctx);
                  final route = voiceRoutes[type];
                  if (route != null) {
                    Navigator.pushNamed(context, route, arguments: {'type': type});
                  }
                },
              ),
              const SizedBox(height: 12),
              _bottomSheetOption(
                icon: Icons.edit_outlined,
                iconColor: purple,
                iconBg: const Color(0xFFF0EEFF),
                title: 'Enter Manually',
                subtitle: 'Fill the form manually',
                onTap: () {
                  Navigator.pop(ctx);
                  final route = manualRoutes[type];
                  if (route != null) {
                    Navigator.pushNamed(context, route, arguments: {'type': type});
                  }
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => Navigator.pop(ctx),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: textGray,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomSheetOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E5FF)),
          ),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTheme.caption.copyWith(color: textGray, fontSize: 12.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: textGray, size: 20),
            ],
          ),
        ),
      ),
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
              rightWidget: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
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

                    // ── Entry Type Cards ──────────────────────────────────
                    const AppSectionHeader(title: 'Entry Type'),
                    ...List.generate(_entries.length, (i) => _entryCard(context, i)),

                    const SizedBox(height: 24),

                    // ── Quick Actions ─────────────────────────────────────
                    const AppSectionHeader(title: 'Quick Actions'),
                    AppCard(
                      onTap: () => Navigator.pushNamed(context, '/update-progress'),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.assignment_turned_in_outlined,
                                color: AppTheme.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Daily Progress Update',
                                    style: AppTheme.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700, color: textDark)),
                                const SizedBox(height: 3),
                                Text('Update work status, %, and photos',
                                    style: AppTheme.caption.copyWith(color: textGray)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: textGray, size: 20),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Team & Access ─────────────────────────────────────
                    const AppSectionHeader(title: 'Team & Access'),
                    _teamAccessCard(context),

                    const SizedBox(height: 12),

                    // ── Admin-only notice ─────────────────────────────────
                    _adminNotice(),
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

  /// Dashed-border card with team illustration + Assign Role gradient button.
  Widget _teamAccessCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadows,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.5,
          // Dart doesn't support native dashed borders — simulate with custom paint
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team & Access',
                  style: AppTheme.heading3.copyWith(color: AppColors.textDark, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Assign roles and manage team access for your project.',
                  style: AppTheme.body.copyWith(color: AppColors.textLight, height: 1.45),
                ),
                const SizedBox(height: 16),
                // Gradient "Assign Role" button
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/assign-role'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF4A6CF7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_outlined, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Assign Role',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Mini team illustration
          _teamIllustration(),
        ],
      ),
    );
  }

  /// Simple SVG-style team illustration using Flutter widgets.
  Widget _teamIllustration() {
    const purple = Color(0xFF6C5CE7);
    const purpleLight = Color(0xFFB8AEFF);
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: purple.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          // Center person (larger)
          Positioned(
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ),
          // Side bubbles
          Positioned(
            top: 4, left: 2,
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: purpleLight.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 11),
            ),
          ),
          Positioned(
            top: 4, right: 2,
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: purpleLight.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 11),
            ),
          ),
          Positioned(
            bottom: 2, left: 8,
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: purpleLight.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 9),
            ),
          ),
          Positioned(
            bottom: 2, right: 8,
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: purpleLight.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primary.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This feature is only available to Admins.',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage user roles, permissions, and project access.',
                  style: AppTheme.caption.copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(BuildContext context, int index) {
    final entry = _entries[index];
    final String type = entry['type'] as String;

    final Map<String, Color> iconColors = {
      'material': primaryBlue,
      'labour': purple,
      'equipment': const Color(0xFF7B3FE7),
    };
    final Map<String, Color> iconBgColors = {
      'material': primaryBlue.withValues(alpha: 0.1),
      'labour': purple.withValues(alpha: 0.1),
      'equipment': const Color(0xFF7B3FE7).withValues(alpha: 0.1),
    };
    final Color iconColor = iconColors[type] ?? primaryBlue;
    final Color iconBg = iconBgColors[type] ?? const Color(0xFFF0F2F8);

    return AppCard(
      onTap: () => _showEntryOptions(context, type),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52, height: 52,
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
                  style: AppTheme.body.copyWith(color: textGray, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right,
              color: textGray.withValues(alpha: 0.5), size: 20),
        ],
      ),
    );
  }
}