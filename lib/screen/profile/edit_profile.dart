import 'dart:convert';
import 'dart:typed_data';
import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_layout.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'profile.dart'; // for ProfileUserData

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;

  PickedImage? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isSaving = false;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    // Defer so ModalRoute.settings.arguments is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFields());
  }

  void _initFields() {
    // ProfileScreen passes the already-fetched ProfileUserData as arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ProfileUserData) {
      _nameCtrl.text = args.name;
      _emailCtrl.text = args.email;
    } else {
      // Fallback: use session values
      _nameCtrl.text =
          UserSession.userId.isNotEmpty ? UserSession.userId : '';
      _emailCtrl.text = '';
      // Try to fetch fresh from API
      _fetchProfile();
      return;
    }
    setState(() => _isLoadingInitial = false);
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ApiService.get('/users/profile');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final userJson = decoded['user'] ?? decoded;
        _nameCtrl.text = userJson['name']?.toString() ?? '';
        _emailCtrl.text = userJson['email']?.toString() ?? '';
      }
    } catch (_) {
      // Keep whatever was set from session
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await pickImageFromGallery(context);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _selectedImage = picked;
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _onSave() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    if (email.isNotEmpty && !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = <String, dynamic>{
        'name': name,
        if (email.isNotEmpty) 'email': email,
      };

      final response = await ApiService.put('/users/profile', payload);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Update local session name so TopBar / other widgets reflect it
        UserSession.set(
          userId: decoded['name']?.toString() ?? name,
          role: UserSession.role,
          projectId: UserSession.projectId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      } else {
        final body = json.decode(response.body);
        final msg = body['message']?.toString() ?? 'Update failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      child: _isLoadingInitial
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.spacingLg),

                // ── Avatar picker ─────────────────────────────────────────
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          backgroundImage: _selectedImageBytes != null
                              ? MemoryImage(_selectedImageBytes!)
                              : null,
                          child: _selectedImageBytes == null
                              ? const Icon(Icons.person,
                                  size: 40, color: Colors.white)
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
                                BoxShadow(
                                    color: Colors.black12, blurRadius: 6),
                              ],
                            ),
                            child: const Icon(Icons.edit,
                                color: AppColors.primary, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // ── Name ──────────────────────────────────────────────────
                AppTextField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                  hint: 'Enter your name',
                  prefixIcon: Icons.person_outline,
                ),

                // ── Email ─────────────────────────────────────────────────
                AppTextField(
                  label: 'Email Address',
                  controller: _emailCtrl,
                  hint: 'name@company.com',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // ── Save button ───────────────────────────────────────────
                _isSaving
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      )
                    : AppButton(
                        label: 'Save Changes',
                        icon: Icons.check_outlined,
                        onPressed: _onSave,
                      ),

                const SizedBox(height: AppTheme.spacingLg),
              ],
            ),
    );
  }
}