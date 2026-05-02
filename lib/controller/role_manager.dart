import 'package:buildtrack_mobile/controller/user_session.dart';
class RoleManager {
  RoleManager._();
  static bool get isAdmin => UserSession.isAdmin;
  static bool get isSupervisor => UserSession.isSupervisor;
  static bool get isMason => UserSession.isMason;
  static bool get canViewTeamAccess => isAdmin;
  static bool get canAssignRole => isAdmin;
  static bool get canApproveEntries => isAdmin || isSupervisor;
  static bool get canManageInventory => isAdmin || isSupervisor;
  static bool get canDeleteEntries => isAdmin || isSupervisor;
  static bool get canAddEntries => true;
  static bool get canUpdateProgress => true;
  static bool get canViewReports => true;
  static bool get canViewNotifications => true;
  static bool get canEditProfile => true;
  static const _restrictedRoutes = <String, bool Function()>{
    '/assign-role': _canAssignRole,
  };
  static bool _canAssignRole() => canAssignRole;
  static bool canNavigate(String route) {
    final check = _restrictedRoutes[route];
    if (check == null) return true;
    return check();
  }
}
