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
  final List<double> chartDataSqft;
  final List<double> chartDataCuyd;
  final Map<String, double> categoryBudget;
  final String efficiencyNote;
  String get formattedTotal => _fmt(totalCost);
  String get formattedMaterial => _fmt(materialCost);
  String get formattedLabour => _fmt(labourCost);
  String get formattedEquipment => _fmt(equipmentCost);
  static String _fmt(double v) {
    if (v >= 1e6) return '₹${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '₹${(v / 1e3).toStringAsFixed(0)}k';
    return '₹${v.toStringAsFixed(0)}';
  }
  static double mockChange(String metric, String period) {
    const table = {
      'total/monthly': 12.0,
      'total/quarterly': 4.0,
      'total/yearly': 8.0,
      'material/monthly': 0.0,
      'material/quarterly': -3.0,
      'material/yearly': 2.0,
      'labour/monthly': 4.0,
      'labour/quarterly': -1.0,
      'labour/yearly': 6.0,
      'equipment/monthly': -2.0,
      'equipment/quarterly': -5.0,
      'equipment/yearly': -1.0,
    };
    return table['$metric/$period'] ?? 0.0;
  }
}
