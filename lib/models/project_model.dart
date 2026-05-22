import 'dart:convert';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';

enum ProjectStage {
  preConstruction, // Pre-Construction
  sitePreparation, // Site Preparation
  foundationPlinthWork, // Foundation & Plinth Work
  floorConstruction, // Floor Construction
  finishingWork, // Finishing Work
  externalWorks, // External Works
  materialMaster, // Material Master
  labourMaster, // Labour Master
  equipmentMaster, // Equipment Master
}

enum EntryType { material, labour, equipment }

extension ProjectStageX on ProjectStage {
  String get label {
    switch (this) {
      case ProjectStage.preConstruction:
        return 'Pre-Construction';
      case ProjectStage.sitePreparation:
        return 'Site Preparation';
      case ProjectStage.foundationPlinthWork:
        return 'Foundation & Plinth Work';
      case ProjectStage.floorConstruction:
        return 'Floor Construction';
      case ProjectStage.finishingWork:
        return 'Finishing Work';
      case ProjectStage.externalWorks:
        return 'External Works';
      case ProjectStage.materialMaster:
        return 'Material Master';
      case ProjectStage.labourMaster:
        return 'Labour Master';
      case ProjectStage.equipmentMaster:
        return 'Equipment Master';
    }
  }
}

extension EntryTypeX on EntryType {
  String get label {
    switch (this) {
      case EntryType.material:
        return 'material';
      case EntryType.labour:
        return 'labour';
      case EntryType.equipment:
        return 'equipment';
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
    this.trackedActivityKeys,
    this.completedActivityKeys,
    this.selectedPhases,
    // ── NEW enterprise fields ──────────────────────────────────────
    this.projectCode,
    this.mapAddress,
    this.contractorName,
    this.siteEngineer,
    this.contactNumber,
    this.actualEndDate,
    this.landArea,
    this.landUnit,
    this.room1BHK,
    this.room2BHK,
    this.room3BHK,
    this.roomCustom,
    this.bathWestern,
    this.bathIndian,
    this.bathCommon,
    this.bathAttached,
    this.selectedFeatures,
    this.budgetMaterial,
    this.budgetLabour,
    this.budgetEquipment,
    this.budgetMisc,
    this.projectStatus,
  });
  // ── Core ───────────────────────────────────────────────────────────────────
  final String id;
  final String name;
  final String city;
  final String sector;
  final ProjectStage stage;
  double progress;
  double totalBudget;
  double spentAmount;
  final DateTime startDate;
  // ── Basic optional ─────────────────────────────────────────────────────────
  final String? clientName;
  final String? projectType;
  final DateTime? expectedEndDate;
  final List<String>? floors;
  final List<String>? selectedPhaseNames;
  final List<String>? trackedActivityKeys;
  final List<String>? completedActivityKeys;
  final List<ProjectPhase>? selectedPhases;
  // ── Enterprise fields ──────────────────────────────────────────────────────
  final String? projectCode;
  final String? mapAddress;
  final String? contractorName;
  final String? siteEngineer;
  final String? contactNumber;
  final DateTime? actualEndDate;
  final String? landArea;
  final String? landUnit;
  final int? room1BHK;
  final int? room2BHK;
  final int? room3BHK;
  final int? roomCustom;
  final int? bathWestern;
  final int? bathIndian;
  final int? bathCommon;
  final int? bathAttached;
  final List<String>? selectedFeatures;
  final double? budgetMaterial;
  final double? budgetLabour;
  final double? budgetEquipment;
  final double? budgetMisc;
  final String? projectStatus;
  // ── Computed ───────────────────────────────────────────────────────────────
  double get remainingBudget => totalBudget - spentAmount;
  double get budgetUtilization =>
      totalBudget > 0 ? spentAmount / totalBudget : 0.0;
  String get location => '$city • $sector';
  String get formattedBudget => formatCurrency(totalBudget);
  String get formattedSpent => formatCurrency(spentAmount);
  String get formattedRemaining => formatCurrency(remainingBudget);
  // ── NEW REPORT ANALYTICS ──────────────────────────────────────────────────
  double get materialCost => budgetMaterial ?? 0;
  double get labourCost => budgetLabour ?? 0;
  double get equipmentCost => budgetEquipment ?? 0;
  double get miscCost => budgetMisc ?? 0;
  double get totalCalculatedCost =>
      materialCost + labourCost + equipmentCost + miscCost;
  // Cost per sqft / unit
  double get costPerUnit {
    final area = double.tryParse(landArea ?? '0') ?? 0;
    if (area <= 0) return 0;
    return spentAmount / area;
  }

