// lib/controller/project_provider.dart
// Global ProjectProvider — single source of truth for all project state.
// Injected at the app root (main.dart) via MultiProvider.

import 'dart:developer' as dev;

import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kProjectsKey = 'buildtrack_projects_v1';
const _kEntriesKey  = 'buildtrack_entries_v1';

class ProjectProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────

  List<ProjectModel> _projects = [];
  List<EntryModel>   _entries  = [];
  ProjectModel?      _selectedProject;

  bool   _isLoading = false;
  String _error     = '';

  // ── Getters ────────────────────────────────────────────────────────────────

  List<ProjectModel> get projects        => List.unmodifiable(_projects);
  List<EntryModel>   get entries         => List.unmodifiable(_entries);
  ProjectModel?      get selectedProject => _selectedProject;
  bool               get isLoading       => _isLoading;
  String             get error           => _error;
  bool               get hasProjects     => _projects.isNotEmpty;
  int                get projectCount    => _projects.length;

  List<EntryModel> entriesForProject(String projectId) =>
      _entries.where((e) => e.projectId == projectId).toList();

  double totalSpentForProject(String projectId) =>
      entriesForProject(projectId).fold(0.0, (s, e) => s + e.amount);

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Call once from main() before runApp, or from initState on root widget.
  Future<void> load() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load projects
      final rawProjects = prefs.getString(_kProjectsKey);
      if (rawProjects != null && rawProjects.isNotEmpty) {
        _projects = ProjectModel.decodeList(rawProjects);
      } else {
        // Seed with demo data on first launch
        _projects = _seedProjects();
        await _persistProjects();
      }

      // Load entries
      final rawEntries = prefs.getString(_kEntriesKey);
      if (rawEntries != null && rawEntries.isNotEmpty) {
        _entries = EntryModel.decodeList(rawEntries);
      } else {
        _entries = _seedEntries();
        await _persistEntries();
      }

      // Auto-select first project
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

  // ── Project mutations ──────────────────────────────────────────────────────

  Future<void> addProject(ProjectModel project) async {
    _projects.add(project);
    _selectedProject = project;
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

  // ── Entry mutations ────────────────────────────────────────────────────────

  Future<void> addEntry(EntryModel entry) async {
    _entries.add(entry);
    // Update spentAmount on corresponding project
    final idx = _projects.indexWhere((p) => p.id == entry.projectId);
    if (idx != -1) {
      final newSpent = _projects[idx].spentAmount + entry.amount;
      _projects[idx] = _projects[idx].copyWith(spentAmount: newSpent);
      if (_selectedProject?.id == entry.projectId) {
        _selectedProject = _projects[idx];
      }
      await _persistProjects();
    }
    await _persistEntries();
    notifyListeners();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _persistProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProjectsKey, ProjectModel.encodeList(_projects));
  }

  Future<void> _persistEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEntriesKey, EntryModel.encodeList(_entries));
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // ── Seed data ──────────────────────────────────────────────────────────────

  List<ProjectModel> _seedProjects() => [
        ProjectModel(
          id:          'p1',
          name:        'Skyline Residences Phase II',
          city:        'Mumbai',
          sector:      'Andheri West',
          stage:       ProjectStage.structure,
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
