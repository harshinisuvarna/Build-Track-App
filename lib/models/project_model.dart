import 'dart:convert';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';

enum ProjectStage {
  preConstruction,
  sitePreparation,
  foundationPlinthWork,
  floorConstruction,
  finishingWork,
  externalWorks,
  materialMaster,
  labourMaster,
  equipmentMaster,
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
        return 'Material';
      case ProjectStage.labourMaster:
        return 'Labour';
      case ProjectStage.equipmentMaster:
        return 'Equipment';
    }
  }
}

extension EntryTypeX on EntryType {
  String get label {
    switch (this) {
      case EntryType.material:
        return 'Material';
      case EntryType.labour:
        return 'Labour';
      case EntryType.equipment:
        return 'Equipment';
    }
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
    this.activity,
    this.activityId,
    this.unit,
    this.createdBy, // ADD: ID of the user who created this entry
    this.approvalStatus = 'Pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
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
  final String? activity;
  final String? activityId;
  final String? unit;
  final String? createdBy; // ADD: nullable — older entries won't have this
  final String approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'type': type.name,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description,
        'brand': brand,
        'ratePerUnit': ratePerUnit,
        'floor': floor,
        'phase': phase?.name,
        'phaseId': phaseId,
        'activity': activity,
        'activityId': activityId,
        'unit': unit,
        'createdBy': createdBy, // ADD
        'approvalStatus': approvalStatus,
        'approvedBy': approvedBy,
        'approvedAt': approvedAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
      };

  factory EntryModel.fromJson(Map<String, dynamic> j) {
    // ADD: read createdBy from persisted cache (stored by project_provider)
    String? createdBy;
    final raw = j['createdBy'];
    if (raw is Map) {
      createdBy = raw['_id']?.toString() ?? raw['id']?.toString();
    } else if (raw != null) {
      createdBy = raw.toString();
    }

    return EntryModel(
      id: j['id']?.toString() ?? '',
      projectId: j['projectId']?.toString() ?? '',
      type: EntryType.values.firstWhere(
        (e) => e.name == j['type'],
        orElse: () => EntryType.material,
      ),
      amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      description: j['description']?.toString() ?? '',
      brand: j['brand']?.toString(),
      ratePerUnit: (j['ratePerUnit'] as num?)?.toDouble(),
      floor: j['floor']?.toString(),
      phase: j['phase'] != null
          ? ProjectStage.values.firstWhere(
              (e) => e.name == j['phase'],
              orElse: () => ProjectStage.preConstruction,
            )
          : null,
      phaseId: j['phaseId']?.toString(),
      activity: j['activity']?.toString(),
      activityId: j['activityId']?.toString(),
      unit: j['unit']?.toString(),
      createdBy: createdBy, // ADD
      approvalStatus: j['approvalStatus']?.toString() ?? 'Pending',
      approvedBy: j['approvedBy'] != null
          ? (j['approvedBy'] is Map
                ? j['approvedBy']['name']?.toString() ??
                      j['approvedBy']['_id']?.toString()
                : j['approvedBy'].toString())
          : null,
      approvedAt: j['approvedAt'] != null
          ? DateTime.tryParse(j['approvedAt'].toString())
          : null,
      rejectionReason: j['rejectionReason']?.toString(),
    );
  }

