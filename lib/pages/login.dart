import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';

import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/services/auth_service.dart';
import 'package:buildtrack_mobile/services/user_session.dart';

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
  bool _loading = false;

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

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'BuildTrack',
          style: AppTheme.heading1.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage your construction smarter',
          style: AppTheme.body.copyWith(color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        AppTextField(
          label: 'Email Address',
          controller: _emailCtrl,
          hint: 'name@company.com',
          prefixIcon: Icons.mail_outline,
        ),
        AppTextField(
          label: 'Password',
          controller: _passCtrl,
          hint: 'Enter your password',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePass,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePass
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () =>
                setState(() => _obscurePass = !_obscurePass),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        AppButton(
          label: _loading ? 'Signing in...' : 'Sign In',
          onPressed: _loading ? null : _login,
        ),

        const SizedBox(height: 20),

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

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await AuthService.login(email, password);

      if (data != null && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);

        UserSession.set(
          userId: data['userId'] ?? '',
          role: _parseRole(data['role']),
        );

        if (mounted) {
          try {
            await context.read<ProjectProvider>().fetchProjects();
          } catch (_) {}

          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        throw Exception("Invalid login response");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  UserRole _parseRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'supervisor':
        return UserRole.supervisor;
      case 'mason':
      case 'worker':
        return UserRole.mason;
      default:
        return UserRole.admin;
    }
  }

  Widget _buildFooter() {
    return Text(
      'Privacy Policy • Terms of Service',
      style: AppTheme.caption,
    );
  }
}