import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // NOTE: You mentioned your backend runs on 5000, so I set it to 5000.
  // Change to 'http://10.0.2.2:5000/api' if testing on an Android Emulator.
  static const String baseUrl = 'http://localhost:5000/api';

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

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }
  
  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
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
        
        // --- SMART PARSING APPLIED HERE SO IT NEVER CRASHES ---
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded['materials'] ?? decoded['inventory'] ?? decoded['data'] ?? decoded['items'] ?? [];
        }
        return [];
        
      } else {
        throw Exception('Failed to load materials');
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
          return decoded['inventory'] ?? decoded['data'] ?? decoded['items'] ?? [];
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
}