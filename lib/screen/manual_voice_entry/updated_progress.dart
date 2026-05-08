import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/models/construction_models.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UpdateProgressScreen extends StatefulWidget {
  const UpdateProgressScreen({super.key});
  @override
  State<UpdateProgressScreen> createState() => _UpdateProgressScreenState();
}

class _UpdateProgressScreenState extends State<UpdateProgressScreen> {
  static const primaryBlue = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;

  // ── Selection state ─────────────────────────────────────────────────────
  String? _selectedProjectId;
  String? _selectedFloor;
  String? _selectedPhaseName;
  String? _selectedActivityName;

  // ── Form state ──────────────────────────────────────────────────────────
  final TextEditingController _notesCtrl = TextEditingController();
  late double _completionProgress;
  DateTime _selectedDate = DateTime.now();
  PickedAttachment? _attachment;

  // ── Full phase catalogue (built once, used for activity lookup) ──────────
  late final List<ConstructionPhase> _catalogue;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _catalogue = buildDefaultPhases();
    _selectedProjectId = UserSession.projectId;
    final provider = context.read<ProjectProvider>();
    _completionProgress = provider.selectedProject?.progress ?? 0.0;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Derive phase names for the selected project ──────────────────────────
  List<String> _phasesFor(ProjectModel? project) {
    if (project == null) return [];
    // Use the project-configured phases if available, else full catalogue
    if (project.selectedPhaseNames != null &&
        project.selectedPhaseNames!.isNotEmpty) {
      return project.selectedPhaseNames!;
    }
    return _catalogue.map((p) => p.name).toList();
  }

  // ── Derive activities for selected phase ─────────────────────────────────
  List<String> _activitiesFor(String? phaseName) {
    if (phaseName == null) return [];
    final match = _catalogue.cast<ConstructionPhase?>().firstWhere(
      (p) => p?.name == phaseName,
      orElse: () => null,
    );
    if (match == null) return [];
    return match.allActivities.map((a) => a.name).toList();
  }

