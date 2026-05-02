import 'checklist_model.dart';

class ActivityModel {
  final String id;
  final String name;
  final String phaseId;
  final String unit; // Sqft, Cum, Nos, Rft
  final bool requiresPhoto;
  final bool requiresVideo;
  final bool requiresApproval;
  final List<ChecklistItem>? checklist;

  ActivityModel({
    required this.id,
    required this.name,
    required this.phaseId,
    required this.unit,
    this.requiresPhoto = false,
    this.requiresVideo = false,
    this.requiresApproval = false,
    this.checklist,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> j) => ActivityModel(
        id: j['id'] as String,
        name: j['name'] as String,
        phaseId: j['phaseId'] as String,
        unit: j['unit'] as String,
        requiresPhoto: j['requiresPhoto'] as bool? ?? false,
        requiresVideo: j['requiresVideo'] as bool? ?? false,
        requiresApproval: j['requiresApproval'] as bool? ?? false,
        checklist: j['checklist'] != null
            ? List<ChecklistItem>.from(
                (j['checklist'] as List).map(
                  (x) => ChecklistItem.fromJson(x as Map<String, dynamic>),
                ),
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phaseId': phaseId,
        'unit': unit,
        'requiresPhoto': requiresPhoto,
        'requiresVideo': requiresVideo,
        'requiresApproval': requiresApproval,
        if (checklist != null)
          'checklist': checklist!.map((x) => x.toJson()).toList(),
      };
}
