import 'dart:convert';
import 'package:http/http.dart' as http;

class BuildTrackAIService {
  static const String baseUrl = "https://b-tmvp-production.up.railway.app";

  static Future<Map<String, dynamic>> chat(String message) async {
    final response = await http.post(
      Uri.parse("$baseUrl/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"session_id": "mobile_app", "message": message}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("AI request failed");
  }
}
