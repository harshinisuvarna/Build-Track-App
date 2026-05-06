import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/construction_models.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key});
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {

  final Set<String> _expanded = {};

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

    // Build phase list — filter to only selected phases (show all for legacy projects)
    final allPhases    = buildDefaultPhases();
    final selectedNames = project.selectedPhaseNames;
    final phases = (selectedNames == null || selectedNames.isEmpty)
        ? allPhases
        : allPhases.where((p) => selectedNames.contains(p.name)).toList();

    final completed = project.completedActivityKeys ?? [];
    final allKeys   = phases.expand((p) => p.allActivities.map((a) => a.key)).toList();
    final total     = allKeys.length;
    final doneCount = completed.length;
    final progress  = total > 0 ? doneCount / total : project.progress;

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
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary Card ──────────────────────────────────────
                    _SummaryCard(project: project, progress: progress,
                        doneCount: doneCount, totalCount: total),
                    const SizedBox(height: 14),

                    // ── Financial Card ────────────────────────────────────
                    const AppSectionHeader(title: 'Financial Overview'),
                    _FinancialCard(project: project),
                    const SizedBox(height: 14),


                    // ── Execution Tracker ─────────────────────────────────
                    if (phases.isNotEmpty) ...[
                      AppSectionHeader(
                        title: 'Execution Tracker',
                        actionLabel: '$doneCount/$total done',
                      ),
                      ...phases.map((phase) {
                        final phaseKeys  = phase.allActivities.map((a) => a.key).toList();
                        final phaseDone  = phaseKeys.where(completed.contains).length;
                        final isExpanded = _expanded.contains(phase.name);
                        return _PhaseAccordion(
                          phase:       phase,
                          completed:   completed,
                          phaseDone:   phaseDone,
                          isExpanded:  isExpanded,
                          totalForProject: total,
                          onToggleExpand: () => setState(() {
                            if (isExpanded) {
                              _expanded.remove(phase.name);
                            } else {
                              _expanded.add(phase.name);
                            }
                          }),
                          onToggleActivity: (key) {
                            context.read<ProjectProvider>()
                                .toggleActivityCompletion(project.id, key, total);
                          },
                        );
                      }),
                      const SizedBox(height: 14),
                    ],

                    // ── Recent Entries ────────────────────────────────────
                    _RecentEntriesSection(project: project, provider: provider),
                    const SizedBox(height: 14),

                    // ── Actions ───────────────────────────────────────────
                    const AppSectionHeader(title: 'Actions'),
                    _ActionButtons(project: project),
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

// ── Summary Card ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.project, required this.progress,
    required this.doneCount, required this.totalCount,
  });
  final ProjectModel project;
  final double progress;
  final int doneCount, totalCount;

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toStringAsFixed(1);
    final statusColor = progress >= 1.0
        ? AppColors.success
        : progress >= 0.7
            ? AppColors.primary
            : AppColors.warning;
    final statusLabel = progress >= 1.0
        ? 'Completed'
        : progress >= 0.3
            ? 'In Progress'
            : 'Starting';

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, style: AppTheme.heading2.copyWith(letterSpacing: -0.3)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor, fontSize: 11,
                          fontWeight: FontWeight.w800, letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _infoRow(Icons.location_on_outlined, project.location),
                    const SizedBox(height: 4),
                    _infoRow(Icons.calendar_today_outlined, 'Started ${_fmt(project.startDate)}'),
                    if (project.expectedEndDate != null) ...[
                      const SizedBox(height: 4),
                      _infoRow(Icons.event_available_outlined,
                          'Due ${_fmt(project.expectedEndDate!)}'),
                    ],
                    if (project.clientName != null && project.clientName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _infoRow(Icons.person_outline, project.clientName!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _budgetChip('Budget', project.formattedBudget, AppColors.textDark),
                  const SizedBox(height: 6),
                  _budgetChip('Spent', project.formattedSpent, AppColors.primary),
                  const SizedBox(height: 6),
                  _budgetChip('Left', project.formattedRemaining,
                      project.remainingBudget >= 0 ? AppColors.success : AppColors.error),
                ],
              ),
            ],
          ),
          if (project.floors != null && project.floors!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: project.floors!.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1),
                ),
                child: Text(f,
                    style: const TextStyle(color: AppColors.primary, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0F5), height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Completion',
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark)),
              Text('$pct%  ($doneCount/$totalCount activities)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFE8ECF8),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: AppColors.textLight, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text, style: AppTheme.caption.copyWith(fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );

  Widget _budgetChip(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight,
              fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      );
}

// ── Phase Accordion ───────────────────────────────────────────────────────────
class _PhaseAccordion extends StatelessWidget {
  const _PhaseAccordion({
    required this.phase,
    required this.completed,
    required this.phaseDone,
    required this.isExpanded,
    required this.totalForProject,
    required this.onToggleExpand,
    required this.onToggleActivity,
  });
  final ConstructionPhase phase;
  final List<String> completed;
  final int phaseDone, totalForProject;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final void Function(String key) onToggleActivity;

