import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'report_model.dart';

class ReportProvider extends ChangeNotifier {
  int _tabIndex = 0;
  int _unitIndex = 0;
  String _selectedProject = 'All Active Projects';

  bool _isLoading = false;
  ReportModel? _report;
  Object? _error;

  ProjectProvider? _projectProvider;

  int get tabIndex => _tabIndex;
  int get unitIndex => _unitIndex;
  String get selectedProject => _selectedProject;

  bool get isLoading => _isLoading;
  ReportModel? get report => _report;
  Object? get error => _error;

  bool get hasData => _report != null && !_isLoading;

  String get currentPeriod {
    const periods = ['daily', 'monthly', 'yearly'];
    return periods[_tabIndex];
  }

  List<double> get activeChartData {
    if (_report == null) return [0.0];

    final data = _unitIndex == 0
        ? _report!.costPerSqftData
        : _report!.chartDataCuyd;

    if (data.isEmpty) return [0.0];

    return data;
  }

  List<String> get projectNames {
    final real = _projectProvider?.projects ?? [];
    return ['All Active Projects', ...real.map((p) => p.name)];
  }

  void linkProjectProvider(ProjectProvider provider) {
    if (_projectProvider != provider) {
      _projectProvider = provider;
      Future.microtask(_load);
    }
  }

  void selectTab(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
    _load();
  }

  void selectUnit(int index) {
    if (_unitIndex == index) return;
    _unitIndex = index;
    notifyListeners();
  }

  void selectProject(String project) {
    if (_selectedProject == project) return;
    _selectedProject = project;
    notifyListeners();
    _load();
  }

  // ✅ FIXED REFRESH (THIS WAS YOUR ERROR)
  Future<void> refresh() async {
    await _load();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Login required");
      }

      const baseUrl = 'http://localhost:5001';

      final uri = Uri.parse(
        '$baseUrl/api/reports/financial?year=2026&month=4',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _report = ReportModel.fromJson(data);
      } else {
        _report = null;
        throw Exception('Failed to load report');
      }
    } catch (e) {
      _error = e;
      _report = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}