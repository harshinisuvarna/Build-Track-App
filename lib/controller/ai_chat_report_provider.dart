// lib/controller/ai_chat_report_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'project_provider.dart';

// ─── Message models ───────────────────────────────────────────────────────────

enum MessageRole { user, assistant }

enum TableType { entries, inventory, none }

class ChatTableRow {
  const ChatTableRow({
    required this.date,
    required this.item,
    this.quantity,
    this.unit,
    required this.amount,
  });
  final String date;
  final String item;
  final String? quantity;
  final String? unit;
  final double amount;
}

class InventoryRow {
  const InventoryRow({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.severity, // 'critical' | 'low' | 'ok'
  });
  final String name;
  final double quantity;
  final String unit;
  final String severity;
}

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.text,
    this.tableType = TableType.none,
    this.tableTitle,
    this.entryRows = const [],
    this.inventoryRows = const [],
    this.totalAmount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final MessageRole role;
  final String text;
  final TableType tableType;
  final String? tableTitle;
  final List<ChatTableRow> entryRows;
  final List<InventoryRow> inventoryRows;
  final double? totalAmount;
  final DateTime timestamp;

  String get timeString {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Suggested chips ──────────────────────────────────────────────────────────

const kSuggestedQuestions = [
  'Cement spend',
  'Date range',
  'Budget health',
  'Labour entries',
  'Inventory status',
];

// ─── Provider ─────────────────────────────────────────────────────────────────

class AiChatReportProvider extends ChangeNotifier {
  AiChatReportProvider({
    required this.projectProvider,
    required this.authToken,
    required this.baseUrl,
  });

  final ProjectProvider projectProvider;
  final String authToken;
  final String baseUrl;

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _messages.isEmpty;

  // ─── Send a user message ──────────────────────────────────────────────────

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _messages.add(ChatMessage(role: MessageRole.user, text: trimmed));
    _isTyping = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await _callBackend(trimmed);
      _messages.add(reply);
    } catch (e) {
      _errorMessage = 'Failed to get a response. Please try again.';
      _messages.add(ChatMessage(
        role: MessageRole.assistant,
        text: 'Something went wrong. Please try again.',
      ));
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

  Future<ChatMessage> _callBackend(String question) async {
    final uri = Uri.parse('$baseUrl/api/reports/ai-chat');

    // Extract projectId from context if available
    // The backend handles all logic locally from MongoDB — no AI key needed
    final projectId = projectProvider.selectedProject?.id ?? 'all';

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'question': question,
        'projectId': projectId,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    // Backend returns { "result": { ...claude json... } }
    final result = decoded['result'] is String
        ? jsonDecode(decoded['result'])
        : decoded['result'] as Map<String, dynamic>;

    return _parseReply(result);
  }

  ChatMessage _parseReply(Map<String, dynamic> json) {
    final text = json['text']?.toString() ?? 'No response.';
    final tableTypeStr = json['table_type']?.toString() ?? 'none';
    final tableTitle = json['table_title']?.toString();
    final totalAmount = (json['total_amount'] as num?)?.toDouble();

    TableType tableType;
    switch (tableTypeStr) {
      case 'entries':
        tableType = TableType.entries;
        break;
      case 'inventory':
        tableType = TableType.inventory;
        break;
      default:
        tableType = TableType.none;
    }

    // Parse entry rows
    final rawRows = json['rows'] as List<dynamic>? ?? [];
    final entryRows = rawRows.map((r) {
      final map = r as Map<String, dynamic>;
      return ChatTableRow(
        date: map['date']?.toString() ?? '',
        item: map['item']?.toString() ?? '',
        quantity: map['quantity']?.toString(),
        unit: map['unit']?.toString(),
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    // Parse inventory rows
    final rawInv = json['inventory_rows'] as List<dynamic>? ?? [];
    final inventoryRows = rawInv.map((r) {
      final map = r as Map<String, dynamic>;
      return InventoryRow(
        name: map['name']?.toString() ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        unit: map['unit']?.toString() ?? '',
        severity: map['severity']?.toString() ?? 'ok',
      );
    }).toList();

    return ChatMessage(
      role: MessageRole.assistant,
      text: text,
      tableType: tableType,
      tableTitle: tableTitle,
      entryRows: entryRows,
      inventoryRows: inventoryRows,
      totalAmount: totalAmount,
    );
  }
}