import 'dart:convert';
import 'dart:developer' as dev;
import 'package:buildtrack_mobile/models/project_model.dart';
import '../models/phase_model.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kEntriesKey = 'buildtrack_entries_v1';

// Key for persisting completedAt dates locally so they survive API reloads
// even when the backend doesn't echo them back inside selectedPhases.
const _kCompletedAtKey = 'buildtrack_completed_at_v1';

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
  // PERSIST / LOAD completedAt
  // Stored as: { "projectId|activityId": "2025-01-15T10:30:00.000" }
  // =========================

  Future<Map<String, DateTime>> _loadPersistedCompletedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCompletedAtKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final result = <String, DateTime>{};
      decoded.forEach((key, value) {
        if (value != null) {
          final dt = DateTime.tryParse(value.toString());
          if (dt != null) result[key] = dt;
        }
      });
      return result;
    } catch (e) {
      dev.log('_loadPersistedCompletedAt error: $e');
      return {};
    }
  }

  Future<void> _saveCompletedAt(
      String projectId, String activityId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCompletedAtKey);
      final Map<String, dynamic> existing =
          raw != null && raw.isNotEmpty ? json.decode(raw) : {};
      existing['$projectId|$activityId'] = date.toIso8601String();
      await prefs.setString(_kCompletedAtKey, json.encode(existing));
    } catch (e) {
      dev.log('_saveCompletedAt error: $e');
    }
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
        _phases = [
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
            .map((e) => PhaseModel(
                  id: e.value.toLowerCase().replaceAll(' ', '_'),
                  name: e.value,
                  order: e.key,
                ))
            .toList();
        _savePhases();
      }

      // ── Projects ────────────────────────────────────────────────
      try {
        // Build a merged completedAt map from two sources:
        //   1. Current in-memory state (most up-to-date during the session)
        //   2. SharedPreferences (survives app restarts)
        // Source 1 wins over source 2; both win over whatever the API returns.
        final Map<String, DateTime> persistedDates =
            await _loadPersistedCompletedAt();

        final Map<String, Map<String, DateTime>> prevCompletedAt = {};

        // Seed from persisted storage first (lower priority)
        persistedDates.forEach((key, date) {
          final parts = key.split('|');
          if (parts.length == 2) {
            prevCompletedAt.putIfAbsent(parts[0], () => {})[parts[1]] = date;
          }
        });

        // Overwrite with current in-memory state (higher priority)
        for (final p in _projects) {
          for (final phase in p.selectedPhases ?? <ProjectPhase>[]) {
            for (final act in phase.activities) {
              if (act.completedAt != null) {
                prevCompletedAt.putIfAbsent(p.id, () => {})[act.id] =
                    act.completedAt!;
              }
            }
          }
        }

        _projects = await ApiService.fetchProjects();

        // Merge completedAt back and apply floor fallback.
        _projects = _projects.map((p) {
          final actDates = prevCompletedAt[p.id];

          List<ProjectPhase>? mergedPhases;
          if (actDates != null && actDates.isNotEmpty) {
            mergedPhases =
                (p.selectedPhases ?? <ProjectPhase>[]).map((phase) {
              final mergedActivities = phase.activities.map((act) {
                final savedDate = actDates[act.id];
                // Use saved date if the API didn't return one
                if (savedDate != null && act.completedAt == null) {
                  return act.copyWith(completedAt: savedDate);
                }
                return act;
              }).toList();
              return phase.copyWith(activities: mergedActivities);
            }).toList();
          }

          final floors = (p.floors == null || p.floors!.isEmpty)
              ? ['Ground']
              : p.floors!;

          return p.copyWith(
            selectedPhases: mergedPhases ?? p.selectedPhases,
            floors: floors,
          );
        }).toList();

        debugPrint('Projects loaded: ${_projects.length}');
        for (final p in _projects) {
          debugPrint(
            '  Project: "${p.name}" id=${p.id} floors=${p.floors} '
            'spentAmount=${p.spentAmount} ',
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
          EntryType parsedType = EntryType.material;
          final rawType = (json['type'] ?? '').toString().toLowerCase();
          if (rawType == 'labour' || rawType == 'wages') {
            parsedType = EntryType.labour;
          } else if (rawType == 'equipment' || rawType == 'expense') {
            parsedType = EntryType.equipment;
          }

          String projectId = '';
          if (json['project'] is Map) {
            projectId = json['project']['_id']?.toString() ?? '';
          } else if (json['project'] != null) {
            projectId = json['project'].toString();
          }
          if (projectId.isEmpty && json['projectId'] != null) {
            if (json['projectId'] is Map) {
              projectId = json['projectId']['_id']?.toString() ?? '';
            } else {
              projectId = json['projectId'].toString();
            }
          }
          projectId = projectId.trim();
          if (projectId.isEmpty) projectId = 'p1';

          double amount = 0;
          final paymentStatus =
              (json['paymentStatus'] ?? '').toString().toLowerCase().trim();
          final paidAmount = json['paidAmount'];

          if (paymentStatus == 'paid') {
            if (paidAmount != null && paidAmount is num && paidAmount > 0) {
              amount = paidAmount.toDouble();
            } else {
              final v = json['amount'];
              if (v != null && v is num && v > 0) {
                amount = v.toDouble();
              } else {
                final qty = json['quantity'];
                final rate = json['rate'];
                if (qty is num && rate is num && qty > 0 && rate > 0) {
                  amount = (qty * rate).toDouble();
                }
              }
            }
          } else if (paymentStatus == 'partial') {
            if (paidAmount != null && paidAmount is num && paidAmount > 0) {
              amount = paidAmount.toDouble();
            }
          }

          debugPrint(
            'Entry → type=$rawType projectId=$projectId '
            'paymentStatus=$paymentStatus '
            'paidAmount=${json['paidAmount']} amount=${json['amount']} '
            'using=$amount',
          );

          return EntryModel(
            id: json['_id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            projectId: projectId,
            type: parsedType,
            amount: amount,
            date: json['date'] != null
                ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
                : DateTime.now(),
            description: json['materialName'] ??
                json['title'] ??
                json['description'] ??
                json['name'] ??
                'Entry',
            brand: json['materialName'] ?? json['brand'] ?? json['name'],
            ratePerUnit:
                (json['rate'] is num) ? (json['rate'] as num).toDouble() : 0,
            unit: json['unit']?.toString(),
          );
        }).toList();

        debugPrint('--- MATCH CHECK ---');
        for (final p in _projects) {
          final matched =
              _entries.where((e) => e.projectId == p.id).toList();
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

      // Retain currently selected project
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
      _projects = _projects.map((p) {
        final floors = p.floors;
        if (floors == null || floors.isEmpty) {
          return p.copyWith(floors: ['Ground']);
        }
        return p;
      }).toList();
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
        ? (project.floors == null || project.floors!.isEmpty
            ? ['Ground']
            : project.floors!)
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

  // =========================
  // UPDATE PROJECT (for Edit screen)
  // =========================

  Future<void> updateProject(ProjectModel updated) async {
    _setLoading(true);
    try {
      final response = await ApiService.put(
        '/projects/${updated.id}',
        updated.toJson(),
      );
      if (response.statusCode == 200) {
        final idx = _projects.indexWhere((p) => p.id == updated.id);
        if (idx != -1) {
          _projects[idx] = updated;
        }
        if (_selectedProject?.id == updated.id) {
          _selectedProject = updated;
          UserSession.projectId = updated.id;
        }
        _error = '';
      } else {
        _error = 'Failed to update project: ${response.statusCode}';
        dev.log('updateProject failed: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Update error: $e';
      dev.log('updateProject error: $e');
    } finally {
      _setLoading(false);
    }
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
  // KEY FIX: if the activity is already completed, this is a no-op.
  // Completion is a one-way action — it can only be set, never unset here.
  // =========================

  Future<void> toggleActivityCompletion(
    String projectId,
    String activityId, {
    DateTime? completedAt,
  }) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final project = _projects[projectIndex];
    final phases = List<ProjectPhase>.from(project.selectedPhases ?? []);

    bool alreadyCompleted = false;
    DateTime? stampedDate;

    for (var p = 0; p < phases.length; p++) {
      final phase = phases[p];
      final activities = List<ProjectActivity>.from(phase.activities);

      final aIndex = activities.indexWhere((a) => a.id == activityId);
      if (aIndex != -1) {
        final current = activities[aIndex];

        // ── GUARD: already done → do nothing ──────────────────────
        if (current.completed) {
          alreadyCompleted = true;
          break;
        }

        // Mark as completed and stamp the date
        stampedDate = completedAt ?? DateTime.now();
        activities[aIndex] = current.copyWith(
          completed: true,
          completedAt: stampedDate,
        );

        phases[p] = phase.copyWith(activities: activities);
        break;
      }
    }

    // If the activity was already done, bail out silently
    if (alreadyCompleted) return;

    final total = phases.fold<int>(0, (sum, p) => sum + p.totalCount);
    final done = phases.fold<int>(0, (sum, p) => sum + p.completedCount);

    final updated = project.copyWith(
      selectedPhases: phases,
      progress: total == 0 ? project.progress : done / total,
    );

    _projects[projectIndex] = updated;

    if (_selectedProject?.id == projectId) {
      _selectedProject = updated;
    }

    notifyListeners();

    // Persist the completedAt date to SharedPreferences so it survives
    // the next load() even if the backend doesn't echo it back.
    if (stampedDate != null) {
      await _saveCompletedAt(projectId, activityId, stampedDate);
    }

    // Push the updated project state to the backend.
    // Do NOT call load() here — it would re-fetch from API and overwrite
    // the completedAt stamps if the backend doesn't return them.
    try {
      await ApiService.put('/projects/$projectId', updated.toJson());
    } catch (e) {
      dev.log('Failed to persist activity completion: $e');
    }
  }

  // =========================
  // MARK ACTIVITY COMPLETE (called from update_progress screen)
  // Uses a specific date (the one the user submitted on the progress form)
  // rather than DateTime.now().
  // =========================

  Future<void> markActivityComplete(
    String projectId,
    String activityId,
    DateTime completionDate,
  ) async {
    await toggleActivityCompletion(
      projectId,
      activityId,
      completedAt: completionDate,
    );
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
    String rawType = "Materials";
    if (entry.type == EntryType.labour) rawType = "Wages";
    if (entry.type == EntryType.equipment) rawType = "Expense";

    final payload = {
      "title":
          entry.description.isNotEmpty ? entry.description : "New Entry",
      "type": rawType,
      "project": entry.projectId,
      "category": brand ?? entry.brand ?? entry.description,
      "unit": entry.unit ?? "unit",
      "quantity": entry.amount,
      "rate": ratePerUnit ?? entry.ratePerUnit ?? 1,
      "amount": entry.amount * (ratePerUnit ?? entry.ratePerUnit ?? 1),
      "paymentStatus": "Pending",
      "paymentMode": "Cash",
      "paidAmount": 0,
    };

    final success = await ApiService.addMaterial(payload);
    if (!success) {
      dev.log("Failed to save entry to backend.");
      return;
    }

    final updatedEntry = EntryModel(
      id: entry.id,
      projectId: entry.projectId,
      type: entry.type,
      amount: 0,
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
      if (_selectedProject?.id == updatedEntry.projectId) {
        _selectedProject = _projects[idx];
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
    _phases.add(PhaseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      order: _phases.length,
    ));
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
}