import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/role_manager.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/models/construction_models.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';
import 'dart:convert';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:buildtrack_mobile/screen/projects/edit_project.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key});
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProjectProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.selectedProject;

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

    final selectedPhases = project.selectedPhases;
    final hasNewTracker = selectedPhases != null && selectedPhases.isNotEmpty;

    final int trackerTotal = hasNewTracker
        ? selectedPhases.fold<int>(0, (s, p) => s + p.totalCount)
        : 0;
    final int trackerDone = hasNewTracker
        ? selectedPhases.fold<int>(0, (s, p) => s + p.completedCount)
        : (project.completedActivityKeys?.length ?? 0);
    final double progress = trackerTotal > 0
        ? trackerDone / trackerTotal
        : project.progress;

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
                    _SummaryCard(
                      project: project,
                      progress: progress,
                      doneCount: trackerDone,
                      totalCount: trackerTotal,
                    ),
                    const SizedBox(height: 14),

                    const AppSectionHeader(title: 'Project Information'),
                    _ProjectInfoCard(project: project),
                    const SizedBox(height: 14),

                    if (project.projectType != null &&
                        project.projectType!.isNotEmpty) ...[
                      const AppSectionHeader(title: 'Building Type'),
                      _BuildingTypeCard(project: project),
                      const SizedBox(height: 14),
                    ],

                    if ((project.landArea != null &&
                            project.landArea!.isNotEmpty) ||
                        (project.floors != null &&
                            project.floors!.isNotEmpty)) ...[
                      const AppSectionHeader(title: 'Land & Floor Configuration'),
                      _LandFloorsCard(project: project),
                      const SizedBox(height: 14),
                    ],

                    if ((project.room1BHK ?? 0) +
                            (project.room2BHK ?? 0) +
                            (project.room3BHK ?? 0) +
                            (project.roomCustom ?? 0) +
                            (project.bathWestern ?? 0) +
                            (project.bathIndian ?? 0) +
                            (project.bathCommon ?? 0) +
                            (project.bathAttached ?? 0) >
                        0) ...[
                      const AppSectionHeader(title: 'Rooms & Bathrooms'),
                      _RoomsBathsCard(project: project),
                      const SizedBox(height: 14),
                    ],

                    if (project.selectedFeatures != null &&
                        project.selectedFeatures!.isNotEmpty)
                      ..._buildConfigSections(project.selectedFeatures!),

                    const AppSectionHeader(title: 'Timeline & Status'),
                    _ProjectTimelineCard(project: project),
                    const SizedBox(height: 14),

                    const AppSectionHeader(title: 'Financial Overview'),
                    _FinancialCard(project: project),
                    const SizedBox(height: 14),

                    AppSectionHeader(
                      title: 'Execution Tracker',
                      actionLabel: hasNewTracker
                          ? '$trackerDone/$trackerTotal done'
                          : null,
                    ),
                    if (hasNewTracker) ...[
                      ...selectedPhases.map(
                        (phase) => _TrackerPhaseCard(
                          phase: phase,
                          projectId: project.id,
                          projectFloors: project.floors ?? [],
                          isExpanded: _expanded.contains(phase.id),
                          onToggleExpand: () => setState(() {
                            if (_expanded.contains(phase.id)) {
                              _expanded.remove(phase.id);
                            } else {
                              _expanded.add(phase.id);
                            }
                          }),
                          onToggleActivity: (activityId) {
                            context
                                .read<ProjectProvider>()
                                .toggleActivityCompletion(
                                  project.id,
                                  activityId,
                                );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFEEF0F5),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.checklist_rounded,
                              size: 40,
                              color: Color(0xFFCDD0DA),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No execution plan configured',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select phases & activities when creating a project.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // FIX: pass currentUserId so only this user's entries show
                    _RecentEntriesSection(
                      project: project,
                      provider: provider,
                      currentUserId: UserSession.userId,
                    ),
                    const SizedBox(height: 14),

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
    final addl = _grp(features, _kAddlConfig);
    final utility = _grp(features, _kUtility);
    final gas = _grp(features, _kGas);
    final kitchen = _grp(features, _kKitchen);
    final electrical = _grp(features, _kElectrical);
    final terrace = _grp(features, _kTerrace);

    final allKnown = [
      ..._kAddlConfig,
      ..._kUtility,
      ..._kGas,
      ..._kKitchen,
      ..._kElectrical,
      ..._kTerrace,
    ];
    final unknown = features.where((f) => !allKnown.contains(f)).toList();
    final addlAll = [...addl, ...unknown];

    Widget sec(String t, List<String> items, IconData icon) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: t),
        _FeatureGroupCard(icon: icon, title: t, features: items),
        const SizedBox(height: 14),
      ],
    );
    return [
      if (addlAll.isNotEmpty)
        sec('Additional Configuration', addlAll, Icons.tune_rounded),
      if (utility.isNotEmpty)
        sec('Utility & Services', utility, Icons.electrical_services_rounded),
      if (gas.isNotEmpty)
        sec('Gas Connection', gas, Icons.local_fire_department_rounded),
      if (kitchen.isNotEmpty)
        sec('Kitchen Requirements', kitchen, Icons.kitchen_rounded),
      if (electrical.isNotEmpty)
        sec('Electrical & Plumbing', electrical, Icons.bolt_rounded),
      if (terrace.isNotEmpty)
        sec('Terrace & Interior', terrace, Icons.roofing_rounded),
    ];
  }
}

