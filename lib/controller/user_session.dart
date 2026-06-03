import 'package:buildtrack_mobile/services/auth_service.dart';

enum UserRole { admin, supervisor, mason }

class UserSession {
  UserSession._();

  static String _userId = '';
  static UserRole _role = UserRole.admin;
  static String projectId = '';

  static List<String> _permissions = [];

  static bool _initialized = false;

  static void set({
    required String userId,
    required UserRole role,
    String projectId = '',
    List<String> permissions = const [],
  }) {
    _userId = userId;
    _role = role;
    UserSession.projectId = projectId;
    _permissions = List<String>.from(permissions);
    _initialized = true;
  }

  static void clear() {
    _userId = '';
    _role = UserRole.admin;
    projectId = '';
    _permissions = [];
    _initialized = false;
  }

  // ----------------------------
  // SAFE INIT FROM STORAGE
  // ----------------------------
  static Future<void> loadFromPrefs() async {
    final roleStr = (await AuthService.getUserRole())?.toLowerCase();

    if (roleStr == null) {
      _role = UserRole.admin;
      _initialized = true;
      return;
    }

    switch (roleStr) {
      case 'supervisor':
        _role = UserRole.supervisor;
        break;

      case 'worker':
      case 'mason':
        _role = UserRole.mason;
        break;

      case 'admin':
        _role = UserRole.admin;
        break;

      default:
        _role = UserRole.admin;
        break;
    }

    _initialized = true;
  }

  static bool get isInitialized => _initialized;

  static String get userId => _userId;
  static UserRole get role => _role;

  static List<String> get permissions => List.unmodifiable(_permissions);

  static bool hasPermission(String key) {
    if (isAdmin) return true;
    return _permissions.contains(key);
  }

  static void fromLoginResponse(Map<String, dynamic> user) {
    _userId = user['id']?.toString() ?? '';
    projectId = user['projectId']?.toString() ?? '';

    final roleStr = user['role']?.toString().toLowerCase() ?? 'admin';
    switch (roleStr) {
      case 'supervisor':
        _role = UserRole.supervisor;
        break;
      case 'worker':
      case 'mason':
        _role = UserRole.mason;
        break;
      case 'admin':
        _role = UserRole.admin;
        break;
      default:
        _role = UserRole.admin;
        break;
    }

    final rawPermissions = user['permissions'];
    if (rawPermissions is List) {
      _permissions = rawPermissions.map((e) => e.toString()).toList();
    } else {
      _permissions = [];
    }

    _initialized = true;
  }

  static String get roleLabel {
    switch (_role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.mason:
        return 'Mason';
    }
  }

  static bool get isAdmin => _role == UserRole.admin;
  static bool get isSupervisor => _role == UserRole.supervisor;
  static bool get isMason => _role == UserRole.mason;

  // ----------------------------
  // DEBUG HELPERS
  // ----------------------------
  static void simulateAdmin() => set(
        userId: 'sim_admin',
        role: UserRole.admin,
        projectId: 'proj_001',
        permissions: const [],
      );

  static void simulateSupervisor() => set(
        userId: 'sim_sup',
        role: UserRole.supervisor,
        projectId: 'proj_001',
        permissions: const [],
      );

  static void simulateMason() => set(
        userId: 'sim_mason',
        role: UserRole.mason,
        projectId: 'proj_001',
        permissions: const [],
      );
}