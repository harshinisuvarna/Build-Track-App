import 'dart:convert';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  // ✅ NOW RETURNS FULL JSON MAP (NOT bool)
  static Future<Map<String, dynamic>?> login(
      String email,
      String password,
  ) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token'];
        final user = data['user'];

        if (token == null) return null;

        final prefs = await SharedPreferences.getInstance();

        // ✅ SINGLE TOKEN KEY (use only ONE in app)
        await prefs.setString('token', token);

        // optional backup
        await prefs.setString('jwt_token', token);

        // save role
        String role = user?['role'] ?? 'worker';
        await prefs.setString('user_role', role);

        // session
        UserSession.set(
          userId: user?['_id'] ?? '',
          role: role == 'admin'
              ? UserRole.admin
              : role == 'supervisor'
                  ? UserRole.supervisor
                  : UserRole.mason,
          projectId: user?['projectId'] ?? '',
        );

        return data; // ✅ IMPORTANT
      }

      return null;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    UserSession.clear();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_role');
}
}