// ── Tracker Phase Card ────────────────────────────────────────────────────────
class _TrackerPhaseCard extends StatelessWidget {
  const _TrackerPhaseCard({
    required this.phase,
    required this.projectId,
    required this.projectFloors,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onToggleActivity,
  });

  final ProjectPhase phase;
  final String projectId;
  final List<String> projectFloors;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final void Function(String activityId) onToggleActivity;

  @override
  Widget build(BuildContext context) {
    final done = phase.completedCount;
    final total = phase.totalCount;
    final pct = total > 0 ? done / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: phase.isCustom
                          ? const Color(0xFF7B3FE7).withValues(alpha: 0.10)
                          : AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      phase.isCustom
                          ? Icons.star_rounded
                          : Icons.construction_rounded,
                      color: phase.isCustom
                          ? const Color(0xFF7B3FE7)
                          : AppColors.primary,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.phaseName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$done of $total activities done',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: pct >= 1.0
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textLight,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 3,
                  backgroundColor: const Color(0xFFEEF0F8),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pct >= 1.0 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Color(0xFFEEF0F5)),
                ...phase.activities.map(
                  (act) => _TrackerActivityRow(
                    activity: act,
                    projectId: projectId,
                    phaseName: phase.phaseName,
                    projectFloors: projectFloors,
                    onToggle: () => onToggleActivity(act.id),
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ── Tracker Activity Row ──────────────────────────────────────────────────────
class _TrackerActivityRow extends StatelessWidget {
  const _TrackerActivityRow({
    required this.activity,
    required this.projectId,
    required this.phaseName,
    required this.projectFloors,
    required this.onToggle,
  });

  final ProjectActivity activity;
  final String projectId;
  final String phaseName;
  final List<String> projectFloors;
  final VoidCallback onToggle;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String? _completedDateLabel() {
    if (!activity.completed) return null;
    final dt = activity.completedAt;
    if (dt == null) return 'Date not recorded';
    // Sentinel date means completed but date was unknown
    if (dt.year == 2000 && dt.month == 1 && dt.day == 1) return 'Date not recorded';
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final done = activity.completed;
    final dateLabel = _completedDateLabel();

    return InkWell(
      onTap: activity.completed ? null : onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: done ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: done ? AppColors.success : const Color(0xFFCDD0DA),
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: done ? FontWeight.w600 : FontWeight.w500,
                      color: done ? const Color(0xFF9CA3AF) : AppColors.textDark,
                      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: const Color(0xFF9CA3AF),
                    ),
                  ),
                  if (done && dateLabel != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 10, color: AppColors.success),
                        const SizedBox(width: 3),
                        Text(
                          'Completed $dateLabel',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: done
                    ? AppColors.success.withValues(alpha: 0.10)
                    : const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                done ? 'Done' : 'Pending',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: done ? AppColors.success : const Color(0xFFF59E0B),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _openUpdateProgress(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'ADD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            if (done) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showActivityDetails(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.20),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'VIEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openUpdateProgress(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/update-progress',
      arguments: {
        'projectId': projectId,
        'phaseName': phaseName,
        'activityName': activity.name,
        'activityId': activity.id,
        'floor': projectFloors.isNotEmpty ? projectFloors.first : null,
        'projectFloors': projectFloors,
      },
    ).then((_) async {
      if (context.mounted) {
        // Wait for any in-flight PUT to finish before re-fetching,
        // otherwise load() overwrites the optimistic tick with stale server data.
        await Future.delayed(const Duration(milliseconds: 600));
        if (context.mounted) {
          context.read<ProjectProvider>().load();
        }
      }
    });
  }

  void _showActivityDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final maxH = MediaQuery.of(context).size.height * 0.75;
        final formattedDate = _completedDateLabel() ?? 'Completed';

        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE0F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                phaseName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status & Date Row
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.success),
                              const SizedBox(width: 8),
                              Text(
                                'Completed on $formattedDate',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          
                          // Notes/Remarks Section
                          if (activity.notes != null && activity.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Notes & Remarks',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Text(
                                activity.notes!,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.5,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          
                          // Photos Section
                          if ((activity.photos != null && activity.photos!.isNotEmpty) ||
                              (activity.photo != null && activity.photo!.isNotEmpty)) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Progress Photos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildProgressPhotosList(context, activity),
                          ],

                          // Empty details placeholder
                          if ((activity.notes == null || activity.notes!.trim().isEmpty) &&
                              (activity.photo == null || activity.photo!.isEmpty) &&
                              (activity.photos == null || activity.photos!.isEmpty)) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: const Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: Colors.grey, size: 28),
                                    SizedBox(height: 8),
                                    Text(
                                      'No additional notes or photos recorded for this activity.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnailImage(String photoUrl) {
    Widget img;
    if (photoUrl.startsWith('data:image/') && photoUrl.contains(';base64,')) {
      try {
        final base64String = photoUrl.split(';base64,').last;
        final bytes = base64.decode(base64String);
        img = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 80,
          height: 80,
        );
      } catch (e) {
        img = Container(
          color: const Color(0xFFF3F4F6),
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 24),
        );
      }
    } else {
      img = Image.network(
        photoUrl,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFF3F4F6),
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 24),
          );
        },
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: img,
    );
  }

  Widget _buildProgressPhotosList(BuildContext context, ProjectActivity activity) {
    final photos = (activity.photos != null && activity.photos!.isNotEmpty)
        ? activity.photos!
        : [activity.photo!];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: photos.asMap().entries.map((entry) {
        final idx = entry.key;
        final url = entry.value;
        return GestureDetector(
          onTap: () => _openPhotoGallery(context, photos, idx),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEF0FF), width: 1.5),
            ),
            child: _buildThumbnailImage(url),
          ),
        );
      }).toList(),
    );
  }

  void _openPhotoGallery(BuildContext context, List<String> photos, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _GalleryDialog(
        photos: photos,
        initialIndex: initialIndex,
      ),
    );
  }


}

