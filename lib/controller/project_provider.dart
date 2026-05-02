import 'dart:developer' as dev;
import 'package:buildtrack_mobile/models/project_model.dart';
import '../models/phase_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
const _kProjectsKey = 'buildtrack_projects_v1';
const _kEntriesKey  = 'buildtrack_entries_v1';
class ProjectProvider extends ChangeNotifier {
  List<ProjectModel> _projects = [];
  List<EntryModel>   _entries  = [];
  List<PhaseModel>   _phases   = [];
  ProjectModel?      _selectedProject;
  bool   _isLoading = false;
  String _error     = '';
  List<ProjectModel> get projects        => List.unmodifiable(_projects);
  List<EntryModel>   get entries         => List.unmodifiable(_entries);
  List<PhaseModel>   get phases          => List.unmodifiable(_phases);
  ProjectModel?      get selectedProject => _selectedProject;
  bool               get isLoading       => _isLoading;
  String             get error           => _error;
  bool               get hasProjects     => _projects.isNotEmpty;
  int                get projectCount    => _projects.length;

  // ── STEP 3D: Inventory — material stock grouped by brand ──────────
  Map<String, double> get materialStock {
    if (_selectedProject == null) return {};
    final Map<String, double> stockMap = {};
    final materialEntries = _entries.where((e) =>
      e.projectId == _selectedProject!.id &&
      e.type == EntryType.material,
    );
    for (final entry in materialEntries) {
      final brand = (entry.brand == null || entry.brand!.isEmpty)
          ? 'Unknown'
          : entry.brand!;
      stockMap[brand] = (stockMap[brand] ?? 0.0) + entry.amount;
    }
    return stockMap;
  }
  // ─────────────────────────────────────────────────────────────────
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
          'Handover'
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
        // ── STEP 3A: Safe migration — fill missing floors on legacy data ──
        _projects = decoded.map((p) {
          if (p.floors == null || p.floors!.isEmpty) {
            return p.copyWith(floors: ['Ground Floor']);
          }
          return p;
        }).toList();
        // ─────────────────────────────────────────────────────────────────
      } else {
        _projects = _seedProjects();
        await _persistProjects();
      }
      final rawEntries = prefs.getString(_kEntriesKey);
      if (rawEntries != null && rawEntries.isNotEmpty) {
        _entries = EntryModel.decodeList(rawEntries);
      } else {
        _entries = _seedEntries();
        await _persistEntries();
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
  // ── STEP 3B: Extended addProject — new optional params added ────────
  // Existing callers (addProject(project)) still work — no breaking change.
  Future<void> addProject(
    ProjectModel project, {
    String?       clientName,
    String?       projectType,
    DateTime?     expectedEndDate,
    List<String>? floors,
  }) async {
    final finalFloors =
        (floors == null || floors.isEmpty) ? ['Ground Floor'] : floors;
    final updatedProject = project.copyWith(
      clientName:      clientName,
      projectType:     projectType,
      expectedEndDate: expectedEndDate,
      floors:          finalFloors,
    );
    _projects.add(updatedProject);
    _selectedProject = updatedProject;
    await _persistProjects();
    notifyListeners();
  }
  // ─────────────────────────────────────────────────────────────────
  void selectProject(ProjectModel project) {
    _selectedProject = project;
    notifyListeners();
  }
  Future<void> updateProjectProgress(String id, double progress) async {
    final idx = _projects.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _projects[idx] = _projects[idx].copyWith(progress: progress.clamp(0.0, 1.0));
    if (_selectedProject?.id == id) _selectedProject = _projects[idx];
    await _persistProjects();
    notifyListeners();
  }
  Future<void> updateProjectCost(String id, double spentAmount) async {
    final idx = _projects.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _projects[idx] = _projects[idx].copyWith(spentAmount: spentAmount);
    if (_selectedProject?.id == id) _selectedProject = _projects[idx];
    await _persistProjects();
    notifyListeners();
  }
  // ── STEP 3C: Extended addEntry — new optional params added ──────────
  // Existing callers (addEntry(entry)) still work — no breaking change.
  Future<void> addEntry(
    EntryModel entry, {
    String?       brand,
    double?       ratePerUnit,
    String?       floor,
    ProjectStage? phase,
  }) async {
    // Merge optional fields with safe defaults
    final updatedEntry = EntryModel(
      id:          entry.id,
      projectId:   entry.projectId,
      type:        entry.type,
      amount:      entry.amount,
      date:        entry.date,
      description: entry.description,
      brand:       brand       ?? entry.brand,
      ratePerUnit: ratePerUnit ?? entry.ratePerUnit,
      floor:       floor       ?? entry.floor,
      phase:       phase       ?? entry.phase,
    );
    _entries.add(updatedEntry);
    // Existing budget update logic — NOT touched
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
    notifyListeners(); // Step 3E: called once, after all updates
  }
  // ─────────────────────────────────────────────────────────────────
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
    await prefs.setString(
      'phases',
      PhaseModel.encodeList(_phases),
    );
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
  List<ProjectModel> _seedProjects() => [
        ProjectModel(
          id:          'p1',
          name:        'Skyline Residences Phase II',
          city:        'Mumbai',
          sector:      'Andheri West',
          stage:       ProjectStage.superstructure,
          progress:    0.68,
          totalBudget: 45_000_000,
          spentAmount: 24_000_000,
          startDate:   DateTime(2024, 1, 15),
        ),
        ProjectModel(
          id:          'p2',
          name:        'Tower Block A – Andheri',
          city:        'Mumbai',
          sector:      'Sector 4',
          stage:       ProjectStage.foundation,
          progress:    0.34,
          totalBudget: 28_000_000,
          spentAmount:  8_400_000,
          startDate:   DateTime(2024, 3, 1),
        ),
        ProjectModel(
          id:          'p3',
          name:        'Commercial Plaza – BKC',
          city:        'Mumbai',
          sector:      'BKC Block G',
          stage:       ProjectStage.finishing,
          progress:    0.92,
          totalBudget: 72_000_000,
          spentAmount: 66_240_000,
          startDate:   DateTime(2023, 6, 10),
        ),
      ];
  List<EntryModel> _seedEntries() => [
        EntryModel(
          id:          'e1',
          projectId:   'p1',
          type:        EntryType.material,
          amount:      842_000,
          date:        DateTime.now().subtract(const Duration(days: 2)),
          description: 'Concrete M30 – 120 m³',
        ),
        EntryModel(
          id:          'e2',
          projectId:   'p1',
          type:        EntryType.labour,
          amount:      1_200_000,
          date:        DateTime.now().subtract(const Duration(days: 1)),
          description: 'Reinforcement crew – 45 workers',
        ),
        EntryModel(
          id:          'e3',
          projectId:   'p1',
          type:        EntryType.equipment,
          amount:      318_000,
          date:        DateTime.now(),
          description: 'Tower crane rental – weekly',
        ),
        EntryModel(
          id:          'e4',
          projectId:   'p2',
          type:        EntryType.material,
          amount:      4_200_000,
          date:        DateTime.now().subtract(const Duration(days: 5)),
          description: 'Foundation RCC pour',
        ),
      ];
}
