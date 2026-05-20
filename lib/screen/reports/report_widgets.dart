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
    final isNeutral = change == 0.0;
    final isGood = change < 0.0;
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
        ? '${change.abs().toStringAsFixed(0)}% Saving'
        : '+${change.toStringAsFixed(0)}% Over';
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
      // ✅ Use Column with mainAxisSize.min — never overflows
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

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.report, required this.period});

  final ReportModel report;
  final String period;
  @override
  Widget build(BuildContext context) {
    final metrics = [
      _M(
        Icons.credit_card_outlined,
        'TOTAL COST',
        report.formattedTotal,
        ReportModel.mockChange('total', period),
      ),
      _M(
        Icons.architecture,
        'MATERIAL',
        report.formattedMaterial,
        ReportModel.mockChange('material', period),
      ),
      _M(
        Icons.people_outline,
        'LABOUR',
        report.formattedLabour,
        ReportModel.mockChange('labour', period),
      ),
      _M(
        Icons.precision_manufacturing_outlined,
        'EQUIPMENT',
        report.formattedEquipment,
        ReportModel.mockChange('equipment', period),
      ),
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: metrics[0].icon,
                label: metrics[0].label,
                value: metrics[0].value,
                change: metrics[0].change,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: metrics[1].icon,
                label: metrics[1].label,
                value: metrics[1].value,
                change: metrics[1].change,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: metrics[2].icon,
                label: metrics[2].label,
                value: metrics[2].value,
                change: metrics[2].change,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: metrics[3].icon,
                label: metrics[3].label,
                value: metrics[3].value,
                change: metrics[3].change,
              ),
            ),
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

class ChartSection extends StatelessWidget {
  const ChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 📊 MOCK DATA (TASK REQUIREMENT)
    final List<double> data = [12, 1350, 100, 1650, 1580, 1720];

    const double targetCost = 1500;

    final List<String> phases = [
      'Foundation',
      'Plinth',
      'Slab',
      'Walls',
      'Roof',
      'Finishing',
    ];

    final actualVal = data.isNotEmpty ? data.last : 0.0;
    final targetVal = targetCost;

    final actualSpots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i]),
    );

    final targetSpots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), targetCost),
    );

    final minY = data.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.1;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📌 HEADER
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cost per SQFT',
                style: AppTheme.heading3.copyWith(color: AppColors.textDark),
              ),
              const SizedBox(height: 3),
              Text(
                'Construction cost vs efficiency benchmark',
                style: AppTheme.caption.copyWith(
                  color: AppColors.textLight,
                  height: 1.4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 📊 CHART
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 3,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: const Color(0xFFEEF0F8), strokeWidth: 1),
                ),

                borderData: FlBorderData(show: false),

                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int i = value.toInt();
                        if (i < 0 || i >= phases.length) {
                          return const SizedBox();
                        }
                        return Text(
                          phases[i],
                          style: AppTheme.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxY - minY) / 3,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        '₹${v.toInt()}',
                        style: AppTheme.caption.copyWith(
                          fontSize: 9,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
                ),

                lineBarsData: [
                  // 📈 ACTUAL COST LINE
                  LineChartBarData(
                    spots: actualSpots,
                    isCurved: true,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.6),
                      ],
                    ),
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // 📉 TARGET LINE (DASHED)
                  LineChartBarData(
                    spots: targetSpots,
                    isCurved: false,
                    barWidth: 2,
                    color: const Color(0xFFBBC0D0),
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 📌 LEGEND
          Row(
            children: [
              _legendDot(AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Actual: ₹${actualVal.toInt()}/SQFT',
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFBBC0D0)),
              const SizedBox(width: 6),
              Text(
                'Target: ₹${targetVal.toInt()}/SQFT',
                style: AppTheme.caption.copyWith(color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.unitIndex, required this.onChanged, required this.report});
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
          final actual = item['actual'] as double;
          final target = item['target'] as double;
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

class CategoryBudgetSection extends StatelessWidget {
  const CategoryBudgetSection({super.key, required this.categoryBudget});
  final Map<String, double> categoryBudget;
  @override
  Widget build(BuildContext context) {
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
          ...categoryBudget.entries.map(
            (e) => _BudgetBar(label: e.key, value: e.value),
          ),
        ],
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.label, required this.value});
  final String label;
  final double value; // 0.0â€“1.0
  @override
  Widget build(BuildContext context) {
    final Color color = value >= 0.90
        ? AppColors.error
        : value >= 0.70
        ? AppColors.warning
        : AppColors.primary;

    final String pct = '${(value * 100).round()}%';
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
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: (value < 0.70)
                            ? AppGradients.progressBar
                            : null,
                        color: (value >= 0.70) ? color : null,
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
              final selectedProjectName = context.read<ReportProvider>().selectedProjectName;
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
          const SizedBox(height: 6),
          Text(note, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
