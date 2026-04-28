/// UserSession — single source of truth for the logged-in user.
///
/// Usage:
///   // Set at login time (or in simulation):
///   UserSession.set(userId: 'u001', role: UserRole.admin, projectId: 'p001');
///
///   // Read anywhere in the app:
///   UserSession.role        // → UserRole.admin
///   UserSession.userId      // → 'u001'
///   UserSession.projectId   // → 'p001'
///   UserSession.roleLabel   // → 'Admin'
///   UserSession.isAdmin     // → true
library;

enum UserRole { admin, supervisor, mason }

class UserSession {
  UserSession._(); // prevent instantiation

  // ── Internal state ────────────────────────────────────────────────────────

  static String _userId = '';
  static UserRole _role = UserRole.admin;
  static String _projectId = '';

  // ── Setters ───────────────────────────────────────────────────────────────

  /// Call this after a successful login (or to simulate one).
  static void set({
    required String userId,
    required UserRole role,
    String projectId = '',
  }) {
    _userId = userId;
    _role = role;
    _projectId = projectId;
  }

  /// Clears the session (call on logout).
  static void clear() {
    _userId = '';
    _role = UserRole.admin;
    _projectId = '';
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  static String get userId => _userId;
  static UserRole get role => _role;
  static String get projectId => _projectId;

  /// Human-readable role label matching the existing UI strings.
  static String get roleLabel {
    switch (_role) {
      case UserRole.admin:      return 'Admin';
      case UserRole.supervisor: return 'Supervisor';
      case UserRole.mason:      return 'Mason';
    }
  }

  // ── Convenience booleans ──────────────────────────────────────────────────

  static bool get isAdmin      => _role == UserRole.admin;
  static bool get isSupervisor => _role == UserRole.supervisor;
  static bool get isMason      => _role == UserRole.mason;

  // ── Temporary login simulation ────────────────────────────────────────────
  // Remove this block once real auth is wired up.

  /// Simulates an Admin login. Call from main() or LoginScreen.
  static void simulateAdmin() =>
      set(userId: 'sim_admin', role: UserRole.admin, projectId: 'proj_001');

  /// Simulates a Supervisor login.
  static void simulateSupervisor() =>
      set(userId: 'sim_sup', role: UserRole.supervisor, projectId: 'proj_001');

  /// Simulates a Mason login.
  static void simulateMason() =>
      set(userId: 'sim_mason', role: UserRole.mason, projectId: 'proj_001');
}
