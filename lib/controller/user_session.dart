library;
enum UserRole { admin, supervisor, mason }
class UserSession {
  UserSession._();
  static String _userId = '';
  static UserRole _role = UserRole.admin;
  static String _projectId = '';
  static void set({
    required String userId,
    required UserRole role,
    String projectId = '',
  }) {
    _userId = userId;
    _role = role;
    _projectId = projectId;
  }
  static void clear() {
    _userId = '';
    _role = UserRole.admin;
    _projectId = '';
  }
  static String get userId => _userId;
  static UserRole get role => _role;
  static String get projectId => _projectId;
  static String get roleLabel {
    switch (_role) {
      case UserRole.admin:      return 'Admin';
      case UserRole.supervisor: return 'Supervisor';
      case UserRole.mason:      return 'Mason';
    }
  }
  static bool get isAdmin      => _role == UserRole.admin;
  static bool get isSupervisor => _role == UserRole.supervisor;
  static bool get isMason      => _role == UserRole.mason;
  static void simulateAdmin() =>
      set(userId: 'sim_admin', role: UserRole.admin, projectId: 'proj_001');
  static void simulateSupervisor() =>
      set(userId: 'sim_sup', role: UserRole.supervisor, projectId: 'proj_001');
  static void simulateMason() =>
      set(userId: 'sim_mason', role: UserRole.mason, projectId: 'proj_001');
}
