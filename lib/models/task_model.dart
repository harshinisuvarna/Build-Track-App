import 'dart:convert';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String project;
  final String? createdBy;
  final String? assignee;
  final Map<String, dynamic>? assignedTo;
  final String? floorId;
  final String? floorName;
  final String? phaseId;
  final String? phaseName;
  final String? activityId;
  final String? activityName;
  final String status;
  final String time;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.project,
    this.createdBy,
    this.assignee,
    this.assignedTo,
    this.floorId,
    this.floorName,
    this.phaseId,
    this.phaseName,
    this.activityId,
    this.activityName,
    this.status = 'Not Started',
    this.time = 'Today',
  });

  factory TaskModel.fromJson(Map<String, dynamic> j) {
    return TaskModel(
      id: j['_id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      project: j['project']?.toString() ?? '',
      createdBy: j['createdBy'] is Map 
          ? j['createdBy']['name']?.toString() ?? j['createdBy']['_id']?.toString() 
          : j['createdBy']?.toString(),
      assignee: j['assignee']?.toString(),
      assignedTo: j['assignedTo'] is Map<String, dynamic> ? j['assignedTo'] : null,
      floorId: j['floorId']?.toString(),
      floorName: j['floorName']?.toString(),
      phaseId: j['phaseId']?.toString(),
      phaseName: j['phaseName']?.toString(),
      activityId: j['activityId']?.toString(),
      activityName: j['activityName']?.toString(),
      status: j['status']?.toString() ?? 'Not Started',
      time: j['time']?.toString() ?? 'Today',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'project': project,
      'createdBy': createdBy,
      'assignee': assignee,
      'assignedTo': assignedTo != null ? assignedTo!['_id'] : null,
      'floorId': floorId,
      'floorName': floorName,
      'phaseId': phaseId,
      'phaseName': phaseName,
      'activityId': activityId,
      'activityName': activityName,
      'status': status,
      'time': time,
    };
  }

  static List<TaskModel> decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
