import 'dart:convert';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';
enum ProjectStage {
  preConstruction,
  sitePreparation,
  foundation,
  plinth,
  superstructure,
  masonry,
  mep,
  plastering,
  finishing,
  fixtures,
  handover
}

enum EntryType { material, labour, equipment }

extension ProjectStageX on ProjectStage {
  String get label {
    switch (this) {
      case ProjectStage.preConstruction: return 'PRE-CONSTRUCTION';
      case ProjectStage.sitePreparation: return 'SITE PREPARATION';
      case ProjectStage.foundation:      return 'FOUNDATION';
      case ProjectStage.plinth:          return 'PLINTH';
      case ProjectStage.superstructure:  return 'SUPERSTRUCTURE';
      case ProjectStage.masonry:         return 'MASONRY';
      case ProjectStage.mep:             return 'MEP';
      case ProjectStage.plastering:      return 'PLASTERING';
      case ProjectStage.finishing:       return 'FINISHING';
      case ProjectStage.fixtures:        return 'FIXTURES';
      case ProjectStage.handover:        return 'HANDOVER';
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
    this.clientName,
    this.projectType,
    this.expectedEndDate,
    this.floors,
    this.selectedPhaseNames,
    this.completedActivityKeys,
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
  final String?       clientName;
  final String?       projectType;
  final DateTime?     expectedEndDate;
  final List<String>? floors;
  final List<String>? selectedPhaseNames;
  final List<String>? completedActivityKeys;
  double get remainingBudget   => totalBudget - spentAmount;
  double get budgetUtilization => totalBudget > 0 ? spentAmount / totalBudget : 0.0;
  String get location          => '$city • $sector';
  String get formattedBudget    => formatCurrency(totalBudget);
  String get formattedSpent     => formatCurrency(spentAmount);
  String get formattedRemaining => formatCurrency(remainingBudget);
  ProjectModel copyWith({
    String?       name,
    String?       city,
    String?       sector,
    ProjectStage? stage,
    double?       progress,
    double?       totalBudget,
    double?       spentAmount,
    String?       clientName,
    String?       projectType,
    DateTime?     expectedEndDate,
    List<String>? floors,
    List<String>? selectedPhaseNames,
    List<String>? completedActivityKeys,
  }) =>
      ProjectModel(
        id:                   id,
        name:                 name                ?? this.name,
        city:                 city                ?? this.city,
        sector:               sector              ?? this.sector,
        stage:                stage               ?? this.stage,
        progress:             progress            ?? this.progress,
        totalBudget:          totalBudget         ?? this.totalBudget,
        spentAmount:          spentAmount         ?? this.spentAmount,
        startDate:            startDate,
        clientName:           clientName          ?? this.clientName,
        projectType:          projectType         ?? this.projectType,
        expectedEndDate:      expectedEndDate     ?? this.expectedEndDate,
        floors:               floors              ?? this.floors,
        selectedPhaseNames:   selectedPhaseNames  ?? this.selectedPhaseNames,
        completedActivityKeys: completedActivityKeys ?? this.completedActivityKeys,
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
        if (clientName != null)           'clientName':           clientName,
        if (projectType != null)          'projectType':          projectType,
        if (expectedEndDate != null)      'expectedEndDate':      expectedEndDate!.toIso8601String(),
        if (floors != null)               'floors':               floors,
        if (selectedPhaseNames != null)   'selectedPhaseNames':   selectedPhaseNames,
        if (completedActivityKeys != null)'completedActivityKeys': completedActivityKeys,
      };
  factory ProjectModel.fromJson(Map<String, dynamic> j) => ProjectModel(
        id:              (j['_id'] ?? j['id'] ?? '').toString(),
        name:            (j['projectName'] ?? j['name'] ?? '').toString(),
        city:            (j['location'] ?? j['city'] ?? '').toString(),
        sector:          (j['sector'] ?? '').toString(),
        stage:           ProjectStage.values.firstWhere(
                           (s) => s.name == j['stage'],
                           orElse: () => ProjectStage.foundation,
                         ),
        progress:        (j['progress'] as num?)?.toDouble() ?? 0.0,
        totalBudget:     (j['totalBudget'] as num?)?.toDouble() ?? 0.0,
        spentAmount:     (j['spentAmount'] as num?)?.toDouble() ?? 0.0,
        startDate:       j['startDate'] != null 
                           ? (DateTime.tryParse(j['startDate'].toString()) ?? DateTime.now()) 
                           : DateTime.now(),
        clientName:      j['clientName']?.toString(),
        projectType:     j['projectType']?.toString(),
        expectedEndDate: j['expectedEndDate'] != null
                           ? DateTime.tryParse(j['expectedEndDate'].toString())
                           : null,
        floors:                j['floors'] != null
                                 ? List<String>.from(j['floors'] as List)
                                 : null,
        selectedPhaseNames:    j['selectedPhaseNames'] != null
                                 ? List<String>.from(j['selectedPhaseNames'] as List)
                                 : null,
        completedActivityKeys: j['completedActivityKeys'] != null
                                 ? List<String>.from(j['completedActivityKeys'] as List)
                                 : null,
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
    this.brand,
    this.ratePerUnit,
    this.floor,
    this.phase,
    this.phaseId,
  });
  final String    id;
  final String    projectId;
  final EntryType type;       
  double          amount;
  final DateTime  date;
  final String    description;
  final String?       brand;
  final double?       ratePerUnit;
  final String?       floor;
  final ProjectStage? phase;
  final String?       phaseId;
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
        if (phaseId != null)     'phaseId':     phaseId,
      };
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
        brand:       j['brand'] as String?,
        ratePerUnit: (j['ratePerUnit'] as num?)?.toDouble(),
        floor:       j['floor'] as String?,
        phase:       j['phase'] != null
                       ? ProjectStage.values.firstWhere(
                           (s) => s.name == j['phase'],
                           orElse: () => ProjectStage.foundation,
                         )
                       : null,
        phaseId:     j['phaseId'] as String?,
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
