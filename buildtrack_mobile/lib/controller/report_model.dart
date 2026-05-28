import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';

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
  String get formattedTotal => formatCurrency(totalCost);
  String get formattedMaterial => formatCurrency(materialCost);
  String get formattedLabour => formatCurrency(labourCost);
  String get formattedEquipment => formatCurrency(equipmentCost);
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
