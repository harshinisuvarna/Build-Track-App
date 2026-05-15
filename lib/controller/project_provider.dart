import 'dart:developer' as dev;
import 'package:buildtrack_mobile/models/project_model.dart';
import '../models/phase_model.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kProjectsKey = 'buildtrack_projects_v1';
const _kEntriesKey = 'buildtrack_entries_v1';

class ProjectProvider extends ChangeNotifier {
  List<ProjectModel> _projects = [];
  List<EntryModel> _entries = [];
  List<PhaseModel> _phases = [];
  ProjectModel? _selectedProject;

  bool _isLoading = false;
  String _error = '';

  List<ProjectModel> get projects => List.unmodifiable(_projects);
  List<EntryModel> get entries => List.unmodifiable(_entries);
  List<PhaseModel> get phases => List.unmodifiable(_phases);
  ProjectModel? get selectedProject => _selectedProject;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasProjects => _projects.isNotEmpty;
  int get projectCount => _projects.length;

  Map<String, double> get materialStock {
    if (_selectedProject == null) return {};
    final Map<String, double> stockMap = {};
    final materialEntries = _entries.where(
      (e) =>
          e.projectId == _selectedProject!.id && e.type == EntryType.material,
    );
    for (final entry in materialEntries) {
      final brand = (entry.brand == null || entry.brand!.isEmpty)
          ? 'Unknown'
          : entry.brand!;
      stockMap[brand] = (stockMap[brand] ?? 0.0) + entry.amount;
    }
    return stockMap;
  }

  List<EntryModel> entriesForProject(String projectId) =>
      _entries.where((e) => e.projectId == projectId).toList();

  double totalSpentForProject(String projectId) =>
      entriesForProject(projectId).fold(0.0, (s, e) => s + e.amount);

  Future<void> load() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();

      final phaseRaw = prefs.getString('phases');

      if (phaseRaw != null && phaseRaw.isNotEmpty) {
        try {
          _phases = PhaseModel.decodeList(phaseRaw);
        } catch (e) {
          _phases = [];
        }
      }

      if (_phases.isEmpty || _phases.length < 11) {
        final phaseNames = [
          'Pre-Construction',
          'Site Preparation',
          'Foundation',
          'Plinth',
          'Superstructure',
          'Masonry',
          'MEP',
          'Plastering',
          'Finishing',
          'Fixtures',
          'Handover',
        ];

        _phases = phaseNames.asMap().entries.map((entry) {
          return PhaseModel(
            id: entry.value.toLowerCase().replaceAll(' ', '_'),
            name: entry.value,
            order: entry.key,
          );
        }).toList();

        _savePhases();
      }

      final rawProjects = prefs.getString(_kProjectsKey);
      if (rawProjects != null && rawProjects.isNotEmpty) {
        final decoded = ProjectModel.decodeList(rawProjects);
        _projects = decoded.map((p) {
          if (p.floors == null || p.floors!.isEmpty) {
            return p.copyWith(floors: ['Ground Floor']);
          }
          return p;
        }).toList();
      } else {
        _projects = [];
      }

