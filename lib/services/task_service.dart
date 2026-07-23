import 'dart:convert';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:buildtrack_mobile/models/task_model.dart';

class TaskService {
  static Future<List<TaskModel>> getDailyTasks() async {
    final response = await ApiService.get('/tasks/daily');
    if (response.statusCode == 200) {
      return TaskModel.decodeList(response.body);
    }
    throw Exception('Failed to load daily tasks');
  }

  static Future<List<TaskModel>> getProjectTasks(String projectId) async {
    final response = await ApiService.get('/tasks/project/$projectId');
    if (response.statusCode == 200) {
      return TaskModel.decodeList(response.body);
    }
    throw Exception('Failed to load project tasks');
  }

  static Future<List<Map<String, dynamic>>> getAssignableUsers() async {
    final response = await ApiService.get('/tasks/users');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load assignable users');
  }

  static Future<TaskModel> createTask(Map<String, dynamic> taskData) async {
    final response = await ApiService.post('/tasks', taskData);
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return TaskModel.fromJson(data['task']);
    }
    throw Exception('Failed to create task');
  }

  static Future<TaskModel> updateTaskStatus(
    String taskId,
    String status,
  ) async {
    final response = await ApiService.put('/tasks/$taskId/status', {
      'status': status,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TaskModel.fromJson(data['task']);
    }
    throw Exception('Failed to update task status');
  }

  static Future<TaskModel> updateTask(
    String taskId,
    Map<String, dynamic> taskData,
  ) async {
    final response = await ApiService.put('/tasks/$taskId', taskData);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TaskModel.fromJson(data['task']);
    }
    throw Exception('Failed to update task');
  }
}
