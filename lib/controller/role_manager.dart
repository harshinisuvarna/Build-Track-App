import 'package:buildtrack_mobile/controller/user_session.dart';

/// Centralized Role-Based Access Control (RBAC) manager.
///
/// All feature-level permission checks live here.
/// Screens should call `RoleManager.canX()` instead of
/// checking `UserSession.isAdmin` directly.
///
/// Usage:
///   if (RoleManager.canViewTeamAccess) { /* show section */ }
///   if (RoleManager.canApproveEntries) { /* show approve button */ }
class RoleManager {
  RoleManager._(); // prevent instantiation

  // ── Role identity ─────────────────────────────────────────────────────────

  /// True when the current user is an Admin.
  static bool get isAdmin => UserSession.isAdmin;

  /// True when the current user is a Supervisor.
  static bool get isSupervisor => UserSession.isSupervisor;

  /// True when the current user is a Mason.
  static bool get isMason => UserSession.isMason;

  // ── Feature-level permissions ─────────────────────────────────────────────

  /// Whether the user can see the "Team & Access" section on Add Entry.
  /// Admin only.
  static bool get canViewTeamAccess => isAdmin;

  /// Whether the user can access the "Assign Role" screen.
  /// Admin only.
  static bool get canAssignRole => isAdmin;

  /// Whether the user can approve or reject entries.
  /// Admin and Supervisor.
  static bool get canApproveEntries => isAdmin || isSupervisor;

  /// Whether the user can manage inventory (add/edit/delete items).
  /// Admin and Supervisor.
  static bool get canManageInventory => isAdmin || isSupervisor;

  /// Whether the user can delete entries.
  /// Admin and Supervisor.
  static bool get canDeleteEntries => isAdmin || isSupervisor;

  /// Whether the user can add new entries (material, labour, equipment).
  /// All roles can add entries.
  static bool get canAddEntries => true;

  /// Whether the user can update their own work progress.
  /// All roles.
  static bool get canUpdateProgress => true;

  /// Whether the user can view reports / dashboard.
  /// All roles (data is filtered per role elsewhere).
  static bool get canViewReports => true;

  /// Whether the user can view notifications.
  /// All roles.
  static bool get canViewNotifications => true;

  /// Whether the user can edit their own profile.
  /// All roles.
  static bool get canEditProfile => true;

  // ── Navigation guard ──────────────────────────────────────────────────────

  /// Set of route names that require specific permissions.
  /// Used by the route guard in main.dart.
  static const _restrictedRoutes = <String, bool Function()>{
    '/assign-role': _canAssignRole,
  };

  // Static tear-off helpers (Dart doesn't allow getters in const maps)
  static bool _canAssignRole() => canAssignRole;

  /// Returns `true` if the current user is allowed to navigate to [route].
  /// Returns `true` for any route not in the restricted list (open by default).
  static bool canNavigate(String route) {
    final check = _restrictedRoutes[route];
    if (check == null) return true; // unrestricted route
    return check();
  }
}
