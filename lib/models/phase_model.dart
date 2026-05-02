import 'dart:convert';

class PhaseModel {
  final String id;
  final String name;
  final int order;

  PhaseModel({
    required this.id,
    required this.name,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
      };

  factory PhaseModel.fromJson(Map<String, dynamic> json) {
    return PhaseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      order: (json['order'] as num).toInt(),
    );
  }

  static String encodeList(List<PhaseModel> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }

  static List<PhaseModel> decodeList(String raw) {
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => PhaseModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