  String get formattedCostPerUnit => '₹${costPerUnit.toStringAsFixed(2)}/sqft';
  // Budget percentages
  double get materialPercentage {
    if (totalBudget <= 0) return 0;
    return (materialCost / totalBudget) * 100;
  }

  double get labourPercentage {
    if (totalBudget <= 0) return 0;
    return (labourCost / totalBudget) * 100;
  }

  double get equipmentPercentage {
    if (totalBudget <= 0) return 0;
    return (equipmentCost / totalBudget) * 100;
  }

  double get miscPercentage {
    if (totalBudget <= 0) return 0;
    return (miscCost / totalBudget) * 100;
  }

  // Budget exceeded
  bool get isBudgetExceeded => spentAmount > totalBudget;
  double get exceededAmount {
    if (!isBudgetExceeded) return 0;
    return spentAmount - totalBudget;
  }

  String get formattedExceededAmount => formatCurrency(exceededAmount);
  // Efficiency note
  String get efficiencyNote {
    if (isBudgetExceeded) {
      return 'Budget exceeded by $formattedExceededAmount';
    }
    final utilization = budgetUtilization * 100;
    if (utilization >= 90) {
      return 'Budget utilization is very high';
    } else if (utilization >= 70) {
      return 'Project spending is on track';
    } else if (utilization >= 40) {
      return 'Budget usage is moderate';
    } else {
      return 'Project is under budget';
    }
  }

