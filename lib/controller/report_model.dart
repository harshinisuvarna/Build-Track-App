import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';

class ReportModel {
  const ReportModel({
    required this.totalCost,
    required this.materialCost,
    required this.labourCost,
    required this.equipmentCost,
    required this.costPerSqftData,
    required this.chartDataCuyd,
    required this.categoryBudget,
    required this.efficiencyNote,
  });

  final double totalCost;
  final double materialCost;
  final double labourCost;
  final double equipmentCost;

  final List<double> costPerSqftData;
  final List<double> chartDataCuyd;

  final Map<String, double> categoryBudget;
  final String efficiencyNote;

  String get formattedTotal => formatCurrency(totalCost);
  String get formattedMaterial => formatCurrency(materialCost);
  String get formattedLabour => formatCurrency(labourCost);
  String get formattedEquipment => formatCurrency(equipmentCost);

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final analytics = json['analytics'] ?? {};

    List<double> safeList(dynamic value) {
      if (value is List) {
        return value.map((e) => (e as num).toDouble()).toList();
      }
      return [0.0];
    }

    return ReportModel(
      totalCost: (json['expenses'] ?? 0).toDouble(),

      materialCost:
          (json['categoryBreakdown']?['Materials'] ?? 0).toDouble(),

      labourCost:
          (json['categoryBreakdown']?['Labour'] ?? 0).toDouble(),

      equipmentCost:
          (json['categoryBreakdown']?['Equipment'] ?? 0).toDouble(),

      costPerSqftData: safeList(analytics['costPerSqftData']),
      chartDataCuyd: safeList(json['chartDataCuyd']),

      categoryBudget: Map<String, double>.from(
        (json['categoryBreakdown'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),

      efficiencyNote: (analytics['chartStatus'] == 'OVER_BUDGET')
          ? 'Project exceeded budget'
          : 'Project within budget',
    );
  }
}