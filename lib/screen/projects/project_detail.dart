import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/construction_models.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';

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
                    // ── Summary Header ─────────────────────────────────
                    _SummaryCard(project: project, progress: progress,
                        doneCount: doneCount, totalCount: total),
                    const SizedBox(height: 14),

                    // ── Project Information ────────────────────────────
                    const AppSectionHeader(title: 'Project Information'),
                    _ProjectInfoCard(project: project),
                    const SizedBox(height: 14),

                    // ── Land & Floors ──────────────────────────────────
                    if ((project.landArea != null && project.landArea!.isNotEmpty) ||
                        (project.floors != null && project.floors!.isNotEmpty)) ...[
                      const AppSectionHeader(title: 'Land & Floor Configuration'),
                      _LandFloorsCard(project: project),
                      const SizedBox(height: 14),
                    ],

                    // ── Rooms & Bathrooms ──────────────────────────────
                    if ((project.room1BHK ?? 0) + (project.room2BHK ?? 0) +
                        (project.room3BHK ?? 0) + (project.roomCustom ?? 0) +
                        (project.bathWestern ?? 0) + (project.bathIndian ?? 0) +
                        (project.bathCommon ?? 0) + (project.bathAttached ?? 0) > 0) ...[
                      const AppSectionHeader(title: 'Rooms & Bathrooms'),
                      _RoomsBathsCard(project: project),
                      const SizedBox(height: 14),
                    ],

                    // ── Configuration Sections (expandable per group) ──
                    if (project.selectedFeatures != null &&
                        project.selectedFeatures!.isNotEmpty)
                      ..._buildConfigSections(project.selectedFeatures!),

                    // ── Timeline & Status ──────────────────────────────
                    const AppSectionHeader(title: 'Timeline & Status'),
                    _ProjectTimelineCard(project: project),
                    const SizedBox(height: 14),

                    // ── Financial Overview ─────────────────────────────
                    const AppSectionHeader(title: 'Financial Overview'),
                    _FinancialCard(project: project),
                    const SizedBox(height: 14),

                    // ── Execution Tracker ──────────────────────────────
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

                    // ── Recent Entries ─────────────────────────────────
                    _RecentEntriesSection(project: project, provider: provider),
                    const SizedBox(height: 14),

                    // ── Actions ────────────────────────────────────────
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

  List<Widget> _buildConfigSections(List<String> features) {
    final known = [..._kUtility, ..._kGas, ..._kKitchen, ..._kElectrical, ..._kTerrace];
    final addl       = features.where((f) => !known.contains(f)).toList();
    final utility    = _grp(features, _kUtility);
    final gas        = _grp(features, _kGas);
    final kitchen    = _grp(features, _kKitchen);
    final electrical = _grp(features, _kElectrical);
    final terrace    = _grp(features, _kTerrace);
    Widget sec(String t, List<String> items, IconData icon) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: t),
        _FeatureGroupCard(icon: icon, title: t, features: items),
        const SizedBox(height: 14),
      ],
    );
    return [
      if (addl.isNotEmpty)       sec('Additional Configuration', addl,       Icons.tune_rounded),
      if (utility.isNotEmpty)    sec('Utility & Services',       utility,    Icons.electrical_services_rounded),
      if (gas.isNotEmpty)        sec('Gas Connection',           gas,        Icons.local_fire_department_rounded),
      if (kitchen.isNotEmpty)    sec('Kitchen Requirements',     kitchen,    Icons.kitchen_rounded),
      if (electrical.isNotEmpty) sec('Electrical & Plumbing',   electrical, Icons.bolt_rounded),
      if (terrace.isNotEmpty)    sec('Terrace & Interior',       terrace,    Icons.roofing_rounded),
    ];
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


// ── Project Info Card ─────────────────────────────────────────────────────────
class _ProjectInfoCard extends StatelessWidget {
  const _ProjectInfoCard({required this.project});
  final ProjectModel project;
  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRow>[
      if (project.clientName?.isNotEmpty == true)     _InfoRow(Icons.person_outline,          'Client',      project.clientName!),
      if (project.contractorName?.isNotEmpty == true) _InfoRow(Icons.engineering_outlined,     'Contractor',  project.contractorName!),
      if (project.siteEngineer?.isNotEmpty == true)   _InfoRow(Icons.construction_outlined,    'Engineer',    project.siteEngineer!),
      if (project.contactNumber?.isNotEmpty == true)  _InfoRow(Icons.phone_outlined,           'Contact',     project.contactNumber!),
      if (project.projectType?.isNotEmpty == true)    _InfoRow(Icons.apartment_outlined,       'Type',        project.projectType!),
      if (project.projectStatus?.isNotEmpty == true)  _InfoRow(Icons.flag_outlined,            'Status',      project.projectStatus!),
      _InfoRow(Icons.location_on_outlined,   'Location',    project.location),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: rows.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Icon(r.icon, color: AppColors.primary, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.label, style: AppTheme.caption.copyWith(fontSize: 10, letterSpacing: 0.5)),
              Text(r.value, style: AppTheme.body.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700)),
            ])),
          ]),
        )).toList(),
      ),
    );
  }
}
class _InfoRow { const _InfoRow(this.icon, this.label, this.value); final IconData icon; final String label, value; }