// ── Summary Card ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.project,
    required this.progress,
    required this.doneCount,
    required this.totalCount,
  });
  final ProjectModel project;
  final double progress;
  final int doneCount, totalCount;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  static Color _statusColor(String? status) {
    switch (status) {
      case 'Completed':   return AppColors.success;
      case 'In Progress': return AppColors.primary;
      case 'On Hold':     return AppColors.warning;
      case 'Cancelled':   return AppColors.error;
      default:            return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toStringAsFixed(1);
    final rawStatus = project.projectStatus;
    final statusLabel = (rawStatus != null && rawStatus.isNotEmpty)
        ? rawStatus
        : (progress >= 1.0
            ? 'Completed'
            : progress >= 0.3
            ? 'In Progress'
            : 'Planning');
    final statusColor = _statusColor(rawStatus);

    final allPhases = buildDefaultPhases();
    final selectedNames = project.selectedPhaseNames;
    final phases = (selectedNames == null || selectedNames.isEmpty)
        ? allPhases
        : allPhases.where((p) => selectedNames.contains(p.name)).toList();
    final completed = project.completedActivityKeys ?? [];
    String? activePhase;
    for (final p in phases) {
      final keys = p.allActivities.map((a) => a.key).toList();
      if (keys.any((k) => !completed.contains(k))) {
        activePhase = p.name;
        break;
      }
    }

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
                    Text(project.name,
                        style: AppTheme.heading2.copyWith(letterSpacing: -0.3)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _chip(statusLabel, statusColor),
                        if (activePhase != null)
                          _chip(activePhase, AppColors.primary,
                              icon: Icons.play_circle_outline, subtle: true),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoRow(Icons.location_on_outlined, project.location),
                    const SizedBox(height: 4),
                    _infoRow(Icons.calendar_today_outlined,
                        'Started ${_fmt(project.startDate)}'),
                    if (project.expectedEndDate != null) ...[
                      const SizedBox(height: 4),
                      _infoRow(Icons.event_available_outlined,
                          'Due ${_fmt(project.expectedEndDate!)}'),
                    ],
                    if (project.clientName != null &&
                        project.clientName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _infoRow(Icons.person_outline, project.clientName!),
                    ],
                    if (project.projectCode != null &&
                        project.projectCode!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _infoRow(
                          Icons.qr_code_scanner_outlined, project.projectCode!),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (project.floors != null && project.floors!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: project.floors!
                  .map((f) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              width: 1),
                        ),
                        child: Text(f,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0F5), height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Completion',
                  style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.textDark)),
              Text('$pct%  ($doneCount/$totalCount activities)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
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

  Widget _chip(String label, Color c, {IconData? icon, bool subtle = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: subtle ? c.withValues(alpha: 0.07) : c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: subtle
              ? Border.all(color: c.withValues(alpha: 0.25), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: c),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    color: c,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4)),
          ],
        ),
      );

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: AppColors.textLight, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                style: AppTheme.caption.copyWith(fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}

