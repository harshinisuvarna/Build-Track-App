import 'dart:convert';
enum ProjectStage { foundation, structure, finishing, handover }
enum EntryType { material, labour, equipment }
extension ProjectStageX on ProjectStage {
  String get label {
    switch (this) {
      case ProjectStage.foundation: return 'FOUNDATION';
      case ProjectStage.structure:  return 'STRUCTURE';
      case ProjectStage.finishing:  return 'FINISHING';
      case ProjectStage.handover:   return 'HANDOVER';
    }
  }
}
extension EntryTypeX on EntryType {
  String get label {
    switch (this) {
      case EntryType.material:  return 'material';
      case EntryType.labour:    return 'labour';
      case EntryType.equipment: return 'equipment';
    }
  }
}
class ProjectModel {
  ProjectModel({
    required this.id,
    required this.name,
    required this.city,
    required this.sector,
    required this.stage,
    required this.progress,
    required this.totalBudget,
    required this.spentAmount,
    required this.startDate,
  });

  final String       id;
  final String       name;
  final String       city;
  final String       sector;
  final ProjectStage stage;
  double             progress;    // 0.0 – 1.0
  double             totalBudget; // in rupees
  double             spentAmount; // in rupees
  final DateTime     startDate;
  double get remainingBudget   => totalBudget - spentAmount;
  double get budgetUtilization => totalBudget > 0 ? spentAmount / totalBudget : 0.0;
  String get location          => '$city • $sector';
  String _fmt(double v) {
    if (v >= 1e7) return '₹${(v / 1e7).toStringAsFixed(2)}Cr';
    if (v >= 1e6) return '₹${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '₹${(v / 1e3).toStringAsFixed(0)}k';
    return '₹${v.toStringAsFixed(0)}';
  }
  String get formattedBudget    => _fmt(totalBudget);
  String get formattedSpent     => _fmt(spentAmount);
  String get formattedRemaining => _fmt(remainingBudget);
  ProjectModel copyWith({
    String?       name,
    String?       city,
    String?       sector,
    ProjectStage? stage,
    double?       progress,
    double?       totalBudget,
    double?       spentAmount,
  }) =>
      ProjectModel(
        id:          id,
        name:        name        ?? this.name,
        city:        city        ?? this.city,
        sector:      sector      ?? this.sector,
        stage:       stage       ?? this.stage,
        progress:    progress    ?? this.progress,
        totalBudget: totalBudget ?? this.totalBudget,
        spentAmount: spentAmount ?? this.spentAmount,
        startDate:   startDate,
      );
  Map<String, dynamic> toJson() => {
        'id':          id,
        'name':        name,
        'city':        city,
        'sector':      sector,
        'stage':       stage.name,
        'progress':    progress,
        'totalBudget': totalBudget,
        'spentAmount': spentAmount,
        'startDate':   startDate.toIso8601String(),
      };
  factory ProjectModel.fromJson(Map<String, dynamic> j) => ProjectModel(
        id:          j['id'] as String,
        name:        j['name'] as String,
        city:        j['city'] as String,
        sector:      j['sector'] as String,
        stage:       ProjectStage.values.firstWhere(
                       (s) => s.name == j['stage'],
                       orElse: () => ProjectStage.foundation,
                     ),
        progress:    (j['progress'] as num).toDouble(),
        totalBudget: (j['totalBudget'] as num).toDouble(),
        spentAmount: (j['spentAmount'] as num).toDouble(),
        startDate:   DateTime.parse(j['startDate'] as String),
      );

  static String encodeList(List<ProjectModel> list) =>
      jsonEncode(list.map((p) => p.toJson()).toList());

  static List<ProjectModel> decodeList(String raw) {
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
class EntryModel {
  EntryModel({
    required this.id,
    required this.projectId,
    required this.type,
    required this.amount,
    required this.date,
    this.description = '',
  });

  final String    id;
  final String    projectId;
  final EntryType type;
  double          amount;
  final DateTime  date;
  final String    description;

  Map<String, dynamic> toJson() => {
        'id':          id,
        'projectId':   projectId,
        'type':        type.name,
        'amount':      amount,
        'date':        date.toIso8601String(),
        'description': description,
      };

  factory EntryModel.fromJson(Map<String, dynamic> j) => EntryModel(
        id:          j['id'] as String,
        projectId:   j['projectId'] as String,
        type:        EntryType.values.firstWhere(
                       (t) => t.name == j['type'],
                       orElse: () => EntryType.material,
                     ),
        amount:      (j['amount'] as num).toDouble(),
        date:        DateTime.parse(j['date'] as String),
        description: (j['description'] as String?) ?? '',
      );

  static String encodeList(List<EntryModel> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<EntryModel> decodeList(String raw) {
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => EntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
