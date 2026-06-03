import 'dart:convert';
import 'dart:io';
import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_layout.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/subscription_card.dart';
import 'package:buildtrack_mobile/controller/role_manager.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
// UserRole enum is defined in user_session.dart — already imported above
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';

// ── Live user data model ──────────────────────────────────────────────────────
class ProfileUserData {
  const ProfileUserData({
    required this.name,
    required this.email,
    required this.role,
    this.profilePhoto,
  });

  final String name;
  final String email;
  final String role;
  final String? profilePhoto;

  factory ProfileUserData.fromJson(Map<String, dynamic> json) {
    return ProfileUserData(
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Mason',
      profilePhoto: json['profilePhoto']?.toString(),
    );
  }

  /// Fallback when API fails — still uses session for role label
  static ProfileUserData get sessionFallback => ProfileUserData(
        name: UserSession.userId.isNotEmpty ? UserSession.userId : 'Guest User',
        email: '${UserSession.userId}@buildtrack.app',
        role: UserSession.roleLabel,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  File? _selectedImage;

  ProfileUserData? _user;
  bool _isLoadingProfile = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });
    try {
      final response = await ApiService.get('/users/profile');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // API returns { user: { ... } }
        final userJson = decoded['user'] ?? decoded;
        final data = ProfileUserData.fromJson(userJson as Map<String, dynamic>);
        // Convert role string from API → UserRole enum, then sync into session
        final roleStr = (userJson['role']?.toString() ?? '').toLowerCase();
        final UserRole parsedRole;
        switch (roleStr) {
          case 'supervisor':
            parsedRole = UserRole.supervisor;
            break;
          case 'mason':
          case 'worker':
            parsedRole = UserRole.mason;
            break;
          default:
            parsedRole = UserRole.admin;
        }
        UserSession.set(
          userId: userJson['name']?.toString() ?? UserSession.userId,
          role: parsedRole,
          projectId: UserSession.projectId,
        );
        setState(() {
          _user = data;
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _user = ProfileUserData.sessionFallback;
          _profileError = 'Could not load profile (${response.statusCode})';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _user = ProfileUserData.sessionFallback;
        _profileError = 'Network error. Showing cached data.';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final file = await pickImageFromGallery(context);
    if (file != null && mounted) setState(() => _selectedImage = file);
  }

  @override
  Widget build(BuildContext context) {
    return AppSubScreenLayout(
      title: 'Profile',
      scrollable: true,
      child: _isLoadingProfile
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : Column(
              children: [
                // Error banner if API failed but we have fallback data
                if (_profileError != null) ...[
                  _ErrorBanner(message: _profileError!),
                  const SizedBox(height: 12),
                ],

                _buildProfileCard(_user!),
                const SizedBox(height: AppTheme.spacingLg),

                const SubscriptionCard(),
                const SizedBox(height: AppTheme.spacingLg),

                _buildSettingsCard(),
                const SizedBox(height: AppTheme.spacingLg),

                if (RoleManager.canViewTeamAccess) ...[
                  _buildTeamAccessSection(),
                  const SizedBox(height: AppTheme.spacingLg),
                ],

                _buildActions(),
                const SizedBox(height: AppTheme.spacingLg),

                Text(
                  'BuildTrack Version 2.4.0 (2024)',
                  style:
                      AppTheme.caption.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
    );
  }

  // ── Profile header card ────────────────────────────────────────────────────
  Widget _buildProfileCard(ProfileUserData user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryButton,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(user.profilePhoto),
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

  Widget _buildAvatar(String? photoUrl) {
    ImageProvider? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl);
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
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
              child:
                  const Icon(Icons.edit, color: AppColors.primary, size: 14),
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

  // ── Settings card ──────────────────────────────────────────────────────────
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
            onTap: () async {
              await Navigator.pushNamed(
                context,
                '/edit-profile',
                arguments: _user,
              );
              // Refresh profile after returning from edit
              _fetchProfile();
            },
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
            onTap: () => setState(
                () => _notificationsEnabled = !_notificationsEnabled),
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
                  child: Text(
                    label,
                    style: AppTheme.heading3.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  trailing,
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right,
                    color: AppColors.textLight, size: 20),
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
          color:
              _notificationsEnabled ? AppColors.primary : AppColors.textLight,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Widget _buildActions() {
    return AppButton(
      label: 'Logout',
      variant: AppButtonVariant.danger,
      icon: Icons.logout_outlined,
      onPressed: _onLogoutPressed,
    );
  }

  void _onLogoutPressed() {
    UserSession.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // ── Team access section ────────────────────────────────────────────────────
  Widget _buildTeamAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Team & Access', style: AppTheme.heading2),
        ),
        const SizedBox(height: 12),
        _teamAccessCard(context),
        const SizedBox(height: 12),
        _adminNotice(),
      ],
    );
  }

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
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team & Access',
                  style: AppTheme.heading3
                      .copyWith(color: AppColors.textDark, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Assign roles and manage team access for your project.',
                  style: AppTheme.body
                      .copyWith(color: AppColors.textLight, height: 1.45),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/assign-role'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryButton,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_outlined,
                            color: Colors.white, size: 18),
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
          _teamIllustration(),
        ],
      ),
    );
  }

  Widget _teamIllustration() {
    const purple = AppColors.primaryPurple;
    const purpleLight = AppColors.primaryLightBlue;
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: purple.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: purple, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
          Positioned(
            top: 4,
            left: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  color: purpleLight.withValues(alpha: 0.6),
                  shape: BoxShape.circle),
              child:
                  const Icon(Icons.person, color: Colors.white, size: 11),
            ),
          ),
          Positioned(
            top: 4,
            right: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  color: purpleLight.withValues(alpha: 0.6),
                  shape: BoxShape.circle),
              child:
                  const Icon(Icons.person, color: Colors.white, size: 11),
            ),
          ),
          Positioned(
            bottom: 2,
            left: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                  color: purpleLight.withValues(alpha: 0.4),
                  shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white, size: 9),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                  color: purpleLight.withValues(alpha: 0.4),
                  shape: BoxShape.circle),
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
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined,
              color: AppColors.primary.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 8),
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
                  style: AppTheme.caption
                      .copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small error banner ────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTheme.caption.copyWith(color: AppColors.textMedium),
            ),
          ),
        ],
      ),
    );
  }
}