// ── Project Info Card ─────────────────────────────────────────────────────────
class _ProjectInfoCard extends StatelessWidget {
  const _ProjectInfoCard({required this.project});
  final ProjectModel project;
  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRow>[
      if (project.projectCode?.isNotEmpty == true)
        _InfoRow(Icons.qr_code_scanner_outlined, 'Project Code', project.projectCode!),
      if (project.clientName?.isNotEmpty == true)
        _InfoRow(Icons.person_outline, 'Client', project.clientName!),
      if (project.contractorName?.isNotEmpty == true)
        _InfoRow(Icons.engineering_outlined, 'Contractor', project.contractorName!),
      if (project.siteEngineer?.isNotEmpty == true)
        _InfoRow(Icons.construction_outlined, 'Engineer', project.siteEngineer!),
      if (project.contactNumber?.isNotEmpty == true)
        _InfoRow(Icons.phone_outlined, 'Contact', project.contactNumber!),
      if (project.mapAddress?.isNotEmpty == true)
        _InfoRow(Icons.place_outlined, 'Map Address', project.mapAddress!),
      if (project.projectStatus?.isNotEmpty == true)
        _InfoRow(Icons.flag_outlined, 'Status', project.projectStatus!),
      _InfoRow(Icons.location_on_outlined, 'Location', project.location),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          if (project.projectCode?.isNotEmpty == true) ...[
            _buildProjectCodeChip(project.projectCode!),
            const AppDivider(verticalPadding: 10),
          ],
          ...rows
              .where((r) => r.label != 'Project Code')
              .map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              Icon(r.icon, color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.label,
                                  style: AppTheme.caption.copyWith(
                                      fontSize: 10, letterSpacing: 0.5)),
                              Text(r.value,
                                  style: AppTheme.body.copyWith(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _buildProjectCodeChip(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.18), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Project Code',
                    style:
                        AppTheme.caption.copyWith(fontSize: 10, letterSpacing: 0.4)),
                Text('Auto-generated',
                    style: AppTheme.caption
                        .copyWith(fontSize: 9, color: AppColors.textLight)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(code,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;
}

// ── Building Type Card ────────────────────────────────────────────────────────
class _BuildingTypeCard extends StatelessWidget {
  const _BuildingTypeCard({required this.project});
  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    final raw = project.projectType ?? '';
    final parts = raw.split(' → ');
    final mainType = parts.isNotEmpty ? parts[0].trim() : raw;
    final subType = parts.length > 1 ? parts[1].trim() : null;
    final IconData mainIcon = _iconForType(mainType);

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(mainIcon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Main Type',
                        style: AppTheme.caption
                            .copyWith(fontSize: 10, letterSpacing: 0.5)),
                    Text(mainType,
                        style: AppTheme.body.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              if (subType != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(subType,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
            ],
          ),
          if (subType != null) ...[
            const AppDivider(verticalPadding: 10),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.category_outlined,
                      color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sub Type',
                          style: AppTheme.caption
                              .copyWith(fontSize: 10, letterSpacing: 0.5)),
                      Text(subType,
                          style: AppTheme.body.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Residential':    return Icons.home_rounded;
      case 'Educational':    return Icons.school_rounded;
      case 'Institutional':  return Icons.account_balance_rounded;
      case 'Business / Commercial': return Icons.store_rounded;
      case 'Industrial':     return Icons.factory_rounded;
      default:               return Icons.apartment_rounded;
    }
  }
}

// ── Land & Floors Card ────────────────────────────────────────────────────────
class _LandFloorsCard extends StatelessWidget {
  const _LandFloorsCard({required this.project});
  final ProjectModel project;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.landArea != null && project.landArea!.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.landscape_outlined,
                      color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Land Area',
                        style: AppTheme.caption.copyWith(fontSize: 10)),
                    Text('${project.landArea} ${project.landUnit ?? ""}',
                        style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (project.floors != null && project.floors!.isNotEmpty) ...[
            Text('Floors Included',
                style: AppTheme.caption
                    .copyWith(fontSize: 10, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: project.floors!
                  .map((f) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(f,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
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
      '1 BHK': project.room1BHK,
      '2 BHK': project.room2BHK,
      '3 BHK': project.room3BHK,
      'Custom': project.roomCustom,
    };
    final baths = <String, int?>{
      'Western': project.bathWestern,
      'Indian':  project.bathIndian,
      'Common':  project.bathCommon,
      'Attached': project.bathAttached,
    };
    Widget tile(String label, int? count, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$label ',
                  style: AppTheme.caption
                      .copyWith(fontSize: 12, color: AppColors.textMedium)),
              Text('${count ?? 0}',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, color: c)),
            ],
          ),
        );
    final roomTiles = rooms.entries
        .where((e) => (e.value ?? 0) > 0)
        .map((e) => tile(e.key, e.value, AppColors.primary))
        .toList();
    final bathTiles = baths.entries
        .where((e) => (e.value ?? 0) > 0)
        .map((e) => tile(e.key, e.value, const Color(0xFF00838F)))
        .toList();
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (roomTiles.isNotEmpty) ...[
            Text('ROOMS',
                style: AppTheme.caption.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: roomTiles),
            if (bathTiles.isNotEmpty) const SizedBox(height: 16),
          ],
          if (bathTiles.isNotEmpty) ...[
            Text('BATHROOMS',
                style: AppTheme.caption.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: bathTiles),
          ],
        ],
      ),
    );
  }
}

