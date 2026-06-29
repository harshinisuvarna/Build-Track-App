// lib/controller/ai_chat_report_provider.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'project_provider.dart';

enum AiReportState { initial, loading, results, error }

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String responseBody;

  ApiException(this.message, this.statusCode, this.responseBody);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class AiReportResult {
  final String summary;
  final Map<String, dynamic> metrics;
  final String tableType;
  final List<dynamic> tableRows;
  final double? totalAmount;
  final int? rowCount;
  final List<String> actions;
  final Map<String, dynamic>? charts;
  final List<Map<String, dynamic>> alerts;
  final List<Map<String, dynamic>> projectBreakdown;

  AiReportResult({
    required this.summary,
    required this.metrics,
    required this.tableType,
    required this.tableRows,
    this.totalAmount,
    this.rowCount,
    this.actions = const [],
    this.charts,
    this.alerts = const [],
    this.projectBreakdown = const [],
  });

  factory AiReportResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final table = data['table'] as Map<String, dynamic>? ?? {};
    
    return AiReportResult(
      summary: data['summary']?.toString() ?? '',
      metrics: data['metrics'] as Map<String, dynamic>? ?? {},
      tableType: table['type']?.toString() ?? 'none',
      tableRows: table['rows'] as List<dynamic>? ?? [],
      totalAmount: (table['totalAmount'] as num?)?.toDouble(),
      rowCount: table['rowCount'] as int?,
      actions: (data['actions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      charts: data['charts'] as Map<String, dynamic>?,
      alerts: (data['alerts'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      projectBreakdown: ((data['charts'] as Map<String, dynamic>?)?['projectBreakdown'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [],
    );
  }
}

class AiChatReportProvider extends ChangeNotifier {
  AiChatReportProvider({
    required this.projectProvider,
    required this.authToken,
    required this.baseUrl,
  });

  final ProjectProvider projectProvider;
  final String authToken;
  final String baseUrl;

  AiReportState _state = AiReportState.initial;
  AiReportState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AiReportResult? _result;
  AiReportResult? get result => _result;

  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  // Recent searches for quick prompts
  final List<String> _recentSearches = [
    'Show material usage',
    'Low stock materials',
    'Labour summary',
    'Pending payments',
    'Budget health'
  ];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  Future<void> sendQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Update recent searches
    if (!_recentSearches.contains(trimmed)) {
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    }

    _currentQuery = trimmed;
    _state = AiReportState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
<<<<<<< HEAD
      final uri = Uri.parse('$baseUrl/api/reports/dashboard/query');
      final projectId = projectProvider.selectedProject?.id ?? 'all';
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };
      
      final payloadStr = jsonEncode({
        'query': trimmed,
        'projectId': projectId,
      });
=======
      final reply = await _callBackend(trimmed);
      _messages.add(reply);
    } catch (e) {
      _errorMessage = 'Failed to get a response. Please try again.';
      _messages.add(
        ChatMessage(
          role: MessageRole.assistant,
          text: 'Something went wrong. Please try again.',
        ),
      );
    }

    _isTyping = false;
    notifyListeners();
  }

  void clearHistory() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Backend call ─────────────────────────────────────────────────────────

  // ─── Backend call ─────────────────────────────────────────────────────────

  Future<ChatMessage> _callBackend(String question) async {
    final uri = Uri.parse('$baseUrl/api/reports/ai-chat');

    // Extract projectId from context if available
    // The backend handles all logic locally from MongoDB — no AI key needed
    final projectId = projectProvider.selectedProject?.id ?? 'all';

    // Send prior turns so the backend (and the model) has conversational
    // context. We exclude the message we just added locally (it's passed
    // separately as `question`), and cap history length to keep payload
    // size sane on a long-running chat.
    const maxHistoryMessages = 20;
    final priorMessages = _messages
        .where((m) => m.text != question || m.role != MessageRole.user)
        .toList();
    final historyToSend = priorMessages.length > maxHistoryMessages
        ? priorMessages.sublist(priorMessages.length - maxHistoryMessages)
        : priorMessages;

    final history = historyToSend
        .map(
          (m) => {
            'role': m.role == MessageRole.user ? 'user' : 'assistant',
            'text': m.text,
          },
        )
        .toList();

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'question': question,
            'projectId': projectId,
            'history': history,
          }),
        )
        .timeout(const Duration(seconds: 30));
>>>>>>> b6ea0ac2883f79e6e2607b4764aeef4697d188ae

      debugPrint('\n==============================');
      debugPrint('[FLUTTER] REQUEST SENDING');
      debugPrint('==============================');
      debugPrint('Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint('URL: $uri');
      debugPrint('Headers: $headers');
      debugPrint('Payload: $payloadStr');

      final stopWatch = Stopwatch()..start();
      
      final response = await http.post(
        uri,
        headers: headers,
        body: payloadStr,
      ).timeout(const Duration(seconds: 45));
      
      stopWatch.stop();

      debugPrint('\n==============================');
      debugPrint('[FLUTTER] RESPONSE RECEIVED');
      debugPrint('==============================');
      debugPrint('Elapsed Time: ${stopWatch.elapsedMilliseconds}ms');
      debugPrint('HTTP Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw ApiException('Server returned ${response.statusCode}', response.statusCode, response.body);
      }

      final decoded = jsonDecode(response.body);
      _result = AiReportResult.fromJson(decoded);
      _state = AiReportState.results;
    } catch (e, stackTrace) {
      debugPrint('\n==============================');
      debugPrint('[FLUTTER] EXCEPTION CAUGHT');
      debugPrint('==============================');
      
      if (e is ApiException) {
        debugPrint('Status Code: ${e.statusCode}');
        debugPrint('Response Body: ${e.responseBody}');
      }
      debugPrint('Exception: $e');
      debugPrint('Request URL: $baseUrl/api/reports/dashboard/query');
      debugPrint('Request Payload: {"query": "$trimmed"}');
      debugPrint('Stack Trace:\n$stackTrace');

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = AiReportState.error;
    }

    notifyListeners();
  }

  void resetToInitial() {
    _state = AiReportState.initial;
    _result = null;
    _errorMessage = null;
    _currentQuery = '';
    notifyListeners();
  }

  Future<void> exportCsv() async {
    if (_result == null || _result!.tableRows.isEmpty) return;

    try {
      List<List<dynamic>> csvData = [];
      
      // Header
      if (_result!.tableType == 'inventory') {
        csvData.add(['Material', 'Quantity', 'Unit', 'Status']);
        for (var row in _result!.tableRows) {
          csvData.add([
            row['name'] ?? '',
            row['quantity'] ?? 0,
            row['unit'] ?? '',
            row['severity'] ?? '',
          ]);
        }
      } else {
        csvData.add(['Date', 'Project', 'Item', 'Quantity', 'Unit', 'Amount']);
        for (var row in _result!.tableRows) {
          csvData.add([
            row['date'] ?? '',
            row['projectName'] ?? '',
            row['item'] ?? '',
            row['quantity'] ?? '',
            row['unit'] ?? '',
            row['amount'] ?? 0,
          ]);
        }
      }

      String csvString = const ListToCsvConverter().convert(csvData);
      
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      await Share.shareXFiles([XFile(path)], text: 'BuildTrack Analytics Export\n\n${_result!.summary}');
    } catch (e) {
      debugPrint('Export Error: $e');
    }
  }

  Future<void> shareSummary() async {
    if (_result == null) return;
    try {
      final text = 'BuildTrack Report: $_currentQuery\n\n${_result!.summary}';
      await Share.share(text);
    } catch (e) {
      debugPrint('Share Error: $e');
    }
  }
}
