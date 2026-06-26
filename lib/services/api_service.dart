import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:buildtrack_mobile/config/api_config.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static List<ProjectModel>? mockProjects;

  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    // Try 'token' first, fall back to 'jwt_token'
    final token = prefs.getString('token') ?? prefs.getString('jwt_token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = '$baseUrl$endpoint';
    debugPrint('API Request [GET]: $url');
    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 45));
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    return response;
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    final url = '$baseUrl$endpoint';
    debugPrint('API Request [POST]: $url');
    debugPrint('Payload: ${jsonEncode(body)}');
    final response = await http
        .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 45));
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    return response;
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    final url = '$baseUrl$endpoint';
    debugPrint('API Request [PUT]: $url');
    debugPrint('Payload: ${jsonEncode(body)}');
    final response = await http
        .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 45));
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    return response;
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = '$baseUrl$endpoint';
    debugPrint('API Request [DELETE]: $url');
    final response = await http
        .delete(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 45));
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    return response;
  }

  // ==========================================
  // PROJECT API METHODS
  // ==========================================

  static Future<List<ProjectModel>> fetchProjects() async {
    if (mockProjects != null) return mockProjects!;
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

        List<ProjectModel> validProjects = [];
        for (var item in rawList) {
          try {
            validProjects.add(
              ProjectModel.fromJson(item as Map<String, dynamic>),
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint('CRASH parsing project ${item['_id']}: $e');
            }
          }
        }

        return validProjects;
      } else if (response.statusCode == 401) {
        if (kDebugMode) {
          debugPrint('AUTH Error: Token missing (401).');
        }
        throw Exception('Unauthorized');
      } else {
        if (kDebugMode) {
          debugPrint('GET /projects failed: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchProjects Master Error: $e');
      }
      return [];
    }
  }

  static Future<ProjectModel?> addProject(Map<String, dynamic> payload) async {
    try {
      final response = await post('/projects', payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        final Map<String, dynamic> projectJson =
            (decoded is Map && decoded.containsKey('project'))
            ? decoded['project'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return ProjectModel.fromJson(projectJson);
      } else {
        if (kDebugMode) {
          debugPrint(
            'POST /projects failed (${response.statusCode}): ${response.body}',
          );
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('addProject Error: $e');
      }
      return null;
    }
  }

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
      if (kDebugMode) {
        debugPrint('fetchProjectById error: $e');
      }
      return null;
    }
  }

  // ==========================================
  // TRANSACTION API METHODS
  // ==========================================

  static Future<List<dynamic>> fetchMaterials() async {
    try {
      final response = await get('/transactions');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded['transactions'] ?? decoded['data'] ?? [];
        }
        return [];
      } else if (response.statusCode == 401) {
        if (kDebugMode) {
          debugPrint(
            'AUTH Error: Token missing or expired (401). Body: ${response.body}',
          );
        }
        throw Exception('Unauthorized – please log in again');
      } else {
        if (kDebugMode) {
          debugPrint(
            'GET /transactions failed with status ${response.statusCode}: ${response.body}',
          );
        }
        throw Exception(
          'Failed to load transactions (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('GET Error: $e');
      }
      return [];
    }
  }

  static Future<bool> addMaterial(Map<String, dynamic> payload) async {
    try {
      final response = await post('/transactions', payload);

      if (kDebugMode) {
        debugPrint('=== SERVER RESPONSE DEBUG ===');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('=============================');
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('POST Error: $e');
      }
      return false;
    }
  }

  static Future<Map<String, dynamic>?> addTransaction(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await post('/transactions', payload);
      if (kDebugMode) {
        debugPrint('=== SERVER RESPONSE DEBUG ===');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('=============================');
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('POST Error: $e');
      }
      return null;
    }
  }

  static Future<bool> updateTransactionPayment(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await put('/transactions/$id', payload);
      if (kDebugMode) {
        debugPrint('=== UPDATE TRANSACTION RESPONSE DEBUG ===');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('=============================');
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PUT /transactions/$id Error: $e');
      }
      return false;
    }
  }

  static Future<bool> updateTransaction(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await put('/transactions/$id', payload);
      if (kDebugMode) {
        debugPrint('=== PUT UPDATE TRANSACTION RESPONSE ===');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PUT /transactions/$id Error: $e');
      }
      return false;
    }
  }

  static Future<bool> deleteTransaction(String id) async {
    try {
      final response = await delete('/transactions/$id');
      if (kDebugMode) {
        debugPrint('=== DELETE TRANSACTION RESPONSE ===');
        debugPrint('Status Code: ${response.statusCode}');
      }
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DELETE /transactions/$id Error: $e');
      }
      return false;
    }
  }

  static Future<bool> deleteProject(String id) async {
    try {
      final response = await delete('/projects/$id');
      if (kDebugMode) {
        debugPrint('=== DELETE PROJECT RESPONSE ===');
        debugPrint('Status Code: ${response.statusCode}');
      }
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DELETE /projects/$id Error: $e');
      }
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchTransactionById(String id) async {
    try {
      final response = await get('/transactions/$id');
      if (kDebugMode) {
        debugPrint('=== FETCH TRANSACTION BY ID ===');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
      }
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded['transaction'] ?? decoded['data'] ?? decoded;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchTransactionById error: $e');
      }
      return null;
    }
  }

  // ==========================================
  // INVENTORY API METHODS
  // ==========================================

  static Future<List<dynamic>> fetchInventory(String projectId) async {
    try {
      String endpoint = '/transactions?limit=10000';
      if (projectId.isNotEmpty) endpoint += '&project=$projectId';

      final response = await get(endpoint);

      if (kDebugMode) {
        debugPrint('fetchInventory status: ${response.statusCode}');
        debugPrint('fetchInventory body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> raw = [];
        if (decoded is List) {
          raw = decoded;
        } else if (decoded is Map) {
          raw =
              (decoded['transactions'] ??
                      decoded['inventory'] ??
                      decoded['data'] ??
                      decoded['items'] ??
                      [])
                  as List<dynamic>;
        }

        final Map<String, Map<String, dynamic>> grouped = {};

        for (final t in raw) {
          final String rawType = (t['type'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          if (rawType == 'income' || rawType == 'revenue') {
            continue;
          }

          final String itemName =
              (t['title'] ?? t['materialName'] ?? t['name'] ?? 'Unknown')
                  .toString()
                  .trim();
          String tabType = 'material';
          if (rawType == 'wages' || rawType == 'labour') {
            tabType = 'labour';
          } else if (rawType == 'expense' || rawType == 'equipment') {
            tabType = 'equipment';
          } else if (rawType == 'materials') {
            tabType = 'material';
          } else {
            final String originalCategory =
                (t['category'] ?? t['materialName'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();
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

          final bool isPositive =
              t['subType']?.toString().toLowerCase() != 'consumption' &&
              t['materialType']?.toString().toLowerCase() != 'usage';

          if (grouped.containsKey(key)) {
            if (isPositive) {
              grouped[key]!['purchased'] =
                  (grouped[key]!['purchased'] as double) + qty;
              grouped[key]!['closingStock'] =
                  (grouped[key]!['closingStock'] as double) + qty;
            } else {
              grouped[key]!['used'] = (grouped[key]!['used'] as double) + qty;
              grouped[key]!['closingStock'] =
                  (grouped[key]!['closingStock'] as double) - qty;
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

        if (kDebugMode) {
          debugPrint('fetchInventory grouped items: ${grouped.length}');
        }
        return grouped.values.toList();
      } else {
        if (kDebugMode) {
          debugPrint(
            'fetchInventory failed: ${response.statusCode} ${response.body}',
          );
        }
        return [];
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Inventory GET Error: $e');
        debugPrint(stack.toString());
      }
      return [];
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
        if (kDebugMode) {
          debugPrint(
            'addInventoryItem failed (${response.statusCode}): ${response.body}',
          );
        }
        throw Exception('Failed to add inventory item');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('addInventoryItem Error: $e');
      }
      rethrow;
    }
  }

  static Future<List<dynamic>> searchMaterials({
    String? query,
    String? category,
    String? projectId,
  }) async {
    try {
      String endpoint = '/transactions?limit=10000&';
      if (projectId != null && projectId.isNotEmpty) {
        endpoint += 'project=$projectId&';
      }
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
          raw =
              (decoded['transactions'] ?? decoded['data'] ?? [])
                  as List<dynamic>;
        }

        final Map<String, Map<String, dynamic>> grouped = {};

        for (final t in raw) {
          final String rawType = (t['type'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          if (rawType == 'income' || rawType == 'revenue') {
            continue;
          }

          final String itemName =
              (t['title'] ?? t['materialName'] ?? t['name'] ?? 'Unknown')
                  .toString()
                  .trim();
          String tabType = 'material';
          if (rawType == 'wages' || rawType == 'labour') {
            tabType = 'labour';
          } else if (rawType == 'expense' || rawType == 'equipment') {
            tabType = 'equipment';
          } else if (rawType == 'materials') {
            tabType = 'material';
          } else {
            final String originalCategory =
                (t['category'] ?? t['materialName'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();
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

          final bool isPositive =
              t['subType']?.toString().toLowerCase() != 'consumption' &&
              t['materialType']?.toString().toLowerCase() != 'usage';

          if (grouped.containsKey(key)) {
            if (isPositive) {
              grouped[key]!['purchased'] =
                  (grouped[key]!['purchased'] as double) + qty;
              grouped[key]!['closingStock'] =
                  (grouped[key]!['closingStock'] as double) + qty;
            } else {
              grouped[key]!['used'] = (grouped[key]!['used'] as double) + qty;
              grouped[key]!['closingStock'] =
                  (grouped[key]!['closingStock'] as double) - qty;
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
      if (kDebugMode) {
        debugPrint('Search API Error: $e');
      }
      return [];
    }
  }

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
      if (kDebugMode) {
        debugPrint('Tasks API Error: $e');
      }
      return [];
    }
  }

  static Future<bool> resetPassword(String email) async {
    try {
      final response = await post('/auth/reset-password', {'email': email});
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('resetPassword Error: $e');
      }
      rethrow;
    }
  }

  static Future<List<dynamic>> fetchRecentTransactions({
    required String projectId,
    required String type,
    String? userId,
  }) async {
    try {
      String url = '/transactions?project=$projectId&type=$type&limit=5';

      if (userId != null && userId.isNotEmpty) {
        url += '&createdBy=$userId';
      }

      final response = await get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map) {
          return (decoded['transactions'] ?? decoded['data'] ?? [])
              as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchRecentTransactions Error: $e');
      }
      return [];
    }
  }

  // ==========================================
  // AUTOCOMPLETE SUGGESTIONS
  // ==========================================

  static Future<List<Map<String, dynamic>>> fetchSuggestions({
    required String projectId,
    required String type,
    String? userId,
  }) async {
    try {
      List<dynamic> projectTxs = [];
      try {
        String projectUrl = '/transactions?limit=10000&project=$projectId&type=$type';
        if (userId != null && userId.isNotEmpty) {
          projectUrl += '&createdBy=$userId';
        }
        final r = await get(projectUrl);
        if (r.statusCode == 200) {
          final d = json.decode(r.body);
          if (d is List) {
            projectTxs = d;
          } else if (d is Map) {
            projectTxs =
                (d['transactions'] ?? d['data'] ?? []) as List<dynamic>;
          }
        }
      } catch (_) {}

      List<dynamic> globalTxs = [];
      try {
        String globalUrl = '/transactions?limit=10000&type=$type';
        if (userId != null && userId.isNotEmpty) {
          globalUrl += '&createdBy=$userId';
        }
        final r = await get(globalUrl);
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
          final existingDate = byTitle[key]!['date']?.toString() ?? '';
          final newDate = tx['date']?.toString() ?? '';
          if (newDate.compareTo(existingDate) > 0) {
            byTitle[key] = Map<String, dynamic>.from(tx);
          }
        }
      }

      for (final rawTx in globalTxs) {
        final tx = rawTx as Map<String, dynamic>;
        final title = (tx['title'] ?? tx['name'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        final key = title.toLowerCase();
        if (!byTitle.containsKey(key)) {
          byTitle[key] = Map<String, dynamic>.from(tx);
          frequency[key] = 1;
          isCurrentProject[key] = false;
        } else if (isCurrentProject[key] != true) {
          final existingDate = byTitle[key]!['date']?.toString() ?? '';
          final newDate = tx['date']?.toString() ?? '';
          if (newDate.compareTo(existingDate) > 0) {
            byTitle[key] = Map<String, dynamic>.from(tx);
          }
          frequency[key] = (frequency[key] ?? 0) + 1;
        }
      }

      final entries = byTitle.entries.toList()
        ..sort((a, b) {
          final aKey = a.key;
          final bKey = b.key;

          final aProj = isCurrentProject[aKey] == true ? 1 : 0;
          final bProj = isCurrentProject[bKey] == true ? 1 : 0;
          if (aProj != bProj) return bProj - aProj;

          final aDate = a.value['date']?.toString() ?? '';
          final bDate = b.value['date']?.toString() ?? '';
          final dateCmp = bDate.compareTo(aDate);
          if (dateCmp != 0) return dateCmp;

          final aFreq = frequency[aKey] ?? 0;
          final bFreq = frequency[bKey] ?? 0;
          return bFreq - aFreq;
        });

      final result = <Map<String, dynamic>>[];
      for (final e in entries.take(50)) {
        final record = Map<String, dynamic>.from(e.value)
          ..['\$freq'] = frequency[e.key] ?? 1
          ..['\$isCurrentProject'] = isCurrentProject[e.key] ?? false;
        result.add(record);
      }

      if (kDebugMode) {
        debugPrint(
          'fetchSuggestions [$type]: ${result.length} unique suggestions',
        );
      }
      return result;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('fetchSuggestions Error: $e');
        debugPrint(stack.toString());
      }
      return [];
    }
  }

  // ==========================================
  // Maker-Checker Approvals
  // ==========================================

  static Future<Map<String, dynamic>?> fetchPendingApprovals() async {
    try {
      final response = await get('/approvals/pending');
      if (kDebugMode) {
        debugPrint('fetchPendingApprovals status: ${response.statusCode}');
        debugPrint('fetchPendingApprovals body: ${response.body}');
      }
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('fetchPendingApprovals error: $e');
      return null;
    }
  }

  static Future<bool> assignSupervisorOversight(
    String supervisorId,
    List<String> roles,
  ) async {
    try {
      final response = await put('/users/$supervisorId/oversight', {
        'overseesRoles': roles,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) debugPrint('assignSupervisorOversight error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchApprovalsHistory() async {
    try {
      final response = await get('/approvals/history');
      if (kDebugMode) {
        debugPrint('fetchApprovalsHistory status: ${response.statusCode}');
        debugPrint('fetchApprovalsHistory body: ${response.body}');
      }
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('fetchApprovalsHistory error: $e');
      return null;
    }
  }

  static Future<bool> approveTransaction(String txId) async {
    try {
      final response = await put('/transactions/$txId/approve', {});
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('approveTransaction error: $e');
      return false;
    }
  }

  static Future<bool> rejectTransaction(String txId, String reason) async {
    try {
      final response = await put('/transactions/$txId/reject', {
        'rejectionReason': reason,
      });
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('rejectTransaction error: $e');
      return false;
    }
  }

  static Future<bool> approveProjectUpdate(String updateId) async {
    try {
      final response = await put('/project-updates/$updateId/approve', {});
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('approveProjectUpdate error: $e');
      return false;
    }
  }

  static Future<bool> rejectProjectUpdate(
    String updateId,
    String reason,
  ) async {
    try {
      final response = await put('/project-updates/$updateId/reject', {
        'rejectionReason': reason,
      });
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('rejectProjectUpdate error: $e');
      return false;
    }
  }

  /// Fetches recent transactions created by the currently logged-in user only.
  static Future<List<dynamic>> fetchMyRecentEntries() async {
    try {
      final response = await get('/transactions/my?limit=10');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        return (decoded['transactions'] ?? decoded['data'] ?? []) as List;
      }
      // Fallback: try with createdBy param if /my route doesn't exist yet
      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString('userId') ?? prefs.getString('user_id') ?? '';
      if (userId.isNotEmpty) {
        final fallback = await get('/transactions?createdBy=$userId&limit=10');
        if (fallback.statusCode == 200) {
          final decoded = json.decode(fallback.body);
          if (decoded is List) return decoded;
          return (decoded['transactions'] ?? decoded['data'] ?? []) as List;
        }
      }
    } catch (e) {
      debugPrint('fetchMyRecentEntries error: $e');
    }
    return [];
  }
}