const _kAddlConfig = [
  'Balcony', 'Car Parking', 'Lift', 'Terrace Access', 'Interior Work',
  'Compound Wall', 'Parapet Wall', 'Waterproofing', 'Putty', 'False Ceiling',
  'Modular Kitchen', 'Wardrobes', 'Sump', 'Septic Tank', 'Rainwater',
  'Borewell', 'Solar', 'Generator', 'CCTV', 'Intercom', 'Landscaping',
  'Paving', 'Water Tanks', 'Stairs', 'Security Room', 'Cladding', 'Elevation',
  'Gates', 'Grills', 'Aluminium', 'Glass',
];
const _kUtility = [
  'Main Electricity', 'Temporary Connection', 'Generator Backup',
  'Water Connection', 'Borewell Motor', 'Sump Motor',
];
const _kGas = ['Piped Gas', 'Cylinder Bank', 'Gas Pipeline Routing'];
const _kKitchen = [
  'Granite Counter', 'Quartz Counter', 'Stainless Steel Sink',
  'Chimney Provision', 'Exhaust Fan Provision',
];
const _kElectrical = [
  'Concealed Wiring', 'Open Wiring', '3-Phase Connection', 'AC Points',
  'Geyser Points',
];
const _kTerrace = [
  'Weathering Course', 'Cool Roof Paint', 'Overhead Tank', 'Solar Panels',
];
List<String> _grp(List<String> all, List<String> opts) =>
    all.where(opts.contains).toList();

