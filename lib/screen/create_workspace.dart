import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_layout.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:flutter/material.dart';

class CreateWorkspaceScreen extends StatefulWidget {
  const CreateWorkspaceScreen({super.key});

  @override
  State<CreateWorkspaceScreen> createState() => _CreateWorkspaceScreenState();
}

class _CreateWorkspaceScreenState extends State<CreateWorkspaceScreen> {
  static const _roles = ['Admin', 'Supervisor', 'Mason'];

  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _selectedRole = 'Admin';
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScrollLayout(
      title: '',
      showAppBar: false,
      backgroundColor: const Color(0xFFF0EEFF),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        margin: EdgeInsets.zero,
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spacingLg),
            _buildForm(),
            const SizedBox(height: AppTheme.spacingLg),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF4A3FDE), Color(0xFF7B52FF)],
          ).createShader(bounds),
          child: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Build',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Track',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7BCFFF),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Create Workspace',
          style: AppTheme.heading2.copyWith(
            fontSize: 26,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Set up your admin account to get started.',
          textAlign: TextAlign.center,
          style: AppTheme.body.copyWith(color: AppColors.textLight),
        ),
      ],
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      children: [
        AppTextField(
          label: 'Full Name',
          controller: _nameCtrl,
          hint: 'e.g. Jane Doe',
          prefixIcon: Icons.person_outline,
        ),
        AppTextField(
          label: 'Company / Project Name',
          controller: _companyCtrl,
          hint: 'e.g. Apex Construction',
          prefixIcon: Icons.business_outlined,
        ),
        AppTextField(
          label: 'Email Address',
          controller: _emailCtrl,
          hint: 'name@company.com',
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        AppDropdownField<String>(
          label: 'Role (Optional)',
          value: _selectedRole,
          hint: 'Select role',
          items: _roles
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() => _selectedRole = v ?? _selectedRole),
        ),
        AppTextField(
          label: 'Password',
          controller: _passCtrl,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePass,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePass
                  ? Icons.remove_red_eye_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textLight,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),
        AppTextField(
          label: 'Confirm Password',
          controller: _confirmCtrl,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirm,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.remove_red_eye_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textLight,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions() {
    return Column(
      children: [
        AppButton(
          label: 'Create Workspace',
          icon: Icons.arrow_forward,
          onPressed: _onCreatePressed,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: AppTheme.body.copyWith(color: AppColors.textLight),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: Text(
                'Sign in',
                style: AppTheme.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _onCreatePressed() {
    // TODO: delegate to AuthController.createWorkspace(...)
    Navigator.pushNamed(context, '/login');
  }
}