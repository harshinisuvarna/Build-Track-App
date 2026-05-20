import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'report_model.dart';

class ReportProvider extends ChangeNotifier {
  int _tabIndex = 0;
  String _selectedProjectId = 'all';
  ProjectProvider? _projectProvider;

  int get tabIndex => _tabIndex;
  String get selectedProjectId => _selectedProjectId;

  String get selectedProjectName {
    if (_selectedProjectId == 'all') return 'All Active Projects';
    final match = _projectProvider?.projects
        .where((p) => p.id == _selectedProjectId)
        .firstOrNull;
    return match?.name ?? 'All Active Projects';
  }

  bool get isLoading => _projectProvider?.isLoading ?? false;
  String? get error => _projectProvider?.error;
  bool get hasData => _projectProvider?.hasProjects ?? false;
  ReportModel get report => buildLiveReport();
  
  String get currentPeriod {
    switch (_tabIndex) {
      case 0: return 'month';
      case 1: return 'quarter';
      case 2: return 'year';
      default: return 'month';
    }
  }

  void linkProjectProvider(ProjectProvider provider) {
    if (_projectProvider == provider) return;
    _projectProvider?.removeListener(_onProjectDataChanged);
    _projectProvider = provider;
    provider.addListener(_onProjectDataChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _onProjectDataChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _projectProvider?.removeListener(_onProjectDataChanged);
    super.dispose();
  }

  void selectTab(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
  }

  void selectProject(String projectId) {
    if (_selectedProjectId == projectId) return;
    _selectedProjectId = projectId;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _projectProvider?.load();
    notifyListeners();
  }

  ReportModel buildLiveReport() {
  final provider = _projectProvider;
  if (provider == null || provider.projects.isEmpty) {
    return ReportModel.empty();
  }

  final List<ProjectModel> targetProjects = _selectedProjectId == 'all'
      ? provider.projects
      : provider.projects.where((p) => p.id == _selectedProjectId).toList();

  if (targetProjects.isEmpty) return ReportModel.empty();

  double material = 0;
  double labour = 0;
  double equipment = 0;

  for (final project in targetProjects) {
    final entries = provider.entriesForProject(project.id);
    
    // Try entries first
    double entryMaterial = 0, entryLabour = 0, entryEquipment = 0;
    for (final entry in entries) {
      switch (entry.type) {
        case EntryType.material: entryMaterial += entry.amount; break;
        case EntryType.labour:   entryLabour   += entry.amount; break;
        case EntryType.equipment:entryEquipment+= entry.amount; break;
      }
    }

    final entryTotal = entryMaterial + entryLabour + entryEquipment;

    if (entryTotal > 0) {
      // ✅ Real entry data exists — use it
      material  += entryMaterial;
      labour    += entryLabour;
      equipment += entryEquipment;
    } else if (project.spentAmount > 0) {
      // ✅ FALLBACK: distribute spentAmount by budget ratio
      final bm = project.budgetMaterial  ?? 0;
      final bl = project.budgetLabour    ?? 0;
      final be = project.budgetEquipment ?? 0;
      final bx = project.budgetMisc      ?? 0;
      final bt = bm + bl + be + bx;

      if (bt > 0) {
        material  += project.spentAmount * (bm / bt);
        labour    += project.spentAmount * (bl / bt);
        equipment += project.spentAmount * (be / bt);
      } else {
        // No budget breakdown — put all in material
        material += project.spentAmount;
      }
    }
  }

  // Target budgets
  double targetMaterial = 0, targetLabour = 0,
         targetEquipment = 0, targetMisc = 0;
  for (final project in targetProjects) {
    targetMaterial  += project.budgetMaterial  ?? 0;
    targetLabour    += project.budgetLabour    ?? 0;
    targetEquipment += project.budgetEquipment ?? 0;
    targetMisc      += project.budgetMisc      ?? 0;
  }

  final total = material + labour + equipment;
  final totalTarget = targetMaterial + targetLabour +
                      targetEquipment + targetMisc;
  final isOver = totalTarget > 0 && total > totalTarget;

  return ReportModel(
    totalCost:    total,
    materialCost: material,
    labourCost:   labour,
    equipmentCost:equipment,
    categoryBudget: {
      'Material':  material,
      'Labour':    labour,
      'Equipment': equipment,
    },
    targetMaterial:  targetMaterial,
    targetLabour:    targetLabour,
    targetEquipment: targetEquipment,
    targetMisc:      targetMisc,
    efficiencyNote: isOver
        ? 'Budget exceeded by ${_fmt(total - totalTarget)}'
        : 'Project is within budget',
  );
}

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}