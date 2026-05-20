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

  /// Returns a mock percentage change for demonstration purposes.
  /// A negative value represents savings (e.g. -5.0 = 5% savings),
  /// while a positive value represents an overrun (e.g. 2.5 = 2.5% over).
  static double mockChange(String category, String period) {
    // Generate some deterministic mock values based on category
    switch (category.toLowerCase()) {
      case 'total':
        return period == 'month' ? -2.5 : 1.2;
      case 'material':
        return period == 'month' ? -5.0 : -1.5;
      case 'labour':
        return period == 'month' ? 3.0 : 4.5;
      case 'equipment':
        return period == 'month' ? 0.0 : -2.0;
      default:
        return 0.0;
    }
  }
}