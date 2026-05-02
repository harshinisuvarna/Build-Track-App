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
    // ── NEW optional fields (Phase 2) ──────────────────────────────────
    this.clientName,
    this.projectType,
    this.expectedEndDate,
    this.floors,
    // ───────────────────────────────────────────────────────────────────
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

  // ── NEW nullable fields ─────────────────────────────────────────────
  // TODO(Phase2): These will become required once backend is connected.
  final String?       clientName;
  final String?       projectType;
  final DateTime?     expectedEndDate;
  final List<String>? floors;
  // ───────────────────────────────────────────────────────────────────

  // ── EXISTING getters — NOT TOUCHED ──────────────────────────────────
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
  // ────────────────────────────────────────────────────────────────────

  ProjectModel copyWith({
    String?       name,
    String?       city,
    String?       sector,
    ProjectStage? stage,
    double?       progress,
    double?       totalBudget,
    double?       spentAmount,
    // ── NEW copyWith params ─────────────────────────────────────────
    String?       clientName,
    String?       projectType,
    DateTime?     expectedEndDate,
    List<String>? floors,
    // ───────────────────────────────────────────────────────────────
  }) =>
      ProjectModel(
        id:              id,
        name:            name            ?? this.name,
        city:            city            ?? this.city,
        sector:          sector          ?? this.sector,
        stage:           stage           ?? this.stage,
        progress:        progress        ?? this.progress,
        totalBudget:     totalBudget     ?? this.totalBudget,
        spentAmount:     spentAmount     ?? this.spentAmount,
        startDate:       startDate,
        // ── NEW ──────────────────────────────────────────────────────
        clientName:      clientName      ?? this.clientName,
        projectType:     projectType     ?? this.projectType,
        expectedEndDate: expectedEndDate ?? this.expectedEndDate,
        floors:          floors          ?? this.floors,
        // ─────────────────────────────────────────────────────────────
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
        // ── NEW — null-safe serialization ────────────────────────────
        if (clientName != null)      'clientName':      clientName,
        if (projectType != null)     'projectType':     projectType,
        if (expectedEndDate != null) 'expectedEndDate': expectedEndDate!.toIso8601String(),
        if (floors != null)          'floors':          floors,
        // ─────────────────────────────────────────────────────────────
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
        // ── NEW — safe parsing (never crashes on missing/null) ────────
        clientName:      j['clientName'] as String?,
        projectType:     j['projectType'] as String?,
        expectedEndDate: j['expectedEndDate'] != null
                           ? DateTime.tryParse(j['expectedEndDate'] as String)
                           : null,
        floors:          j['floors'] != null
                           ? List<String>.from(j['floors'] as List)
                           : null,
        // ─────────────────────────────────────────────────────────────
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
    // ── NEW optional fields (Step 2B/2C) ──────────────────────────
    this.brand,
    this.ratePerUnit,
    this.floor,
    this.phase,
    // ──────────────────────────────────────────────────────────────
  });

  // ── EXISTING fields — NOT TOUCHED ────────────────────────────────
  final String    id;
  final String    projectId;
  final EntryType type;       // EntryType enum kept as-is
  double          amount;
  final DateTime  date;
  final String    description;
  // ─────────────────────────────────────────────────────────────────

  // ── NEW nullable fields (Step 2B) ────────────────────────────────
  // TODO(Phase2): These become required once backend is live.
  final String?       brand;
  final double?       ratePerUnit;
  final String?       floor;
  final ProjectStage? phase;
  // ─────────────────────────────────────────────────────────────────

  // ── STEP 2D: toJson — new fields added safely ────────────────────
  Map<String, dynamic> toJson() => {
        'id':          id,
        'projectId':   projectId,
        'type':        type.name,
        'amount':      amount,
        'date':        date.toIso8601String(),
        'description': description,
        // New fields — written only when non-null
        if (brand != null)       'brand':       brand,
        if (ratePerUnit != null) 'ratePerUnit': ratePerUnit,
        if (floor != null)       'floor':       floor,
        if (phase != null)       'phase':       phase!.name,
      };

  // ── STEP 2E/2F: fromJson — NEVER crashes on old data ─────────────
  factory EntryModel.fromJson(Map<String, dynamic> j) => EntryModel(
        id:          j['id'] as String,
        projectId:   j['projectId'] as String,
        // Step 2F: safe enum recovery with fallback
        type:        EntryType.values.firstWhere(
                       (t) => t.name == j['type'],
                       orElse: () => EntryType.material,
                     ),
        amount:      (j['amount'] as num).toDouble(),
        date:        DateTime.parse(j['date'] as String),
        description: (j['description'] as String?) ?? '',
        // Step 2E: new fields — safe defaults for legacy entries
        brand:       j['brand'] as String?,
        ratePerUnit: (j['ratePerUnit'] as num?)?.toDouble(),
        floor:       j['floor'] as String?,
        phase:       j['phase'] != null
                       ? ProjectStage.values.firstWhere(
                           (s) => s.name == j['phase'],
                           orElse: () => ProjectStage.foundation,
                         )
                       : null,
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
