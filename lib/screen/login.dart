import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _bgColor = Color(0xFFF0EEFF);

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: _bgColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 32, 20, 24 + bottomInset),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
                    margin: EdgeInsets.zero,
                    borderRadius: 28,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: AppTheme.spacingXl),
                        _buildForm(),
                        const SizedBox(height: AppTheme.spacingLg),
                        _buildActions(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header: app icon + title + subtitle ───────────────────────────────────

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AppIconBadge(),
        const SizedBox(height: 20),
        Text(
          'BuildTrack',
          style: AppTheme.heading1.copyWith(fontSize: 30, letterSpacing: -0.8),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage your construction smarter',
          textAlign: TextAlign.center,
          style: AppTheme.body.copyWith(color: AppColors.textLight),
        ),
      ],
    );
  }

  // ── Form: email + password + remember me ──────────────────────────────────

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Email Address',
          controller: _emailCtrl,
          hint: 'name@company.com',
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
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

        // "Forgot Password?" — right-aligned, below the password input field
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/forgot-password'),
            child: Text(
              'Forgot Password?',
              style: AppTheme.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Remember me
        Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) =>
                    setState(() => _rememberMe = v ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                side: const BorderSide(
                  color: Color(0xFFCBCFE8),
                  width: 1.5,
                ),
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Remember me for 30 days',
                style: AppTheme.body.copyWith(color: AppColors.textDark),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Actions: sign in button + signup link ─────────────────────────────────

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: 'Sign In',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/home'),
        ),
        const SizedBox(height: 20),

        // Use Wrap to prevent overflow when text wraps on narrow screens
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: AppTheme.body.copyWith(color: AppColors.textLight),
            ),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, '/create-workspace'),
              child: Text(
                'Create account',
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

  // ── Footer: privacy + terms ───────────────────────────────────────────────

  Widget _buildFooter() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        Text(
          'Privacy Policy',
          style: AppTheme.caption.copyWith(fontWeight: FontWeight.w500),
        ),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.textLight,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          'Terms of Service',
          style: AppTheme.caption.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── Private sub-widget ─────────────────────────────────────────────────────

class _AppIconBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B3FE0), Color(0xFF9B59FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3FE0).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.domain_outlined,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}