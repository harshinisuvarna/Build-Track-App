import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buildtrack_mobile/models/project_model.dart';

class ApiService {
  // NOTE: You mentioned your backend runs on 5000, so I set it to 5000.
  // Change to 'http://10.0.2.2:5001/api' if testing on an Android Emulator.
  static const String baseUrl = 'https://unsecured-coastland-canister.ngrok-free.dev/api';
  // static const String baseUrl = 'https://jargon-tit-stained.ngrok-free.dev/api';

  // ==========================================
  // ROSELIN'S WORK: CORE AUTH & GENERIC ROUTES
  // ==========================================
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ Try 'token' first, fall back to 'jwt_token'
    final token = prefs.getString('token') ?? prefs.getString('jwt_token');

  return {
    'Content-Type': 'application/json',
    // ✅ Required for ngrok to not block browser requests
    'ngrok-skip-browser-warning': 'true',
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
  // PROJECT API METHODS
  // ==========================================

  static Future<List<ProjectModel>> fetchProjects() async {
    try {
      final response = await get('/projects');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> rawList = [];
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map) {
          rawList = decoded['projects'] ?? decoded['data'] ?? [];
        }

        // --- THE FIX: Parse one by one to prevent full crashes ---
        List<ProjectModel> validProjects = [];
        for (var item in rawList) {
          try {
            validProjects.add(
              ProjectModel.fromJson(item as Map<String, dynamic>),
            );
          } catch (e) {
            // If a legacy project crashes, print exactly why, but keep loading the rest!
            print('CRASH parsing project ${item['_id']}: $e');
          }
        }

        return validProjects;
      } else if (response.statusCode == 401) {
        print('AUTH Error: Token missing (401).');
        throw Exception('Unauthorized');
      } else {
        print('GET /projects failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('fetchProjects Master Error: $e');
      return [];
    }
  }

  /// POST /api/projects → creates a project on the backend and returns the
  /// server-generated ProjectModel (with real `_id`), or `null` on failure.
  static Future<ProjectModel?> addProject(Map<String, dynamic> payload) async {
    try {
      final response = await post('/projects', payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        // The response may wrap the project in a key or return it directly.
        final Map<String, dynamic> projectJson =
            (decoded is Map && decoded.containsKey('project'))
            ? decoded['project'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return ProjectModel.fromJson(projectJson);
      } else {
        print(
          'POST /projects failed (${response.statusCode}): ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('addProject Error: $e');
      return null;
    }
  }

  // ==========================================
  // HARSHINI'S WORK: TRACK 2 SPECIFIC METHODS
  // ==========================================

  // 1. HTTP GET: Fetch Materials
  static Future<List<dynamic>> fetchMaterials() async {
    try {
      final response = await get('/transactions');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // --- SMART PARSING: handles List, Map-wrapped, or empty ---
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded['transactions'] ?? decoded['data'] ?? [];
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
          'GET /transactions failed with status ${response.statusCode}: ${response.body}',
        );
        throw Exception(
          'Failed to load transactions (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      print('GET Error: $e');
      return [];
    }
  }

  // 2. HTTP POST: Add New Entry (Redirected to the correct transactional router context)
  static Future<bool> addMaterial(Map<String, dynamic> payload) async {
    try {
      // 🌟 CHANGED PATH URL: From '/inventory' to '/transactions' to resolve your 404 Route Not Found error
      final response = await post('/transactions', payload);

      print('=== SERVER RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('POST Error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> addTransaction(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await post('/transactions', payload);
      print('=== SERVER RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('POST Error: $e');
      return null;
    }
  }

  // Update transaction payment (e.g. Record Payment)
  static Future<bool> updateTransactionPayment(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await put('/transactions/$id', payload);
      print('=== UPDATE TRANSACTION RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('PUT /transactions/$id Error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> fetchInventory(String projectId) async {
    try {
      // 1. CHANGED: Ask for the full transaction history to capture Wages and Expenses
      String endpoint = '/transactions';
      if (projectId.isNotEmpty) endpoint += '?project=$projectId';

      final response = await get(endpoint);

      print('fetchInventory status: ${response.statusCode}');
      print('fetchInventory body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> raw = [];
        if (decoded is List) {
          raw = decoded;
        } else if (decoded is Map) {
          // 2. CHANGED: Added 'transactions' so it recognizes the backend payload
          raw =
              (decoded['transactions'] ??
                      decoded['inventory'] ??
                      decoded['data'] ??
                      decoded['items'] ??
                      [])
                  as List<dynamic>;
        }

        // ROSELIN'S LOGIC: Preserving her complex grouping algorithm
        // --- UPDATED GROUPING ALGORITHM ---
        final Map<String, Map<String, dynamic>> grouped = {};

        for (final t in raw) {
          // 1. Get the original category name (e.g., "gas", "Crane Rental", "Sunil Contractors")
          final String originalCategory =
              (t['category'] ?? t['materialName'] ?? 'Unknown')
                  .toString()
                  .trim();

          // 2. Determine the TAB type (material, labour, or equipment)
          final String rawCat = originalCategory.toLowerCase();
          final String rawType = (t['type'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          String tabType = 'material'; // Default
          if (rawCat == 'labour' ||
              rawCat == 'wages' ||
              rawCat == 'labor' ||
              rawCat.contains('labour') ||
              rawType == 'wages' ||
              rawType == 'labour') {
            tabType = 'labour';
          } else if (rawCat == 'equipment' ||
              rawCat == 'machinery' ||
              rawCat == 'expense' ||
              rawType == 'expense' ||
              rawType == 'equipment') {
            tabType = 'equipment';
          }

          // 3. Group by the ORIGINAL CATEGORY name, not the title
          final String key = '$originalCategory||$tabType';
          final double qty = (t['quantity'] ?? t['purchased'] ?? 0).toDouble();
          final String unit = (t['unit'] ?? 'units').toString();

          if (grouped.containsKey(key)) {
            // If the category exists, add to the total stock
            grouped[key]!['purchased'] =
                (grouped[key]!['purchased'] as double) + qty;
            grouped[key]!['closingStock'] =
                (grouped[key]!['closingStock'] as double) + qty;
          } else {
            // Create a new category card
            grouped[key] = {
              '_id': t['_id'] ?? key,
              'materialName':
                  originalCategory, // <-- UI reads this for the Card Title!
              'category': tabType, // <-- UI reads this to sort into Tabs!
              'purchased': qty,
              'used': 0.0,
              'closingStock': qty,
              'threshold': 10.0,
              'unit': unit,
            };
          }
        }

        print('fetchInventory grouped items: ${grouped.length}');
        return grouped.values.toList();
      } else {
        print('fetchInventory failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e, stack) {
      print('Inventory GET Error: $e');
      print(stack.toString());
      return [];
    }
  }

  // POST /api/auth/reset-password
  static Future<bool> resetPassword(String email) async {
    try {
      // Using your existing 'post' helper!
      // baseUrl is already 'http:', so we just add the endpoint.
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

  static Future<void> addInventoryItem({
    required String materialName,
    required double purchased,
    required String unit,
    required String projectId,
    required String category,
    double threshold = 10,
  }) async {
    try {
      final response = await post('/inventory/add', {
        'materialName': materialName,
        'purchased': purchased,
        'unit': unit,
        'project': projectId,
        'category': category,
        'threshold': threshold,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
          'addInventoryItem failed (${response.statusCode}): ${response.body}',
        );
        throw Exception('Failed to add inventory item');
      }
    } catch (e) {
      print('addInventoryItem Error: $e');
      rethrow;
    }
  }

  static Future<bool> updateTransaction(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await put('/transactions/$id', payload);
      print('=== PUT UPDATE TRANSACTION RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('PUT /transactions/$id Error: $e');
      return false;
    }
  }

  static Future<bool> deleteTransaction(String id) async {
    try {
      final response = await delete('/transactions/$id');
      print('=== DELETE TRANSACTION RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('DELETE /transactions/$id Error: $e');
      return false;
    }
  }

  static Future<bool> deleteProject(String id) async {
    try {
      final response = await delete('/projects/$id');
      print('=== DELETE PROJECT RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('DELETE /projects/$id Error: $e');
      return false;
    }
  }
}
