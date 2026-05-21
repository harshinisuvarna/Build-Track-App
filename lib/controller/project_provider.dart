import 'dart:developer' as dev;
import 'package:buildtrack_mobile/models/project_model.dart';
import '../models/phase_model.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      _entries.where((e) => e.projectId.trim() == projectId.trim()).toList();

  double totalSpentForProject(String projectId) =>
      entriesForProject(projectId).fold(0.0, (sum, e) => sum + e.amount);

  double getProjectSqftCost(ProjectModel project) {
    final area = double.tryParse(project.landArea ?? '0') ?? 0;
    if (area <= 0) return 0;
    return project.spentAmount / area;
  }

  bool isProjectOverBudget(ProjectModel project) =>
      project.spentAmount > project.totalBudget;

  double budgetExceededAmount(ProjectModel project) {
    if (!isProjectOverBudget(project)) return 0;
    return project.spentAmount - project.totalBudget;
  }

  double budgetRemainingAmount(ProjectModel project) {
    final remain = project.totalBudget - project.spentAmount;
    return remain < 0 ? 0 : remain;
  }

  // =========================
  // LOAD
  // =========================

  Future<void> load() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // ── Phases ──────────────────────────────────────────────────
      final phaseRaw = prefs.getString('phases');
      if (phaseRaw != null && phaseRaw.isNotEmpty) {
        try {
          _phases = PhaseModel.decodeList(phaseRaw);
        } catch (_) {
          _phases = [];
        }
      }
      if (_phases.isEmpty || _phases.length < 11) {
        _phases =
            [
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
                ]
                .asMap()
                .entries
                .map(
                  (e) => PhaseModel(
                    id: e.value.toLowerCase().replaceAll(' ', '_'),
                    name: e.value,
                    order: e.key,
                  ),
                )
                .toList();
        _savePhases();
      }

      // ── Projects ────────────────────────────────────────────────
      try {
        _projects = await ApiService.fetchProjects();
        _projects = _projects
            .map(
              (p) => p.copyWith(
                floors: (p.floors == null || p.floors!.isEmpty)
                    ? ['Ground Floor']
                    : p.floors,
              ),
            )
            .toList();
        debugPrint('Projects loaded: ${_projects.length}');
        for (final p in _projects) {
          debugPrint(
            '  Project: "${p.name}" id=${p.id} '
            'spentAmount=${p.spentAmount} '
            'budgetMaterial=${p.budgetMaterial} '
            'budgetLabour=${p.budgetLabour} '
            'budgetEquipment=${p.budgetEquipment}',
          );
        }
      } catch (e) {
        dev.log('fetchProjects failed: $e');
        _projects = [];
      }

      // ── Entries ──────────────────────────────────────────────────
      try {
        final apiMaterials = await ApiService.fetchMaterials();
        debugPrint('fetchMaterials: ${apiMaterials.length} items');

        if (apiMaterials.isNotEmpty) {
          debugPrint('=== RAW FIRST ENTRY FIELDS ===');
          apiMaterials.first.forEach((key, value) {
            debugPrint('  [$key] = $value  (${value?.runtimeType})');
          });
          debugPrint('==============================');
        }

        _entries = apiMaterials.map<EntryModel>((json) {
          // --- Type ---
          EntryType parsedType = EntryType.material;
          final rawType = (json['type'] ?? '').toString().toLowerCase();

          // ✅ Matches both frontend logic and backend schema
          if (rawType == 'labour' || rawType == 'wages') {
            parsedType = EntryType.labour;
          } else if (rawType == 'equipment' || rawType == 'expense') {
            parsedType = EntryType.equipment;
          }

          // --- ProjectId ---
          String projectId = '';
          if (json['project'] is Map) {
            projectId = json['project']['_id']?.toString() ?? '';
          } else if (json['project'] != null) {
            projectId = json['project'].toString();
          }

          // --- Amount: total cost fields first, then payment details ---
          double amount = 0;
          final fieldsToTry = [
            'amount',
            'totalCost',
            'totalAmount',
            'total',
            'cost',
            'price',
            'paidAmount',
            'amountPaid',
            'paymentAmount',
            'paid',
            'totalPaid',
            'closingStock',
          ];
          for (final field in fieldsToTry) {
            final v = json[field];
            if (v != null && v is num && v > 0) {
              amount = v.toDouble();
              break;
            }
          }
          // quantity * rate fallback
          if (amount == 0) {
            final qty = json['quantity'];
            final rate = json['rate'];
            if (qty is num && qty > 0) {
              amount = rate is num && rate > 0
                  ? (qty * rate).toDouble()
                  : qty.toDouble();
            }
          }
          if (projectId.isEmpty && json['projectId'] != null) {
            if (json['projectId'] is Map) {
              projectId = json['projectId']['_id']?.toString() ?? '';
            } else {
              projectId = json['projectId'].toString();
            }
          }
          projectId = projectId.trim();
          if (projectId.isEmpty) {
            projectId = 'p1'; // ultimate fallback
          }

          return EntryModel(
            id:
                json['_id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            projectId: projectId,
            type: parsedType,
            amount: amount, // Your robust pre-calculated amount
            date: json['date'] != null
                ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
                : DateTime.now(),
            description:
                json['materialName'] ??
                json['title'] ??
                json['description'] ??
                json['name'] ??
                'Entry',
            brand: json['materialName'] ?? json['brand'] ?? json['name'],
            ratePerUnit: (json['rate'] is num)
                ? (json['rate'] as num).toDouble()
                : 0,
            unit: json['unit']?.toString(), // SALVAGED FROM MUNESHA'S MAIN
          );
        }).toList();

        debugPrint('--- MATCH CHECK ---');
        for (final p in _projects) {
          final matched = _entries.where((e) => e.projectId == p.id).toList();
          final total = matched.fold(0.0, (s, e) => s + e.amount);
          debugPrint('  "${p.name}" → ${matched.length} entries, ₹$total');
        }
        debugPrint('-------------------');

        await _persistEntries();
      } catch (e, st) {
        debugPrint('fetchMaterials failed: $e\n$st');
        final rawEntries = prefs.getString(_kEntriesKey);
        if (rawEntries != null && rawEntries.isNotEmpty) {
          _entries = EntryModel.decodeList(rawEntries);
        } else {
          _entries = [];
        }
      }

      // Retain currently selected project if it still exists in the fetched list
      if (_selectedProject != null) {
        final existingIdx = _projects.indexWhere(
          (p) => p.id.trim() == _selectedProject!.id.trim(),
        );
        if (existingIdx != -1) {
          _selectedProject = _projects[existingIdx];
        } else if (_projects.isNotEmpty) {
          _selectedProject = _projects.first;
        } else {
          _selectedProject = null;
        }
      } else if (_projects.isNotEmpty) {
        _selectedProject = _projects.first;
      }
      if (_selectedProject != null) {
        UserSession.projectId = _selectedProject!.id;
      }
      _error = '';
    } catch (e, st) {
      _error = 'Failed to load: $e';
      dev.log('ProjectProvider.load error', error: e, stackTrace: st);
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // FETCH PROJECTS
  // =========================

  Future<void> fetchProjects() async {
    _setLoading(true);
    try {
      _projects = await ApiService.fetchProjects();
      _projects = _projects
          .map(
            (p) => p.copyWith(
              floors: (p.floors == null || p.floors!.isEmpty)
                  ? ['Ground Floor']
                  : p.floors,
            ),
          )
          .toList();
      if (_projects.isNotEmpty && _selectedProject == null) {
        _selectedProject = _projects.first;
      }
      if (_selectedProject != null) {
        UserSession.projectId = _selectedProject!.id;
      }
      _error = '';
    } catch (e) {
      _error = 'Failed to fetch projects: $e';
      dev.log('fetchProjects error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // ADD PROJECT
  // =========================

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
    final saved = await ApiService.addProject(updatedProject.toJson());
    if (saved == null) {
      dev.log('addProject failed');
      throw Exception('Failed to save project');
    }
    _projects.add(saved);
    _selectedProject = saved;
    UserSession.projectId = saved.id;
    notifyListeners();
  }

  void selectProject(ProjectModel project) {
    _selectedProject = project;
    UserSession.projectId = project.id;
    notifyListeners();
  }

  // =========================
  // UPDATE PROGRESS
  // =========================

  Future<void> updateProjectProgress(String id, double progress) async {
    final idx = _projects.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _projects[idx] = _projects[idx].copyWith(
      progress: progress.clamp(0.0, 1.0),
    );
    if (_selectedProject?.id == id) _selectedProject = _projects[idx];
    try {
      await ApiService.put('/projects/$id', _projects[idx].toJson());
    } catch (e) {
      dev.log('Failed to persist progress: $e');
    }
    notifyListeners();
  }

  // =========================
  // TOGGLE ACTIVITY
  // =========================

  Future<void> toggleActivityCompletion(
    String projectId,
    String activityId, {
    int? legacyTotalActivities,
  }) async {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx == -1) return;
    final project = _projects[idx];
    List<String> updatedCompletedKeys = List.from(
      project.completedActivityKeys ?? [],
    );

    if (project.selectedPhases != null && project.selectedPhases!.isNotEmpty) {
      final updatedPhases = project.selectedPhases!.map((phase) {
        final updatedActivities = phase.activities.map((act) {
          if (act.id == activityId) {
            final isNowCompleted = !act.completed;
            if (isNowCompleted && !updatedCompletedKeys.contains(activityId)) {
              updatedCompletedKeys.add(activityId);
            } else if (!isNowCompleted) {
              updatedCompletedKeys.remove(activityId);
            }
            return act.copyWith(completed: isNowCompleted);
          }
          return act;
        }).toList();
        return phase.copyWith(activities: updatedActivities);
      }).toList();

      final total = updatedPhases.fold<int>(0, (s, p) => s + p.totalCount);
      final done = updatedPhases.fold<int>(0, (s, p) => s + p.completedCount);
      _projects[idx] = project.copyWith(
        selectedPhases: updatedPhases,
        completedActivityKeys: updatedCompletedKeys,
        progress: total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0,
      );
    } else {
      if (updatedCompletedKeys.contains(activityId)) {
        updatedCompletedKeys.remove(activityId);
      } else {
        updatedCompletedKeys.add(activityId);
      }
      final totalToUse = legacyTotalActivities ?? 161;
      _projects[idx] = project.copyWith(
        completedActivityKeys: updatedCompletedKeys,
        progress: totalToUse > 0
            ? (updatedCompletedKeys.length / totalToUse).clamp(0.0, 1.0)
            : 0.0,
      );
    }

    if (_selectedProject?.id == projectId) {
      _selectedProject = _projects[idx];
    }
    notifyListeners();

    try {
      final response = await ApiService.put(
        '/projects/$projectId',
        _projects[idx].toJson(),
      );
      if (response.statusCode != 200) {
        dev.log('Failed saving activity: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('Network error saving activity: $e');
    }
  }

  // =========================
  // ADD ENTRY
  // =========================

  Future<void> addEntry(
    EntryModel entry, {
    String? brand,
    double? ratePerUnit,
    String? floor,
    ProjectStage? phase,
  }) async {
    // 1. Map Dart Enums back to exact Backend strings
    String rawType = "Materials";
    if (entry.type == EntryType.labour) rawType = "Wages";
    if (entry.type == EntryType.equipment) rawType = "Expense";

    // 2. Build the STRICT payload that your backend demands
    final payload = {
      "title": entry.description.isNotEmpty ? entry.description : "New Entry",
      "type": rawType,
      "project": entry.projectId,
      "category":
          brand ?? entry.brand ?? entry.description, // Links to inventory item
      "unit": entry.unit ?? "unit",
      "quantity": entry.amount,
      "rate": ratePerUnit ?? entry.ratePerUnit ?? 1,
      "amount":
          entry.amount * (ratePerUnit ?? entry.ratePerUnit ?? 1), // Total bill
      "paymentStatus": "Paid", // Enforced default to pass validation
      "paymentMode": "Cash", // Enforced default to pass validation
      "paidAmount":
          entry.amount *
          (ratePerUnit ?? entry.ratePerUnit ?? 1), // Full payment
    };

    final success = await ApiService.addMaterial(payload);
    if (!success) {
      dev.log(
        "Failed to save entry to backend. Check terminal for server errors.",
      );
      return;
    }

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
      final oldProject = _projects[idx];
      final newSpent = oldProject.spentAmount + updatedEntry.amount;
      _projects[idx] = oldProject.copyWith(spentAmount: newSpent);
      if (_selectedProject?.id == updatedEntry.projectId) {
        _selectedProject = _projects[idx];
      }
      try {
        await ApiService.put(
          '/projects/${oldProject.id}',
          _projects[idx].toJson(),
        );
      } catch (e) {
        dev.log('Failed updating project spent: $e');
      }
    }

    await _persistEntries();
    notifyListeners();
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<EntryModel> _seedEntries() => [];
}