  // Progress percentage display
  String get progressPercent => '${(progress * 100).toStringAsFixed(0)}%';
  // Total rooms
  int get totalRooms =>
      (room1BHK ?? 0) + (room2BHK ?? 0) + (room3BHK ?? 0) + (roomCustom ?? 0);
  // Total bathrooms
  int get totalBathrooms =>
      (bathWestern ?? 0) +
      (bathIndian ?? 0) +
      (bathCommon ?? 0) +
      (bathAttached ?? 0);
  // ── copyWith ───────────────────────────────────────────────────────────────
  ProjectModel copyWith({
    String? name,
    String? city,
    String? sector,
    ProjectStage? stage,
    double? progress,
    double? totalBudget,
    double? spentAmount,
    String? clientName,
    String? projectType,
    DateTime? expectedEndDate,
    List<String>? floors,
    List<String>? selectedPhaseNames,
    List<String>? trackedActivityKeys,
    List<String>? completedActivityKeys,
    List<ProjectPhase>? selectedPhases,
    String? projectCode,
    String? mapAddress,
    String? contractorName,
    String? siteEngineer,
    String? contactNumber,
    DateTime? actualEndDate,
    String? landArea,
    String? landUnit,
    int? room1BHK,
    int? room2BHK,
    int? room3BHK,
    int? roomCustom,
    int? bathWestern,
    int? bathIndian,
    int? bathCommon,
    int? bathAttached,
    List<String>? selectedFeatures,
    double? budgetMaterial,
    double? budgetLabour,
    double? budgetEquipment,
    double? budgetMisc,
    String? projectStatus,
  }) => ProjectModel(
    id: id,
    name: name ?? this.name,
    city: city ?? this.city,
    sector: sector ?? this.sector,
    stage: stage ?? this.stage,
    progress: progress ?? this.progress,
    totalBudget: totalBudget ?? this.totalBudget,
    spentAmount: spentAmount ?? this.spentAmount,
    startDate: startDate,
    clientName: clientName ?? this.clientName,
    projectType: projectType ?? this.projectType,
    expectedEndDate: expectedEndDate ?? this.expectedEndDate,
    floors: floors ?? this.floors,
    selectedPhaseNames: selectedPhaseNames ?? this.selectedPhaseNames,
    trackedActivityKeys: trackedActivityKeys ?? this.trackedActivityKeys,
    completedActivityKeys: completedActivityKeys ?? this.completedActivityKeys,
    selectedPhases: selectedPhases ?? this.selectedPhases,
    projectCode: projectCode ?? this.projectCode,
    mapAddress: mapAddress ?? this.mapAddress,
    contractorName: contractorName ?? this.contractorName,
    siteEngineer: siteEngineer ?? this.siteEngineer,
    contactNumber: contactNumber ?? this.contactNumber,
    actualEndDate: actualEndDate ?? this.actualEndDate,
    landArea: landArea ?? this.landArea,
    landUnit: landUnit ?? this.landUnit,
    room1BHK: room1BHK ?? this.room1BHK,
    room2BHK: room2BHK ?? this.room2BHK,
    room3BHK: room3BHK ?? this.room3BHK,
    roomCustom: roomCustom ?? this.roomCustom,
    bathWestern: bathWestern ?? this.bathWestern,
    bathIndian: bathIndian ?? this.bathIndian,
    bathCommon: bathCommon ?? this.bathCommon,
    bathAttached: bathAttached ?? this.bathAttached,
    selectedFeatures: selectedFeatures ?? this.selectedFeatures,
    budgetMaterial: budgetMaterial ?? this.budgetMaterial,
    budgetLabour: budgetLabour ?? this.budgetLabour,
    budgetEquipment: budgetEquipment ?? this.budgetEquipment,
    budgetMisc: budgetMisc ?? this.budgetMisc,
    projectStatus: projectStatus ?? this.projectStatus,
  );
  // ── JSON ───────────────────────────────────────────────────────────────────
  /// Produces a backend-compatible JSON payload.
  /// Keys mirror the Node.js Mongoose schema (`projectName`, `location`, etc.).
  Map<String, dynamic> toJson() {
    // 1. Safely extract mainType and subType from the combined string ("Commercial → Plaza")
    String mainType = 'Residential';
    String subType = 'Independent';
    if (projectType != null && projectType!.contains('→')) {
      final parts = projectType!.split('→');
      mainType = parts[0].trim();
      subType = parts.length > 1 ? parts[1].trim() : 'General';
    } else if (projectType != null) {
      mainType = projectType!;
      subType = 'General';
    }
    // 2. Map the UI status to the exact backend enum values (Title Case)
    //    Backend enum: ["Active", "Completed", "On Hold", "Review Needed"]
    String mappedStatus = 'Active'; // Default fallback
    final rawStatus = (projectStatus ?? '').toLowerCase();
    if (rawStatus.contains('progress') ||
        rawStatus.contains('active') ||
        rawStatus.contains('plan')) {
      mappedStatus = 'Active';
    } else if (rawStatus.contains('hold') || rawStatus.contains('cancel')) {
      mappedStatus = 'On Hold';
    } else if (rawStatus.contains('complet')) {
      mappedStatus = 'Completed';
    } else if (rawStatus.contains('review')) {
      mappedStatus = 'Review Needed';
    }
    return {
      'projectName': name,
      'location': city,
      'sector': sector,
      'stage': stage.name,
      'progress': progress,
      'spentAmount': spentAmount,
      'totalBudget': totalBudget,
      'startDate': startDate.toIso8601String(),
      // Core fields required by the backend schema
      'clientName': clientName ?? 'Internal Client',
      'projectCode':
          projectCode ?? 'PRJ-${DateTime.now().millisecondsSinceEpoch}',
      // Flat budget fields extracted by backend controller
      'budgetMaterial': budgetMaterial ?? 0,
      'budgetMaterials': budgetMaterial ?? 0, // Fallback for backend
      'budgetLabour': budgetLabour ?? 0,
      'budgetEquipment': budgetEquipment ?? 0,
      'budgetMisc': budgetMisc ?? 0,
      'budgetMiscellaneous': budgetMisc ?? 0, // Fallback for backend

      // Nested buildingType object required by validation
      'buildingType': {'mainType': mainType, 'subType': subType},
      // Nested budget object to fix the "0 budget" issue
      'budget': {
        'total': totalBudget,
        'material': budgetMaterial ?? 0,
        'materials': budgetMaterial ?? 0, // Fallback
        'labour': budgetLabour ?? 0,
        'equipment': budgetEquipment ?? 0,
        'misc': budgetMisc ?? 0,
        'miscellaneous': budgetMisc ?? 0, // Fallback
      },
      // Mapped enum
      'status': mappedStatus,
      'floors': floors,
      'selectedPhaseNames': selectedPhaseNames,
      'trackedActivityKeys': trackedActivityKeys,
      'completedActivityKeys': completedActivityKeys,
      'selectedPhases': selectedPhases?.map((p) => p.toJson()).toList(),
      'projectStatus': projectStatus,
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> j) {
    // 1. Safely extract nested objects from the new backend schema
    final dates = j['dates'] as Map<String, dynamic>?;
    final budget = j['budget'] as Map<String, dynamic>?;
    final buildingType = j['buildingType'] as Map<String, dynamic>?;
    // 2. Handle the missing name bug (fallback to projectCode if backend drops it)
    final rawName = (j['projectName'] ?? j['name'] ?? '').toString();
    final pCode = (j['projectCode'] ?? 'Unnamed Project').toString();
    final finalName = rawName.trim().isNotEmpty ? rawName : pCode;
    return ProjectModel(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      name: finalName,
      city: (j['location'] ?? j['city'] ?? '').toString(),
      sector: (j['sector'] ?? '').toString(),
      stage: ProjectStage.values.firstWhere(
        (s) => s.name == j['stage'],
        orElse: () => ProjectStage.preConstruction,
      ),
      progress: (j['progress'] as num?)?.toDouble() ?? 0.0,
      // 3. Extract budgets from nested 'budget' object
      totalBudget:
          (budget?['total'] as num?)?.toDouble() ??
          (j['totalBudget'] as num?)?.toDouble() ??
          0.0,
      spentAmount: (j['spentAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: dates?['startDate'] != null
          ? (DateTime.tryParse(dates!['startDate'].toString()) ?? DateTime.now())
          : j['startDate'] != null
          ? (DateTime.tryParse(j['startDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      clientName: j['clientName']?.toString(),
      projectType: buildingType != null
          ? '${buildingType['mainType']} → ${buildingType['subType']}'
          : j['projectType']?.toString(),
      expectedEndDate: dates?['expectedEndDate'] != null
          ? DateTime.tryParse(dates!['expectedEndDate'].toString())
          : j['expectedEndDate'] != null
          ? DateTime.tryParse(j['expectedEndDate'].toString())
          : null,
      floors: j['floors'] != null
          ? List<String>.from(j['floors'] as List)
          : null,
      selectedPhaseNames: j['selectedPhaseNames'] != null
          ? List<String>.from(j['selectedPhaseNames'] as List)
          : null,
      trackedActivityKeys: j['trackedActivityKeys'] != null
          ? List<String>.from(j['trackedActivityKeys'] as List)
          : null,
      completedActivityKeys: j['completedActivityKeys'] != null
          ? List<String>.from(j['completedActivityKeys'] as List)
          : null,
      selectedPhases: j['selectedPhases'] != null
          ? (j['selectedPhases'] as List<dynamic>)
                .map((e) => ProjectPhase.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      contractorName: j['contractorName'] as String?,
      siteEngineer: j['siteEngineer'] as String?,
      contactNumber: j['contactNumber'] as String?,
      actualEndDate: dates?['actualEndDate'] != null
          ? DateTime.tryParse(dates!['actualEndDate'].toString())
          : j['actualEndDate'] != null
          ? DateTime.tryParse(j['actualEndDate'] as String)
          : null,
      landArea: j['landArea'] as String?,
      landUnit: j['landUnit'] as String?,
      projectCode: j['projectCode'] as String?,
      mapAddress: j['mapAddress'] as String?,
      room1BHK: j['room1BHK'] as int?,
      room2BHK: j['room2BHK'] as int?,
      room3BHK: j['room3BHK'] as int?,
      roomCustom: j['roomCustom'] as int?,
      bathWestern: j['bathWestern'] as int?,
      bathIndian: j['bathIndian'] as int?,
      bathCommon: j['bathCommon'] as int?,
      bathAttached: j['bathAttached'] as int?,
      selectedFeatures: j['selectedFeatures'] != null
          ? List<String>.from(j['selectedFeatures'] as List)
          : null,
      // 6. Extract specific nested budgets with alternatives
      budgetMaterial:
          (budget?['material'] as num?)?.toDouble() ??
          (budget?['materials'] as num?)?.toDouble() ??
          (j['budgetMaterial'] as num?)?.toDouble() ??
          (j['budgetMaterials'] as num?)?.toDouble(),
      budgetLabour:
          (budget?['labour'] as num?)?.toDouble() ??
          (j['budgetLabour'] as num?)?.toDouble(),
      budgetEquipment:
          (budget?['equipment'] as num?)?.toDouble() ??
          (j['budgetEquipment'] as num?)?.toDouble(),
      budgetMisc: (() {
        double bMat = (budget?['material'] as num?)?.toDouble() ??
            (budget?['materials'] as num?)?.toDouble() ??
            (j['budgetMaterial'] as num?)?.toDouble() ??
            (j['budgetMaterials'] as num?)?.toDouble() ?? 0.0;
        double bLab = (budget?['labour'] as num?)?.toDouble() ??
            (j['budgetLabour'] as num?)?.toDouble() ?? 0.0;
        double bEq = (budget?['equipment'] as num?)?.toDouble() ??
            (j['budgetEquipment'] as num?)?.toDouble() ?? 0.0;
        double bMisc = (budget?['misc'] as num?)?.toDouble() ??
            (budget?['miscellaneous'] as num?)?.toDouble() ??
            (j['budgetMisc'] as num?)?.toDouble() ??
            (j['budgetMiscellaneous'] as num?)?.toDouble() ?? 0.0;
        double tBudget = (budget?['total'] as num?)?.toDouble() ??
            (j['totalBudget'] as num?)?.toDouble() ?? 0.0;

        // If backend dropped misc but we have the total, recover it dynamically!
        if (bMisc == 0 && tBudget > 0) {
          final calcMisc = tBudget - (bMat + bLab + bEq);
          if (calcMisc > 0) {
            bMisc = calcMisc;
          }
        }
        return bMisc > 0 ? bMisc : null;
      })(),
      projectStatus: j['status'] as String?,
    );
  }
  static String encodeList(List<ProjectModel> list) =>
      jsonEncode(list.map((p) => p.toJson()).toList());
  static List<ProjectModel> decodeList(String raw) {
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── ProjectActivity ─────────────────────────────────────────────────────────
class ProjectActivity {
  final String id;
  final String name;
  final bool isCustom;
  bool completed;
  ProjectActivity({
    required this.id,
    required this.name,
    this.isCustom = false,
    this.completed = false,
  });
  ProjectActivity copyWith({bool? completed}) => ProjectActivity(
    id: id,
    name: name,
    isCustom: isCustom,
    completed: completed ?? this.completed,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isCustom': isCustom,
    'completed': completed,
  };
  factory ProjectActivity.fromJson(Map<String, dynamic> j) => ProjectActivity(
    id: j['id'] as String,
    name: j['name'] as String,
    isCustom: (j['isCustom'] as bool?) ?? false,
    completed: (j['completed'] as bool?) ?? false,
  );
}

// ── ProjectPhase ─────────────────────────────────────────────────────────────
class ProjectPhase {
  final String id;
  final String phaseName;
  final bool isCustom;
  bool isExpanded;
  final List<ProjectActivity> activities;
  ProjectPhase({
    required this.id,
    required this.phaseName,
    this.isCustom = false,
    this.isExpanded = false,
    List<ProjectActivity>? activities,
  }) : activities = activities ?? [];
  int get totalCount => activities.length;
  int get completedCount => activities.where((a) => a.completed).length;
  // Deep-copy with optional activity list override
  ProjectPhase copyWith({List<ProjectActivity>? activities}) => ProjectPhase(
    id: id,
    phaseName: phaseName,
    isCustom: isCustom,
    isExpanded: isExpanded,
    activities: activities ?? List<ProjectActivity>.from(this.activities),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'phaseName': phaseName,
    'isCustom': isCustom,
    'activities': activities.map((a) => a.toJson()).toList(),
  };
  factory ProjectPhase.fromJson(Map<String, dynamic> j) => ProjectPhase(
    id: j['id'] as String,
    phaseName: j['phaseName'] as String,
    isCustom: (j['isCustom'] as bool?) ?? false,
    activities:
        (j['activities'] as List<dynamic>?)
            ?.map((e) => ProjectActivity.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

// ── EntryModel ─────────────────────────────────────────────────────────────────
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
    this.unit,
  });
  final String id;
  final String projectId;
  final EntryType type;
  double amount;
  final DateTime date;
  final String description;
  final String? brand;
  final double? ratePerUnit;
  final String? floor;
  final ProjectStage? phase;
  final String? phaseId;
  final String? unit;
  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'type': type.name,
    'amount': amount,
    'date': date.toIso8601String(),
    'description': description,
    if (brand != null) 'brand': brand,
    if (ratePerUnit != null) 'ratePerUnit': ratePerUnit,
    if (floor != null) 'floor': floor,
    if (phase != null) 'phase': phase!.name,
    if (phaseId != null) 'phaseId': phaseId,
    if (unit != null) 'unit': unit,
  };
  factory EntryModel.fromJson(Map<String, dynamic> j) => EntryModel(
    id: j['id'] as String,
    projectId: j['projectId'] as String,
    type: EntryType.values.firstWhere(
      (t) => t.name == j['type'],
      orElse: () => EntryType.material,
    ),
    amount: (j['amount'] as num).toDouble(),
    date: DateTime.parse(j['date'] as String),
    description: (j['description'] as String?) ?? '',
    brand: j['brand'] as String?,
    ratePerUnit: (j['ratePerUnit'] as num?)?.toDouble(),
    floor: j['floor'] as String?,
    phase: j['phase'] != null
        ? ProjectStage.values.firstWhere(
            (s) => s.name == j['phase'],
            orElse: () => ProjectStage.preConstruction,
          )
        : null,
    phaseId: j['phaseId'] as String?,
    unit: j['unit'] as String?,
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
