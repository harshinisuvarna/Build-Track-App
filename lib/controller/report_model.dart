// lib/controller/report_model.dart
// Pure data class – no Flutter imports, no business logic.

class ReportModel {
  const ReportModel({
    required this.totalCost,
    required this.materialCost,
    required this.labourCost,
    required this.equipmentCost,
    required this.chartDataSqft,
    required this.chartDataCuyd,
    required this.categoryBudget,
    required this.efficiencyNote,
  });

  final double totalCost;
  final double materialCost;
  final double labourCost;
  final double equipmentCost;

  /// 6 data-points for the "actual" line when unit = SQFT (cost per sqft).
  final List<double> chartDataSqft;

  /// 6 data-points for the "actual" line when unit = CUYD (cost per cu-yd).
  final List<double> chartDataCuyd;

  /// Category name → fraction spent 0.0–1.0 (e.g. 'STRUCTURAL': 0.82).
  final Map<String, double> categoryBudget;

  /// Short text shown in the efficiency banner.
  final String efficiencyNote;

  // ── Convenience formatters ─────────────────────────────────────────────────

  String get formattedTotal     => _fmt(totalCost);
  String get formattedMaterial  => _fmt(materialCost);
  String get formattedLabour    => _fmt(labourCost);
  String get formattedEquipment => _fmt(equipmentCost);

  static String _fmt(double v) {
    if (v >= 1e6) return '₹${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '₹${(v / 1e3).toStringAsFixed(0)}k';
    return '₹${v.toStringAsFixed(0)}';
  }

  // ── Comparison helpers (vs previous period) ────────────────────────────────

  /// Positive = over budget (bad, pink). Negative = saving (good, green).
  static double mockChange(String metric, String period) {
    // Mock percentage changes per metric/period combo.
    const table = {
      'total/monthly':     12.0,
      'total/quarterly':    4.0,
      'total/yearly':       8.0,
      'material/monthly':   0.0,
      'material/quarterly': -3.0,
      'material/yearly':    2.0,
      'labour/monthly':     4.0,
      'labour/quarterly':  -1.0,
      'labour/yearly':      6.0,
      'equipment/monthly': -2.0,
      'equipment/quarterly': -5.0,
      'equipment/yearly':  -1.0,
    };
    return table['$metric/$period'] ?? 0.0;
  }
}