  @override
  Widget build(BuildContext context) {
    final total    = phase.totalCount;
    final phasePct = total > 0 ? (phaseDone / total * 100).toStringAsFixed(0) : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0,2)),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggleExpand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(phase.name,
                            style: const TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        const SizedBox(height: 2),
                        Text('$phaseDone of $total activities • $phasePct%',
                            style: const TextStyle(fontSize: 11,
                                color: AppColors.textLight, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (phaseDone > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$phaseDone/$total',
                          style: const TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ),
                  const SizedBox(width: 8),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.textLight),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            // Phase progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total > 0 ? phaseDone / total : 0.0,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE8ECF8),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEF0F5)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flat activities
                  ...phase.activities.map((a) => _ActivityRow(
                    activity: a,
                    isDone: completed.contains(a.key),
                    onTap: () => onToggleActivity(a.key),
                  )),
                  // Grouped activities (MEP etc.)
                  ...phase.groups.map((g) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(g.name.toUpperCase(),
                          style: const TextStyle(fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textLight, letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      ...g.activities.map((a) => _ActivityRow(
                        activity: a,
                        isDone: completed.contains(a.key),
                        onTap: () => onToggleActivity(a.key),
                      )),
                    ],
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Activity Row ──────────────────────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.isDone, required this.onTap});
  final ConstructionActivity activity;
  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isDone
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDone ? AppColors.success.withValues(alpha: 0.4) : const Color(0xFFEEF0F5),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: isDone ? AppColors.success : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDone ? AppColors.success : AppColors.textLight.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                activity.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDone ? AppColors.success : AppColors.textDark,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.success,
                ),
              ),
            ),
            if (!isDone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Pending',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                        color: AppColors.warning, letterSpacing: 0.4)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Done',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                        color: AppColors.success, letterSpacing: 0.4)),
              ),
          ],
        ),
      ),
    );
  }
}


// ── Financial Card ────────────────────────────────────────────────────────────
class _FinancialCard extends StatelessWidget {
  const _FinancialCard({required this.project});
  final ProjectModel project;
  @override
  Widget build(BuildContext context) {
    final util = project.budgetUtilization;
    final over = project.spentAmount > project.totalBudget;
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(children: [
        _row('Total Budget', project.formattedBudget, AppColors.textDark, Icons.account_balance_outlined),
        const AppDivider(verticalPadding: 8),
        _row('Spent', project.formattedSpent, over ? AppColors.error : AppColors.primary, Icons.payments_outlined),
        const AppDivider(verticalPadding: 8),
        _row('Remaining', project.formattedRemaining,
            project.remainingBudget >= 0 ? AppColors.success : AppColors.error, Icons.savings_outlined),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Budget Used', style: AppTheme.label.copyWith(color: AppColors.textLight, letterSpacing: 0.3)),
          Text('${(util * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: util >= 1.0 ? AppColors.error : util >= 0.8 ? AppColors.warning : AppColors.primary)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: LinearProgressIndicator(
            value: util.clamp(0.0, 1.0), minHeight: 8,
            backgroundColor: const Color(0xFFEEF0F8),
            valueColor: AlwaysStoppedAnimation<Color>(
              util >= 1.0 ? AppColors.error : util >= 0.8 ? AppColors.warning : AppColors.primary),
          ),
        ),
      ]),
    );
  }
  Widget _row(String label, String value, Color color, IconData icon) => Row(children: [
    Container(
      width: 34, height: 34,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, color: color, size: 17),
    ),
    const SizedBox(width: 8),
    Expanded(child: Text(label, style: AppTheme.body.copyWith(color: AppColors.textMedium))),
    Text(value, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: color)),
  ]);
}

// ── Recent Entries Section ────────────────────────────────────────────────────
class _RecentEntriesSection extends StatelessWidget {
  const _RecentEntriesSection({required this.project, required this.provider});
  final ProjectModel project;
  final ProjectProvider provider;
  @override
  Widget build(BuildContext context) {
    final entries = provider.entriesForProject(project.id).take(3).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppSectionHeader(
        title: 'Recent Entries',
        actionLabel: entries.isEmpty ? null : 'View All',
        onAction: () => Navigator.pushNamed(context, '/logs'),
      ),
      if (entries.isEmpty)
        const AppEmptyState(icon: Icons.receipt_long_outlined, message: 'No entries logged yet.')
      else
        ...entries.map((e) => _EntryTile(entry: e)),
    ]);
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final EntryModel entry;
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  String _fmt(double v) {
    if (v >= 1e6) return '₹${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '₹${(v / 1e3).toStringAsFixed(0)}k';
    return '₹${v.toStringAsFixed(0)}';
  }
  (Color, IconData) _style(EntryType t) {
    switch (t) {
      case EntryType.material:  return (AppColors.primary, Icons.category_outlined);
      case EntryType.labour:    return (AppColors.info,    Icons.people_outline);
      case EntryType.equipment: return (const Color(0xFF7B3FE7), Icons.construction_outlined);
    }
  }
  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style(entry.type);
    final d = entry.date;
    final dateStr = '${d.day} ${_months[d.month - 1]} ${d.year}';
    return AppCard(child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(entry.description.isEmpty ? entry.type.label.toUpperCase() : entry.description,
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark)),
        Text(dateStr, style: AppTheme.caption),
      ])),
      Text(_fmt(entry.amount),
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
    ]));
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.project});
  final ProjectModel project;
  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Add Entry',
      icon: Icons.add_circle_outline,
      onPressed: () => Navigator.pushNamed(context, '/add-entry'),
    );
  }
}


