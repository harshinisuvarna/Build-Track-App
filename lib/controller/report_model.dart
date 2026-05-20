import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';

class ReportModel {
  const ReportModel({
    required this.totalCost,
    required this.materialCost,
    required this.labourCost,
    required this.equipmentCost,
    required this.categoryBudget,
    required this.efficiencyNote,
    required this.targetMaterial,
    required this.targetLabour,
    required this.targetEquipment,
    required this.targetMisc,
  });

  final double totalCost;
  final double materialCost;
  final double labourCost;
  final double equipmentCost;

  // Actual spent per category (from entries)
  final Map<String, double> categoryBudget;

  // Target budgets (from project budget breakdown)
  final double targetMaterial;
  final double targetLabour;
  final double targetEquipment;
  final double targetMisc;

  final String efficiencyNote;

  String get formattedTotal => formatCurrency(totalCost);
  String get formattedMaterial => formatCurrency(materialCost);
  String get formattedLabour => formatCurrency(labourCost);
  String get formattedEquipment => formatCurrency(equipmentCost);

  bool get isBudgetExceeded {
    final totalTarget = targetMaterial + targetLabour + targetEquipment + targetMisc;
    return totalTarget > 0 && totalCost > totalTarget;
  }

  factory ReportModel.empty() => const ReportModel(
        totalCost: 0,
        materialCost: 0,
        labourCost: 0,
        equipmentCost: 0,
        categoryBudget: {},
        efficiencyNote: 'No data available',
        targetMaterial: 0,
        targetLabour: 0,
        targetEquipment: 0,
        targetMisc: 0,
      );
}