// ── Land & Floors Card ────────────────────────────────────────────────────────
class _LandFloorsCard extends StatelessWidget {
  const _LandFloorsCard({required this.project});
  final ProjectModel project;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (project.landArea != null && project.landArea!.isNotEmpty) ...[
          Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.landscape_outlined, color: AppColors.primary, size: 16)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Land Area', style: AppTheme.caption.copyWith(fontSize: 10)),
              Text('${project.landArea} ${project.landUnit ?? ""}',
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.textDark)),
            ]),
          ]),
          const SizedBox(height: 14),
        ],
        if (project.floors != null && project.floors!.isNotEmpty) ...[
          Text('Floors Included', style: AppTheme.caption.copyWith(fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: project.floors!.map((f) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(f, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          )).toList()),
        ],
      ]),
    );
  }
}

// ── Rooms & Baths Card ────────────────────────────────────────────────────────
class _RoomsBathsCard extends StatelessWidget {
  const _RoomsBathsCard({required this.project});
  final ProjectModel project;
  @override
  Widget build(BuildContext context) {
    final rooms = <String, int?>{
      '1 BHK': project.room1BHK, '2 BHK': project.room2BHK,
      '3 BHK': project.room3BHK, 'Custom': project.roomCustom,
    };
    final baths = <String, int?>{
      'Western': project.bathWestern, 'Indian': project.bathIndian,
      'Common': project.bathCommon,   'Attached': project.bathAttached,
    };
    Widget tile(String label, int? count, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.15))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label ', style: AppTheme.caption.copyWith(fontSize: 12, color: AppColors.textMedium)),
        Text('${count ?? 0}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: c)),
      ]),
    );
    final roomTiles = rooms.entries.where((e) => (e.value ?? 0) > 0)
        .map((e) => tile(e.key, e.value, AppColors.primary)).toList();
    final bathTiles = baths.entries.where((e) => (e.value ?? 0) > 0)
        .map((e) => tile(e.key, e.value, const Color(0xFF00838F))).toList();
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (roomTiles.isNotEmpty) ...[
          Text('ROOMS', style: AppTheme.caption.copyWith(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: roomTiles),
          if (bathTiles.isNotEmpty) const SizedBox(height: 16),
        ],
        if (bathTiles.isNotEmpty) ...[
          Text('BATHROOMS', style: AppTheme.caption.copyWith(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: bathTiles),
        ],
      ]),
    );
  }
}

// ── Feature group constants (mirror add_project.dart) ────────────────────────
const _kUtility    = ['Main Electricity','Temporary Connection','Generator Backup','Water Connection','Borewell Motor','Sump Motor'];
const _kGas        = ['Piped Gas','Cylinder Bank','Gas Pipeline Routing'];
const _kKitchen    = ['Granite Counter','Quartz Counter','Stainless Steel Sink','Chimney Provision','Exhaust Fan Provision'];
const _kElectrical = ['Concealed Wiring','Open Wiring','3-Phase Connection','AC Points','Geyser Points'];
const _kTerrace    = ['Weathering Course','Cool Roof Paint','Overhead Tank','Solar Panels'];
List<String> _grp(List<String> all, List<String> opts) => all.where(opts.contains).toList();

// ── Feature Group Card (self-expanding accordion) ──────────────────────────────
class _FeatureGroupCard extends StatefulWidget {
  const _FeatureGroupCard({required this.icon, required this.title, required this.features});
  final IconData icon;
  final String title;
  final List<String> features;
  @override
  State<_FeatureGroupCard> createState() => _FeatureGroupCardState();
}
class _FeatureGroupCardState extends State<_FeatureGroupCard> {
  bool _open = true;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(width: 32, height: 32,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Icon(widget.icon, color: AppColors.primary, size: 16)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                Text('${widget.features.length} selected', style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
              ])),
              Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textLight),
            ]),
          ),
        ),
        if (_open) ...[
          const Divider(height: 1, color: Color(0xFFEEF0F5)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 6, runSpacing: 6,
              children: widget.features.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                ),
                child: Text(f, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              )).toList(),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Project Timeline & Status Card ────────────────────────────────────────────