  static String encodeList(List<EntryModel> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<EntryModel> decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => EntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class ProjectActivity {
  final String id;
  final String name;
  final bool isCustom;
  final bool completed;
  final DateTime? completedAt;
  final String? notes;
  final String? photo;
  final List<String>? photos;

  ProjectActivity({
    required this.id,
    required this.name,
    this.isCustom = false,
    this.completed = false,
    this.completedAt,
    this.notes,
    this.photo,
    this.photos,
  });

  ProjectActivity copyWith({
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool clearPhoto = false,
    bool clearPhotos = false,
    String? notes,
    String? photo,
    List<String>? photos,
  }) {
    return ProjectActivity(
      id: id,
      name: name,
      isCustom: isCustom,
      completed: completed ?? this.completed,
      completedAt: clearCompletedAt
          ? null
          : (completedAt ?? this.completedAt),
      notes: notes ?? this.notes,
      photo: clearPhoto ? null : (photo ?? this.photo),
      photos: clearPhotos ? null : (photos ?? this.photos),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isCustom': isCustom,
        'completed': completed,
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (notes != null) 'notes': notes,
        'photo': photo,
        'photos': photos,
      };

  factory ProjectActivity.fromJson(Map<String, dynamic> j) => ProjectActivity(
        id: (j['id'] ?? j['_id'])?.toString() ?? '',
        name: (j['name'] ?? '').toString(),
        isCustom: (j['isCustom'] as bool?) ?? false,
        completed: (j['completed'] as bool?) ?? false,
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'].toString())
            : null,
        notes: j['notes']?.toString(),
        photo: j['photo']?.toString(),
        photos: j['photos'] != null
            ? List<String>.from(j['photos'] as List)
            : null,
      );
}
class ProjectPhase {
  final String id;
  final String phaseName;
  final bool isCustom;
  final bool isExpanded;
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

  ProjectPhase copyWith({List<ProjectActivity>? activities}) {
    return ProjectPhase(
      id: id,
      phaseName: phaseName,
      isCustom: isCustom,
      isExpanded: isExpanded,
      activities: activities ?? List<ProjectActivity>.from(this.activities),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phaseName': phaseName,
    'isCustom': isCustom,
    'activities': activities.map((a) => a.toJson()).toList(),
  };

  factory ProjectPhase.fromJson(Map<String, dynamic> j) {
    return ProjectPhase(
      id: (j['id'] ?? j['_id'])?.toString() ?? '',
      phaseName: (j['phaseName'] ?? j['name'] ?? '').toString(),
      isCustom: j['isCustom'] as bool? ?? false,
      activities:
          (j['activities'] as List<dynamic>?)
              ?.map((e) => ProjectActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ProjectModel {
  final String id;
  final String name;
  final String city;
  final String sector;
  final ProjectStage stage;
  final double progress;
  final double totalBudget;
  final double spentAmount;
  final double totalIncome;
  final DateTime startDate;

  final String location;
  final String? clientName;
  final String? projectType;
  final DateTime? expectedEndDate;
  final List<String>? floors;
  final List<String>? selectedPhaseNames;
  final List<String>? trackedActivityKeys;
  final List<String>? completedActivityKeys;
  final List<ProjectPhase>? selectedPhases;

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

  ProjectModel({
    required this.id,
    required this.name,
    required this.city,
    required this.sector,
    required this.stage,
    required this.progress,
    required this.totalBudget,
    required this.spentAmount,
    this.totalIncome = 0.0,
    required this.startDate,
    required this.location,
    this.clientName,
    this.projectType,
    this.expectedEndDate,
    this.floors,
    this.selectedPhaseNames,
    this.trackedActivityKeys,
    this.completedActivityKeys,
    this.selectedPhases,
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

  ProjectModel copyWith({
    String? id,
    String? name,
    String? city,
    String? sector,
    ProjectStage? stage,
    double? progress,
    double? totalBudget,
    double? spentAmount,
    double? totalIncome,
    DateTime? startDate,
    String? location,
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
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      sector: sector ?? this.sector,
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      totalBudget: totalBudget ?? this.totalBudget,
      spentAmount: spentAmount ?? this.spentAmount,
      totalIncome: totalIncome ?? this.totalIncome,
      startDate: startDate ?? this.startDate,
      location: location ?? this.location,
      clientName: clientName ?? this.clientName,
      projectType: projectType ?? this.projectType,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      floors: floors ?? this.floors,
      selectedPhaseNames: selectedPhaseNames ?? this.selectedPhaseNames,
      trackedActivityKeys: trackedActivityKeys ?? this.trackedActivityKeys,
      completedActivityKeys:
          completedActivityKeys ?? this.completedActivityKeys,
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
  }

  double get remainingBudget => totalBudget - spentAmount;
  double get budgetUtilization =>
      totalBudget <= 0 ? 0 : (spentAmount / totalBudget).clamp(0.0, 1.0);

  String get formattedBudget => formatCurrency(totalBudget);
  String get formattedSpent => formatCurrency(spentAmount);
  String get formattedRemaining => formatCurrency(remainingBudget);

  Map<String, dynamic> toJson() {
    final mappedStatus = (() {
      final status = (projectStatus ?? '').trim().toLowerCase();
      if (status == 'completed') return 'Completed';
      if (status == 'on hold') return 'On Hold';
      if (status == 'cancelled') return 'Cancelled';
      if (status == 'in progress') return 'Active';
      return 'Planning';
    })();

    final String ptStr = projectType ?? '';
    final String separator = ptStr.contains('→') ? '→' : '/';
    final mainType = ptStr.contains(separator)
        ? ptStr.split(separator).first.trim()
        : ptStr.trim();
    final subType = ptStr.contains(separator)
        ? ptStr.split(separator).last.trim()
        : '';

    return {
      '_id': id,
      'name': name,
      'projectName': name,
      'city': city,
      'sector': sector,
      'stage': stage.name,
      'progress': progress,
      'spentAmount': spentAmount,
      'totalIncome': totalIncome,
      'totalBudget': totalBudget,

      'startDate': startDate.toIso8601String(),
      'dates': {
        'startDate': startDate.toIso8601String(),
        if (expectedEndDate != null)
          'expectedEndDate': expectedEndDate!.toIso8601String(),
        if (actualEndDate != null)
          'actualEndDate': actualEndDate!.toIso8601String(),
      },

      if (expectedEndDate != null)
        'expectedEndDate': expectedEndDate!.toIso8601String(),
      if (actualEndDate != null)
        'actualEndDate': actualEndDate!.toIso8601String(),

      'location': location,
      'clientName': clientName ?? 'Internal Client',
      'projectCode':
          projectCode ?? 'PRJ-${DateTime.now().millisecondsSinceEpoch}',

      'budgetMaterial': budgetMaterial ?? 0,
      'budgetMaterials': budgetMaterial ?? 0,
      'budgetLabour': budgetLabour ?? 0,
      'budgetEquipment': budgetEquipment ?? 0,
      'budgetMisc': budgetMisc ?? 0,
      'budgetMiscellaneous': budgetMisc ?? 0,

      'buildingType': {'mainType': mainType, 'subType': subType},

      'budget': {
        'total': totalBudget,
        'material': budgetMaterial ?? 0,
        'materials': budgetMaterial ?? 0,
        'labour': budgetLabour ?? 0,
        'equipment': budgetEquipment ?? 0,
        'misc': budgetMisc ?? 0,
        'miscellaneous': budgetMisc ?? 0,
      },

      'status': mappedStatus,
      'projectStatus': projectStatus,

      'floors': floors,
      'selectedPhaseNames': selectedPhaseNames,
      'trackedActivityKeys': trackedActivityKeys,
      'completedActivityKeys': completedActivityKeys,
      'selectedPhases': selectedPhases?.map((p) => p.toJson()).toList(),

      'contractorName': contractorName,
      'siteEngineer': siteEngineer,
      'contactNumber': contactNumber,
      'mapAddress': mapAddress,
      'landArea': landArea,
      'landUnit': landUnit,

      'room1BHK': room1BHK,
      'room2BHK': room2BHK,
      'room3BHK': room3BHK,
      'roomCustom': roomCustom,

      'bathWestern': bathWestern,
      'bathIndian': bathIndian,
      'bathCommon': bathCommon,
      'bathAttached': bathAttached,

      'selectedFeatures': selectedFeatures,
      'projectType': projectType,
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> j) {
    final dates = j['dates'] as Map<String, dynamic>?;
    final budget = j['budget'] as Map<String, dynamic>?;
    final buildingType = j['buildingType'] as Map<String, dynamic>?;

    final rawName = (j['projectName'] ?? j['name'] ?? '').toString();
    final pCode = (j['projectCode'] ?? 'Unnamed Project').toString();
    final finalName = rawName.trim().isNotEmpty ? rawName : pCode;

    DateTime parsedStartDate = DateTime.now();
    final rawStartDate =
        j['startDate']?.toString() ?? dates?['startDate']?.toString();
    if (rawStartDate != null && rawStartDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawStartDate);
      if (parsed != null) parsedStartDate = parsed;
    }

    DateTime? parsedExpectedEnd;
    final rawExpected =
        j['expectedEndDate']?.toString() ??
        dates?['expectedEndDate']?.toString();
    if (rawExpected != null && rawExpected.isNotEmpty) {
      parsedExpectedEnd = DateTime.tryParse(rawExpected);
    }

    List<String>? parsedFloors;
    final rawFloors = j['floors'] as List?;
    if (rawFloors != null && rawFloors.isNotEmpty) {
      parsedFloors = rawFloors.map((f) => f.toString()).toList();
    }

    String? resolvedProjectStatus = j['projectStatus']?.toString();
    if (resolvedProjectStatus == null || resolvedProjectStatus.isEmpty) {
      final backendStatus = (j['status'] ?? '').toString().toLowerCase();
      if (backendStatus == 'active') {
        resolvedProjectStatus = 'In Progress';
      } else if (backendStatus == 'on hold') {
        resolvedProjectStatus = 'On Hold';
      } else if (backendStatus == 'completed') {
        resolvedProjectStatus = 'Completed';
      } else if (backendStatus == 'review needed') {
        resolvedProjectStatus = 'On Hold';
      } else {
        resolvedProjectStatus = 'Planning';
      }
    }

    int? safeInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

    final bMat =
        (budget?['material'] as num?)?.toDouble() ??
        (budget?['materials'] as num?)?.toDouble() ??
        (j['budgetMaterial'] as num?)?.toDouble() ??
        (j['budgetMaterials'] as num?)?.toDouble() ??
        0.0;

    final bLab =
        (budget?['labour'] as num?)?.toDouble() ??
        (j['budgetLabour'] as num?)?.toDouble() ??
        0.0;

    final bEq =
        (budget?['equipment'] as num?)?.toDouble() ??
        (j['budgetEquipment'] as num?)?.toDouble() ??
        0.0;

    final bMisc =
        (budget?['misc'] as num?)?.toDouble() ??
        (budget?['miscellaneous'] as num?)?.toDouble() ??
        (j['budgetMisc'] as num?)?.toDouble() ??
        (j['budgetMiscellaneous'] as num?)?.toDouble() ??
        0.0;

    String? projectTypeStr = j['projectType']?.toString();
    if ((projectTypeStr == null || projectTypeStr.isEmpty) &&
        buildingType != null) {
      final mainType = buildingType['mainType']?.toString() ?? '';
      final subType = buildingType['subType']?.toString() ?? '';
      // Use ' → ' to match the separator used in edit_project.dart _populateFrom
      projectTypeStr = subType.isNotEmpty ? '$mainType → $subType' : mainType;
    }
    if (projectTypeStr != null) {
      // Normalize legacy 'Business / Commercial' to 'Commercial'
      if (projectTypeStr.contains('Business / Commercial')) {
        projectTypeStr = projectTypeStr.replaceAll(
          'Business / Commercial',
          'Commercial',
        );
      } else if (projectTypeStr.contains('Business/Commercial')) {
        projectTypeStr = projectTypeStr.replaceAll(
          'Business/Commercial',
          'Commercial',
        );
      }
      // Normalize legacy ' / ' separator to ' → ' so edit screen always gets consistent format
      if (projectTypeStr.contains(' / ')) {
        projectTypeStr = projectTypeStr.replaceFirst(' / ', ' → ');
      }
    }

    return ProjectModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      name: finalName,
      // Some backends return city inside location or omit it entirely
      city: (j['city']?.toString() ?? '').isNotEmpty
          ? j['city'].toString()
          : (j['location']?.toString() ?? ''),
      sector: j['sector']?.toString() ?? '',
      stage: ProjectStage.values.firstWhere(
        (e) => e.name == j['stage'],
        orElse: () => ProjectStage.preConstruction,
      ),
      progress: (j['progress'] as num?)?.toDouble() ?? 0.0,
      spentAmount: (j['spentAmount'] as num?)?.toDouble() ?? 0.0,
      totalIncome: (j['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalBudget: (j['totalBudget'] as num?)?.toDouble() ??
          (budget?['total'] as num?)?.toDouble() ??
          0.0,
      startDate: parsedStartDate,
      location: j['location']?.toString() ?? '',
      clientName: j['clientName']?.toString(),
      projectType: projectTypeStr,
      expectedEndDate: parsedExpectedEnd,
      floors: parsedFloors,
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
      contractorName: j['contractorName']?.toString(),
      siteEngineer:
          j['siteEngineer']?.toString() ?? j['siteEngineerName']?.toString(),
      contactNumber: j['contactNumber']?.toString(),
      mapAddress: j['mapAddress']?.toString(),
      actualEndDate: dates?['actualEndDate'] != null
          ? DateTime.tryParse(dates!['actualEndDate'].toString())
          : (j['actualEndDate'] != null
                ? DateTime.tryParse(j['actualEndDate'].toString())
                : null),
      landArea: j['landArea']?.toString(),
      landUnit: j['landUnit']?.toString(),
      projectCode: j['projectCode']?.toString(),
      room1BHK: safeInt(j['room1BHK']),
      room2BHK: safeInt(j['room2BHK']),
      room3BHK: safeInt(j['room3BHK']),
      roomCustom: safeInt(j['roomCustom']),
      bathWestern: safeInt(j['bathWestern']),
      bathIndian: safeInt(j['bathIndian']),
      bathCommon: safeInt(j['bathCommon']),
      bathAttached: safeInt(j['bathAttached']),
      selectedFeatures: j['selectedFeatures'] != null
          ? List<String>.from(j['selectedFeatures'] as List)
          : null,
      budgetMaterial: bMat > 0 ? bMat : null,
      budgetLabour: bLab > 0 ? bLab : null,
      budgetEquipment: bEq > 0 ? bEq : null,
      budgetMisc: bMisc > 0 ? bMisc : null,
      projectStatus: resolvedProjectStatus,
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
