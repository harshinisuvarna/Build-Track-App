import 'package:buildtrack_mobile/controller/user_session.dart';

/// Single source of truth for what the current user can do.
/// Admin always passes every check.
/// Supervisor/Mason pass only if the admin granted them that permission.
class RoleManager {
  RoleManager._();

  // ── Role shortcuts ─────────────────────────────────────
  static bool get isAdmin      => UserSession.isAdmin;
  static bool get isSupervisor => UserSession.isSupervisor;
  static bool get isMason      => UserSession.isMason;

  // ── Permission keys — must match what backend stores ───
  // These are the strings your AssignRoleScreen sends:
  //   'view_projects', 'add_entries', 'approve_payments',
  //   'mark_paid', 'view_reports', 'manage_team'

  // Can the user see the project list / project details?
  static bool get canViewProjects =>
      UserSession.hasPermission('view_projects');

  // Can the user add labour / material / equipment entries?
  static bool get canAddEntries =>
      UserSession.hasPermission('add_entries');

  // Can the user approve a payment?
  static bool get canApprovePayments =>
      UserSession.hasPermission('approve_payments');

  // Can the user mark an entry as paid?
  static bool get canMarkPaid =>
      UserSession.hasPermission('mark_paid');

  // Can the user open reports / analytics?
  static bool get canViewReports =>
      UserSession.hasPermission('view_reports');

  // Can the user assign roles / manage team? (Admin-only effectively)
  static bool get canManageTeam =>
      UserSession.hasPermission('manage_team');

  // ── Compound convenience getters ───────────────────────
  static bool get canAssignRole      => isAdmin;
  static bool get canViewTeamAccess  => isAdmin;
  static bool get canDeleteEntries   => isAdmin || canApprovePayments;
  static bool get canManageInventory => isAdmin || canAddEntries;
  static bool get canApproveEntries  => isAdmin || canApprovePayments;
  static bool get canUpdateProgress  => canAddEntries;
  static bool get canViewNotifications => true;
  static bool get canEditProfile     => true;

  // ── Route guard ────────────────────────────────────────
  static const _restrictedRoutes = <String, bool Function()>{
    '/assign-role': _checkAssignRole,
    '/reports':     _checkReports,
  };

  static bool _checkAssignRole() => canAssignRole;
  static bool _checkReports()    => canViewReports;

  static bool canNavigate(String route) {
    final check = _restrictedRoutes[route];
    if (check == null) return true;
    return check();
  }
}