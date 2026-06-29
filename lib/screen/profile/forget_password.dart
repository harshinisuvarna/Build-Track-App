import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_layout.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/services/api_service.dart'; // Added API Service

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false; // Added loading state

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - 160;
    return AppSubScreenLayout(
      title: 'Reset Password',
      scrollable: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: availableHeight),
        child: Center(
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
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
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset_outlined,
            color: AppColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Text(
          'Reset Password',
          style: AppTheme.heading2.copyWith(fontSize: 26, letterSpacing: -0.5),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'Enter your email to receive a reset link',
          textAlign: TextAlign.center,
          style: AppTheme.body.copyWith(
            color: AppColors.textLight,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return AppTextField(
      label: 'Email Address',
      controller: _emailCtrl,
      hint: 'name@company.com',
      prefixIcon: Icons.mail_outline,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        // Show loading spinner if waiting for API, otherwise show the button
        _isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : AppButton(label: 'Reset Password', onPressed: _onResetPressed),
        const SizedBox(height: AppTheme.spacingLg),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back, color: AppColors.textDark, size: 16),
              const SizedBox(width: 6),
              Text(
                'Back to login',
                style: AppTheme.body.copyWith(
                  color: AppColors.textDark.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- UPDATED: Live API connection with Snackbars ---
  Future<void> _onResetPressed() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ApiService.resetPassword(email);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email.'),
            backgroundColor: Colors.green, // Green on success
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Send user back to login screen
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red, // Red on error
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
