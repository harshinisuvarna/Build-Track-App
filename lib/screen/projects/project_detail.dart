// lib/screen/project_detail.dart
// Full project detail screen â€” reads the currently selected project
// from ProjectProvider and shows info, financials, and action buttons.

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key});

  // Stage appearance map
  static const _stageMeta = <ProjectStage, _StageStyle>{
    ProjectStage.foundation: _StageStyle(Color(0xFFEEEFFF), Color(0xFF4455CC)),
    ProjectStage.structure:  _StageStyle(Color(0xFFF3E8FF), Color(0xFF9B59B6)),
    ProjectStage.finishing:  _StageStyle(Color(0xFFE8F5E9), Color(0xFF2E7D32)),
    ProjectStage.handover:   _StageStyle(Color(0xFFFFF8E1), Color(0xFFF57F17)),
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project  = provider.selectedProject;

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.gradientStart,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: 'Project Detail',
                isSubScreen: true,
                leftIcon: Icons.arrow_back,
                onLeftTap: () => Navigator.maybePop(context),
              ),
              const Expanded(
                child: AppEmptyState(
                  icon: Icons.folder_open_outlined,
                  message: 'No project selected.\nGo back and select a project.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final style = _stageMeta[project.stage]!;
    final entries = provider.entriesForProject(project.id);

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: project.name,
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  // In a real app, this would reload from API
                  await Future<void>.delayed(const Duration(milliseconds: 500));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // â”€â”€ Project header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _HeaderCard(project: project, style: style),
                      const SizedBox(height: 14),

                      // â”€â”€ Progress â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      const AppSectionHeader(title: 'Overall Progress'),
                      _ProgressCard(project: project),
                      const SizedBox(height: 14),

                      // â”€â”€ Financial breakdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      const AppSectionHeader(title: 'Financial Breakdown'),
                      _FinancialCard(project: project),
                      const SizedBox(height: 14),

                      // â”€â”€ Recent Entries â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      AppSectionHeader(
                        title: 'Recent Entries',
                        actionLabel: entries.isEmpty ? null : 'View All',
                        onAction: () => Navigator.pushNamed(context, '/logs'),
                      ),
                      if (entries.isEmpty)
                        const AppEmptyState(
                          icon: Icons.receipt_long_outlined,
                          message: 'No entries logged yet.',
                        )
                      else
                        ...entries.take(3).map((e) => _EntryTile(entry: e)),
                      const SizedBox(height: 20),

                      // â”€â”€ Action buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      const AppSectionHeader(title: 'Actions'),
                      _ActionButtons(project: project),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Header card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.project, required this.style});

  final ProjectModel project;
  final _StageStyle  style;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: AppTheme.heading2.copyWith(letterSpacing: -0.3),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  project.stage.label,
                  style: TextStyle(
                    color: style.fg,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.textLight, size: 14),
              const SizedBox(width: 4),
              Text(project.location,
                  style: AppTheme.caption.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppColors.textLight, size: 14),
              const SizedBox(width: 4),
              Text(
                'Started ${_formatDate(project.startDate)}',
                style: AppTheme.caption.copyWith(fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Progress card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Completion',
                  style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              Text(
                '${(project.progress * 100).toStringAsFixed(1)}%',
                style: AppTheme.heading3.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: project.progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8ECF8),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Financial card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FinancialCard extends StatelessWidget {
  const _FinancialCard({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    final utilization = project.budgetUtilization;
    final isOverBudget = project.spentAmount > project.totalBudget;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _finRow('Total Budget', project.formattedBudget,
              AppColors.textDark, Icons.account_balance_outlined),
          const AppDivider(verticalPadding: 8),
          _finRow('Spent', project.formattedSpent,
              isOverBudget ? AppColors.error : AppColors.primary,
              Icons.payments_outlined),
          const AppDivider(verticalPadding: 8),
          _finRow(
              'Remaining',
              project.formattedRemaining,
              project.remainingBudget >= 0
                  ? AppColors.success
                  : AppColors.error,
              Icons.savings_outlined),
          const SizedBox(height: 14),
          // Budget utilization bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget Used',
                      style: AppTheme.label.copyWith(
                          color: AppColors.textLight, letterSpacing: 0.3)),
                  Text(
                    '${(utilization * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: utilization >= 1.0
                          ? AppColors.error
                          : utilization >= 0.8
                              ? AppColors.warning
                              : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LinearProgressIndicator(
                  value: utilization.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEEF0F8),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    utilization >= 1.0
                        ? AppColors.error
                        : utilization >= 0.8
                            ? AppColors.warning
                            : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _finRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: AppTheme.body.copyWith(color: AppColors.textMedium)),
        ),
        Text(value,
            style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Entry tile
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final EntryModel entry;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _typeStyle(entry.type);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.description.isEmpty
                    ? entry.type.label.toUpperCase()
                    : entry.description,
                    style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                Text(
                  _formatDate(entry.date),
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          Text(
            _fmt(entry.amount),
            style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _typeStyle(EntryType t) {
    switch (t) {
      case EntryType.material:  return (AppColors.primary,  Icons.category_outlined);
      case EntryType.labour:    return (AppColors.info,      Icons.people_outline);
      case EntryType.equipment: return (const Color(0xFF7B3FE7), Icons.construction_outlined);
    }
  }

  String _fmt(double v) {
    if (v >= 1e6) return 'â‚¹${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return 'â‚¹${(v / 1e3).toStringAsFixed(0)}k';
    return 'â‚¹${v.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Action buttons
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: 'View Report',
          icon: Icons.bar_chart_outlined,
          onPressed: () => Navigator.pushNamed(context, '/project-report'),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Update Progress',
          icon: Icons.trending_up,
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.pushNamed(context, '/update-progress'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Add Entry',
                icon: Icons.add_circle_outline,
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.pushNamed(context, '/add-entry'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'All Logs',
                icon: Icons.receipt_long_outlined,
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.pushNamed(context, '/logs'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Internal style record
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StageStyle {
  const _StageStyle(this.bg, this.fg);
  final Color bg;
  final Color fg;
}
