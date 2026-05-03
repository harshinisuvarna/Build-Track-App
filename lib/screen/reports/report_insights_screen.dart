import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportInsightsScreen extends StatefulWidget {
  const ReportInsightsScreen({super.key});
  @override
  State<ReportInsightsScreen> createState() => _ReportInsightsScreenState();
}
class _ReportInsightsScreenState extends State<ReportInsightsScreen> {
  int _unitIndex = 0; // 0 = SQFT, 1 = CUYD
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final passedProjectName = args?['projectName'];
    final isAll = passedProjectName == 'All Active Projects';
    ProjectModel? project;
    if (isAll) {
      final totalBudget = provider.projects.fold(0.0, (s, p) => s + p.totalBudget);
      final spentAmount = provider.projects.fold(0.0, (s, p) => s + p.spentAmount);
      final avgProgress = provider.projects.isEmpty 
          ? 0.0 
          : provider.projects.fold(0.0, (s, p) => s + p.progress) / provider.projects.length;
      project = ProjectModel(
        id: 'all',
        name: 'All Active Projects',
        city: 'Multiple',
        sector: 'Locations',
        stage: ProjectStage.preConstruction,
        progress: avgProgress,
        totalBudget: totalBudget,
        spentAmount: spentAmount,
        startDate: DateTime.now(),
      );
    } else {
      project = passedProjectName != null 
          ? provider.projects.firstWhere((p) => p.name == passedProjectName, orElse: () => provider.selectedProject!)
          : provider.selectedProject;
    }
    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.gradientStart,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.gradientStart,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: 'Report Insights',
                isSubScreen: true,
                leftIcon: Icons.arrow_back,
                onLeftTap: () => Navigator.maybePop(context),
              ),
              const Expanded(
                child: AppEmptyState(
                  icon: Icons.bar_chart_outlined,
                  message: 'No project selected.',
                ),
              ),
            ],
          ),
        ),
      );
    }
    final entries = isAll ? provider.entries : provider.entriesForProject(project.id);
    final matCost = entries.where((e) => e.type == EntryType.material).fold(0.0, (s, e) => s + e.amount);
    final labCost = entries.where((e) => e.type == EntryType.labour).fold(0.0, (s, e) => s + e.amount);
    final eqCost  = entries.where((e) => e.type == EntryType.equipment).fold(0.0, (s, e) => s + e.amount);
    final categoryCosts = {
      'Material':     matCost,
      'Labour':       labCost,
      'Equipment':    eqCost,
    };
    
    final categoryBudgets = {
      'Material':     project.totalBudget * 0.40,
      'Labour':       project.totalBudget * 0.35,
      'Equipment':    project.totalBudget * 0.25,
    };
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Report Insights',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProjectSummaryCard(project: project),
                    const SizedBox(height: 14),
                    const AppSectionHeader(title: 'Cost Trend'),
                    _CostTrendChartCard(
                      project: project,
                      entries: entries,
                      unitIndex: _unitIndex,
                      onUnitChanged: (i) => setState(() => _unitIndex = i),
                    ),
                    const SizedBox(height: 14),
                    const AppSectionHeader(title: 'Category Breakdown'),
                    _CategoryBreakdownCard(
                      project: project,
                      categoryCosts: categoryCosts,
                      categoryBudgets: categoryBudgets,
                    ),
                    const SizedBox(height: 20),
                  
                    AppButton(
                      label: 'Update Progress',
                      icon: Icons.trending_up,
                      onPressed: () => Navigator.pushNamed(context, '/update-progress'),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'View Full Logs',
                      icon: Icons.receipt_long_outlined,
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.pushNamed(context, '/logs'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
String _fmt(double v) {
  if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)}M';
  if (v >= 1_000)     return '${(v / 1_000).toStringAsFixed(0)}k';
  return v.toStringAsFixed(0);
}
class _ProjectSummaryCard extends StatelessWidget {
  final ProjectModel project;
  const _ProjectSummaryCard({required this.project});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.name, style: AppTheme.heading2.copyWith(fontSize: 18, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(project.location, style: AppTheme.caption.copyWith(fontSize: 13, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (project.id != 'all')
                Text('Stage: ${project.stage.name.toUpperCase()}', style: AppTheme.label.copyWith(color: AppColors.primary))
              else
                Text('Aggregate Portfolio View', style: AppTheme.label.copyWith(color: AppColors.primary)),
              Text('${(project.progress * 100).toStringAsFixed(1)}% Complete', style: AppTheme.label.copyWith(color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: project.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8ECF8),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
class _CostTrendChartCard extends StatelessWidget {
  final ProjectModel project;
  final List<EntryModel> entries;
  final int unitIndex;
  final ValueChanged<int> onUnitChanged;
  const _CostTrendChartCard({
    required this.project,
    required this.entries,
    required this.unitIndex,
    required this.onUnitChanged,
  });
  @override
  Widget build(BuildContext context) {
    final isSqft     = unitIndex == 0;
    final unitLabel  = isSqft ? 'SQFT' : 'CUYD';
    final multiplier = isSqft ? 1.0 : 1.5;
    final baseCost   = (project.spentAmount > 0 ? project.spentAmount / 1000 : 50.0) * multiplier;
    final data = [
      baseCost * 0.60, baseCost * 0.70, baseCost * 0.75,
      baseCost * 0.85, baseCost * 0.92, baseCost,
    ];
    final target = data.map((v) => v * 0.93).toList();
    final spots       = [for (int i = 0; i < data.length;   i++) FlSpot(i.toDouble(), data[i])];
    final targetSpots = [for (int i = 0; i < target.length; i++) FlSpot(i.toDouble(), target[i])];
    final minY = data.reduce((a, b) => a < b ? a : b) * 0.92;
    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.05;
    final currentVal = data.last;
    final targetVal  = target.last;
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cost per $unitLabel',
                      style: AppTheme.heading3.copyWith(color: AppColors.textDark)),
                  const SizedBox(height: 3),
                  Text('Spending trend vs target',
                      style: AppTheme.caption
                          .copyWith(color: AppColors.textLight, height: 1.4)),
                ],
              ),
              _InsightUnitToggle(unitIndex: unitIndex, onChanged: onUnitChanged),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: LineChart(
              key: ValueKey('ins-$unitIndex-${project.id}'),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              LineChartData(
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (barData, spotIndexes) =>
                      spotIndexes.map((i) => TouchedSpotIndicatorData(
                            const FlLine(strokeWidth: 0), // no stick
                            FlDotData(
                              getDotPainter: (spot, pct, bar, idx) =>
                                  FlDotCirclePainter(
                                radius: 6,
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                                strokeColor: Colors.white,
                              ),
                            ),
                          )).toList(),
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1A1D3A),
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    getTooltipItems: (spots) => spots.map((s) {
                      if (s.barIndex != 0) return null;
                      final v = s.y >= 1000
                          ? '₹${(s.y).toStringAsFixed(0)}k/$unitLabel'
                          : '₹${s.y.toStringAsFixed(0)}/$unitLabel';
                      return LineTooltipItem(
                        v,
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 3,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFEEF0F8), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (maxY - minY) / 3,
                      getTitlesWidget: (v, _) {
                        final s = v >= 1000
                            ? '${(v / 1000).toStringAsFixed(1)}k'
                            : v.toStringAsFixed(0);
                        return Text(s,
                            style: AppTheme.caption.copyWith(
                                fontSize: 9, color: AppColors.textLight));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  // Actual — gradient line + fill
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    gradient: LinearGradient(colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.70),
                    ]),
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.22),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Target — dashed grey
                  LineChartBarData(
                    spots: targetSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFFBBC0D0),
                    barWidth: 1.8,
                    dashArray: [6, 4],
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['WK 12', 'WK 13', 'WK 14', 'WK 15', 'WK 16', 'WK 17']
                .map((w) => Text(w,
                    style: AppTheme.caption
                        .copyWith(color: AppColors.textLight)))
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _dot(AppColors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Actual: ₹${_shortNum(currentVal)}/$unitLabel',
                overflow: TextOverflow.ellipsis,
                style: AppTheme.caption.copyWith(
                    color: AppColors.textDark, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 14),
            _dot(const Color(0xFFBBC0D0)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Target: ₹${_shortNum(targetVal)}/$unitLabel',
                overflow: TextOverflow.ellipsis,
                style: AppTheme.caption.copyWith(color: AppColors.textLight),
              ),
            ),
          ]),
        ],
      ),
    );
  }
  Widget _dot(Color c) => Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  String _shortNum(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(1);
  }
}
class _InsightUnitToggle extends StatelessWidget {
  const _InsightUnitToggle({required this.unitIndex, required this.onChanged});
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
              child: Text(e.value,
                  style: TextStyle(
                      color: sel ? Colors.white : AppColors.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
class _CategoryBreakdownCard extends StatelessWidget {
  final ProjectModel project;
  final Map<String, double> categoryCosts;
  final Map<String, double> categoryBudgets;
  const _CategoryBreakdownCard({
    required this.project,
    required this.categoryCosts,
    required this.categoryBudgets,
  });
  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: categoryCosts.entries.map((e) {
          final cat    = e.key;
          final cost   = e.value;
          final budget = categoryBudgets[cat] ?? 1.0;
          final pct    = budget > 0 ? (cost / budget).clamp(0.0, 1.0) : 0.0;
          final color = pct >= 0.9
              ? Colors.redAccent
              : pct >= 0.6
                  ? AppColors.warning
                  : AppColors.primary;
          return InkWell(
            onTap: () => Navigator.pushNamed(context, '/logs',
                arguments: {'projectId': project.id, 'category': cat}),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(cat,
                            style: AppTheme.bodyLarge.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600)),
                      ),
                      // ₹ spent
                      Text(
                        '₹${_fmt(cost)}',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                      ),
                      Text(
                        ' / ₹${_fmt(budget)}',
                        style: AppTheme.caption.copyWith(
                            color: AppColors.textLight, fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right,
                          size: 14, color: AppColors.textLight),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: const Color(0xFFEEF0F8),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 38,
                        child: Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