      try {
        final apiMaterials = await ApiService.fetchMaterials();

        _entries = apiMaterials.map<EntryModel>((json) {
          EntryType parsedType = EntryType.material;
          if (json['type'] == 'labour') parsedType = EntryType.labour;
          if (json['type'] == 'equipment') parsedType = EntryType.equipment;

          // Safe extraction of projectId from object or string
          String pId = 'p1';
          if (json['project'] is Map) {
            pId = json['project']['_id']?.toString() ?? 'p1';
          } else if (json['project'] != null) {
            pId = json['project'].toString();
          }

          return EntryModel(
<<<<<<< HEAD
            id: json['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            projectId: json['project'] ?? 'p1',
            type: parsedType,
            amount: (json['quantity'] ?? 0).toDouble(),
            date: json['date'] != null
                ? DateTime.tryParse(json['date']) ?? DateTime.now()
                : DateTime.now(),
            description: json['title'] ?? 'Material Entry',
            brand: json['brand'],
=======
            id: json['_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            projectId: pId, 
            type: parsedType,
            amount: (json['closingStock'] ?? json['quantity'] ?? 0).toDouble(),
            date: json['date'] != null ? DateTime.tryParse(json['date']) ?? DateTime.now() : DateTime.now(),
            description: json['materialName'] ?? json['title'] ?? 'Material Entry',
            brand: json['materialName'] ?? json['brand'],
>>>>>>> feat/roselin-sprint-final
            ratePerUnit: (json['rate'] ?? 0).toDouble(),
          );
        }).toList();

        await _persistEntries();
      } catch (e) {
        dev.log('API fetch failed, falling back to local storage: $e');
        final rawEntries = prefs.getString(_kEntriesKey);
        if (rawEntries != null && rawEntries.isNotEmpty) {
          _entries = EntryModel.decodeList(rawEntries);
        } else {
          _entries = _seedEntries();
          await _persistEntries();
        }
      }

      if (_projects.isNotEmpty) {
        _selectedProject = _projects.first;
      }
      _error = '';
    } catch (e, st) {
      _error = 'Failed to load data: $e';
      dev.log('ProjectProvider.load error', error: e, stackTrace: st);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchProjects() async {
    _setLoading(true);
    _setLoading(false);
    notifyListeners();
  }

  Future<void> addProject(
    ProjectModel project, {
    String? clientName,
    String? projectType,
    DateTime? expectedEndDate,
    List<String>? floors,
  }) async {
    final finalFloors = (floors == null || floors.isEmpty)
        ? ['Ground Floor']
        : floors;
    final updatedProject = project.copyWith(
      clientName: clientName,
      projectType: projectType,
      expectedEndDate: expectedEndDate,
      floors: finalFloors,
    );
    _projects.add(updatedProject);
    _selectedProject = updatedProject;
    await _persistProjects();
    notifyListeners();
  }

  void selectProject(ProjectModel project) {
    _selectedProject = project;
    notifyListeners();
  }

  Future<void> updateProjectProgress(String id, double progress) async {
    final idx = _projects.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _projects[idx] = _projects[idx].copyWith(
      progress: progress.clamp(0.0, 1.0),
    );
    if (_selectedProject?.id == id) _selectedProject = _projects[idx];
    await _persistProjects();
    notifyListeners();
  }

<<<<<<< HEAD
  // --- MERGED ACTIVITY COMPLETION FEATURE ---
  Future<void> toggleActivityCompletion(
    String projectId,
    String activityId, {
    int? legacyTotalActivities,
  }) async {
=======
  // --- ROSELIN'S ACTIVITY COMPLETION FEATURE ---
  Future<void> toggleActivityCompletion(String projectId, String activityId) async {
>>>>>>> feat/roselin-sprint-final
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx == -1) return;
    final project = _projects[idx];

    // ── New path: project has selectedPhases ───────────────────────
    if (project.selectedPhases != null && project.selectedPhases!.isNotEmpty) {
      final updatedPhases = project.selectedPhases!.map((phase) {
        final updatedActivities = phase.activities.map((act) {
          if (act.id == activityId)
            return act.copyWith(completed: !act.completed);
          return act;
        }).toList();
        return phase.copyWith(activities: updatedActivities);
      }).toList();

      final total = updatedPhases.fold<int>(0, (sum, p) => sum + p.totalCount);
      final done = updatedPhases.fold<int>(
        0,
        (sum, p) => sum + p.completedCount,
      );
      final newProgress = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;

      _projects[idx] = project.copyWith(
        selectedPhases: updatedPhases,
        progress: newProgress,
      );
    } else {
      // ── Legacy path: use completedActivityKeys list ──────────────
      final completed = List<String>.from(project.completedActivityKeys ?? []);
      if (completed.contains(activityId)) {
        completed.remove(activityId);
      } else {
        completed.add(activityId);
      }

      final totalToUse = legacyTotalActivities ?? 161;
      final newProgress = totalToUse > 0
          ? (completed.length / totalToUse).clamp(0.0, 1.0)
          : 0.0;

      _projects[idx] = project.copyWith(
        completedActivityKeys: completed,
        progress: newProgress,
      );
    }

    if (_selectedProject?.id == projectId) _selectedProject = _projects[idx];
    await _persistProjects();
    notifyListeners();
  }

  Future<void> addEntry(
    EntryModel entry, {
    String? brand,
    double? ratePerUnit,
    String? floor,
    ProjectStage? phase,
  }) async {
    // --- HARSHINI'S INTEGRATION CODE FOR POSTING ---
    final payload = {
      "title": entry.description,
      "type": entry.type.name,
      "project": entry.projectId,
      "quantity": entry.amount,
      "rate": ratePerUnit ?? entry.ratePerUnit ?? 0,
      "brand": brand ?? entry.brand,
    };

    final success = await ApiService.addMaterial(payload);

    if (!success) {
      dev.log("Failed to save entry to backend!");
      return;
    }
    // --------------------------------------------

    final updatedEntry = EntryModel(
      id: entry.id,
      projectId: entry.projectId,
      type: entry.type,
      amount: entry.amount,
      date: entry.date,
      description: entry.description,
      brand: brand ?? entry.brand,
      ratePerUnit: ratePerUnit ?? entry.ratePerUnit,
      floor: floor ?? entry.floor,
      phase: phase ?? entry.phase,
    );
    _entries.add(updatedEntry);

    final idx = _projects.indexWhere((p) => p.id == updatedEntry.projectId);
    if (idx != -1) {
      final newSpent = _projects[idx].spentAmount + updatedEntry.amount;
      _projects[idx] = _projects[idx].copyWith(spentAmount: newSpent);
      if (_selectedProject?.id == updatedEntry.projectId) {
        _selectedProject = _projects[idx];
      }
      await _persistProjects();
    }
    await _persistEntries();
    notifyListeners();
  }

  Future<void> _persistProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProjectsKey, ProjectModel.encodeList(_projects));
  }

