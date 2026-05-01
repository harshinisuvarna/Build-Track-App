import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'report_model.dart';
class ReportProvider extends ChangeNotifier {
  int    _tabIndex        = 0;           
  int    _unitIndex       = 0;            
  String _selectedProject = 'All Active Projects';
  bool   _isLoading       = false;
  ReportModel? _report;
  Object? _error;
  ProjectProvider? _projectProvider;
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
  List<String> get projectNames {
    final real = _projectProvider?.projects ?? [];
    return ['All Active Projects', ...real.map((p) => p.name)];
  }
  void linkProjectProvider(ProjectProvider provider) {
    if (_projectProvider != provider) {
      _projectProvider = provider;
      if (_report == null) _load();
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
  Future<void> refresh() => _load();
  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
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
    final periodMultiplier = _tabIndex == 0 ? 1.0 : _tabIndex == 1 ? 3.0 : 12.0;
    final periodTotal = total * periodMultiplier;
    final periodMat   = matCost * periodMultiplier;
    final periodLab   = labCost * periodMultiplier;
    final periodEq    = eqCost * periodMultiplier;
    final base = total > 0 ? total / 1000 : 50.0;
    final sqft = [
      base * 0.60, base * 0.68, base * 0.75,
      base * 0.82, base * 0.91, base,
    ];
    final cuyd = sqft.map((v) => v * 27.0).toList(); // 1 cuyd ≈ 27 sqft
    final budgetFraction = totalBudget > 0 ? total / totalBudget : 0.0;
    final matFrac = totalBudget > 0 ? matCost / (totalBudget * 0.40) : 0.0;
    final labFrac = totalBudget > 0 ? labCost / (totalBudget * 0.35) : 0.0;
    final eqFrac  = totalBudget > 0 ? eqCost  / (totalBudget * 0.15) : 0.0;
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
