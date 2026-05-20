import 'dart:convert';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = data['user']; 

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);

          // Update UserSession
          UserRole role = UserRole.admin;
          String savedRole = 'admin';
          if (user != null && user['role'] != null) {
            final roleStr = user['role'].toString().toLowerCase();
            savedRole = roleStr;
            if (roleStr == 'supervisor') role = UserRole.supervisor;
            if (roleStr == 'worker' || roleStr == 'mason') role = UserRole.mason;
          }

          await prefs.setString('user_role', savedRole);

          UserSession.set(
            userId: user?['_id'] ?? user?['id'] ?? '',
            role: role,
            projectId: user?['projectId'] ?? '',
          );

          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    UserSession.clear();
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }
}
