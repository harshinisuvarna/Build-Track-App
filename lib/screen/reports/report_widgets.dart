import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../common/themes/app_theme.dart';
import '../../common/themes/app_colors.dart';
import '../../common/themes/app_gradients.dart';
import '../../common/widgets/app_widgets.dart';
import '../../controller/report_model.dart';
import '../../controller/project_provider.dart';
import '../../models/project_model.dart';
import '../../controller/report_provider.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
  });

  final IconData icon;
  final String label;
  final String value;
  final double change;

  @override
  Widget build(BuildContext context) {
    // 🛡️ SAFETY NET: Prevent NaN and Infinity from crashing the UI
    final safeChange = (change.isNaN || change.isInfinite) ? 0.0 : change;

    final isNeutral = safeChange == 0.0;
    final isGood = safeChange < 0.0;

    final subColor = isNeutral
        ? AppColors.textLight
        : isGood
        ? AppColors.success
        : AppColors.error;

    final subIcon = isNeutral
        ? Icons.remove
        : isGood
        ? Icons.trending_down
        : Icons.trending_up;

    final subText = isNeutral
        ? 'On Track'
        : isGood
        ? '${safeChange.abs().toStringAsFixed(0)}% Saving'
        : '+${safeChange.toStringAsFixed(0)}% Over';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.label.copyWith(
              color: AppColors.textLight,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(subIcon, size: 12, color: subColor),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  subText,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    color: subColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Replace MetricGrid ──────────────────────────────────────────────────────

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.report, required this.period});

  final ReportModel report;
  final String period;

  @override
  Widget build(BuildContext context) {
    // ✅ Show actual spent vs target — no mock percentages
    final totalTarget = report.targetMaterial +
        report.targetLabour +
        report.targetEquipment +
        report.targetMisc;

    double _pct(double actual, double target) {
      if (target <= 0) return 0;
      return ((actual / target) - 1) * 100; // negative = saving, positive = over
    }

    final cards = [
      _M(Icons.credit_card_outlined, 'TOTAL COST',
          report.formattedTotal, _pct(report.totalCost, totalTarget)),
      _M(Icons.architecture, 'MATERIAL',
          report.formattedMaterial, _pct(report.materialCost, report.targetMaterial)),
      _M(Icons.people_outline, 'LABOUR',
          report.formattedLabour, _pct(report.labourCost, report.targetLabour)),
      _M(Icons.precision_manufacturing_outlined, 'EQUIPMENT',
          report.formattedEquipment, _pct(report.equipmentCost, report.targetEquipment)),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: MetricCard(
              icon: cards[0].icon, label: cards[0].label,
              value: cards[0].value, change: cards[0].change)),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(
              icon: cards[1].icon, label: cards[1].label,
              value: cards[1].value, change: cards[1].change)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: MetricCard(
              icon: cards[2].icon, label: cards[2].label,
              value: cards[2].value, change: cards[2].change)),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(
              icon: cards[3].icon, label: cards[3].label,
              value: cards[3].value, change: cards[3].change)),
          ],
        ),
      ],
    );
  }
}

class _M {
  const _M(this.icon, this.label, this.value, this.change);
  final IconData icon;
  final String label;
  final String value;
  final double change;
}

// ── Replace ChartSection ────────────────────────────────────────────────────

class ChartSection extends StatelessWidget {
  const ChartSection({super.key, required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'name': 'Material',
        'actual': report.materialCost.isNaN ? 0.0 : report.materialCost,
        'target': report.targetMaterial.isNaN ? 0.0 : report.targetMaterial,
      },
      {
        'name': 'Labour',
        'actual': report.labourCost.isNaN ? 0.0 : report.labourCost,
        'target': report.targetLabour.isNaN ? 0.0 : report.targetLabour,
      },
      {
        'name': 'Equipment',
        'actual': report.equipmentCost.isNaN ? 0.0 : report.equipmentCost,
        'target': report.targetEquipment.isNaN ? 0.0 : report.targetEquipment,
      },
      {
        'name': 'Misc',
        'actual': (report.categoryBudget['Misc'] ?? 0.0).isNaN
            ? 0.0
            : (report.categoryBudget['Misc'] ?? 0.0),
        'target': report.targetMisc.isNaN ? 0.0 : report.targetMisc,
      },
    ];

