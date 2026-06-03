import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NOTE: Do NOT import AuthService here — that creates a circular dependency.

enum UserRole { admin, supervisor, mason }

/// A ChangeNotifier so that any widget watching it via
/// context.watch<UserSession>() rebuilds when session loads.
class UserSession extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────
  static final UserSession _instance = UserSession._();
  factory UserSession() => _instance;
  UserSession._();

  static const String _kSessionKey = 'buildtrack_user_session';

  // ── In-memory state ────────────────────────────────────
  static String       _userId      = '';
  static UserRole     _role        = UserRole.admin;
  static String       projectId    = '';
  static List<String> _permissions = [];
  static bool         _initialized = false;

  // ── Getters ────────────────────────────────────────────
  static String       get userId        => _userId;
  static UserRole     get role          => _role;
  static List<String> get permissions   => List.unmodifiable(_permissions);
  static bool         get isInitialized => _initialized;

  static bool get isAdmin      => _role == UserRole.admin;
  static bool get isSupervisor => _role == UserRole.supervisor;
  static bool get isMason      => _role == UserRole.mason;

  static String get roleLabel {
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
    _userId   = user['id']?.toString() ?? '';
    projectId = user['projectId']?.toString() ?? '';
    _role     = _parseRole(user['role']?.toString());

    final raw = user['permissions'];
    _permissions = raw is List
        ? raw.map((e) => e.toString()).toList()
        : [];

    _initialized = true;
    await _persist();

    // Notify all listening widgets
    _instance.notifyListeners();

    debugPrint('[UserSession] fromLoginResponse → '
        'role=$roleLabel projectId=$projectId permissions=$_permissions');
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

      _userId   = data['id']?.toString()        ?? '';
      projectId = data['projectId']?.toString() ?? '';
      _role     = _parseRole(data['role']?.toString());

      final perms  = data['permissions'];
      _permissions = perms is List
          ? perms.map((e) => e.toString()).toList()
          : [];

      _initialized = true;
      _instance.notifyListeners();

      debugPrint('[UserSession] loadFromPrefs → '
          'role=$roleLabel projectId=$projectId permissions=$_permissions');
    } catch (e) {
      debugPrint('[UserSession] loadFromPrefs error: $e');
      _initialized = true;
      _instance.notifyListeners();
    }
  }

  // ── Called on logout ───────────────────────────────────
  static Future<void> clear() async {
    _userId      = '';
    _role        = UserRole.admin;
    projectId    = '';
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
    String            projectId    = '',
    List<String>      permissions  = const [],
  }) {
    _userId               = userId;
    _role                 = role;
    UserSession.projectId = projectId;
    _permissions          = List<String>.from(permissions);
    _initialized          = true;
    _instance.notifyListeners();
  }

  // ── Private helpers ────────────────────────────────────
  static UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'supervisor': return UserRole.supervisor;
      case 'mason':
      case 'worker':     return UserRole.mason;
      default:           return UserRole.admin;
    }
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSessionKey, json.encode({
        'id':          _userId,
        'role':        roleLabel,
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
    projectId: 'proj_001', permissions: const [],
  );

  static void simulateSupervisor() => set(
    userId: 'sim_sup', role: UserRole.supervisor,
    projectId: 'proj_001',
    permissions: const [
      'view_projects', 'add_entries',
      'approve_payments', 'mark_paid', 'view_reports',
    ],
  );

  static void simulateMason() => set(
    userId: 'sim_mason', role: UserRole.mason,
    projectId: 'proj_001',
    permissions: const ['view_projects', 'add_entries'],
  );
}