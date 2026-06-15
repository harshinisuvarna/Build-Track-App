// ════════════════════════════════════════════════════════════════════════════
// CHANGES FROM ORIGINAL — search "FIX 3" to find every change:
//
//  FIX 3a  EntryModel gets a new `createdBy` field (nullable String).
//          Add this field to your existing EntryModel class (in project_model.dart
//          or wherever EntryModel is defined). See the patch comment below.
//
//  FIX 3b  ProjectProvider.load() now reads `createdBy` / `addedBy` /
//          `submittedBy` from the API JSON and stores it on each EntryModel.
//
//  FIX 3c  ApiService.fetchRecentTransactions() and fetchSuggestions() now
//          accept an optional `userId` parameter that is forwarded as a query
//          param so the backend can filter server-side when supported.
//          The frontend also does client-side filtering as a fallback.
// ════════════════════════════════════════════════════════════════════════════
//
// ── EntryModel PATCH ────────────────────────────────────────────────────────
// In your project_model.dart, add `createdBy` to EntryModel:
//
//   class EntryModel {
//     final String id;
//     final String projectId;
//     final EntryType type;
//     final double amount;
//     final DateTime date;
//     final String description;
//     final String? brand;
//     final double? ratePerUnit;
//     final String? unit;
//     final String? floor;
//     final ProjectStage? phase;
//     final String? createdBy;   // <-- ADD THIS FIELD
//
//     EntryModel({
//       required this.id,
//       required this.projectId,
//       required this.type,
//       required this.amount,
//       required this.date,
//       required this.description,
//       this.brand,
//       this.ratePerUnit,
//       this.unit,
//       this.floor,
//       this.phase,
//       this.createdBy,            // <-- ADD TO CONSTRUCTOR
//     });
//   }
//
// Also update EntryModel.decodeList / encodeList / copyWith if you have them
// to include the createdBy field.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:buildtrack_mobile/models/project_model.dart';
import '../models/phase_model.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kEntriesKey = 'buildtrack_entries_v1';
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
      (e) => e.projectId == _selectedProject!.id && e.type == EntryType.material,
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

  // FIX 3: New helper — entries for a project filtered to a specific user
  List<EntryModel> entriesForProjectByUser(String projectId, String userId) {
    final all = entriesForProject(projectId);
    if (userId.isEmpty) return all;
    final filtered = all.where((e) => e.createdBy == userId).toList();
    // Fall back to all entries if no user-specific ones found (older data)
    return filtered.isNotEmpty ? filtered : all;
  }

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

