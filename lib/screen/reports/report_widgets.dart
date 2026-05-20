import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/controller/report_model.dart';
import 'package:buildtrack_mobile/controller/report_provider.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';

// ─────────────────────────────────────────────
// METRIC CARD
// ─────────────────────────────────────────────

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.actual,
    required this.target,
  });

  final IconData icon;
  final String label;
  final String value;
  final double actual;
  final double target;

  @override
  Widget build(BuildContext context) {
    final isOver = target > 0 && actual > target;
    final isOnTrack = target <= 0;

    final color = isOnTrack
        ? AppColors.textLight
        : isOver
            ? AppColors.error
            : AppColors.success;

    final iconData = isOnTrack
        ? Icons.remove
        : isOver
            ? Icons.trending_up
            : Icons.trending_down;

    final statusText = isOnTrack
        ? 'No budget set'
        : isOver
            ? 'Over budget'
            : 'Within budget';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
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
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(iconData, size: 12, color: color),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  statusText,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
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

// ─────────────────────────────────────────────
// METRIC GRID — fixed layout, no infinite height
// ─────────────────────────────────────────────

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final cards = [
      MetricCard(
        icon: Icons.attach_money,
        label: 'Total Cost',
        value: report.formattedTotal,
        actual: report.totalCost,
        target: report.targetMaterial +
            report.targetLabour +
            report.targetEquipment +
            report.targetMisc,
      ),
      MetricCard(
        icon: Icons.category,
        label: 'Material Cost',
        value: report.formattedMaterial,
        actual: report.materialCost,
        target: report.targetMaterial,
      ),
      MetricCard(
        icon: Icons.build,
        label: 'Labour Cost',
        value: report.formattedLabour,
        actual: report.labourCost,
        target: report.targetLabour,
      ),
      MetricCard(
        icon: Icons.precision_manufacturing,
        label: 'Equipment Cost',
        value: report.formattedEquipment,
        actual: report.equipmentCost,
        target: report.targetEquipment,
      ),
    ];

    const spacing = 12.0;

    // ✅ Use Wrap instead of LayoutBuilder+Row to avoid infinite height
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: cards.map((card) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Each card takes exactly half width minus spacing
            final width = (MediaQuery.of(context).size.width - 32 - spacing) / 2;
            return SizedBox(width: width, child: card);
          },
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// CHART SECTION
// ─────────────────────────────────────────────

class ChartSection extends StatelessWidget {
  const ChartSection({super.key, required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Material', 'actual': report.materialCost, 'target': report.targetMaterial},
      {'name': 'Labour',   'actual': report.labourCost,   'target': report.targetLabour},
      {'name': 'Equipment','actual': report.equipmentCost,'target': report.targetEquipment},
      {'name': 'Misc',     'actual': report.categoryBudget['Misc'] ?? 0.0, 'target': report.targetMisc},
    ];

    final actualSpots = List.generate(
      categories.length,
      (i) => FlSpot(i.toDouble(), (categories[i]['actual'] as double)),
    );

    final targetSpots = List.generate(
      categories.length,
      (i) => FlSpot(i.toDouble(), (categories[i]['target'] as double)),
    );

    final allValues = [
      ...categories.map((e) => e['actual'] as double),
      ...categories.map((e) => e['target'] as double),
    ];

    final maxRaw = allValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxRaw <= 0 ? 1000.0 : maxRaw * 1.25;

    final isExceeded = categories.any(
      (e) => (e['actual'] as double) > (e['target'] as double) &&
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
            Text(
              'Budget Analytics',
              style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w800),
            ),
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
              child: LineChart(
                LineChartData(
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
                          if (i < 0 || i >= categories.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              categories[i]['name'].toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 44),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
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
                    LineChartBarData(
                      spots: targetSpots,
                      isCurved: false,
                      barWidth: 2,
                      color: Colors.red,
                      dashArray: [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _dot(AppColors.primary),
                const SizedBox(width: 6),
                const Text('Actual Spent', style: TextStyle(fontSize: 12)),
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

// ─────────────────────────────────────────────
// CATEGORY BUDGET SECTION
// ─────────────────────────────────────────────

class CategoryBudgetSection extends StatelessWidget {
  const CategoryBudgetSection({super.key, required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Material',  'actual': report.materialCost,  'target': report.targetMaterial},
      {'label': 'Labour',    'actual': report.labourCost,    'target': report.targetLabour},
      {'label': 'Equipment', 'actual': report.equipmentCost, 'target': report.targetEquipment},
      {'label': 'Misc',      'actual': report.categoryBudget['Misc'] ?? 0.0, 'target': report.targetMisc},
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
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
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
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
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

// ─────────────────────────────────────────────
// PROJECT SELECTOR
// ─────────────────────────────────────────────

class ProjectSelector extends StatelessWidget {
  const ProjectSelector({super.key, required this.provider});

  final ReportProvider provider;

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final projects = projectProvider.projects;

    return AppCard(
      margin: EdgeInsets.zero,
      onTap: () => _showSheet(context, projects, provider),
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
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context, List projects, ReportProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('All Active Projects'),
              leading: const Icon(Icons.grid_view),
              onTap: () {
                provider.selectProject('all');
                Navigator.pop(context);
              },
            ),
            ...projects.map((p) => ListTile(
                  title: Text(p.name),
                  leading: const Icon(Icons.folder_outlined),
                  onTap: () {
                    provider.selectProject(p.id);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EFFICIENCY BANNER
// ─────────────────────────────────────────────

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
          const Text(
            'Efficiency Report',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}