class _FeatureGroupCard extends StatefulWidget {
  const _FeatureGroupCard({
    required this.icon,
    required this.title,
    required this.features,
  });
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(widget.icon, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                        Text('${widget.features.length} selected',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const Divider(height: 1, color: Color(0xFFEEF0F5)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.features
                    .map((f) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.18)),
                          ),
                          child: Text(f,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Project Timeline & Status Card ────────────────────────────────────────────
class _ProjectTimelineCard extends StatelessWidget {
  const _ProjectTimelineCard({required this.project});
  final ProjectModel project;
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
  @override
  Widget build(BuildContext context) {
    final status = project.projectStatus;
    final statusColor = status == 'Completed'
        ? AppColors.success
        : status == 'In Progress'
        ? AppColors.primary
        : status == 'On Hold'
        ? AppColors.warning
        : status == 'Cancelled'
        ? AppColors.error
        : const Color(0xFF6B7280);
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null) ...[
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child:
                      Icon(Icons.flag_rounded, color: statusColor, size: 17),
                ),
                const SizedBox(width: 10),
                Text('Project Status',
                    style:
                        AppTheme.body.copyWith(color: AppColors.textMedium)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: statusColor)),
                ),
              ],
            ),
            const AppDivider(verticalPadding: 12),
          ],
          Text('PROJECT TIMELINE',
              style: AppTheme.caption.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              _dateBox('Start Date', _fmt(project.startDate),
                  Icons.play_circle_outline, AppColors.primary),
              if (project.expectedEndDate != null) ...[
                const SizedBox(width: 10),
                _dateBox('Expected End', _fmt(project.expectedEndDate!),
                    Icons.event_outlined, AppColors.warning),
              ],
            ],
          ),
          if (project.actualEndDate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _dateBox('Actual End Date', _fmt(project.actualEndDate!),
                    Icons.event_available_rounded, AppColors.success),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateBox(String label, String val, IconData icon, Color c) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: c, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTheme.caption
                            .copyWith(fontSize: 9, letterSpacing: 0.4)),
                    Text(val,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: c)),
                  ],
                ),
              ),
            ],
          ),
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
    final bMat = project.budgetMaterial ?? 0;
    final bLab = project.budgetLabour ?? 0;
    final bEq = project.budgetEquipment ?? 0;
    final bMisc = project.budgetMisc ?? 0;
    final hasBrk = bMat + bLab + bEq + bMisc > 0;
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL BUDGET',
                          style: AppTheme.caption.copyWith(
                              fontSize: 10,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textLight)),
                      Text(project.formattedBudget,
                          style: AppTheme.heading2
                              .copyWith(color: AppColors.primary, letterSpacing: -0.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const AppDivider(verticalPadding: 12),
          _frow('Spent Amount', project.formattedSpent,
              over ? AppColors.error : AppColors.primary, Icons.payments_outlined),
          const AppDivider(verticalPadding: 8),
          _frow(
              'Remaining',
              project.formattedRemaining,
              project.remainingBudget >= 0 ? AppColors.success : AppColors.error,
              Icons.savings_outlined),
          if (hasBrk) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFEEF0F8), height: 1),
            const SizedBox(height: 10),
            Text('BUDGET BREAKDOWN',
                style: AppTheme.caption.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (bMat > 0) ...[
              _catRow('Material', bMat, AppColors.primary, Icons.category_outlined),
              const AppDivider(verticalPadding: 6),
            ],
            if (bLab > 0) ...[
              _catRow('Labour', bLab, AppColors.info, Icons.people_outline_rounded),
              const AppDivider(verticalPadding: 6),
            ],
            if (bEq > 0) ...[
              _catRow('Equipment', bEq, const Color(0xFF7B3FE7),
                  Icons.precision_manufacturing_outlined),
              const AppDivider(verticalPadding: 6),
            ],
            if (bMisc > 0)
              _catRow('Miscellaneous', bMisc, AppColors.warning,
                  Icons.more_horiz_rounded),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget Used',
                  style: AppTheme.label
                      .copyWith(color: AppColors.textLight, letterSpacing: 0.3)),
              Text('${(util * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: util >= 1.0
                          ? AppColors.error
                          : util >= 0.8
                          ? AppColors.warning
                          : AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: util.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFEEF0F8),
              valueColor: AlwaysStoppedAnimation<Color>(
                util >= 1.0
                    ? AppColors.error
                    : util >= 0.8
                    ? AppColors.warning
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _frow(String label, String value, Color color, IconData icon) => Row(
        children: [
          Container(
            width: 34,
            height: 34,
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
              style: AppTheme.bodyLarge
                  .copyWith(fontWeight: FontWeight.w800, color: color)),
        ],
      );

  Widget _catRow(String label, double amount, Color c, IconData icon) => Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: c, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: AppTheme.body
                    .copyWith(color: AppColors.textMedium, fontSize: 13)),
          ),
          Text(formatCurrency(amount),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: c)),
        ],
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// RECENT ENTRIES SECTION
// FIX: Filter entries to show only the current user's own entries.
//      Admins see all entries (no filter); non-admins see only their own.
// ══════════════════════════════════════════════════════════════════════════════
class _RecentEntriesSection extends StatelessWidget {
  const _RecentEntriesSection({
    required this.project,
    required this.provider,
    this.currentUserId,
  });
  final ProjectModel project;
  final ProjectProvider provider;
  // FIX: userId passed in from ProjectDetailScreen via UserSession.userId
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final isAdmin = UserSession.isAdmin;

    // FIX: Admins see all entries; non-admins see only their own
    final allEntries = provider.entriesForProject(project.id).toList();
    final filtered = isAdmin
        ? allEntries
        : (currentUserId != null && currentUserId!.isNotEmpty)
            ? allEntries
                .where((e) => e.createdBy == currentUserId)
                .toList()
            : allEntries;

