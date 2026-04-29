// lib/screen/report_widgets.dart
// Extracted, stateless sub-widgets consumed by ReportsScreen.
// No state, no business logic.

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/controller/report_model.dart';
import 'package:buildtrack_mobile/controller/report_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. MetricCard
// ─────────────────────────────────────────────────────────────────────────────

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.change, // positive = over-budget (bad), negative = saving
  });

  final IconData icon;
  final String   label;
  final String   value;
  final double   change;

  @override
  Widget build(BuildContext context) {
    final isNeutral = change == 0.0;
    final isGood    = change < 0.0;

    final subColor = isNeutral
        ? AppColors.textLight
        : isGood
            ? AppColors.success
            : Colors.pinkAccent;

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: AppTheme.label.copyWith(color: AppColors.textLight, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.heading2.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(subIcon, size: 13, color: subColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  subText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: subColor,
                    fontWeight: FontWeight.w700,
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

// ─────────────────────────────────────────────────────────────────────────────
// 2. MetricGrid — 2×2 responsive grid of MetricCards
// ─────────────────────────────────────────────────────────────────────────────

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.report, required this.period});

  final ReportModel report;
  final String      period;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _M(Icons.credit_card_outlined,  'TOTAL COST', report.formattedTotal,
          ReportModel.mockChange('total',     period)),
      _M(Icons.architecture,           'MATERIAL',   report.formattedMaterial,
          ReportModel.mockChange('material',  period)),
      _M(Icons.people_outline,         'LABOUR',     report.formattedLabour,
          ReportModel.mockChange('labour',    period)),
      _M(Icons.construction_outlined,  'EQUIPMENT',  report.formattedEquipment,
          ReportModel.mockChange('equipment', period)),
    ];

    return Column(
      children: [
        Row(children: [
          Expanded(child: MetricCard(icon: metrics[0].icon, label: metrics[0].label, value: metrics[0].value, change: metrics[0].change)),
          const SizedBox(width: 12),
          Expanded(child: MetricCard(icon: metrics[1].icon, label: metrics[1].label, value: metrics[1].value, change: metrics[1].change)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: MetricCard(icon: metrics[2].icon, label: metrics[2].label, value: metrics[2].value, change: metrics[2].change)),
          const SizedBox(width: 12),
          Expanded(child: MetricCard(icon: metrics[3].icon, label: metrics[3].label, value: metrics[3].value, change: metrics[3].change)),
        ]),
      ],
    );
  }
}

class _M {
  const _M(this.icon, this.label, this.value, this.change);
  final IconData icon;
  final String   label;
  final String   value;
  final double   change;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. ChartSection — fl_chart LineChart with animated transitions
// ─────────────────────────────────────────────────────────────────────────────

class ChartSection extends StatelessWidget {
  const ChartSection({
    super.key,
    required this.provider,
  });

  final ReportProvider provider;

  @override
  Widget build(BuildContext context) {
    final data      = provider.activeChartData;
    final unitIndex = provider.unitIndex;

    // Derive target line as 93% of the actual – mirrors the "target" concept.
    final target = data.map((v) => v * 0.93).toList();

    final actualSpots = [
      for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ];
    final targetSpots = [
      for (int i = 0; i < target.length; i++) FlSpot(i.toDouble(), target[i]),
    ];

    final unit      = unitIndex == 0 ? 'sqft' : 'cuyd';
    final actualVal = data.isNotEmpty ? data.last : 0.0;
    final targetVal = target.isNotEmpty ? target.last : 0.0;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header + unit toggle ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost per Unit',
                        style: AppTheme.heading3.copyWith(color: AppColors.textDark)),
                    const SizedBox(height: 3),
                    Text(
                      'Concrete pouring efficiency vs target',
                      style: AppTheme.caption.copyWith(color: AppColors.textLight, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _UnitToggle(unitIndex: unitIndex, onChanged: provider.selectUnit),
            ],
          ),
          const SizedBox(height: 18),

