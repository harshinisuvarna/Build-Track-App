
import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProjectReportScreen extends StatelessWidget {
  const ProjectReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project  = provider.selectedProject;

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
                title: 'Project Activity',
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

    final all       = provider.entriesForProject(project.id);
    final labour    = all.where((e) => e.type == EntryType.labour).toList();
    final materials = all.where((e) => e.type == EntryType.material).toList();
    final equipment = all.where((e) => e.type == EntryType.equipment).toList();
    final recent    = ([...all]..sort((a, b) => b.date.compareTo(a.date))).take(8).toList();

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Project Activity',
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

                    // ── 1. Project Summary ─────────────────────────────────
                    _SummaryCard(project: project),
                    const SizedBox(height: 14),

                    // ── 2. Financial Snapshot ──────────────────────────────
                    const AppSectionHeader(title: 'Financial Snapshot'),
                    _FinancialSnapshot(project: project),
                    const SizedBox(height: 14),

                    // ── 3. Labour ──────────────────────────────────────────
                    AppSectionHeader(
                      title: 'Labour',
                      actionLabel: labour.isEmpty ? null : 'All',
                      onAction: () => Navigator.pushNamed(context, '/logs'),
                    ),
                    _EntrySection(
                      entries: labour,
                      type: EntryType.labour,
                      emptyMsg: 'No labour entries logged yet.',
                    ),
                    const SizedBox(height: 14),

                    // ── 4. Materials ───────────────────────────────────────
                    AppSectionHeader(
                      title: 'Materials',
                      actionLabel: materials.isEmpty ? null : 'All',
                      onAction: () => Navigator.pushNamed(context, '/logs'),
                    ),
                    _EntrySection(
                      entries: materials,
                      type: EntryType.material,
                      emptyMsg: 'No material entries logged yet.',
                    ),
                    const SizedBox(height: 14),

                    // ── 5. Equipment ───────────────────────────────────────
                    AppSectionHeader(
                      title: 'Equipment',
                      actionLabel: equipment.isEmpty ? null : 'All',
                      onAction: () => Navigator.pushNamed(context, '/logs'),
                    ),
                    _EntrySection(
                      entries: equipment,
                      type: EntryType.equipment,
                      emptyMsg: 'No equipment entries logged yet.',
                    ),
                    const SizedBox(height: 14),

                    // ── 6. Recent Activity Timeline ────────────────────────
                    AppSectionHeader(
                      title: 'Recent Activity',
                      actionLabel: recent.isEmpty ? null : 'View All',
                      onAction: () => Navigator.pushNamed(context, '/logs'),
                    ),
                    _ActivityTimeline(entries: recent),
                    const SizedBox(height: 20),

                    // ── 7. Actions ─────────────────────────────────────────
                    AppButton(
                      label: 'Update Progress',
                      icon: Icons.trending_up,
                      onPressed: () =>
                          Navigator.pushNamed(context, '/update-progress'),
                    ),
                    const SizedBox(height: 10),
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

// ─────────────────────────────────────────────────────────────────────────────
// 1. Project Summary Card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.project});
  final ProjectModel project;

  static const _stageMeta = <ProjectStage, (Color, Color)>{
    ProjectStage.foundation: (Color(0xFFEEEFFF), Color(0xFF4455CC)),
    ProjectStage.structure:  (Color(0xFFF3E8FF), Color(0xFF9B59B6)),
    ProjectStage.finishing:  (Color(0xFFE8F5E9), Color(0xFF2E7D32)),
    ProjectStage.handover:   (Color(0xFFFFF8E1), Color(0xFFF57F17)),
  };

  @override
  Widget build(BuildContext context) {
    final (stageBg, stageFg) = _stageMeta[project.stage]!;
    final pct = project.progress;
    final barColor = pct >= 0.9
        ? AppColors.error
        : pct >= 0.6
            ? AppColors.warning
            : AppColors.primary;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project name + stage badge
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: AppTheme.heading2.copyWith(
                      fontSize: 17,
                      color: AppColors.textDark,
                      letterSpacing: -0.3),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                    color: stageBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(project.stage.label,
                    style: TextStyle(
                        color: stageFg,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location
          Row(children: [
            const Icon(Icons.location_on_outlined,
                size: 13, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text(project.location,
                style: AppTheme.caption.copyWith(fontSize: 12)),
          ]),
          const SizedBox(height: 4),

          // Start date
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text('Started ${_fmtDate(project.startDate)}',
                style: AppTheme.caption.copyWith(fontSize: 12)),
          ]),
          const SizedBox(height: 16),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Progress',
                  style: AppTheme.label
                      .copyWith(color: AppColors.textLight, letterSpacing: 0.3)),
              Text('${(pct * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: barColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 9,
              backgroundColor: const Color(0xFFE8ECF8),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Financial Snapshot — three simple stat chips, no chart
// ─────────────────────────────────────────────────────────────────────────────

class _FinancialSnapshot extends StatelessWidget {
  const _FinancialSnapshot({required this.project});
  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    final u = project.budgetUtilization;
    final statusColor = u >= 0.9
        ? AppColors.error
        : u >= 0.6
            ? AppColors.warning
            : AppColors.success;

    return Row(
      children: [
        _StatChip(
          label: 'Budget',
          value: project.formattedBudget,
          icon: Icons.account_balance_outlined,
          color: AppColors.textDark,
        ),
        const SizedBox(width: 10),
        _StatChip(
          label: 'Spent',
          value: project.formattedSpent,
          icon: Icons.payments_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        _StatChip(
          label: 'Remaining',
          value: project.formattedRemaining,
          icon: Icons.savings_outlined,
          color: statusColor,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTheme.caption
                    .copyWith(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-5. Entry Section (Labour / Material / Equipment)
// ─────────────────────────────────────────────────────────────────────────────

class _EntrySection extends StatelessWidget {
  const _EntrySection({
    required this.entries,
    required this.type,
    required this.emptyMsg,
  });
  final List<EntryModel> entries;
  final EntryType        type;
  final String           emptyMsg;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return AppCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(_typeIcon(type),
                color: AppColors.textLight, size: 18),
            const SizedBox(width: 10),
            Text(emptyMsg,
                style:
                    AppTheme.body.copyWith(color: AppColors.textLight)),
          ]),
        ),
      );
    }

    final displayed = entries.take(3).toList();
    final total     = entries.fold(0.0, (s, e) => s + e.amount);
    final color     = _typeColor(type);

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header row: total entries + total amount
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(_typeIcon(type), color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${entries.length} ${_typeLabel(type)} entr${entries.length == 1 ? 'y' : 'ies'}',
                style: AppTheme.body.copyWith(color: AppColors.textMedium),
              ),
            ),
            Text(_fmtAmt(total),
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: color, fontSize: 14)),
          ]),

          if (displayed.isNotEmpty) ...[
            const Divider(color: Color(0xFFEEF0F8), height: 20),
            ...displayed.map((e) => _entryRow(e, color)),
          ],
        ],
      ),
    );
  }

  Widget _entryRow(EntryModel e, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(
          child: Text(
            e.description.isEmpty ? _typeLabel(type) : e.description,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.body.copyWith(color: AppColors.textDark),
          ),
        ),
        const SizedBox(width: 8),
        Text(_fmtAmt(e.amount),
            style: TextStyle(
                fontWeight: FontWeight.w700, color: c, fontSize: 13)),
      ]),
    );
  }

  IconData _typeIcon(EntryType t) {
    switch (t) {
      case EntryType.material:  return Icons.category_outlined;
      case EntryType.labour:    return Icons.people_outline;
      case EntryType.equipment: return Icons.construction_outlined;
    }
  }

  Color _typeColor(EntryType t) {
    switch (t) {
      case EntryType.material:  return AppColors.primary;
      case EntryType.labour:    return AppColors.info;
      case EntryType.equipment: return const Color(0xFF7B3FE7);
    }
  }

  String _typeLabel(EntryType t) {
    switch (t) {
      case EntryType.material:  return 'Material';
      case EntryType.labour:    return 'Labour';
      case EntryType.equipment: return 'Equipment';
    }
  }

  String _fmtAmt(double v) {
    if (v >= 1e6) return '₹${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '₹${(v / 1e3).toStringAsFixed(0)}k';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Activity Timeline — chronological entry feed
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({required this.entries});
  final List<EntryModel> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const AppCard(
        margin: EdgeInsets.zero,
        child: AppEmptyState(
          icon: Icons.history_outlined,
          message: 'No activity yet.',
        ),
      );
    }

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: List.generate(entries.length, (idx) {
          final e             = entries[idx];
          final (color, icon) = _typeStyle(e.type);
          final isLast        = idx == entries.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline spine
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 15),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            color: const Color(0xFFE0E3F0),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(
                              _entryTitle(e),
                              style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  fontSize: 13),
                            ),
                          ),
                          Text(
                            _fmtAmt(e.amount),
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: color,
                                fontSize: 13),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text(
                          _fmtDate(e.date),
                          style: AppTheme.caption
                              .copyWith(fontSize: 11, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _entryTitle(EntryModel e) {
    if (e.description.isNotEmpty) return e.description;
    switch (e.type) {
      case EntryType.material:  return 'Material Added';
      case EntryType.labour:    return 'Labour Entry';
      case EntryType.equipment: return 'Equipment Used';
    }
  }

  (Color, IconData) _typeStyle(EntryType t) {
    switch (t) {
      case EntryType.material:
        return (AppColors.primary, Icons.category_outlined);
      case EntryType.labour:
        return (AppColors.info, Icons.people_outline);
      case EntryType.equipment:
        return (const Color(0xFF7B3FE7), Icons.construction_outlined);
    }
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String _fmtAmt(double v) {
    if (v >= 1e6) return '₹${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '₹${(v / 1e3).toStringAsFixed(0)}k';
    return '₹${v.toStringAsFixed(0)}';
  }
}