  Future<void> _persistEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEntriesKey, EntryModel.encodeList(_entries));
  }

  void _savePhases() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phases', PhaseModel.encodeList(_phases));
  }

  void addPhase(String name) {
    _phases.add(
      PhaseModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        order: _phases.length,
      ),
    );
    _savePhases();
    notifyListeners();
  }

  void renamePhase(String id, String newName) {
    final index = _phases.indexWhere((p) => p.id == id);
    if (index != -1) {
      _phases[index] = PhaseModel(
        id: _phases[index].id,
        name: newName,
        order: _phases[index].order,
      );
      _savePhases();
      notifyListeners();
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // --- SEED FALLBACK DATA ---
<<<<<<< HEAD
  List<ProjectModel> _seedProjects() => [
    ProjectModel(
      id: 'p1',
      name: 'Skyline Residences Phase II',
      city: 'Mumbai',
      sector: 'Andheri West',
      stage: ProjectStage.floorConstruction,
      progress: 0.68,
      totalBudget: 45000000,
      spentAmount: 24000000,
      startDate: DateTime(2024, 1, 15),
    ),
    ProjectModel(
      id: 'p2',
      name: 'Tower Block A – Andheri',
      city: 'Mumbai',
      sector: 'Sector 4',
      stage: ProjectStage.foundationPlinthWork,
      progress: 0.34,
      totalBudget: 28000000,
      spentAmount: 8400000,
      startDate: DateTime(2024, 3, 1),
    ),
    ProjectModel(
      id: 'p3',
      name: 'Commercial Plaza – BKC',
      city: 'Mumbai',
      sector: 'BKC Block G',
      stage: ProjectStage.finishingWork,
      progress: 0.92,
      totalBudget: 72_000_000,
      spentAmount: 66_240_000,
      startDate: DateTime(2023, 6, 10),
    ),
  ];

  List<EntryModel> _seedEntries() => [
    EntryModel(
      id: 'e1',
      projectId: 'p1',
      type: EntryType.material,
      amount: 120.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
      description: 'Concrete M30 – 120 m³',
    ),
  ];
}
=======
  // Completely emptied out per requirement to remove all dummy projects and records
  List<ProjectModel> _seedProjects() => [];
  List<EntryModel> _seedEntries() => [];
}
>>>>>>> feat/roselin-sprint-final
