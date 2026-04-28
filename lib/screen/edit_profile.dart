import 'dart:io';
import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_layout.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;

  File? _selectedImage;

  Future<void> _pickImage() async {
    final file = await pickImageFromGallery(context);
    if (file != null && mounted) setState(() => _selectedImage = file);
  }

  @override
  void initState() {
    super.initState();
    final uid = UserSession.userId;
    _nameCtrl  = TextEditingController(
      text: uid.isNotEmpty ? uid : 'Guest User',
    );
    _emailCtrl = TextEditingController(
      text: uid.isNotEmpty ? '$uid@buildtrack.app' : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSubScreenLayout(
      title: 'Edit Profile',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingLg),

          // ── Avatar preview ───────────────────────────────────────────
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage:
                        _selectedImage != null ? FileImage(_selectedImage!) : null,
                    child: _selectedImage == null
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
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingXl),

          // ── Form fields ──────────────────────────────────────────────
          AppTextField(
            label: 'Full Name',
            controller: _nameCtrl,
            hint: 'Enter your name',
            prefixIcon: Icons.person_outline,
          ),

          AppTextField(
            label: 'Email Address',
            controller: _emailCtrl,
            hint: 'name@company.com',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: AppTheme.spacingXl),

          // ── Save button ──────────────────────────────────────────────
          AppButton(
            label: 'Save Changes',
            icon: Icons.check_outlined,
            onPressed: () {
              final name = _nameCtrl.text.trim();
              _emailCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name cannot be empty')),
                );
                return;
              }
              // Persist into session (swap for API call when backend is ready)
              UserSession.set(
                userId: UserSession.userId,
                role: UserSession.role,
                projectId: UserSession.projectId,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated'),
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.pop(context);
            },
          ),

          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }
}
