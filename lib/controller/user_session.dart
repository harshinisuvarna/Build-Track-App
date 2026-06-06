import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { admin, supervisor, mason }

/// A ChangeNotifier so that any widget watching it via
/// `context.watch<UserSession>()` rebuilds when session loads or changes.
class UserSession extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────
  static final UserSession _instance = UserSession._();
  factory UserSession() => _instance;
  UserSession._();

  static const String _kSessionKey = 'buildtrack_user_session';

  // ── In-memory state ────────────────────────────────────
  static String        _userId      = '';
  static UserRole      _role        = UserRole.mason;

  // FIX 1: Store the raw display name from backend (e.g. "Contractor", "Site Manager")
  static String        _rawRoleName = '';

  // ✅ PRIMARY: list of assigned project IDs
  static List<String>  _projectIds  = [];

  // ✅ LEGACY COMPAT: first of projectIds, used by old code that reads projectId
  static String get projectId => _projectIds.isNotEmpty ? _projectIds.first : '';

  // Allow direct set for backward compat (sets _projectIds to [value])
  static set projectId(String value) {
    if (value.isEmpty) {
      _projectIds = [];
    } else if (!_projectIds.contains(value)) {
      _projectIds = [value, ..._projectIds];
    }
    _instance.notifyListeners();
  }

  static List<String>  _permissions = [];
  static bool          _initialized = false;

  // ── Getters ────────────────────────────────────────────
  static String       get userId        => _userId;
  static UserRole     get role          => _role;
  static List<String> get projectIds    => List.unmodifiable(_projectIds);
  static List<String> get permissions   => List.unmodifiable(_permissions);
  static bool         get isInitialized => _initialized;

  static bool get isAdmin      => _role == UserRole.admin;
  static bool get isSupervisor => _role == UserRole.supervisor;
  static bool get isMason      => _role == UserRole.mason;

  /// Whether the user is assigned to a specific project
  static bool hasProjectAccess(String pid) {
    if (isAdmin) return true;
    return _projectIds.any((id) => id.trim() == pid.trim());
  }

  // FIX 1: roleLabel now returns the raw role name from backend when available,
  // falling back to the enum label. This means "Contractor", "Site Manager",
  // "Viewer" etc. all show their actual name instead of always showing "Mason".
  static String get roleLabel {
    if (_rawRoleName.isNotEmpty) return _rawRoleName;
    switch (_role) {
      case UserRole.admin:      return 'Admin';
      case UserRole.supervisor: return 'Supervisor';
      case UserRole.mason:      return 'Mason';
    }
  }

  // ── Permission check ───────────────────────────────────
  static bool hasPermission(String key) {
    if (isAdmin) return true;
    return _permissions.contains(key);
  }

  // ── Called after successful login ──────────────────────
  static Future<void> fromLoginResponse(Map<String, dynamic> user) async {
    _userId = user['id']?.toString() ?? '';

    // FIX 1: Store the raw role string from backend for display purposes
    final rawRoleStr = user['role']?.toString() ?? '';
    _rawRoleName = _toDisplayName(rawRoleStr);
    _role = _parseRole(rawRoleStr);

    // ✅ Read projectIds array from backend (new field)
    final rawIds = user['projectIds'];
    if (rawIds is List) {
      _projectIds = rawIds
          .where((e) => e != null && e.toString().isNotEmpty)
          .map((e) => e.toString())
          .toList();
    } else {
      final legacyId = user['projectId']?.toString() ?? '';
      _projectIds = legacyId.isNotEmpty ? [legacyId] : [];
    }

    final raw = user['permissions'];
    _permissions = raw is List
        ? raw.map((e) => e.toString()).toList()
        : [];

    _initialized = true;
    await _persist();
    _instance.notifyListeners();

    debugPrint('[UserSession] fromLoginResponse → '
        'role=$roleLabel (_raw=$_rawRoleName) projectIds=$_projectIds permissions=$_permissions');
  }

  // ── Called on app start ────────────────────────────────
  static Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kSessionKey);

      if (raw == null || raw.isEmpty) {
        _initialized = true;
        _instance.notifyListeners();
        return;
      }

      final data = json.decode(raw) as Map<String, dynamic>;

      _userId = data['id']?.toString() ?? '';

      // FIX 1: Restore raw role name from persisted prefs
      final rawRoleStr = data['role']?.toString() ?? '';
      _rawRoleName = data['rawRoleName']?.toString() ?? _toDisplayName(rawRoleStr);
      _role = _parseRole(rawRoleStr);

      final savedIds = data['projectIds'];
      if (savedIds is List) {
        _projectIds = savedIds
            .where((e) => e != null && e.toString().isNotEmpty)
            .map((e) => e.toString())
            .toList();
      } else {
        final legacyId = data['projectId']?.toString() ?? '';
        _projectIds = legacyId.isNotEmpty ? [legacyId] : [];
      }

      final perms = data['permissions'];
      _permissions = perms is List
          ? perms.map((e) => e.toString()).toList()
          : [];

      _initialized = true;
      _instance.notifyListeners();

      debugPrint('[UserSession] loadFromPrefs → '
          'role=$roleLabel (_raw=$_rawRoleName) projectIds=$_projectIds');
    } catch (e) {
      debugPrint('[UserSession] loadFromPrefs error: $e');
      _initialized = true;
      _instance.notifyListeners();
    }
  }

  // ── Called on logout ───────────────────────────────────
  static Future<void> clear() async {
    _userId      = '';
    _role        = UserRole.mason;
    _rawRoleName = '';
    _projectIds  = [];
    _permissions = [];
    _initialized = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionKey);

    _instance.notifyListeners();
    debugPrint('[UserSession] cleared');
  }

  // ── Manual set (debug / simulation) ───────────────────
  static void set({
    required String   userId,
    required UserRole role,
    List<String>      projectIds   = const [],
    String            projectId    = '',
    List<String>      permissions  = const [],
    String            rawRoleName  = '',
  }) {
    _userId      = userId;
    _role        = role;
    // FIX 1: allow explicit rawRoleName for simulations
    _rawRoleName = rawRoleName.isNotEmpty ? rawRoleName : _enumToDisplay(role);
    final merged = List<String>.from(projectIds);
    if (projectId.isNotEmpty && !merged.contains(projectId)) {
      merged.insert(0, projectId);
    }
    _projectIds  = merged;
    _permissions = List<String>.from(permissions);
    _initialized = true;
    _instance.notifyListeners();
  }

  // ── Private helpers ────────────────────────────────────

  /// Converts a raw role string from the backend into a human-readable display
  /// name. Preserves the original casing/value for custom roles so that
  /// "Contractor" shows as "Contractor", not "Mason".
  static String _toDisplayName(String? roleStr) {
    if (roleStr == null || roleStr.trim().isEmpty) return 'Worker';
    final trimmed = roleStr.trim();
    // For known enum roles, return the canonical display name
    switch (trimmed.toLowerCase()) {
      case 'admin':      return 'Admin';
      case 'supervisor': return 'Supervisor';
      case 'mason':      return 'Mason';
      case 'worker':     return 'Worker';
      default:
        // For custom roles (Contractor, Site Manager, Viewer, etc.)
        // return the raw string with first letter capitalised
        return trimmed[0].toUpperCase() + trimmed.substring(1);
    }
  }

  static String _enumToDisplay(UserRole role) {
    switch (role) {
      case UserRole.admin:      return 'Admin';
      case UserRole.supervisor: return 'Supervisor';
      case UserRole.mason:      return 'Mason';
    }
  }

  /// Maps role string → enum for permission logic.
  /// SECURITY: unknown roles always map to mason (most restricted).
  static UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase().trim()) {
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      case 'mason':
      case 'worker':
        return UserRole.mason;
      default:
        debugPrint('[UserSession] _parseRole: unknown role "$roleStr" '
            '→ defaulting to UserRole.mason');
        return UserRole.mason;
    }
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSessionKey, json.encode({
        'id':          _userId,
        'role':        roleLabel,       // still stored for _parseRole compat
        'rawRoleName': _rawRoleName,    // FIX 1: persist raw name separately
        'projectIds':  _projectIds,
        'projectId':   projectId,
        'permissions': _permissions,
      }));
    } catch (e) {
      debugPrint('[UserSession] _persist error: $e');
    }
  }

  // ── Debug helpers ──────────────────────────────────────
  static void simulateAdmin() => set(
    userId: 'sim_admin', role: UserRole.admin,
    projectIds: ['proj_001'],
    rawRoleName: 'Admin',
  );

  static void simulateSupervisor() => set(
    userId: 'sim_sup', role: UserRole.supervisor,
    projectIds: ['proj_001', 'proj_002'],
    rawRoleName: 'Supervisor',
    permissions: const [
      'view_assigned_project', 'submit_daily_update',
      'upload_photos', 'upload_videos', 'submit_checklist',
      'report_issue', 'report_delay', 'approve_updates',
      'reject_updates', 'add_supervisor_remarks',
      'view_progress_dashboard', 'view_issue_tracker',
      'view_delay_tracker', 'view_media_gallery', 'view_reports',
      'view_projects', 'add_entries', 'approve_payments',
      'mark_paid',
    ],
  );

  static void simulateMason() => set(
    userId: 'sim_mason', role: UserRole.mason,
    projectIds: ['proj_001'],
    rawRoleName: 'Mason',
    permissions: const [
      'view_assigned_project', 'submit_daily_update',
      'upload_photos', 'upload_videos', 'submit_checklist',
      'report_issue', 'report_delay',
      'view_projects', 'add_entries',
    ],
  );

  /// Simulate a custom role (e.g. "Contractor") — resolves to mason for permissions
  static void simulateContractor() => set(
    userId: 'sim_contractor', role: UserRole.mason,
    projectIds: ['proj_001'],
    rawRoleName: 'Contractor', // FIX 1: shows "Contractor" in UI, not "Mason"
    permissions: const [
      'view_assigned_project',
      'submit_daily_update',
      'upload_photos',
    ],
  );
}