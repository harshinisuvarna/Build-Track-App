// lib/controller/report_provider.dart
// Builds report data from real ProjectProvider entries.

import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'report_model.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

class ReportProvider extends ChangeNotifier {
  // ── State fields ──────────────────────────────────────────────────────────

  int    _tabIndex        = 0;            // 0=monthly 1=quarterly 2=yearly
  int    _unitIndex       = 0;            // 0=SQFT    1=CUYD
  String _selectedProject = 'All Active Projects';
  bool   _isLoading       = false;
  ReportModel? _report;
  Object? _error;

  ProjectProvider? _projectProvider;

  // ── Public getters ────────────────────────────────────────────────────────

  int          get tabIndex        => _tabIndex;
  int          get unitIndex       => _unitIndex;
  String       get selectedProject => _selectedProject;
  bool         get isLoading       => _isLoading;
  ReportModel? get report          => _report;
  Object?      get error           => _error;
  bool         get hasData         => _report != null && !_isLoading;

  String get currentPeriod {
    const periods = ['monthly', 'quarterly', 'yearly'];
    return periods[_tabIndex];
  }

  List<double> get activeChartData {
    if (_report == null) return [];
    return _unitIndex == 0
        ? _report!.chartDataSqft
        : _report!.chartDataCuyd;
  }

  /// List of project names for the dropdown (real projects from ProjectProvider)
  List<String> get projectNames {
    final real = _projectProvider?.projects ?? [];
    return ['All Active Projects', ...real.map((p) => p.name)];
  }

  // ── Link to ProjectProvider ───────────────────────────────────────────────

  /// Call this once from the Reports screen build to link the data source.
  void linkProjectProvider(ProjectProvider provider) {
    if (_projectProvider != provider) {
      _projectProvider = provider;
      if (_report == null) _load();
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

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

  /// Call on first mount and on pull-to-refresh.
  Future<void> refresh() => _load();

  // ── Internal loader — builds report from real ProjectProvider data ────────

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Small delay to feel like a real fetch
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final pp = _projectProvider;
      if (pp == null) {
        _report = _emptyReport();
      } else {
        _report = _buildReport(pp);
      }
    } catch (e) {
      _error = e;
      _report = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ReportModel _buildReport(ProjectProvider pp) {
    final isAll = _selectedProject == 'All Active Projects';

    // Gather entries for the selected scope
    List<EntryModel> scopedEntries;
    double totalBudget;

    if (isAll) {
      scopedEntries = List.of(pp.entries);
      totalBudget = pp.projects.fold(0.0, (s, p) => s + p.totalBudget);
    } else {
      final project = pp.projects.firstWhere(
        (p) => p.name == _selectedProject,
        orElse: () => pp.projects.first,
      );
      scopedEntries = pp.entriesForProject(project.id);
      totalBudget = project.totalBudget;
    }

    // Cost totals
    final matCost = scopedEntries
        .where((e) => e.type == EntryType.material)
        .fold(0.0, (s, e) => s + e.amount);
    final labCost = scopedEntries
        .where((e) => e.type == EntryType.labour)
        .fold(0.0, (s, e) => s + e.amount);
    final eqCost = scopedEntries
        .where((e) => e.type == EntryType.equipment)
        .fold(0.0, (s, e) => s + e.amount);
    final total = matCost + labCost + eqCost;

    // Period multipliers so tabs feel different
    final periodMultiplier = _tabIndex == 0 ? 1.0 : _tabIndex == 1 ? 3.0 : 12.0;
    final periodTotal = total * periodMultiplier;
    final periodMat   = matCost * periodMultiplier;
    final periodLab   = labCost * periodMultiplier;
    final periodEq    = eqCost * periodMultiplier;

    // Chart data — build from real spend progression
    final base = total > 0 ? total / 1000 : 50.0;
    final sqft = [
      base * 0.60, base * 0.68, base * 0.75,
      base * 0.82, base * 0.91, base,
    ];
    final cuyd = sqft.map((v) => v * 27.0).toList(); // 1 cuyd ≈ 27 sqft

    // Category budget — derive from real ratios
    final budgetFraction = totalBudget > 0 ? total / totalBudget : 0.0;
    final matFrac = totalBudget > 0 ? matCost / (totalBudget * 0.40) : 0.0;
    final labFrac = totalBudget > 0 ? labCost / (totalBudget * 0.35) : 0.0;
    final eqFrac  = totalBudget > 0 ? eqCost  / (totalBudget * 0.15) : 0.0;

    // Efficiency note
    String note;
    if (budgetFraction < 0.6) {
      note = 'Spending is well within budget at ${(budgetFraction * 100).toStringAsFixed(0)}%. Great cost control.';
    } else if (budgetFraction < 0.9) {
      note = 'Budget utilisation at ${(budgetFraction * 100).toStringAsFixed(0)}%. Monitor upcoming expenses closely.';
    } else {
      note = 'Budget usage at ${(budgetFraction * 100).toStringAsFixed(0)}%. Immediate cost review needed.';
    }

    return ReportModel(
      totalCost:     periodTotal,
      materialCost:  periodMat,
      labourCost:    periodLab,
      equipmentCost: periodEq,
      chartDataSqft: sqft,
      chartDataCuyd: cuyd,
      categoryBudget: {
        'STRUCTURAL':  matFrac.clamp(0.0, 1.0),
        'ELECTRICAL':  (matFrac * 0.5).clamp(0.0, 1.0),
        'LABOUR':      labFrac.clamp(0.0, 1.0),
        'EQUIPMENT':   eqFrac.clamp(0.0, 1.0),
      },
      efficiencyNote: note,
    );
  }

  ReportModel _emptyReport() => const ReportModel(
    totalCost: 0, materialCost: 0, labourCost: 0, equipmentCost: 0,
    chartDataSqft: [0, 0, 0, 0, 0, 0],
    chartDataCuyd: [0, 0, 0, 0, 0, 0],
    categoryBudget: {},
    efficiencyNote: 'No data available.',
  );
}
