import 'dart:convert';
import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/role_manager.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:flutter/material.dart';

class AssignRoleScreen extends StatefulWidget {
  const AssignRoleScreen({super.key});

  @override
  State<AssignRoleScreen> createState() => _AssignRoleScreenState();
}

class _AssignRoleScreenState extends State<AssignRoleScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _customRoleCtrl = TextEditingController();

  final Map<String, bool> _permissions = {
    'view_projects': false,
    'add_entries': false,
    'approve_payments': false,
    'mark_paid': false,
    'view_reports': false,
    'manage_team': false,
  };

  bool _obscurePass = true;
  String? _selectedRole;
  String? _selectedProjectId;
  String? _selectedProjectName;
  bool _isLoading = false;

  List<Map<String, String>> _projects = [];
  bool _isLoadingProjects = true;
  String? _projectsError;

  static const _customRoleValue = '__custom_role__';
  static const _roles = ['Supervisor', 'Mason', _customRoleValue];

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _customRoleCtrl.dispose();
    super.dispose();
  }

  bool get _isCustomRoleSelected => _selectedRole == _customRoleValue;

  Future<void> _fetchProjects() async {
    setState(() {
      _isLoadingProjects = true;
      _projectsError = null;
    });

    try {
      final response = await ApiService.get('/projects/mine');

      debugPrint('ASSIGN ROLE /projects/mine status => ${response.statusCode}');
      debugPrint('ASSIGN ROLE /projects/mine body   => ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> raw = [];
        if (decoded is List) {
          raw = decoded;
        } else if (decoded is Map) {
          raw = (decoded['projects'] ??
              decoded['data'] ??
              decoded['items'] ??
              decoded['results'] ??
              []) as List<dynamic>;
        }

        final parsed = raw.map<Map<String, String>>((p) {
          final map = Map<String, dynamic>.from(p as Map);
          final id = (map['_id'] ?? map['id'] ?? '').toString();
          final name = (map['projectName'] ??
                  map['name'] ??
                  map['title'] ??
                  'Unnamed Project')
              .toString()
              .trim();
          return {
            'id': id,
            'name': name.isEmpty ? 'Unnamed Project' : name,
          };
        }).where((p) => p['id']!.isNotEmpty).toList();

        setState(() {
          _projects = parsed;
          _isLoadingProjects = false;
        });
      } else {
        setState(() {
          _projectsError = 'Could not load projects (${response.statusCode})';
          _isLoadingProjects = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _projectsError = 'Network error loading projects';
        _isLoadingProjects = false;
      });
    }
  }

  void _applyDefaultPermissionsForRole(String? role) {
    if (role == null) return;

    final defaults = <String, bool>{
      'view_projects': true,
      'add_entries': true,
      'approve_payments': false,
      'mark_paid': false,
      'view_reports': false,
      'manage_team': false,
    };

    if (role == 'Supervisor') {
      defaults['view_projects'] = true;
      defaults['add_entries'] = true;
      defaults['approve_payments'] = true;
      defaults['mark_paid'] = true;
      defaults['view_reports'] = true;
      defaults['manage_team'] = false;
    } else if (role == 'Mason') {
      defaults['view_projects'] = true;
      defaults['add_entries'] = true;
      defaults['approve_payments'] = false;
      defaults['mark_paid'] = false;
      defaults['view_reports'] = false;
      defaults['manage_team'] = false;
    } else if (role == _customRoleValue) {
      defaults['view_projects'] = true;
      defaults['add_entries'] = false;
      defaults['approve_payments'] = false;
      defaults['mark_paid'] = false;
      defaults['view_reports'] = false;
      defaults['manage_team'] = false;
    }

    setState(() {
      _selectedRole = role;
      if (role != _customRoleValue) {
        _customRoleCtrl.clear();
      }
      _permissions
        ..clear()
        ..addAll(defaults);
    });
  }

  List<Widget> _buildPermissionTiles(bool isAdmin) {
    final permissionLabels = <String, String>{
      'view_projects': 'View projects',
      'add_entries': 'Add entries',
      'approve_payments': 'Approve payments',
      'mark_paid': 'Mark as paid',
      'view_reports': 'View reports',
      'manage_team': 'Manage team',
    };

    final permissionSubtitles = <String, String>{
      'view_projects': 'Can open project lists and details',
      'add_entries': 'Can add labour, material, and equipment entries',
      'approve_payments': 'Can approve payment-related actions',
      'mark_paid': 'Can mark pending items as paid or partial',
      'view_reports': 'Can access reports and analytics',
      'manage_team': 'Can assign roles and manage user access',
    };

    return _permissions.keys.map((key) {
      return CheckboxListTile(
        value: _permissions[key],
        onChanged: isAdmin
            ? (value) {
                setState(() {
                  _permissions[key] = value ?? false;
                });
              }
            : null,
        activeColor: AppColors.primary,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: Text(
          permissionLabels[key]!,
          style: AppTheme.body.copyWith(color: AppColors.textDark),
        ),
        subtitle: Text(
          permissionSubtitles[key]!,
          style: AppTheme.caption.copyWith(color: AppColors.textLight),
        ),
      );
    }).toList();
  }

  Future<void> _onAssignPressed() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final roleToSend = _isCustomRoleSelected
        ? _customRoleCtrl.text.trim()
        : (_selectedRole ?? '').trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || roleToSend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields and select a role.'),
        ),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    final selectedPermissions = _permissions.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'name': name,
      'email': email,
      'temporaryPassword': pass,
      'role': roleToSend,
      'permissions': selectedPermissions,
      if (_selectedProjectId != null) 'projectId': _selectedProjectId,
    };

    try {
      final response = await ApiService.post('/auth/provision', payload);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name has been assigned as $roleToSend.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      } else {
        final body = json.decode(response.body);
        final msg = body['message']?.toString() ?? 'Failed to assign role.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    _adminBadge(),
                    const SizedBox(height: 6),
                    Text(
                      'Only Admins can assign roles and manage team access.',
                      style: AppTheme.body.copyWith(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 20),
                    _formCard(isAdmin),
                    const SizedBox(height: 12),
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

  Widget _adminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
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

  Widget _formCard(bool isAdmin) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              Text(
                'Temporary Password',
                style: AppTheme.label.copyWith(color: AppTheme.textMedium),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                enabled: true,
                style: AppTheme.bodyLarge.copyWith(color: AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: 'Enter temporary password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
          AppDropdownField<String>(
            label: 'Role',
            value: _selectedRole,
            hint: 'Select role',
            items: _roles
                .map(
                  (r) => DropdownMenuItem<String>(
                    value: r,
                    child: Text(
                      r == _customRoleValue ? 'Custom Role' : r,
                    ),
                  ),
                )
                .toList(),
            onChanged: isAdmin ? (v) => _applyDefaultPermissionsForRole(v) : (_) {},
          ),
          if (_isCustomRoleSelected) ...[
            const SizedBox(height: AppTheme.spacingMd),
            AppTextField(
              label: 'Custom Role Name',
              controller: _customRoleCtrl,
              hint: 'Type new role name',
              prefixIcon: Icons.badge_outlined,
              enabled: isAdmin,
            ),
          ],
          _roleHints(),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Permissions',
            style: AppTheme.heading3.copyWith(
              color: AppColors.textDark,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ..._buildPermissionTiles(isAdmin),
          const SizedBox(height: AppTheme.spacingMd),
          _buildProjectDropdown(isAdmin),
          Text(
            'Leave blank for organisation-wide access',
            style: AppTheme.caption.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDropdown(bool isAdmin) {
    if (_isLoadingProjects) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading projects…',
              style: AppTheme.body.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    if (_projectsError != null && _projects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _projectsError!,
                style: AppTheme.caption.copyWith(color: AppColors.warning),
              ),
            ),
            TextButton(
              onPressed: _fetchProjects,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final items = [
      DropdownMenuItem<String>(
        value: '__none__',
        child: Text(
          'No specific project',
          style: AppTheme.body.copyWith(color: AppColors.textLight),
        ),
      ),
      ..._projects.map(
        (p) => DropdownMenuItem<String>(
          value: p['id'],
          child: Text(p['name']!),
        ),
      ),
    ];

    return AppDropdownField<String>(
      label: 'Project Access (Optional)',
      value: _selectedProjectId,
      hint: 'Select project',
      items: items,
      onChanged: isAdmin
          ? (v) => setState(() {
                if (v == '__none__') {
                  _selectedProjectId = null;
                  _selectedProjectName = null;
                } else {
                  _selectedProjectId = v;
                  _selectedProjectName = _projects.firstWhere(
                    (p) => p['id'] == v,
                    orElse: () => {'name': v ?? ''},
                  )['name'];
                }
              })
          : (_) {},
    );
  }

  Widget _roleHints() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gradientStart,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roleHintRow('Supervisor', 'Manage work, approve payments, view reports'),
          const SizedBox(height: 4),
          _roleHintRow('Mason', 'Add and update own work only'),
          const SizedBox(height: 4),
          _roleHintRow('Custom Role', 'Create a role name and choose permissions manually'),
        ],
      ),
    );
  }

  Widget _roleHintRow(String role, String desc) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12.5, height: 1.4),
        children: [
          TextSpan(
            text: '• ',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: '$role: ',
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: desc,
            style: const TextStyle(color: AppColors.textLight),
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
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      color: Colors.white,
                      size: 19,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Assign Role',
                      style: TextStyle(
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