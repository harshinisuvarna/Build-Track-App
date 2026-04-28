import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_layout.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:flutter/material.dart';

/// Shape of the user data this screen expects.
/// Navigate to '/profile' with:
///   Navigator.pushNamed(context, '/profile',
///       arguments: ProfileUserData(name: ..., email: ..., role: ...));
///
/// Replace field reads with your actual AuthController / UserModel.
class ProfileUserData {
  const ProfileUserData({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  /// Fallback shown when no arguments are passed to the route.
  static const empty = ProfileUserData(name: '—', email: '—', role: '—');
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  /// Reads user data injected via Navigator.pushNamed arguments.
  ProfileUserData get _user {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is ProfileUserData ? args : ProfileUserData.empty;
  }

  @override
  Widget build(BuildContext context) {
    return AppSubScreenLayout(
      title: 'Profile',
      scrollable: true,
      child: Column(
        children: [
          _buildProfileCard(_user),
          const SizedBox(height: AppTheme.spacingLg),
          _buildSettingsCard(),
          const SizedBox(height: AppTheme.spacingLg),
          _buildActions(),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'BuildTrack Version 2.4.0 (2024)',
            style: AppTheme.caption.copyWith(
              color: AppColors.textLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient profile header card ──────────────────────────────────────────

  Widget _buildProfileCard(ProfileUserData user) {
    // Container is necessary here: AppCard doesn't support gradients.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2233DD), Color(0xFF7B3FEF), Color(0xFFAA44FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2233DD).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildRoleBadge(user.role),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 3,
            ),
          ),
          child: const ClipOval(
            child: ColoredBox(
              color: Color(0xFFE8473F),
              child: Icon(Icons.person, color: Colors.white, size: 48),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.edit,
              color: AppColors.primary,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Account Settings card ─────────────────────────────────────────────────

  Widget _buildSettingsCard() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Text('Account Settings', style: AppTheme.heading3),
          ),
          _buildSettingsTile(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            onTap: () {}, // TODO: navigate to edit profile
            showDivider: true,
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () => Navigator.pushNamed(context, '/forgot-password'),
            showDivider: true,
          ),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            trailing: _buildNotificationsBadge(),
            onTap: () =>
                setState(() => _notificationsEnabled = !_notificationsEnabled),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    Widget? trailing,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: showDivider
              ? BorderRadius.zero
              : const BorderRadius.vertical(bottom: Radius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingMd,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label, style: AppTheme.heading3.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  )),
                ),
                if (trailing != null) ...[
                  trailing,
                  const SizedBox(width: 8),
                ],
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textLight,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 18, endIndent: 18),
      ],
    );
  }

  Widget _buildNotificationsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _notificationsEnabled
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _notificationsEnabled
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: Text(
        _notificationsEnabled ? 'Enabled' : 'Disabled',
        style: TextStyle(
          color: _notificationsEnabled ? AppColors.primary : AppColors.textLight,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions() {
    return AppButton(
      label: 'Logout',
      variant: AppButtonVariant.danger,
      icon: Icons.logout_outlined,
      onPressed: _onLogoutPressed,
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _onLogoutPressed() {
    // TODO: call AuthController.logout() before navigating
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }
}