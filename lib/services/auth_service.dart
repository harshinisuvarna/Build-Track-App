// auth_service.dart — full replacement

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  // ─────────────────────────────────────────────────────────
  // LOGIN
  // Returns the full decoded response body on success,
  // throws Exception with the server message on failure.
  // ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        // ✅ backend safeUser() returns 'id' not '_id'
        final Map<String, dynamic> user =
            Map<String, dynamic>.from(data['user'] ?? {});

        if (token == null) {
          throw Exception('Token not found in login response');
        }

        // ── Persist token ──────────────────────────────────
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('jwt_token', token); // backup

        // ── Persist role string for legacy getUserRole() ───
        final roleStr = user['role']?.toString() ?? 'Mason';
        await prefs.setString('user_role', roleStr);

        // ✅ fromLoginResponse stores userId, role, projectId,
        //    AND permissions — and persists all of them to prefs
        await UserSession.fromLoginResponse(user);

        debugPrint('[AuthService] Login OK — role=$roleStr '
            'projectId=${UserSession.projectId} '
            'permissions=${UserSession.permissions}');

        return data;
      } else {
        final message = data is Map && data.containsKey('message')
            ? data['message'].toString()
            : 'Login failed (${response.statusCode})';
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('[AuthService] Login error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // LOGOUT — clears token + full session
  // ─────────────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    // ✅ await — UserSession.clear() is now async (removes prefs key too)
    await UserSession.clear();
    debugPrint('[AuthService] Logged out — session cleared');
  }

  // ─────────────────────────────────────────────────────────
  // TOKEN HELPERS
  // ─────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Kept for legacy callers — returns just the role string
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // ─────────────────────────────────────────────────────────
  // CHECK IF LOGGED IN (token exists + session loaded)
  // Call this in main.dart / splash screen
  // ─────────────────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}