          // ── Animated line chart ───────────────────────────────────────
          SizedBox(
            height: 130,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: data.isEmpty
                  ? const Center(child: Text('No chart data'))
                  : LineChart(
                      key: ValueKey('$unit-${provider.tabIndex}'),
                      LineChartData(
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => AppColors.textDark.withValues(alpha: 0.85),
                            getTooltipItems: (spots) => spots.map((s) {
                              final isActual = s.barIndex == 0;
                              return LineTooltipItem(
                                '₹${s.y.toStringAsFixed(2)}/$unit',
                                TextStyle(
                                  color: isActual ? Colors.white : Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _interval(data),
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: const Color(0xFFEEF0F8),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                              interval: _interval(data),
                              getTitlesWidget: (v, _) => Text(
                                _shortNum(v),
                                style: AppTheme.caption.copyWith(
                                  fontSize: 9,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        lineBarsData: [
                          // Actual line
                          LineChartBarData(
                            spots: actualSpots,
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.18),
                                  AppColors.primary.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          // Target line
                          LineChartBarData(
                            spots: targetSpots,
                            isCurved: true,
                            color: const Color(0xFFBBC0D0),
                            barWidth: 2.0,
                            dashArray: [5, 4],
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Week labels ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['WK 12', 'WK 13', 'WK 14', 'WK 15', 'WK 16', 'WK 17']
                .map((w) => Text(w,
                    style: AppTheme.caption.copyWith(color: AppColors.textLight)))
                .toList(),
          ),
          const SizedBox(height: 12),

          // ── Legend ────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.circle, color: AppColors.primary, size: 10),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Actual: ₹${actualVal.toStringAsFixed(2)}/$unit',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption.copyWith(
                      color: AppColors.textDark, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.circle, color: Color(0xFFBBC0D0), size: 10),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Target: ₹${targetVal.toStringAsFixed(2)}/$unit',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption.copyWith(
                      color: AppColors.textLight, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _interval(List<double> d) {
    if (d.isEmpty) return 5;
    final range = d.reduce((a, b) => a > b ? a : b) - d.reduce((a, b) => a < b ? a : b);
    return (range / 3).clamp(1.0, 200.0);
  }

  String _shortNum(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

// ── Unit toggle chip (SQFT / CUYD) ────────────────────────────────────────────

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.unitIndex, required this.onChanged});

  final int unitIndex;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDE0F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: ['SQFT', 'CUYD'].asMap().entries.map((e) {
          final sel = e.key == unitIndex;
          return InkWell(
            onTap: () => onChanged(e.key),
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: sel ? Colors.white : AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. ProjectSelector — tappable filter card → bottom sheet picker
// ─────────────────────────────────────────────────────────────────────────────

class ProjectSelector extends StatelessWidget {
  const ProjectSelector({super.key, required this.provider});

  final ReportProvider provider;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => _showSheet(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              provider.selectedProject,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.textLight, size: 22),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProjectPickerSheet(provider: provider),
    );
  }
}

class _ProjectPickerSheet extends StatelessWidget {
  const _ProjectPickerSheet({required this.provider});

  final ReportProvider provider;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE0F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text('Select Project', style: AppTheme.heading3),
            const SizedBox(height: 12),
            ...kProjects.map((p) {
              final selected = p == provider.selectedProject;
              return InkWell(
                onTap: () {
                  provider.selectProject(p);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: selected ? AppColors.primary : AppColors.textLight,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          p,
                          style: AppTheme.bodyLarge.copyWith(
                            color: selected ? AppColors.primary : AppColors.textDark,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────────────────────
// 5. CategoryBudgetSection
// ─────────────────────────────────────────────────────────────────────────────

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
          Text('Budget Usage by Category',
              style: AppTheme.heading3.copyWith(color: AppColors.textDark)),
          const SizedBox(height: 16),
          ...categoryBudget.entries.map((e) => _BudgetBar(
                label: e.key,
                value: e.value,
              )),
        ],
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.label, required this.value});

  final String label;
  final double value; // 0.0–1.0

  @override
  Widget build(BuildContext context) {
    final Color color = value >= 0.90
        ? Colors.redAccent
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
              Text(label,
                  style: AppTheme.label.copyWith(
                      color: AppColors.textDark, fontSize: 12, letterSpacing: 0.4)),
              Text(pct,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: color)),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: const Color(0xFFEEF0F8),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. EfficiencyBanner
// ─────────────────────────────────────────────────────────────────────────────

class EfficiencyBanner extends StatelessWidget {
  const EfficiencyBanner({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Efficiency Report',
                  style: AppTheme.heading3.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          Text(note,
              style: AppTheme.body.copyWith(color: Colors.white70, height: 1.4)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            borderRadius: BorderRadius.circular(4),
            splashColor: Colors.white24,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'View Details  →',
                style: AppTheme.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