class _ProjectTimelineCard extends StatelessWidget {
  const _ProjectTimelineCard({required this.project});
  final ProjectModel project;
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
  @override
  Widget build(BuildContext context) {
    final status = project.projectStatus;
    final statusColor = status == 'Completed' ? AppColors.success
        : status == 'In Progress' ? AppColors.primary
        : status == 'On Hold'     ? AppColors.warning
        : status == 'Cancelled'   ? AppColors.error
        : const Color(0xFF6B7280);
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (status != null) ...[
          Row(children: [
            Container(width: 34, height: 34,
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.flag_rounded, color: statusColor, size: 17)),
            const SizedBox(width: 10),
            Text('Project Status', style: AppTheme.body.copyWith(color: AppColors.textMedium)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
              child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
            ),
          ]),
          const AppDivider(verticalPadding: 12),
        ],
        Text('PROJECT TIMELINE', style: AppTheme.caption.copyWith(fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(children: [
          _dateBox('Start Date', _fmt(project.startDate), Icons.play_circle_outline, AppColors.primary),
          if (project.expectedEndDate != null) ...[
            const SizedBox(width: 10),
            _dateBox('Expected End', _fmt(project.expectedEndDate!), Icons.event_outlined, AppColors.warning),
          ],
        ]),
      ]),
    );
  }
  Widget _dateBox(String label, String val, IconData icon, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, color: c, size: 15),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.caption.copyWith(fontSize: 9, letterSpacing: 0.4)),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c)),
        ])),
      ]),
    ),
  );
}

// ── Financial Card ────────────────────────────────────────────────────────────
class _FinancialCard extends StatelessWidget {
  const _FinancialCard({required this.project});
  final ProjectModel project;
  @override
  Widget build(BuildContext context) {
    final util = project.budgetUtilization;
    final over = project.spentAmount > project.totalBudget;
    final hasBrk = (project.budgetMaterial ?? 0) + (project.budgetLabour ?? 0) +
        (project.budgetEquipment ?? 0) + (project.budgetMisc ?? 0) > 0;
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(children: [
        _frow('Total Budget', project.formattedBudget, AppColors.textDark, Icons.account_balance_outlined),
        const AppDivider(verticalPadding: 8),
        _frow('Spent', project.formattedSpent, over ? AppColors.error : AppColors.primary, Icons.payments_outlined),
        const AppDivider(verticalPadding: 8),
        _frow('Remaining', project.formattedRemaining,
            project.remainingBudget >= 0 ? AppColors.success : AppColors.error, Icons.savings_outlined),
        if (hasBrk) ...[
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEEF0F8), height: 1),
          const SizedBox(height: 10),
          Text('BUDGET BREAKDOWN', style: AppTheme.caption.copyWith(fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if ((project.budgetMaterial ?? 0) > 0)  _brkChip('Material',  project.budgetMaterial!,  AppColors.primary),
            if ((project.budgetLabour ?? 0) > 0)    _brkChip('Labour',    project.budgetLabour!,    AppColors.info),
            if ((project.budgetEquipment ?? 0) > 0) _brkChip('Equipment', project.budgetEquipment!, const Color(0xFF7B3FE7)),
            if ((project.budgetMisc ?? 0) > 0)      _brkChip('Misc',      project.budgetMisc!,      AppColors.warning),
          ]),
        ],
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Budget Used', style: AppTheme.label.copyWith(color: AppColors.textLight, letterSpacing: 0.3)),
          Text('${(util * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: util >= 1.0 ? AppColors.error : util >= 0.8 ? AppColors.warning : AppColors.primary)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(16),
          child: LinearProgressIndicator(value: util.clamp(0.0, 1.0), minHeight: 8,
            backgroundColor: const Color(0xFFEEF0F8),
            valueColor: AlwaysStoppedAnimation<Color>(
              util >= 1.0 ? AppColors.error : util >= 0.8 ? AppColors.warning : AppColors.primary))),
      ]),
    );
  }
  Widget _frow(String label, String value, Color color, IconData icon) => Row(children: [
    Container(width: 34, height: 34,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, color: color, size: 17)),
    const SizedBox(width: 8),
    Expanded(child: Text(label, style: AppTheme.body.copyWith(color: AppColors.textMedium))),
    Text(value, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: color)),
  ]);
  static Widget _brkChip(String label, double amount, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c.withValues(alpha: 0.2))),
    child: Column(children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
      const SizedBox(height: 2),
      Text(formatCurrency(amount), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: c)),
    ]),
  );
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
      Text(formatCurrency(entry.amount),
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


