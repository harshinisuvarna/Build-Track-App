import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/controller/report_model.dart';
import 'package:buildtrack_mobile/controller/report_provider.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:provider/provider.dart';

/// -------------------- METRIC CARD --------------------

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
    final isGood = change < 0;
    final isNeutral = change == 0;

    final color = isNeutral
        ? AppColors.textLight
        : isGood
            ? AppColors.success
            : AppColors.error;

    final iconData = isNeutral
        ? Icons.remove
        : isGood
            ? Icons.trending_down
            : Icons.trending_up;

    final text = isNeutral
        ? 'On Track'
        : isGood
            ? '${change.abs().toStringAsFixed(0)}% Saving'
            : '+${change.toStringAsFixed(0)}% Over';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: AppTheme.label.copyWith(
                fontSize: 11,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: AppTheme.heading2.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(iconData, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
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

/// -------------------- METRIC GRID --------------------

class MetricGrid extends StatelessWidget {
  const MetricGrid({
    super.key,
    required this.report,
    required this.period,
  });

  final ReportModel report;
  final String period;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: Icons.credit_card,
                label: 'TOTAL COST',
                value: report.formattedTotal,
                change: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: Icons.architecture,
                label: 'MATERIAL',
                value: report.formattedMaterial,
                change: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: Icons.people,
                label: 'LABOUR',
                value: report.formattedLabour,
                change: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: Icons.precision_manufacturing,
                label: 'EQUIPMENT',
                value: report.formattedEquipment,
                change: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// -------------------- CHART --------------------

class ChartSection extends StatelessWidget {
  const ChartSection({super.key, required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final data = report.costPerSqftData;

    if (data.isEmpty) {
      return const AppCard(
        child: Center(child: Text("No data")),
      );
    }

    const target = 1500.0;

    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i]),
    );

    final targetSpots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), target),
    );

    final minY = data.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.15;

    final isExceeded = data.any((e) => e > target);

    return AppCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ⭐ HEADER (ONLY ONCE - FIX DUPLICATE ISSUE)
            Text(
              "Cost per Unit (SQFT)",
              style: AppTheme.heading3.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              isExceeded
                  ? "⚠ Cost exceeded target in some stages"
                  : "Cost within expected range",
              style: TextStyle(
                fontSize: 12,
                color: isExceeded ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            /// ⭐ CHART
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),

                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const labels = [
                            'Foundation',
                            'Floor',
                            'Slab',
                            'Walls',
                            'Roof',
                            'Finish'
                          ];

                          final i = value.toInt();
                          if (i < 0 || i >= labels.length) {
                            return const SizedBox();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[i],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
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
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: AppColors.primary,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.08),
                      ),
                    ),
                    LineChartBarData(
                      spots: targetSpots,
                      isCurved: false,
                      barWidth: 2,
                      color: Colors.grey,
                      dashArray: [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// ⭐ LEGEND (RESTORED)
            Row(
              children: [
                _dot(AppColors.primary),
                const SizedBox(width: 6),
                const Text("Actual"),
                const SizedBox(width: 16),
                _dot(Colors.grey),
                const SizedBox(width: 6),
                const Text("Target"),
                const Spacer(),
                Text(
                  "Target: 1500",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}

/// -------------------- PROJECT SELECTOR --------------------

class ProjectSelector extends StatelessWidget {
  const ProjectSelector({super.key, required this.provider});

  final ReportProvider provider;

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final projects = projectProvider.projects;

    return AppCard(
      margin: EdgeInsets.zero,
      onTap: () => _showSheet(context, projects),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            provider.selectedProject,
            style: AppTheme.bodyLarge,
          ),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context, List projects) {
    final provider = context.read<ReportProvider>();

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: [
          ListTile(
            title: const Text('All Active Projects'),
            onTap: () {
              provider.selectProject('All Active Projects');
              Navigator.pop(context);
            },
          ),
          ...projects.map((p) => ListTile(
                title: Text(p.name),
                onTap: () {
                  provider.selectProject(p.name);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}

/// -------------------- CATEGORY BUDGET --------------------

class CategoryBudgetSection extends StatelessWidget {
  const CategoryBudgetSection({super.key, required this.categoryBudget});

  final Map<String, double> categoryBudget;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: categoryBudget.entries.map((e) {
          final amount = e.value;

          // FIX: treat value as AMOUNT, not percentage
          const double target = 1500.0;

          final percent = (amount / target).clamp(0.0, 1.0);

          final color = percent >= 0.9
              ? AppColors.error
              : percent >= 0.7
                  ? AppColors.warning
                  : AppColors.primary;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // ✅ SHOW AMOUNT ONLY (NOT %)
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEFEFEF),
                    valueColor: AlwaysStoppedAnimation(color),
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

/// -------------------- EFFICIENCY BANNER --------------------

class EfficiencyBanner extends StatelessWidget {
  const EfficiencyBanner({
    super.key,
    required this.note,
    required this.selectedProjectName,
  });

  final String note;
  final String selectedProjectName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // ✅ FIX: full width restored
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.7),
          ],
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
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}