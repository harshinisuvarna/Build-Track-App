// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buildtrack_mobile/models/project_model.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  // Configured Base URL based on runtime platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    // Android emulator maps 10.0.2.2 to host localhost port 5000
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    // iOS simulator, macOS, Windows, Linux
    return 'http://localhost:5000/api';
    
    // Ngrok Fallback (Uncomment if testing on a physical device over network)
    // return 'https://unsecured-coastland-canister.ngrok-free.dev/api';
  }

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

  /// GET /api/projects/:id → fetches a single project with ALL fields
  static Future<ProjectModel?> fetchProjectById(String id) async {
    try {
      final response = await get('/projects/$id');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final Map<String, dynamic> projectJson =
            (decoded is Map && decoded.containsKey('project'))
            ? decoded['project'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return ProjectModel.fromJson(projectJson);
      }
      return null;
    } catch (e) {
      print('fetchProjectById error: $e');
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

        // --- UPDATED GROUPING ALGORITHM (GROUP BY ITEM/TRANSACTION TITLE) ---
        final Map<String, Map<String, dynamic>> grouped = {};

        for (final t in raw) {
          // Get the item name (Cement, Steel, M Sand, Mason, Excavator, etc.) from the title field
          final String itemName = (t['title'] ?? t['materialName'] ?? t['name'] ?? 'Unknown')
              .toString()
              .trim();

          // Determine the TAB type (material, labour, or equipment) based on transaction type or category fallback
          final String rawType = (t['type'] ?? '').toString().trim().toLowerCase();
          String tabType = 'material'; // Default
          if (rawType == 'wages' || rawType == 'labour') {
            tabType = 'labour';
          } else if (rawType == 'expense' || rawType == 'equipment') {
            tabType = 'equipment';
          } else if (rawType == 'materials') {
            tabType = 'material';
          } else {
            final String originalCategory = (t['category'] ?? t['materialName'] ?? '').toString().trim().toLowerCase();
            if (originalCategory == 'labour' ||
                originalCategory == 'wages' ||
                originalCategory == 'labor' ||
                originalCategory.contains('labour')) {
              tabType = 'labour';
            } else if (originalCategory == 'equipment' ||
                originalCategory == 'machinery' ||
                originalCategory == 'expense') {
              tabType = 'equipment';
            }
          }

          String unit = (t['unit'] ?? '').toString().trim();
          if (unit.toLowerCase() == 'units' || unit.toLowerCase() == 'unit') {
            unit = '';
          }
          final String key = '$itemName||$tabType||$unit';
          final double qty = (t['quantity'] ?? t['purchased'] ?? 0).toDouble();

          final bool isPositive = t['subType']?.toString().toLowerCase() != 'consumption' &&
              t['materialType']?.toString().toLowerCase() != 'usage';

          if (grouped.containsKey(key)) {
            // If the item exists, add to the total stock
            if (isPositive) {
              grouped[key]!['purchased'] = (grouped[key]!['purchased'] as double) + qty;
              grouped[key]!['closingStock'] = (grouped[key]!['closingStock'] as double) + qty;
            } else {
              grouped[key]!['used'] = (grouped[key]!['used'] as double) + qty;
              grouped[key]!['closingStock'] = (grouped[key]!['closingStock'] as double) - qty;
            }
            (grouped[key]!['transactions'] as List<dynamic>).add(t);
          } else {
            // Create a new item card
            grouped[key] = {
              '_id': t['_id'] ?? key,
              'materialName': itemName, // <-- UI reads this for the Card Title!
              'category': tabType, // <-- UI reads this to sort into Tabs!
              'purchased': isPositive ? qty : 0.0,
              'used': isPositive ? 0.0 : qty,
              'closingStock': isPositive ? qty : -qty,
              'threshold': 10.0,
              'unit': unit,
              'transactions': [t],
            };
          }
        }

        // Sort transactions in each group descending by date
        for (final item in grouped.values) {
          final txs = item['transactions'] as List<dynamic>;
          txs.sort((a, b) {
            final dateA = a['date'] ?? '';
            final dateB = b['date'] ?? '';
            return dateB.toString().compareTo(dateA.toString());
          });
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
    String? projectId,
  }) async {
    try {
      // Build the query string dynamically
      String endpoint = '/transactions?';
      if (projectId != null && projectId.isNotEmpty) endpoint += 'project=$projectId&';
      if (query != null && query.isNotEmpty) endpoint += 'search=$query&';
      if (category != null && category.isNotEmpty && category != 'All') {
        String backendType = 'Materials';
        if (category.toLowerCase() == 'labour') backendType = 'Wages';
        if (category.toLowerCase() == 'equipment') backendType = 'Expense';
        endpoint += 'type=$backendType&';
      }

      final response = await get(endpoint);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> raw = [];
        if (decoded is List) {
          raw = decoded;
        } else if (decoded is Map) {
          raw = (decoded['transactions'] ?? decoded['data'] ?? []) as List<dynamic>;
        }

        final Map<String, Map<String, dynamic>> grouped = {};

        for (final t in raw) {
          final String itemName = (t['title'] ?? t['materialName'] ?? t['name'] ?? 'Unknown')
              .toString()
              .trim();

          final String rawType = (t['type'] ?? '').toString().trim().toLowerCase();
          String tabType = 'material';
          if (rawType == 'wages' || rawType == 'labour') {
            tabType = 'labour';
          } else if (rawType == 'expense' || rawType == 'equipment') {
            tabType = 'equipment';
          } else if (rawType == 'materials') {
            tabType = 'material';
          } else {
            final String originalCategory = (t['category'] ?? t['materialName'] ?? '').toString().trim().toLowerCase();
            if (originalCategory == 'labour' ||
                originalCategory == 'wages' ||
                originalCategory == 'labor' ||
                originalCategory.contains('labour')) {
              tabType = 'labour';
            } else if (originalCategory == 'equipment' ||
                originalCategory == 'machinery' ||
                originalCategory == 'expense') {
              tabType = 'equipment';
            }
          }

          String unit = (t['unit'] ?? '').toString().trim();
          if (unit.toLowerCase() == 'units' || unit.toLowerCase() == 'unit') {
            unit = '';
          }
          final String key = '$itemName||$tabType||$unit';
          final double qty = (t['quantity'] ?? t['purchased'] ?? 0).toDouble();

          final bool isPositive = t['subType']?.toString().toLowerCase() != 'consumption' &&
              t['materialType']?.toString().toLowerCase() != 'usage';

          if (grouped.containsKey(key)) {
            if (isPositive) {
              grouped[key]!['purchased'] = (grouped[key]!['purchased'] as double) + qty;
              grouped[key]!['closingStock'] = (grouped[key]!['closingStock'] as double) + qty;
            } else {
              grouped[key]!['used'] = (grouped[key]!['used'] as double) + qty;
              grouped[key]!['closingStock'] = (grouped[key]!['closingStock'] as double) - qty;
            }
            (grouped[key]!['transactions'] as List<dynamic>).add(t);
          } else {
            grouped[key] = {
              '_id': t['_id'] ?? key,
              'materialName': itemName,
              'category': tabType,
              'purchased': isPositive ? qty : 0.0,
              'used': isPositive ? 0.0 : qty,
              'closingStock': isPositive ? qty : -qty,
              'threshold': 10.0,
              'unit': unit,
              'transactions': [t],
            };
          }
        }

        for (final item in grouped.values) {
          final txs = item['transactions'] as List<dynamic>;
          txs.sort((a, b) {
            final dateA = a['date'] ?? '';
            final dateB = b['date'] ?? '';
            return dateB.toString().compareTo(dateA.toString());
          });
        }

        return grouped.values.toList();
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

  static Future<List<dynamic>> fetchRecentTransactions({
    required String projectId,
    required String type,
  }) async {
    try {
      final response = await get('/transactions?project=$projectId&type=$type');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map) {
          return (decoded['transactions'] ?? decoded['data'] ?? []) as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('fetchRecentTransactions Error: $e');
      return [];
    }
  }

  // ── SMART AUTOCOMPLETE SUGGESTION ENGINE ────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchSuggestions({
    required String projectId,
    required String type, // 'Materials' | 'Wages' | 'Expense'
  }) async {
    try {
      // ── 1. Fetch current-project transactions ──────────────────────────
      List<dynamic> projectTxs = [];
      try {
        final r = await get('/transactions?project=$projectId&type=$type');
        if (r.statusCode == 200) {
          final d = json.decode(r.body);
          if (d is List) {
            projectTxs = d;
          } else if (d is Map) {
            projectTxs = (d['transactions'] ?? d['data'] ?? []) as List<dynamic>;
          }
        }
      } catch (_) {}

      // ── 2. Fetch global transactions (all projects) ────────────────────
      List<dynamic> globalTxs = [];
      try {
        final r = await get('/transactions?type=$type');
        if (r.statusCode == 200) {
          final d = json.decode(r.body);
          if (d is List) {
            globalTxs = d;
          } else if (d is Map) {
            globalTxs = (d['transactions'] ?? d['data'] ?? []) as List<dynamic>;
          }
        }
      } catch (_) {}

      final Map<String, Map<String, dynamic>> byTitle = {};
      final Map<String, int> frequency = {};
      final Map<String, bool> isCurrentProject = {};

      // Process current-project first (higher priority)
      for (final rawTx in projectTxs) {
        final tx = rawTx as Map<String, dynamic>;
        final title = (tx['title'] ?? tx['name'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        final key = title.toLowerCase();
        frequency[key] = (frequency[key] ?? 0) + 1;
        isCurrentProject[key] = true;

        if (!byTitle.containsKey(key)) {
          byTitle[key] = Map<String, dynamic>.from(tx);
        } else {
          // Keep most recent record
          final existingDate = byTitle[key]!['date']?.toString() ?? '';
          final newDate = tx['date']?.toString() ?? '';
          if (newDate.compareTo(existingDate) > 0) {
            byTitle[key] = Map<String, dynamic>.from(tx);
          }
        }
      }

      // Process global transactions — only add if title not already seen
      for (final rawTx in globalTxs) {
        final tx = rawTx as Map<String, dynamic>;
        final title = (tx['title'] ?? tx['name'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        final key = title.toLowerCase();
        if (!byTitle.containsKey(key)) {
          // New title from another project
          byTitle[key] = Map<String, dynamic>.from(tx);
          frequency[key] = 1;
          isCurrentProject[key] = false;
        } else if (isCurrentProject[key] != true) {
          // Same title from another project — keep most recent
          final existingDate = byTitle[key]!['date']?.toString() ?? '';
          final newDate = tx['date']?.toString() ?? '';
          if (newDate.compareTo(existingDate) > 0) {
            byTitle[key] = Map<String, dynamic>.from(tx);
          }
          frequency[key] = (frequency[key] ?? 0) + 1;
        }
      }

      // ── 4. Sort: current-project > recency > frequency ─────────────────
      final entries = byTitle.entries.toList()
        ..sort((a, b) {
          final aKey = a.key;
          final bKey = b.key;

          // Current project first
          final aProj = isCurrentProject[aKey] == true ? 1 : 0;
          final bProj = isCurrentProject[bKey] == true ? 1 : 0;
          if (aProj != bProj) return bProj - aProj;

          // Most recent first
          final aDate = a.value['date']?.toString() ?? '';
          final bDate = b.value['date']?.toString() ?? '';
          final dateCmp = bDate.compareTo(aDate);
          if (dateCmp != 0) return dateCmp;

          // Most frequent first
          final aFreq = frequency[aKey] ?? 0;
          final bFreq = frequency[bKey] ?? 0;
          return bFreq - aFreq;
        });

      // ── 5. Embed frequency metadata for potential future use ───────────
      final result = <Map<String, dynamic>>[];
      for (final e in entries.take(50)) {
        final record = Map<String, dynamic>.from(e.value)
          ..['\$freq'] = frequency[e.key] ?? 1
          ..['\$isCurrentProject'] = isCurrentProject[e.key] ?? false;
        result.add(record);
      }

      print('fetchSuggestions [$type]: ${result.length} unique suggestions');
      return result;
    } catch (e, stack) {
      print('fetchSuggestions Error: $e');
      print(stack);
      return [];
    }
  }
}