    // Sort newest first, take 3 for the preview
    filtered.sort((a, b) => b.date.compareTo(a.date));
    final entries = filtered.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          // FIX: label differentiates admin vs user view
          title: isAdmin ? 'Recent Entries' : 'My Recent Entries',
          actionLabel: entries.isEmpty ? null : 'View All',
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _AllProjectEntriesScreen(
                  project: project,
                  provider: provider,
                  currentUserId: currentUserId,
                  isAdmin: isAdmin,
                ),
              ),
            );
          },
        ),
        if (entries.isEmpty)
          const AppEmptyState(
            icon: Icons.receipt_long_outlined,
            message: 'No entries logged yet.',
          )
        else
          ...entries.map((e) => _EntryTile(entry: e)),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final EntryModel entry;
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  (Color, IconData) _style(EntryType t) {
    switch (t) {
      case EntryType.material:
        return (AppColors.primary, Icons.category_outlined);
      case EntryType.labour:
        return (AppColors.info, Icons.people_outline);
      case EntryType.equipment:
        return (const Color(0xFF7B3FE7), Icons.construction_outlined);
    }
  }

  void _navigateToDetailFallback(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/entry-detail',
      arguments: {
        'id': entry.id,
        'title': entry.description.isEmpty
            ? entry.type.name.toUpperCase()
            : entry.description,
        'ref': entry.id.length > 4
            ? '#${entry.id.substring(entry.id.length - 4)}'
            : '#${entry.id}',
        'amount': '+${entry.amount}',
        'date': entry.date.toIso8601String(),
        'isPositive': true,
        'type': entry.type.name,
        'name': entry.description.isEmpty
            ? entry.type.name.toUpperCase()
            : entry.description,
        'projectId': entry.projectId,
        'status': 'pending',
        'paymentStatus': PaymentStatus.pending,
        'billAmount': entry.amount,
        'paidAmount': 0.0,
      },
    ).then((_) {
      if (context.mounted) {
        context.read<ProjectProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style(entry.type);
    final d = entry.date;
    final dateStr = '${d.day} ${_months[d.month - 1]} ${d.year}';
    return GestureDetector(
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (lCtx) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );

        try {
          final response = await ApiService.get('/transactions');
          if (context.mounted) Navigator.pop(context);

          if (response.statusCode == 200) {
            final decoded = json.decode(response.body);
            List<dynamic> raw = [];
            if (decoded is List) {
              raw = decoded;
            } else if (decoded is Map) {
              raw = (decoded['transactions'] ??
                      decoded['data'] ??
                      decoded['items'] ??
                      []) as List<dynamic>;
            }

            Map<String, dynamic>? matched;
            for (final t in raw) {
              final tId = t['_id']?.toString() ?? '';
              if (tId == entry.id) {
                matched = Map<String, dynamic>.from(t);
                break;
              }
            }

            if (matched != null) {
              String? statusStr = matched['paymentStatus']?.toString();
              PaymentStatus payStatus = PaymentStatus.pending;
              if (statusStr != null) {
                final lower = statusStr.trim().toLowerCase();
                if (lower == 'paid') payStatus = PaymentStatus.paid;
                if (lower == 'partial') payStatus = PaymentStatus.partial;
                if (lower == 'overdue') payStatus = PaymentStatus.overdue;
              }

              final String rawCat =
                  (matched['category'] ?? '').toString().trim().toLowerCase();
              final String rawType =
                  (matched['type'] ?? '').toString().trim().toLowerCase();

              String category = 'material';
              if (rawCat == 'labour' ||
                  rawCat == 'wages' ||
                  rawCat == 'labor' ||
                  rawCat.contains('labour') ||
                  rawType == 'wages' ||
                  rawType == 'labour') {
                category = 'labour';
              } else if (rawCat == 'equipment' ||
                  rawCat == 'machinery' ||
                  rawCat == 'expense' ||
                  rawType == 'expense' ||
                  rawType == 'equipment') {
                category = 'equipment';
              }

              bool isPositive = true;
              if (matched['subType']?.toString().toLowerCase() == 'consumption') {
                isPositive = false;
              }

              final String tId = matched['_id']?.toString() ?? '';
              final String ref = tId.length > 4
                  ? '#${tId.substring(tId.length - 4)}'
                  : '#${tId.isNotEmpty ? tId : DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

              final Map<String, dynamic> mappedArgs = {
                ...matched,
                'id': tId,
                'title': matched['title'] ?? matched['materialName'] ?? 'Unknown',
                'ref': ref,
                'amount': '${isPositive ? "+" : "-"}${matched['quantity'] ?? 0}',
                'date': matched['date'] ?? '',
                'isPositive': isPositive,
                'type': category,
                'name': matched['title'] ?? matched['materialName'] ?? 'Unknown',
                'receipt': (matched['attachments'] is List &&
                        matched['attachments'].isNotEmpty)
                    ? matched['attachments'].first?.toString()
                    : null,
                'attachment': null,
                'createdBy': matched['createdBy'] ?? '',
                'projectId': entry.projectId,
                'status': matched['status'] ?? 'pending',
                'paymentStatus': payStatus,
                'billAmount': (matched['amount'] ?? 0).toDouble(),
                'paidAmount': (matched['paidAmount'] ?? 0).toDouble(),
                'supplier': matched['supplier'] ?? '',
                'paymentMethod': matched['paymentMode'] ?? '',
                'lastUpdated': matched['updatedAt'] ?? matched['date'] ?? '',
                'paymentHistory': matched['paymentHistory'],
                'rate': (matched['rate'] ?? 0).toDouble(),
                'brand': matched['brand'] ?? '',
                'notes': matched['notes'] ?? '',
                'remarks': matched['remarks'] ?? '',
                'categoryName': matched['category'] ?? '',
                'quantity': (matched['quantity'] ?? 0).toDouble(),
                'overtime': (matched['overtime'] ?? 0).toDouble(),
                'subType': matched['subType'] ?? '',
                'materialType': matched['materialType'] ?? '',
              };

              if (context.mounted) {
                Navigator.pushNamed(
                  context,
                  '/entry-detail',
                  arguments: mappedArgs,
                ).then((_) {
                  if (context.mounted) {
                    context.read<ProjectProvider>().load();
                  }
                });
              }
            } else {
              if (context.mounted) _navigateToDetailFallback(context);
            }
          } else {
            if (context.mounted) _navigateToDetailFallback(context);
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context);
            _navigateToDetailFallback(context);
          }
        }
      },
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
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
                  Text(
                    entry.description.isEmpty
                        ? entry.type.label.toUpperCase()
                        : entry.description,
                    style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  Text(dateStr, style: AppTheme.caption),
                ],
              ),
            ),
            Text(
              formatCurrency(entry.amount),
              style: AppTheme.bodyLarge
                  .copyWith(fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ACTION BUTTONS
// FIX: All three buttons are permission-gated via RoleManager.
// ══════════════════════════════════════════════════════════════════════════════
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.project});
  final ProjectModel project;

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Text('Delete Project',
                style: AppTheme.heading2.copyWith(color: AppColors.textDark)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${project.name}"? This action '
          'cannot be undone and all associated entries will be permanently removed.',
          style: AppTheme.bodyLarge.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textLight, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (lCtx) => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              );
              final success = await ApiService.deleteProject(project.id);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Project deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await context.read<ProjectProvider>().load();
                  if (context.mounted) Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete project'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAddEntry = RoleManager.canManageExpenses;
    final canEdit     = RoleManager.canEditProject;
    final canDelete   = RoleManager.canDeleteProject;

    if (!canAddEntry && !canEdit && !canDelete) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.lock_outline,
                color: AppColors.textLight, size: 18),
            const SizedBox(width: 10),
            Text('No project actions permitted',
                style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (canAddEntry) ...[
          AppButton(
            label: 'Add Entry',
            icon: Icons.add_circle_outline,
            onPressed: () => Navigator.pushNamed(context, '/add-entry'),
          ),
          const SizedBox(height: 10),
        ],
        if (canEdit) ...[
          AppButton(
            label: 'Edit Project',
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.outline,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditProjectScreen(project: project)),
              ).then((_) => context.read<ProjectProvider>().load());
            },
          ),
          const SizedBox(height: 10),
        ],
        if (canDelete)
          AppButton(
            label: 'Delete Project',
            icon: Icons.delete_outline_outlined,
            variant: AppButtonVariant.danger,
            onPressed: () => _showDeleteConfirmation(context),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ALL ENTRIES SCREEN
// FIX: Filters entries by current user (non-admins see only their own).
//      Edit icon in top bar hidden unless user has edit_project permission.
// ══════════════════════════════════════════════════════════════════════════════
class _AllProjectEntriesScreen extends StatelessWidget {
  const _AllProjectEntriesScreen({
    required this.project,
    required this.provider,
    this.currentUserId,
    this.isAdmin = false,
  });

  final ProjectModel project;
  final ProjectProvider provider;
  final String? currentUserId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    // FIX: admins see all entries; others see only their own
    final allEntries = provider.entriesForProject(project.id).toList();
    final entries = isAdmin
        ? allEntries
        : (currentUserId != null && currentUserId!.isNotEmpty)
            ? allEntries
                .where((e) => e.createdBy == currentUserId)
                .toList()
            : allEntries;

    entries.sort((a, b) => b.date.compareTo(a.date));

    final canEdit = RoleManager.canEditProject;

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
              // FIX: edit icon only shown when user has edit_project permission
              rightWidget: canEdit
                  ? IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.primary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  EditProjectScreen(project: project)),
                        ).then(
                            (_) => context.read<ProjectProvider>().load());
                      },
                    )
                  : null,
            ),
            Expanded(
              child: entries.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: 'No entries logged yet.',
                    )
                  : ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _EntryTile(entry: entries[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryDialog extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _GalleryDialog({required this.photos, required this.initialIndex});

  @override
  State<_GalleryDialog> createState() => _GalleryDialogState();
}

class _GalleryDialogState extends State<_GalleryDialog> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Semi-transparent backdrop
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black.withValues(alpha: 0.9),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // PageView for swipeable images
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              final photoUrl = widget.photos[index];
              Widget imageWidget;
              if (photoUrl.startsWith('data:image/') && photoUrl.contains(';base64,')) {
                try {
                  final base64String = photoUrl.split(';base64,').last;
                  final bytes = base64.decode(base64String);
                  imageWidget = Image.memory(bytes, fit: BoxFit.contain);
                } catch (e) {
                  imageWidget = const Icon(Icons.broken_image, color: Colors.white, size: 48);
                }
              } else {
                imageWidget = Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, color: Colors.white, size: 48);
                  },
                );
              }
              return InteractiveViewer(
                maxScale: 4.0,
                minScale: 1.0,
                child: Center(child: imageWidget),
              );
            },
          ),
          // Floating Close Button (Top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Paging Indicator (Bottom)
          Positioned(
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.photos.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}