    final actualSpots = List.generate(
      categories.length,
      (i) => FlSpot(i.toDouble(), categories[i]['actual'] as double),
    );
    final targetSpots = List.generate(
      categories.length,
      (i) => FlSpot(i.toDouble(), categories[i]['target'] as double),
    );

    final allValues = [
      ...categories.map((e) => e['actual'] as double),
      ...categories.map((e) => e['target'] as double),
    ];
    final maxRaw = allValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxRaw <= 0 ? 1000.0 : maxRaw * 1.25;

    final isExceeded = categories.any(
      (e) =>
          (e['actual'] as double) > (e['target'] as double) &&
          (e['target'] as double) > 0,
    );

    return AppCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Budget Analytics',
                style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              isExceeded
                  ? '⚠ Budget exceeded in one or more categories'
                  : '✓ All categories within budget',
              style: TextStyle(
                fontSize: 12,
                color: isExceeded ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: LineChart(LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= categories.length)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(categories[i]['name'].toString(),
                              style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 44),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  // ✅ Blue solid = actual paid amount spent
                  LineChartBarData(
                    spots: actualSpots,
                    isCurved: true,
                    barWidth: 3,
                    color: AppColors.primary,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                  // ✅ Red dashed = target budget
                  LineChartBarData(
                    spots: targetSpots,
                    isCurved: false,
                    barWidth: 2,
                    color: Colors.red,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              )),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _dot(AppColors.primary),
                const SizedBox(width: 6),
                const Text('Actual Paid', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                _dot(Colors.red),
                const SizedBox(width: 6),
                const Text('Target Budget', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({
    required this.unitIndex,
    required this.onChanged,
    required this.report,
  });
  final int unitIndex;
  final void Function(int) onChanged;
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'label': 'Material',
        'actual': report.materialCost,
        'target': report.targetMaterial,
      },
      {
        'label': 'Labour',
        'actual': report.labourCost,
        'target': report.targetLabour,
      },
      {
        'label': 'Equipment',
        'actual': report.equipmentCost,
        'target': report.targetEquipment,
      },
      {
        'label': 'Misc',
        'actual': report.categoryBudget['Misc'] ?? 0.0,
        'target': report.targetMisc,
      },
    ];

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          final actualRaw = item['actual'] as double;
          final targetRaw = item['target'] as double;

          // 🛡️ SAFETY NET: Prevent NaN crashes
          final actual = (actualRaw.isNaN || actualRaw.isInfinite)
              ? 0.0
              : actualRaw;
          final target = (targetRaw.isNaN || targetRaw.isInfinite)
              ? 0.0
              : targetRaw;

          final hasTarget = target > 0;
          final percent = hasTarget ? (actual / target).clamp(0.0, 1.0) : 0.0;
          final isOver = hasTarget && actual > target;

          final color = isOver
              ? AppColors.error
              : percent >= 0.75
              ? AppColors.warning
              : AppColors.primary;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['label'].toString(),
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${actual.toStringAsFixed(0)} spent',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (hasTarget)
                          Text(
                            'of ₹${target.toStringAsFixed(0)} budget',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: hasTarget ? percent : 0,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEFEFEF),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                if (isOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Exceeded by ₹${(actual - target).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ProjectSelector extends StatelessWidget {
  const ProjectSelector({super.key, required this.provider});

  final ReportProvider provider;

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final projects = projectProvider.projects;

    return AppCard(
      margin: EdgeInsets.zero,
      onTap: () => _showSheet(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              provider.selectedProjectName,
              style: AppTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textLight,
            size: 22,
          ),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final projectProvider = context.read<ProjectProvider>();
    final realProjects = projectProvider.projects;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _ProjectPickerSheet(provider: provider, projects: realProjects),
    );
  }
}

class _ProjectPickerSheet extends StatelessWidget {
  const _ProjectPickerSheet({required this.provider, required this.projects});

  final ReportProvider provider;
  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('All Active Projects'),
              leading: const Icon(Icons.grid_view),
              onTap: () {
                provider.selectProject('all');
                Navigator.pop(context);
              },
            ),
            Text('Select Project', style: AppTheme.heading3),
            const SizedBox(height: 12),
            ...projects.map((p) {
              final selected = p.id == provider.selectedProjectId;
              return InkWell(
                onTap: () {
                  provider.selectProject(p.id);
                  context.read<ProjectProvider>().selectProject(p);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textLight,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          p.name,
                          style: AppTheme.bodyLarge.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textDark,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Replace CategoryBudgetSection ───────────────────────────────────────────
// Shows actual ₹ spent vs ₹ budget — no percentages, blue progress bar

class CategoryBudgetSection extends StatelessWidget {
  const CategoryBudgetSection({super.key, required this.categoryBudget});

  final Map<String, double> categoryBudget;

  @override
  Widget build(BuildContext context) {
    // categoryBudget keys are actual spent amounts
    // We need targets from the report — get them from ReportProvider
    final report = context.read<ReportProvider>().buildLiveReport();

    final items = [
      {
        'label': 'Material',
        'actual': report.materialCost,
        'target': report.targetMaterial,
      },
      {
        'label': 'Labour',
        'actual': report.labourCost,
        'target': report.targetLabour,
      },
      {
        'label': 'Equipment',
        'actual': report.equipmentCost,
        'target': report.targetEquipment,
      },
      if (report.targetMisc > 0 || (report.categoryBudget['Misc'] ?? 0) > 0)
        {
          'label': 'Misc',
          'actual': report.categoryBudget['Misc'] ?? 0.0,
          'target': report.targetMisc,
        },
    ];

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Usage by Category',
            style: AppTheme.heading3.copyWith(color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final actual = (item['actual'] as double).isNaN
                ? 0.0
                : (item['actual'] as double);
            final target = (item['target'] as double).isNaN
                ? 0.0
                : (item['target'] as double);
            final hasTarget = target > 0;
            final percent =
                hasTarget ? (actual / target).clamp(0.0, 1.0) : 0.0;
            final isOver = hasTarget && actual > target;

            final color = isOver
                ? AppColors.error
                : percent >= 0.75
                    ? AppColors.warning
                    : AppColors.primary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['label'].toString(),
                        style: AppTheme.label.copyWith(
                          color: AppColors.textDark,
                          fontSize: 12,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // ✅ Show actual ₹ amount, not percentage
                          Text(
                            '₹${actual.toStringAsFixed(0)} spent',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: color,
                            ),
                          ),
                          if (hasTarget)
                            Text(
                              'of ₹${target.toStringAsFixed(0)} budget',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LinearProgressIndicator(
                      // ✅ Blue progress bar showing spent/budget ratio
                      value: hasTarget ? percent : 0,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEEF0F8),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  if (isOver)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Exceeded by ₹${(actual - target).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    // 🛡️ SAFETY NET: Stop FractionallySizedBox & .round() from crashing on NaN
    final safeValue = (value.isNaN || value.isInfinite) ? 0.0 : value;

    final Color color = safeValue >= 0.90
        ? AppColors.error
        : safeValue >= 0.70
        ? AppColors.warning
        : AppColors.primary;

    final String pct = '${(safeValue * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.label.copyWith(
                  color: AppColors.textDark,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                pct,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0F8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: safeValue.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: (safeValue < 0.70)
                            ? AppGradients.progressBar
                            : null,
                        color: (safeValue >= 0.70) ? color : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EfficiencyBanner extends StatelessWidget {
  const EfficiencyBanner({
    super.key,
    required this.note,
    required this.isExceeded,
  });

  final String note;
  final bool isExceeded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExceeded
              ? [AppColors.error, AppColors.error.withOpacity(0.7)]
              : [AppColors.primary, AppColors.primary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Efficiency Report',
                style: AppTheme.heading3.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note,
            style: AppTheme.body.copyWith(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              final selectedProjectName = context
                  .read<ReportProvider>()
                  .selectedProjectName;
              Navigator.pushNamed(
                context,
                '/report-insights',
                arguments: {'projectName': selectedProjectName},
              );
            },
            borderRadius: BorderRadius.circular(4),
            splashColor: Colors.white24,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Details',
                    style: AppTheme.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