// NEW: call this for activities that are completed but have no date stamp
Future<void> _backfillCompletedActivities() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCompletedAtKey);
    final Map<String, dynamic> existing =
        raw != null && raw.isNotEmpty ? json.decode(raw) : {};
    bool changed = false;
    for (final p in _projects) {
      for (final phase in p.selectedPhases ?? <ProjectPhase>[]) {
        for (final act in phase.activities) {
          final key = '${p.id}|${act.id}';
          if (act.completed && !existing.containsKey(key)) {
            // Use a sentinel date so we know it was completed but date unknown
            existing[key] = DateTime(2000).toIso8601String();
            changed = true;
          }
        }
      }
    }
    if (changed) {
      await prefs.setString(_kCompletedAtKey, json.encode(existing));
    }
  } catch (e) {
    dev.log('_backfillCompletedActivities error: $e');
  }
}

  List<ProjectModel> _filterForCurrentUser(List<ProjectModel> all) {
    if (UserSession.isAdmin) return all;

    final assignedIds = UserSession.projectIds
        .map((id) => id.trim())
        .toSet();
    if (assignedIds.isEmpty) return [];

    return all.where((p) => assignedIds.contains(p.id.trim())).toList();
  }

  Future<void> load() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();

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

      try {
        final Map<String, DateTime> persistedDates =
            await _loadPersistedCompletedAt();

        final Map<String, Map<String, DateTime>> prevCompletedAt = {};
        persistedDates.forEach((key, date) {
          final parts = key.split('|');
          if (parts.length == 2) {
            prevCompletedAt.putIfAbsent(parts[0], () => {})[parts[1]] = date;
          }
        });

        // Snapshot ALL completed activities from current in-memory state BEFORE fetch,
        // regardless of whether completedAt is set — use completed flag as fallback.
        for (final p in _projects) {
          for (final phase in p.selectedPhases ?? <ProjectPhase>[]) {
            for (final act in phase.activities) {
              if (act.completed && act.completedAt != null) {
                prevCompletedAt
                    .putIfAbsent(p.id, () => {})[act.id] = act.completedAt!;
              } else if (act.completed && act.completedAt == null) {
                // Activity was completed but date was never stamped — use epoch as
                // a sentinel so we at least preserve the completed state.
                prevCompletedAt
                    .putIfAbsent(p.id, () => {})
                    .putIfAbsent(act.id, () => DateTime(2000));
              }
            }
          }
        }

        final fetched = await ApiService.fetchProjects();

        _projects = _filterForCurrentUser(fetched);

        _projects = _projects.map((p) {
          final actDates = prevCompletedAt[p.id];
          List<ProjectPhase>? mergedPhases;
          if (actDates != null && actDates.isNotEmpty) {
            mergedPhases = (p.selectedPhases ?? <ProjectPhase>[]).map((phase) {
              final mergedActivities = phase.activities.map((act) {
              final savedDate = actDates[act.id];
              if (savedDate != null) {
                // Always restore the saved date — API may return null for old completions
                // that were only persisted locally. Also ensure completed flag is true.
                if (act.completedAt == null || !act.completed) {
                  return act.copyWith(
                    completed: true,
                    completedAt: savedDate == DateTime(2000) ? null : savedDate,
                  );
                }
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
            '  Project: "${p.name}" id=${p.id} floors=${p.floors} spentAmount=${p.spentAmount}',
          );
        }
      } catch (e) {
        dev.log('fetchProjects failed: $e');
        _projects = [];
      }

      try {
        final apiMaterials = await ApiService.fetchMaterials();
        debugPrint('fetchMaterials: ${apiMaterials.length} items');

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

          // FIX 3b: Extract createdBy from API response.
          // Backend may send it as createdBy, addedBy, submittedBy, or
          // as a nested user object with _id. We try all common variants.
          String? createdBy;
          final createdByRaw = json['createdBy'] ??
              json['addedBy'] ??
              json['submittedBy'] ??
              json['userId'] ??
              json['user'];
          if (createdByRaw is Map) {
            createdBy = createdByRaw['_id']?.toString() ??
                createdByRaw['id']?.toString();
          } else if (createdByRaw != null) {
            createdBy = createdByRaw.toString();
          }

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
            createdBy: createdBy, // FIX 3b
          );
        }).toList();

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

      if (_selectedProject != null) {
        final existingIdx =
            _projects.indexWhere((p) => p.id.trim() == _selectedProject!.id.trim());
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
      // Backfill any completed activities that never got a saved date
      await _backfillCompletedActivities();

      _error = '';
    } catch (e, st) {
      _error = 'Failed to load: $e';
      dev.log('ProjectProvider.load error', error: e, stackTrace: st);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchProjects() async {
    _setLoading(true);
    try {
      final fetched = await ApiService.fetchProjects();

      _projects = _filterForCurrentUser(fetched);

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

  Future<void> updateProject(ProjectModel updated) async {
    _setLoading(true);
    try {
      final response =
          await ApiService.put('/projects/${updated.id}', updated.toJson());
      if (response.statusCode == 200) {
        final idx = _projects.indexWhere((p) => p.id == updated.id);
        if (idx != -1) _projects[idx] = updated;
        if (_selectedProject?.id == updated.id) {
          _selectedProject = updated;
          UserSession.projectId = updated.id;
        }
        _error = '';
      } else {
        _error = 'Failed to update project: ${response.statusCode}';
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

  Future<void> updateProjectProgress(String id, double progress) async {
    final idx = _projects.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _projects[idx] = _projects[idx].copyWith(progress: progress.clamp(0.0, 1.0));
    if (_selectedProject?.id == id) _selectedProject = _projects[idx];
    try {
      await ApiService.put('/projects/$id', _projects[idx].toJson());
    } catch (e) {
      dev.log('Failed to persist progress: $e');
    }
    notifyListeners();
  }

  // AFTER
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
      if (current.completed) {
        alreadyCompleted = true;
        break;
      }
      stampedDate = completedAt ?? DateTime.now();
      activities[aIndex] =
          current.copyWith(completed: true, completedAt: stampedDate);
      phases[p] = phase.copyWith(activities: activities);
      break;
    }
  }

  if (alreadyCompleted) return;

  final total = phases.fold<int>(0, (sum, p) => sum + p.totalCount);
  final done = phases.fold<int>(0, (sum, p) => sum + p.completedCount);
  final updated = project.copyWith(
    selectedPhases: phases,
    progress: total == 0 ? project.progress : done / total,
  );

  // Optimistic update — paint the tick immediately
  _projects[projectIndex] = updated;
  if (_selectedProject?.id == projectId) _selectedProject = updated;
  notifyListeners();

  if (stampedDate != null) {
    await _saveCompletedAt(projectId, activityId, stampedDate);
  }

  try {
    await ApiService.put('/projects/$projectId', updated.toJson());
  } catch (e) {
    dev.log('Failed to persist activity completion: $e');
    // Rollback on API failure so UI stays consistent with server
    _projects[projectIndex] = project;
    if (_selectedProject?.id == projectId) _selectedProject = project;
    notifyListeners();
  }
}

  Future<void> markActivityComplete(
    String projectId,
    String activityId,
    DateTime completionDate,
  ) async {
    await toggleActivityCompletion(projectId, activityId,
        completedAt: completionDate);
  }

  Future<void> addEntry(
    EntryModel entry, {
    String? brand,
    double? ratePerUnit,
    String? floor,
    ProjectStage? phase,
  }) async {
    String rawType = 'Materials';
    if (entry.type == EntryType.labour) rawType = 'Wages';
    if (entry.type == EntryType.equipment) rawType = 'Expense';

    final payload = {
      'title': entry.description.isNotEmpty ? entry.description : 'New Entry',
      'type': rawType,
      'project': entry.projectId,
      'category': brand ?? entry.brand ?? entry.description,
      'unit': entry.unit ?? 'unit',
      'quantity': entry.amount,
      'rate': ratePerUnit ?? entry.ratePerUnit ?? 1,
      'amount': entry.amount * (ratePerUnit ?? entry.ratePerUnit ?? 1),
      'paymentStatus': 'Pending',
      'paymentMode': 'Cash',
      'paidAmount': 0,
    };

    final success = await ApiService.addMaterial(payload);
    if (!success) {
      dev.log('Failed to save entry to backend.');
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
      createdBy: UserSession.userId, // FIX 3b: tag new entries with current user
    );

    _entries.add(updatedEntry);
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

  void clear() {
    _projects = [];
    _entries = [];
    _phases = [];
    _selectedProject = null;
    _isLoading = false;
    _error = '';
    notifyListeners();
  }
}