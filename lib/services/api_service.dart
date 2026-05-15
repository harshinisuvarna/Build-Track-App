import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // NOTE: You mentioned your backend runs on 5000, so I set it to 5000.
  // Change to 'http://10.0.2.2:5000/api' if testing on an Android Emulator.
  static const String baseUrl = 'http://localhost:5001/api';

  // ==========================================
  // ROSELIN'S WORK: CORE AUTH & GENERIC ROUTES
  // ==========================================
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  // ==========================================
  // HARSHINI'S WORK: TRACK 2 SPECIFIC METHODS
  // ==========================================

  // 1. HTTP GET: Fetch Materials
  static Future<List<dynamic>> fetchMaterials() async {
    try {
      final response = await get('/inventory');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // --- SMART PARSING: handles List, Map-wrapped, or empty ---
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded['materials'] ??
              decoded['inventory'] ??
              decoded['data'] ??
              decoded['items'] ??
              [];
        }
        return [];
      } else if (response.statusCode == 401) {
        // Token missing/expired — surface this clearly
        print(
          'AUTH Error: Token missing or expired (401). Body: ${response.body}',
        );
        throw Exception('Unauthorized – please log in again');
      } else {
        print(
          'GET /inventory failed with status ${response.statusCode}: ${response.body}',
        );
        throw Exception(
          'Failed to load materials (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      print('GET Error: $e');
      return [];
    }
  }

  // 2. HTTP POST: Add New Material
  static Future<bool> addMaterial(Map<String, dynamic> payload) async {
    try {
      final response = await post('/inventory', payload);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('POST Error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> fetchInventory(String projectId) async {
    try {
      final response = await get('/inventory');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded['inventory'] ??
              decoded['data'] ??
              decoded['items'] ??
              [];
        }
        return [];
      } else {
        throw Exception('Failed to load live inventory');
      }
    } catch (e) {
      print('Inventory GET Error: $e');
      return [];
    }
  }

  // POST /api/auth/reset-password
  static Future<bool> resetPassword(String email) async {
    try {
      // Using your existing 'post' helper!
      // baseUrl is already 'http://localhost:5000/api', so we just add the endpoint.
      final response = await post('/auth/reset-password', {'email': email});

      // Return true if 200 OK or 201 Created
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to request password reset: $e');
    }
  }

  // GET /api/inventory with Search & Category filters
  static Future<List<dynamic>> searchMaterials({
    String? query,
    String? category,
  }) async {
    try {
      // Build the query string dynamically
      String endpoint = '/inventory?';
      if (query != null && query.isNotEmpty) endpoint += 'search=$query&';
      if (category != null && category.isNotEmpty && category != 'All') {
        endpoint += 'category=${category.toLowerCase()}';
      }

      final response = await get(endpoint);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map) {
          return decoded['inventory'] ?? decoded['data'] ?? [];
        }
        return [];
      } else {
        throw Exception('Search failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Search API Error: $e');
      return [];
    }
  }

  // TASK 3: Fetch Live Daily Tasks
  static Future<List<dynamic>> fetchDailyTasks() async {
    try {
      final response = await get('/tasks/daily');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map) return decoded['tasks'] ?? decoded['data'] ?? [];
        return [];
      } else {
        throw Exception('Failed to load daily tasks');
      }
    } catch (e) {
      print('Tasks API Error: $e');
      return []; // Return empty list on error to prevent UI crash
    }
  }
}
