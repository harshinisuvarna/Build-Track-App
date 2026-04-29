// lib/controller/report_provider.dart

import 'package:flutter/material.dart';
import 'report_model.dart';

// ── Mock project list ──────────────────────────────────────────────────────────

const List<String> kProjects = [
  'All Active Projects',
  'Tower Block A – Andheri',
  'Commercial Plaza – BKC',
  'Residential Wing C',
  'Road Widening Phase 2',
];

// ── Mock repository ────────────────────────────────────────────────────────────

Future<ReportModel> fetchReport(String period, String project) async {
  // Simulate real network latency.
  await Future<void>.delayed(const Duration(milliseconds: 800));

  // Different datasets per period so tabs feel distinct.
  switch (period) {
    case 'quarterly':
      return ReportModel(
        totalCost:      7_200_000,
        materialCost:   2_526_000,
        labourCost:     3_600_000,
        equipmentCost:  1_074_000,
        chartDataSqft:  [12.1, 13.5, 11.8, 14.2, 13.0, 15.1],
        chartDataCuyd:  [326.7, 364.5, 318.6, 383.4, 351.0, 407.7],
        categoryBudget: {
          'STRUCTURAL':  0.68,
          'ELECTRICAL':  0.55,
          'FINISHING':   0.30,
          'LANDSCAPING': 0.78,
        },
        efficiencyNote:
            'Material costs are 3% under budget this quarter. Review Q4 concrete orders.',
      );

    case 'yearly':
      return ReportModel(
        totalCost:      28_800_000,
        materialCost:   10_080_000,
        labourCost:     14_400_000,
        equipmentCost:   4_320_000,
        chartDataSqft:  [13.0, 14.0, 12.5, 15.5, 14.8, 16.2],
        chartDataCuyd:  [351.0, 378.0, 337.5, 418.5, 399.6, 437.4],
        categoryBudget: {
          'STRUCTURAL':  0.91,
          'ELECTRICAL':  0.72,
          'FINISHING':   0.48,
          'LANDSCAPING': 0.99,
        },
        efficiencyNote:
            'Annual equipment spend is 1% below target. Labour overtime is the key risk for FY.',
      );

    default: // 'monthly'
      return ReportModel(
        totalCost:      2_400_000,
        materialCost:     842_000,
        labourCost:     1_200_000,
        equipmentCost:    318_000,
        chartDataSqft:  [11.2, 13.0, 12.4, 14.6, 13.8, 15.5],
        chartDataCuyd:  [302.4, 351.0, 334.8, 394.2, 372.6, 418.5],
        categoryBudget: {
          'STRUCTURAL':  0.82,
          'ELECTRICAL':  0.45,
          'FINISHING':   0.18,
          'LANDSCAPING': 0.95,
        },
        efficiencyNote:
            'Labour costs are 12% under budget this month due to optimised scheduling.',
      );
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

class ReportProvider extends ChangeNotifier {
  // ── State fields ──────────────────────────────────────────────────────────

  int    _tabIndex      = 0;            // 0=monthly 1=quarterly 2=yearly
  int    _unitIndex     = 0;            // 0=SQFT    1=CUYD
  String _selectedProject = kProjects.first;
  bool   _isLoading     = false;
  ReportModel? _report;
  Object? _error;

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

  // ── Mutations ─────────────────────────────────────────────────────────────

  void selectTab(int index) {
    if (_tabIndex == index) return; // prevent redundant reload
    _tabIndex = index;
    notifyListeners();
    _load();
  }

  void selectUnit(int index) {
    if (_unitIndex == index) return;
    _unitIndex = index;
    notifyListeners(); // chart swaps datasets instantly – no reload needed
  }

  void selectProject(String project) {
    if (_selectedProject == project) return;
    _selectedProject = project;
    notifyListeners();
    _load();
  }

  /// Call on first mount and on pull-to-refresh.
  Future<void> refresh() => _load();

  // ── Internal loader ───────────────────────────────────────────────────────

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _report = await fetchReport(currentPeriod, _selectedProject);
    } catch (e) {
      _error = e;
      _report = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