  // ── Build helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: primaryBlue,
            letterSpacing: 0.4,
          ),
        ),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.2,
          ),
        ),
      );

  Widget _dropdownCard<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool enabled = true,
  }) {
    final bool hasValue = items.any((i) => i.value == value);
    final T? safe = hasValue ? value : null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? (safe != null ? primaryBlue : const Color(0xFFE0E5FF))
                : const Color(0xFFE0E5FF),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: safe,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled ? primaryBlue : textGray,
              size: 22,
            ),
            hint: Text(
              hint,
              style: const TextStyle(
                  color: textGray, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
            items: enabled ? items : [],
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      // ← No AppBottomNav: this is a focused workflow route
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Update Progress',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Consumer<ProjectProvider>(
                builder: (context, provider, _) {
                  final projects = provider.projects;
                  final selProject = _selectedProjectId == null
                      ? null
                      : projects.cast<ProjectModel?>().firstWhere(
                          (p) => p?.id == _selectedProjectId,
                          orElse: () => null,
                        );

                  final floors = (selProject?.floors?.isNotEmpty ?? false)
                      ? List<String>.from(selProject!.floors!)
                      : ['Basement', 'Ground Floor', '1st Floor', '2nd Floor', 'Terrace'];
                  if (_selectedFloor != null && !floors.contains(_selectedFloor)) {
                    floors.add(_selectedFloor!);
                  }

                  final phaseNames = _phasesFor(selProject);
                  final activityNames = _activitiesFor(_selectedPhaseName);

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── EXECUTION CONTEXT CARD ──────────────────────
                        _buildContextCard(
                          projects: projects,
                          floors: floors,
                          phaseNames: phaseNames,
                          activityNames: activityNames,
                        ),
                        const SizedBox(height: 20),

                        // ── ACTIVE STAGE SUMMARY (shown after selection) ─
                        if (_selectedPhaseName != null && _selectedFloor != null) ...[
                          _buildStageSummaryCard(),
                          const SizedBox(height: 20),
                        ],

                        // ── EXECUTION NOTES ──────────────────────────────
                        _buildExecutionNotes(),
                        const SizedBox(height: 20),

                        // ── UPDATE DATE ──────────────────────────────────
                        _buildDateField(),
                        const SizedBox(height: 20),

                        // ── PROGRESS PHOTOS ──────────────────────────────
                        _buildPhotoUpload(),
                        const SizedBox(height: 20),

                        // ── MATERIAL CONSUMPTION ─────────────────────────
                        _buildMaterialConsumption(context, provider),
                        const SizedBox(height: 32),

                        // ── SUBMIT CTA ───────────────────────────────────
                        _buildSaveButton(context, provider),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EXECUTION CONTEXT CARD ───────────────────────────────────────────────
  Widget _buildContextCard({
    required List<ProjectModel> projects,
    required List<String> floors,
    required List<String> phaseNames,
    required List<String> activityNames,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: primaryBlue, size: 17),
              ),
              const SizedBox(width: 10),
              const Text(
                'EXECUTION CONTEXT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textGray,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Project
          _sectionLabel('Project'),
          _dropdownCard<String>(
            value: _selectedProjectId,
            hint: 'Select project',
            items: projects
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                .toList(),
            onChanged: (val) => setState(() {
              _selectedProjectId = val;
              _selectedFloor = null;
              _selectedPhaseName = null;
              _selectedActivityName = null;
              final p = projects.cast<ProjectModel?>()
                  .firstWhere((x) => x?.id == val, orElse: () => null);
              _completionProgress = p?.progress ?? 0.0;
            }),
          ),
          const SizedBox(height: 16),

          // 2. Floor / Zone
          _sectionLabel('Floor / Zone'),
          _dropdownCard<String>(
            value: _selectedFloor,
            hint: _selectedProjectId == null ? 'Select project first' : 'Select floor or zone',
            enabled: _selectedProjectId != null,
            items: floors
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: _selectedProjectId == null
                ? null
                : (val) => setState(() {
                      _selectedFloor = val;
                      _selectedPhaseName = null;
                      _selectedActivityName = null;
                    }),
          ),
          const SizedBox(height: 16),

          // 3. Phase (dynamic — from project's selectedPhaseNames)
          _sectionLabel('Phase'),
          _dropdownCard<String>(
            value: _selectedPhaseName,
            hint: _selectedFloor == null ? 'Select floor first' : 'Select phase',
            enabled: _selectedFloor != null,
            items: phaseNames
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: _selectedFloor == null
                ? null
                : (val) => setState(() {
                      _selectedPhaseName = val;
                      _selectedActivityName = null;
                    }),
          ),
          const SizedBox(height: 16),

          // 4. Activity (reactive on phase)
          _sectionLabel('Activity'),
          _dropdownCard<String>(
            value: _selectedActivityName,
            hint: _selectedPhaseName == null ? 'Select phase first' : 'Select activity',
            enabled: _selectedPhaseName != null && activityNames.isNotEmpty,
            items: activityNames.isEmpty && _selectedPhaseName != null
                ? [const DropdownMenuItem(value: '__none', child: Text('No activities configured'))]
                : activityNames
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
            onChanged: (_selectedPhaseName == null || activityNames.isEmpty)
                ? null
                : (val) => setState(() => _selectedActivityName = val),
          ),
        ],
      ),
    );
  }

  // ── ACTIVE STAGE SUMMARY ─────────────────────────────────────────────────
  Widget _buildStageSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ACTIVE EXECUTION CONTEXT',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Phase name + activity
          Text(
            _selectedPhaseName ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          if (_selectedActivityName != null) ...[
            const SizedBox(height: 4),
            Text(
              _selectedActivityName!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryBlue,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: textGray, size: 13),
              const SizedBox(width: 4),
              Text(
                _selectedFloor ?? '',
                style: const TextStyle(
                  color: textGray,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Completion slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OVERALL COMPLETION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: textGray,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '${(_completionProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 7,
              activeTrackColor: primaryBlue,
              inactiveTrackColor: const Color(0xFFE8ECF8),
              thumbColor: primaryBlue,
              overlayColor: primaryBlue.withValues(alpha: 0.10),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _completionProgress,
              onChanged: (v) => setState(() => _completionProgress = v),
            ),
          ),
        ],
      ),
    );
  }

  // ── EXECUTION NOTES ──────────────────────────────────────────────────────
  Widget _buildExecutionNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Execution Notes'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E5FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextField(
            controller: _notesCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'What work was completed today?',
              hintStyle: TextStyle(color: textGray, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: textDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── UPDATE DATE ──────────────────────────────────────────────────────────
  Widget _buildDateField() {
    final dateStr =
        '${_months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Update Date'),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: primaryBlue,
                    onPrimary: Colors.white,
                    onSurface: textDark,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E5FF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, color: primaryBlue, size: 19),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── PROGRESS PHOTOS ──────────────────────────────────────────────────────
  Widget _buildPhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Progress Photos'),
        UploadBox(
          attachment: _attachment,
          emptyLabel: 'Tap to add site photo or proof of work',
          onPicked: (a) => setState(() => _attachment = a),
          onRemove: () => setState(() => _attachment = null),
        ),
      ],
    );
  }

  // ── MATERIAL CONSUMPTION ─────────────────────────────────────────────────
  Widget _buildMaterialConsumption(
      BuildContext context, ProjectProvider provider) {
    List<EntryModel> materials = [];
    if (_selectedProjectId != null && _selectedFloor != null) {
      materials = provider.entries
          .where((e) =>
              e.type == EntryType.material &&
              e.projectId == _selectedProjectId &&
              e.floor == _selectedFloor)
          .toList();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MATERIAL CONSUMPTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textGray,
                  letterSpacing: 0.7,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/add-material',
                  arguments: {'type': 'material'},
                ),
                child: const Text(
                  'ADD MATERIAL',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (materials.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No materials logged for this location yet.',
                style: TextStyle(color: textGray, fontStyle: FontStyle.italic, fontSize: 13),
              ),
            )
          else
            ...materials.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _materialTag(m.description, m.amount.toString()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _materialTag(String label, String qty) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: textDark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF0FF),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            qty,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ── SUBMIT CTA ───────────────────────────────────────────────────────────
  Widget _buildSaveButton(BuildContext context, ProjectProvider provider) {
    return GestureDetector(
      onTap: () async {
        final project = provider.selectedProject;
        if (project != null) {
          await provider.updateProjectProgress(project.id, _completionProgress);
        }
        if (context.mounted) Navigator.maybePop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: AppGradients.primaryButton,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Submit Progress Update',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
