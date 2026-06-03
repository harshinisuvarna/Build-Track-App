import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NOTE: Do NOT import AuthService here — that creates a circular dependency
// (AuthService imports UserSession, UserSession imports AuthService).
// loadFromPrefs() reads SharedPreferences directly instead.

enum UserRole { admin, supervisor, mason }

class UserSession {
  UserSession._();

  static const String _kSessionKey = 'buildtrack_user_session';

  // ── In-memory state ────────────────────────────────────
  static String    _userId      = '';
  static UserRole  _role        = UserRole.admin;
  static String    projectId    = '';
  static List<String> _permissions = [];
  static bool      _initialized = false;

  // ── Getters ────────────────────────────────────────────
  static String       get userId      => _userId;
  static UserRole     get role        => _role;
  static List<String> get permissions => List.unmodifiable(_permissions);
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
  // Admin always passes every check.
  static bool hasPermission(String key) {
    if (isAdmin) return true;
    return _permissions.contains(key);
  }

  // ── Called right after a successful login API response ─
  // Populates memory AND persists to SharedPreferences so
  // the session survives app restarts.
  static Future<void> fromLoginResponse(
      Map<String, dynamic> user) async {
    // backend safeUser() returns 'id' (not '_id')
    _userId   = user['id']?.toString() ?? '';
    projectId = user['projectId']?.toString() ?? '';
    _role     = _parseRole(user['role']?.toString());

    final raw = user['permissions'];
    _permissions = raw is List
        ? raw.map((e) => e.toString()).toList()
        : [];

    _initialized = true;

    await _persist();

    debugPrint('[UserSession] fromLoginResponse → '
        'role=$roleLabel '
        'projectId=$projectId '
        'permissions=$_permissions');
  }

  // ── Called on app start (main.dart / splash) ───────────
  // Restores the full session from SharedPreferences so the
  // user doesn't have to log in again after a restart.
  static Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kSessionKey);

      if (raw == null || raw.isEmpty) {
        _initialized = true;
        return;
      }

      final data = json.decode(raw) as Map<String, dynamic>;

      _userId      = data['id']?.toString()        ?? '';
      projectId    = data['projectId']?.toString() ?? '';
      _role        = _parseRole(data['role']?.toString());

      final perms  = data['permissions'];
      _permissions = perms is List
          ? perms.map((e) => e.toString()).toList()
          : [];

      _initialized = true;

      debugPrint('[UserSession] loadFromPrefs → '
          'role=$roleLabel '
          'projectId=$projectId '
          'permissions=$_permissions');
    } catch (e) {
      debugPrint('[UserSession] loadFromPrefs error: $e');
      _initialized = true; // don't block app start
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

    debugPrint('[UserSession] cleared');
  }

  // ── Manual set (kept for compatibility / debug sims) ───
  static void set({
    required String   userId,
    required UserRole role,
    String            projectId    = '',
    List<String>      permissions  = const [],
  }) {
    _userId           = userId;
    _role             = role;
    UserSession.projectId = projectId;
    _permissions      = List<String>.from(permissions);
    _initialized      = true;
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