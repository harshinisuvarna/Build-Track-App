import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/role_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignRoleScreen extends StatefulWidget {
  const AssignRoleScreen({super.key});

  @override
  State<AssignRoleScreen> createState() => _AssignRoleScreenState();
}

class _AssignRoleScreenState extends State<AssignRoleScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _obscurePass   = true;
  String? _selectedRole;
  String? _selectedProject;
  bool _isLoading     = false;

  static const _roles = ['Supervisor', 'Mason'];
  static const _projects = [
    'North District Phase 2',
    'Main Building Block A',
    'Road Extension – Zone 4',
  ];


  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onAssignPressed() async {
    final name  = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields and select a role.')),
      );
      return;
    }
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900)); // simulate API
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name has been assigned as $_selectedRole.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = RoleManager.canAssignRole;

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Assign Role',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Admin badge + subtitle ────────────────────────────
                    _adminBadge(),
                    const SizedBox(height: 6),
                    Text(
                      'Only Admins can assign roles and manage team access.',
                      style: AppTheme.body.copyWith(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 20),

                    // ── Form card ─────────────────────────────────────────
                    _formCard(isAdmin),

                    const SizedBox(height: 12),

                    // ── Assign button ─────────────────────────────────────
                    if (isAdmin) _assignButton(),

                    const SizedBox(height: 24),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Admin Access Only badge ───────────────────────────────────────────────

  Widget _adminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, color: AppColors.primary, size: 13),
          const SizedBox(width: 6),
          Text(
            'Admin Access Only',
            style: AppTheme.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Main form card ────────────────────────────────────────────────────────

  Widget _formCard(bool isAdmin) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          AppTextField(
            label: 'Full Name',
            controller: _nameCtrl,
            hint: 'Enter full name',
            prefixIcon: Icons.person_outline,
            enabled: true,
          ),

          AppTextField(
            label: 'Email Address',
            controller: _emailCtrl,
            hint: 'Enter email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            enabled: true,
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Temporary Password',
                  style: AppTheme.label.copyWith(color: AppTheme.textMedium)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
              enabled: true,
                style: AppTheme.bodyLarge.copyWith(color: AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: 'Enter temporary password',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textLight, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),

          // Role dropdown
          AppDropdownField<String>(
            label: 'Role',
            value: _selectedRole,
            hint: 'Select role',
            items: _roles
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: isAdmin ? (v) => setState(() => _selectedRole = v) : (_) {},
          ),

          // Role helper bullets
          _roleHints(),

          const SizedBox(height: AppTheme.spacingMd),

          // Project access dropdown (optional)
          AppDropdownField<String>(
            label: 'Project Access (Optional)',
            value: _selectedProject,
            hint: 'Select project',
            items: _projects
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: isAdmin ? (v) => setState(() => _selectedProject = v) : (_) {},
          ),

          Text(
            'Leave blank for organization-wide access',
            style: AppTheme.caption.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _roleHints() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gradientStart,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roleHintRow('Supervisor', 'Manage & approve assigned work'),
          const SizedBox(height: 4),
          _roleHintRow('Mason', 'Add & update own work only'),
        ],
      ),
    );
  }

  Widget _roleHintRow(String role, String desc) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(fontSize: 12.5, height: 1.4),
        children: [
          TextSpan(
            text: '• ',
            style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: '$role: ',
            style: GoogleFonts.inter(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: desc,
            style: GoogleFonts.inter(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _assignButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onAssignPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            gradient: AppGradients.primaryButton,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_outlined, color: Colors.white, size: 19),
                    SizedBox(width: 9),
                    Text(
                      'Assign Role',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

}
