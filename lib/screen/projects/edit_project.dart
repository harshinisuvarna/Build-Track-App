// ════════════════════════════════════════════════════════════════════════════
// CHANGES FROM ORIGINAL — search "FIX 4" to find every change:
//
//  FIX 4a  Added `_currentProject` — holds the freshest ProjectModel we have
//          (updated whenever `_populateFrom` runs, including after the API
//          refetch). `_save()` now builds on top of THIS instead of the
//          stale `widget.project` that was passed into the widget. This is
//          the root cause of "edit doesn't retain everything": any field not
//          present on the edit form (selectedPhases, trackedActivityKeys,
//          etc.) was being overwritten with old/blank data on every save.
//
//  FIX 4b  Added `_existingActivityById` — a lookup of every activity the
//          project already had tracked (built from selectedPhases), keyed by
//          activity id. Used to restore `completed` / `completedAt` when the
//          phases list is rebuilt for saving, so re-saving an edit doesn't
//          un-complete already-finished activities.
//
//  FIX 4c  Added the full "Construction Phases" section (mirrors AddProject
//          screen): _phases state, _buildConstructionPhasesCard,
//          _buildPhaseAccordion, _showAddCustomStageDialog,
//          _showAddCustomActivityDialog. On load, `_populateFrom` now merges
//          the project's existing selectedPhases (including any custom
//          phases/activities the user previously added) into the full phase
//          list, so editing shows everything that's actually tracked instead
//          of nothing.
//
//  FIX 4d  `_save()` now rebuilds selectedPhaseNames / trackedActivityKeys /
//          selectedPhases / completedActivityKeys from the current `_phases`
//          state (preserving completed status via _existingActivityById) and
//          includes them in the saved ProjectModel.
//
// NOTE: This assumes `ProjectActivity` has `completed` (bool) and
// `completedAt` (DateTime?) fields available in its constructor — this is
// confirmed by ProjectProvider's `current.copyWith(completed: true,
// completedAt: stampedDate)` usage. If your constructor only exposes these
// via `copyWith` (not directly), change the two ProjectActivity(...) calls
// below to construct first then `.copyWith(completed: ..., completedAt: ...)`.
// ════════════════════════════════════════════════════════════════════════════

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/construction_models.dart'; // FIX 4c
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProjectScreen extends StatefulWidget {
  const EditProjectScreen({super.key, required this.project});
  final ProjectModel project;
  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  static const primaryBlue = AppColors.primary;
  static const bgColor = AppColors.gradientStart;
  static const textDark = AppColors.textDark;
  static const textGray = AppColors.textLight;

  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _mapAddressCtrl;
  late final TextEditingController _clientCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _contractorCtrl;
  late final TextEditingController _engineerCtrl;
  late final TextEditingController _landAreaCtrl;
  late final TextEditingController _budgetMaterialCtrl;
  late final TextEditingController _budgetLabourCtrl;
  late final TextEditingController _budgetEquipmentCtrl;
  late final TextEditingController _budgetMiscCtrl;
  late final TextEditingController _customSubTypeCtrl;
  final _customStageNameCtrl = TextEditingController(); // FIX 4c

  // State
  late DateTime _startDate;
  DateTime? _expectedEndDate;
  late String _projectStatus;
  late String _landUnit;

  String? _mainBuildingType;
  String? _buildingSubType;
  bool _isCustomSubType = false;
  String? _buildingTypeError;

  late List<String> _selectedFloorChips;

  late int _room1BHKCount, _room2BHKCount, _room3BHKCount, _roomCustomCount;
  late int _bathWesternCount, _bathIndianCount, _bathCommonCount, _bathAttachedCount;
  late Set<String> _additionalConfigs;

  // FIX 4a: the freshest project data we have — used as the merge base on save
  // instead of the (possibly stale) widget.project passed into this screen.
  late ProjectModel _currentProject;

  // FIX 4c: full construction phases list (defaults + any custom ones the
  // project already has), with isSelected reflecting what's tracked.
  late List<ConstructionPhase> _phases;

  // FIX 4b: lookup of already-tracked activities by id, so completed/
  // completedAt survives being rebuilt on save.
  Map<String, ProjectActivity> _existingActivityById = {};

  bool _saving = false;
  bool _loading = true; // true while fetching fresh data from API
  bool _basicExpanded = true;
  bool _buildingExpanded = true;
  bool _landExpanded = true;
  bool _roomsExpanded = true;  // expanded so user can see existing data
  bool _addlExpanded = true;
  bool _utilityExpanded = true;
  bool _gasExpanded = true;
  bool _kitchenExpanded = true;
  bool _electricalExpanded = true;
  bool _terraceExpanded = true;
  bool _datesExpanded = true;

  static const Map<String, List<String>> _buildingSubTypes = {
    'Residential': ['1 BHK', '2 BHK', '3 BHK', 'Villa', 'Apartment', 'Other (Custom)'],
    'Educational': ['School', 'College', 'Other (Custom)'],
    'Institutional': ['Church', 'Presbytery', 'Convention Hall', 'Other (Custom)'],
    'Commercial': ['Shop', 'Office', 'Complex', 'Plaza', 'Other (Custom)'],
    'Industrial': ['Factory', 'Warehouse', 'Other (Custom)'],
  };

  final List<String> _statusOptions = ['Planning', 'In Progress', 'On Hold', 'Completed', 'Cancelled'];
  // FIX: chip options match exactly what we save to backend (short labels)
  final List<String> _floorChipOptions = ['Ground', '1st', '2nd', '3rd', '4th', 'Terrace', 'Head Room'];

  // Split option lists matching the create screen exactly
  static const _kAddlConfigEdit = [
    'Balcony','Car Parking','Lift','Terrace Access','Interior Work',
    'Compound Wall','Parapet Wall','Waterproofing','Putty','False Ceiling',
    'Modular Kitchen','Wardrobes','Sump','Septic Tank','Rainwater',
    'Borewell','Solar','Generator','CCTV','Intercom','Landscaping',
    'Paving','Water Tanks','Stairs','Security Room','Cladding',
    'Elevation','Gates','Grills','Aluminium','Glass',
  ];
  static const _kUtilityEdit = [
    'Main Electricity','Temporary Connection','Generator Backup',
    'Water Connection','Borewell Motor','Sump Motor',
  ];
  static const _kGasEdit = [
    'Piped Gas','Cylinder Bank','Gas Pipeline Routing',
  ];
  static const _kKitchenEdit = [
    'Granite Counter','Quartz Counter','Stainless Steel Sink',
    'Chimney Provision','Exhaust Fan Provision',
  ];
  static const _kElectricalEdit = [
    'Concealed Wiring','Open Wiring','3-Phase Connection',
    'AC Points','Geyser Points',
  ];
  static const _kTerraceEdit = [
    'Weathering Course','Cool Roof Paint','Overhead Tank','Solar Panels',
  ];

  // FIX: comprehensive floor normalization — handles every format the backend might send
  String _normalizeFloor(String f) {
    final lower = f.trim().toLowerCase();
    // Exact short-label matches (already correct)
    const shortLabels = ['Ground', '1st', '2nd', '3rd', '4th', 'Terrace', 'Head Room'];
    for (final label in shortLabels) {
      if (f.trim() == label) return label;
    }
    // Long-form variants
    if (lower.contains('ground')) return 'Ground';
    if (lower.startsWith('1') || lower.contains('first') || lower == '1st floor') return '1st';
    if (lower.startsWith('2') || lower.contains('second') || lower == '2nd floor') return '2nd';
    if (lower.startsWith('3') || lower.contains('third') || lower == '3rd floor') return '3rd';
    if (lower.startsWith('4') || lower.contains('fourth') || lower == '4th floor') return '4th';
    if (lower.contains('terrace')) return 'Terrace';
    if (lower.contains('head') || lower.contains('room')) return 'Head Room';
    // Return as-is and let the chip check handle it
    return f.trim();
  }

  // FIX: map backend status strings to UI display labels
  // Backend stores: 'Active', 'On Hold', 'Completed', 'Review Needed' (see toJson)
  // UI shows: 'Planning', 'In Progress', 'On Hold', 'Completed', 'Cancelled'
  String _resolveStatus(String? raw) {
    if (raw == null || raw.isEmpty) return 'Planning';
    final lower = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    // Handle backend-mapped values (from toJson)
    if (lower == 'active') return 'In Progress';
    if (lower == 'onhold') return 'On Hold';
    if (lower == 'completed') return 'Completed';
    if (lower == 'reviewneeded') return 'On Hold';
    // Handle UI-direct values (if backend echoes them back unchanged)
    if (lower == 'planning') return 'Planning';
    if (lower == 'inprogress') return 'In Progress';
    if (lower == 'cancelled') return 'Cancelled';
    // Fuzzy fallbacks
    if (lower.contains('progress') || lower.contains('active')) return 'In Progress';
    if (lower.contains('hold')) return 'On Hold';
    if (lower.contains('complet')) return 'Completed';
    if (lower.contains('cancel')) return 'Cancelled';
    if (lower.contains('plan')) return 'Planning';
    // Try exact match with UI options as last resort
    for (final opt in ['Planning', 'In Progress', 'On Hold', 'Completed', 'Cancelled']) {
      if (opt == raw.trim()) return opt;
    }
    return 'Planning';
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty/default values first
    _nameCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _mapAddressCtrl = TextEditingController();
    _clientCtrl = TextEditingController();
    _contactCtrl = TextEditingController();
    _contractorCtrl = TextEditingController();
    _engineerCtrl = TextEditingController();
    _landAreaCtrl = TextEditingController();
    _budgetMaterialCtrl = TextEditingController();
    _budgetLabourCtrl = TextEditingController();
    _budgetEquipmentCtrl = TextEditingController();
    _budgetMiscCtrl = TextEditingController();
    _customSubTypeCtrl = TextEditingController();
    _startDate = DateTime.now();
    _selectedFloorChips = [];
    _room1BHKCount = 0;
    _room2BHKCount = 0;
    _room3BHKCount = 0;
    _roomCustomCount = 0;
    _bathWesternCount = 0;
    _bathIndianCount = 0;
    _bathCommonCount = 0;
    _bathAttachedCount = 0;
    _additionalConfigs = {};
    _projectStatus = 'Planning';
    _landUnit = 'Sq ft';
    _currentProject = widget.project; // FIX 4a
    _phases = buildDefaultPhases(); // FIX 4c — merged properly inside _populateFrom

    // Pre-populate from passed project immediately, then fetch fresh from API
    _populateFrom(widget.project);
    _fetchFreshAndPopulate();
  }

  /// Populate all form fields from a [ProjectModel].
  void _populateFrom(ProjectModel p) {
    _currentProject = p; // FIX 4a — always keep the freshest project as our merge base

    _nameCtrl.text = p.name;
    _cityCtrl.text = p.city.isNotEmpty
        ? p.city
        : (p.location.isNotEmpty ? p.location : '');
    _mapAddressCtrl.text = p.mapAddress ?? '';
    _clientCtrl.text = p.clientName ?? '';
    _contactCtrl.text = p.contactNumber ?? '';
    _contractorCtrl.text = p.contractorName ?? '';
    _engineerCtrl.text = p.siteEngineer ?? '';
    _landAreaCtrl.text = p.landArea ?? '';
    _budgetMaterialCtrl.text =
        p.budgetMaterial != null && p.budgetMaterial! > 0
            ? p.budgetMaterial!.toStringAsFixed(0)
            : '';
    _budgetLabourCtrl.text =
        p.budgetLabour != null && p.budgetLabour! > 0
            ? p.budgetLabour!.toStringAsFixed(0)
            : '';
    _budgetEquipmentCtrl.text =
        p.budgetEquipment != null && p.budgetEquipment! > 0
            ? p.budgetEquipment!.toStringAsFixed(0)
            : '';
    _budgetMiscCtrl.text =
        p.budgetMisc != null && p.budgetMisc! > 0
            ? p.budgetMisc!.toStringAsFixed(0)
            : '';

    _startDate = p.startDate;
    _expectedEndDate = p.expectedEndDate;
    _projectStatus = _resolveStatus(p.projectStatus);

    _landUnit = p.landUnit ?? 'Sq ft';
    const landUnits = ['Sq ft', 'Sq m', 'Acres', 'Hectares'];
    if (!landUnits.contains(_landUnit)) _landUnit = 'Sq ft';

    // Building type
    _mainBuildingType = null;
    _buildingSubType = null;
    _isCustomSubType = false;
    _customSubTypeCtrl.clear();
    if (p.projectType != null && p.projectType!.isNotEmpty) {
      String raw = p.projectType!;
      if (raw.contains('Business / Commercial')) {
        raw = raw.replaceFirst('Business / Commercial', 'Commercial');
      } else if (raw.contains('Business/Commercial')) {
        raw = raw.replaceFirst('Business/Commercial', 'Commercial');
      }
      // Support both ' → ' (new) and ' / ' (legacy) separators
      final sepIndex = raw.contains('→')
          ? raw.indexOf('→')
          : raw.contains('/')
              ? raw.indexOf('/')
              : -1;
      if (sepIndex != -1) {
        final mainPart = raw.substring(0, sepIndex).trim();
        final subPart = raw.substring(sepIndex + 1).trim();
        // Only accept known main types
        if (_buildingSubTypes.containsKey(mainPart)) {
          _mainBuildingType = mainPart;
          if (subPart.isNotEmpty && subPart != 'General') {
            final knownSubs = _buildingSubTypes[mainPart] ?? [];
            if (knownSubs.contains(subPart)) {
              _buildingSubType = subPart;
              _isCustomSubType = false;
            } else {
              _isCustomSubType = true;
              _customSubTypeCtrl.text = subPart;
            }
          }
        }
      } else {
        // No separator — the whole string is just the main type
        if (_buildingSubTypes.containsKey(raw.trim())) {
          _mainBuildingType = raw.trim();
        }
      }
    }

    // Floors
    final rawFloors = p.floors ?? [];
    _selectedFloorChips = rawFloors
        .map((f) => _normalizeFloor(f))
        .where((f) => _floorChipOptions.contains(f))
        .toList();

    // Rooms & bathrooms
    _room1BHKCount = p.room1BHK ?? 0;
    _room2BHKCount = p.room2BHK ?? 0;
    _room3BHKCount = p.room3BHK ?? 0;
    _roomCustomCount = p.roomCustom ?? 0;
    _bathWesternCount = p.bathWestern ?? 0;
    _bathIndianCount = p.bathIndian ?? 0;
    _bathCommonCount = p.bathCommon ?? 0;
    _bathAttachedCount = p.bathAttached ?? 0;

    // Additional features
    _additionalConfigs = Set<String>.from(p.selectedFeatures ?? []);

    // ── FIX 4b/4c: Rebuild the full Construction Phases list, restoring
    // which phases/activities are already tracked for this project
    // (including any custom phases/activities), and remembering each
    // activity's completed/completedAt so we don't lose progress on save. ──
    _existingActivityById = {};
    final existingPhaseNames = <String>{};
    for (final ph in p.selectedPhases ?? <ProjectPhase>[]) {
      existingPhaseNames.add(ph.phaseName);
      for (final act in ph.activities) {
        _existingActivityById[act.id] = act;
      }
    }

    final freshPhases = buildDefaultPhases();

    // Mark default phases/activities as selected based on what's tracked.
    for (final phase in freshPhases) {
      bool phaseHasSelection = false;
      for (final act in phase.allActivities) {
        if (_existingActivityById.containsKey(act.key)) {
          act.isSelected = true;
          phaseHasSelection = true;
        }
      }
      if (phaseHasSelection || existingPhaseNames.contains(phase.name)) {
        phase.isSelected = true;
        phase.isExpanded = true;
      }
    }

    // Bring in any custom phases or custom activities under default phases
    // that aren't part of the built-in defaults.
    for (final ph in p.selectedPhases ?? <ProjectPhase>[]) {
      final idx = freshPhases.indexWhere((cp) => cp.name == ph.phaseName);
      if (idx == -1) {
        // Entirely custom phase
        final customPhase = ConstructionPhase(name: ph.phaseName, isCustom: true);
        customPhase.isSelected = true;
        customPhase.isExpanded = true;
        for (final act in ph.activities) {
          final customAct = ConstructionActivity(
            key: act.id,
            name: act.name,
            isCustom: true,
          );
          customAct.isSelected = true;
          customPhase.activities.add(customAct);
        }
        freshPhases.add(customPhase);
      } else {
        // Default phase — add any activities not already in the defaults
        final matchPhase = freshPhases[idx];
        for (final act in ph.activities) {
          final alreadyThere =
              matchPhase.allActivities.any((a) => a.key == act.id);
          if (!alreadyThere) {
            final customAct = ConstructionActivity(
              key: act.id,
              name: act.name,
              isCustom: true,
            );
            customAct.isSelected = true;
            matchPhase.activities.add(customAct);
          }
        }
      }
    }

    _phases = freshPhases;
  }

  /// Fetch the latest project data from the API to ensure all fields are fresh.
  Future<void> _fetchFreshAndPopulate() async {
    try {
      final fresh = await ApiService.fetchProjectById(widget.project.id);
      if (fresh != null && mounted) {
        setState(() {
          _populateFrom(fresh);
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    // API call failed — just stop loading, keep whatever we already have
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _mapAddressCtrl.dispose();
    _clientCtrl.dispose();
    _contactCtrl.dispose();
    _contractorCtrl.dispose();
    _engineerCtrl.dispose();
    _landAreaCtrl.dispose();
    _budgetMaterialCtrl.dispose();
    _budgetLabourCtrl.dispose();
    _budgetEquipmentCtrl.dispose();
    _budgetMiscCtrl.dispose();
    _customSubTypeCtrl.dispose();
    _customStageNameCtrl.dispose(); // FIX 4c
    super.dispose();
  }

  Future<void> _pickDate({required DateTime initial, required ValueChanged<DateTime> onPicked}) async {
    final savedOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => onPicked(picked));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(savedOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mainBuildingType == null) {
      setState(() => _buildingTypeError = 'Please select a Building Type');
      return;
    }
    setState(() => _saving = true);
    try {
      double parseBudget(TextEditingController c) => double.tryParse(c.text) ?? 0.0;
      final bMat = parseBudget(_budgetMaterialCtrl);
      final bLab = parseBudget(_budgetLabourCtrl);
      final bEq = parseBudget(_budgetEquipmentCtrl);
      final bMisc = parseBudget(_budgetMiscCtrl);
      final budgetTotal = bMat + bLab + bEq + bMisc;

      String? nn(String s) => s.trim().isEmpty ? null : s.trim();

      String? effectiveSubType = _buildingSubType;
      if (_isCustomSubType && _customSubTypeCtrl.text.trim().isNotEmpty) {
        effectiveSubType = _customSubTypeCtrl.text.trim();
      }
      String? buildingTypeStr;
      if (_mainBuildingType != null) {
        buildingTypeStr = effectiveSubType != null ? '$_mainBuildingType → $effectiveSubType' : _mainBuildingType;
      }

      // FIX: save exact chip labels — no conversion to long form
      final finalFloors = _selectedFloorChips.isEmpty ? <String>['Ground'] : List<String>.from(_selectedFloorChips);

      // ── FIX 4d: rebuild phases/activities from current _phases state,
      // preserving completed/completedAt for anything already tracked. ──
      final selectedPhaseNamesList =
          _phases.where((ph) => ph.isSelected).map((ph) => ph.name).toList();
      final trackedActivityKeysList = _phases
          .expand((ph) => ph.allActivities)
          .where((a) => a.isSelected)
          .map((a) => a.key)
          .toList();

      final existingPhasesByName = <String, ProjectPhase>{
        for (final ph in _currentProject.selectedPhases ?? <ProjectPhase>[])
          ph.phaseName: ph,
      };

      final selectedPhasesList = _phases
          .where((ph) => ph.isSelected && ph.allActivities.any((a) => a.isSelected))
          .map((ph) {
            final existingId = existingPhasesByName[ph.name]?.id;
            return ProjectPhase(
              id: existingId ??
                  'phase_${ph.name.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
              phaseName: ph.name,
              isCustom: ph.isCustom,
              activities: ph.allActivities.where((a) => a.isSelected).map((a) {
                final prev = _existingActivityById[a.key];
                return ProjectActivity(
                  id: a.key,
                  name: a.name,
                  isCustom: a.isCustom,
                  completed: prev?.completed ?? false,
                  completedAt: prev?.completedAt,
                );
              }).toList(),
            );
          })
          .toList();

      final completedActivityKeysList = selectedPhasesList
          .expand((ph) => ph.activities)
          .where((a) => a.completed)
          .map((a) => a.id)
          .toList();

      // FIX 4a: build on top of _currentProject (freshest data), not the
      // stale widget.project — otherwise fields not on this form (like
      // phases) would get reverted to whatever was passed in at open time.
      final updated = _currentProject.copyWith(
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        startDate: _startDate,
        sector: _currentProject.sector,
        mapAddress: nn(_mapAddressCtrl.text),
        clientName: nn(_clientCtrl.text),
        contactNumber: nn(_contactCtrl.text),
        contractorName: nn(_contractorCtrl.text),
        siteEngineer: nn(_engineerCtrl.text),
        landArea: nn(_landAreaCtrl.text),
        landUnit: _landUnit,
        floors: finalFloors,
        projectType: buildingTypeStr,
        expectedEndDate: _expectedEndDate,
        projectStatus: _projectStatus,
        budgetMaterial: bMat > 0 ? bMat : null,
        budgetLabour: bLab > 0 ? bLab : null,
        budgetEquipment: bEq > 0 ? bEq : null,
        budgetMisc: bMisc > 0 ? bMisc : null,
        totalBudget: budgetTotal > 0 ? budgetTotal : _currentProject.totalBudget,
        room1BHK: _room1BHKCount > 0 ? _room1BHKCount : null,
        room2BHK: _room2BHKCount > 0 ? _room2BHKCount : null,
        room3BHK: _room3BHKCount > 0 ? _room3BHKCount : null,
        roomCustom: _roomCustomCount > 0 ? _roomCustomCount : null,
        bathWestern: _bathWesternCount > 0 ? _bathWesternCount : null,
        bathIndian: _bathIndianCount > 0 ? _bathIndianCount : null,
        bathCommon: _bathCommonCount > 0 ? _bathCommonCount : null,
        bathAttached: _bathAttachedCount > 0 ? _bathAttachedCount : null,
        selectedFeatures: _additionalConfigs.isEmpty ? null : _additionalConfigs.toList(),
        selectedPhaseNames: selectedPhaseNamesList, // FIX 4d
        trackedActivityKeys: trackedActivityKeysList, // FIX 4d
        selectedPhases: selectedPhasesList, // FIX 4d
        completedActivityKeys: completedActivityKeysList, // FIX 4d
      );

      await context.read<ProjectProvider>().updateProject(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Edit Project', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark, letterSpacing: -0.4)),
                  const Spacer(),
                  if (_currentProject.projectCode != null && _currentProject.projectCode!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(_currentProject.projectCode!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryBlue)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Loading indicator while fetching fresh data from API
            if (_loading)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Loading latest project data…',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryBlue),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PROJECT SETUP
                      _buildSectionCard(
                        title: 'Project Setup',
                        icon: Icons.business_center_rounded,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('Project Name'),
                          const SizedBox(height: 8),
                          _field(controller: _nameCtrl, hint: 'e.g. Skyline Towers', icon: Icons.apartment_rounded, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          _label('City'),
                          const SizedBox(height: 8),
                          _field(controller: _cityCtrl, hint: 'e.g. Bengaluru', icon: Icons.location_city_rounded, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // BASIC INFORMATION
                      _buildAccordion(
                        title: 'Basic Information',
                        isExpanded: _basicExpanded,
                        onToggle: () => setState(() => _basicExpanded = !_basicExpanded),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('Map Address', icon: Icons.location_on_rounded),
                          const SizedBox(height: 8),
                          _field(controller: _mapAddressCtrl, hint: 'e.g. 12 Main St, Bengaluru', icon: Icons.place_rounded),
                          const SizedBox(height: 16),
                          _groupContainer(icon: Icons.person_rounded, title: 'Client Details', child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Client Name'), const SizedBox(height: 8), _field(controller: _clientCtrl, hint: 'Client / Owner', icon: Icons.person_outline_rounded)])),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Contact Number'), const SizedBox(height: 8), _field(controller: _contactCtrl, hint: '+91 XXXXX XXXXX', icon: Icons.phone_outlined, keyboardType: TextInputType.phone)])),
                          ])),
                          const SizedBox(height: 12),
                          _groupContainer(icon: Icons.engineering_rounded, title: 'Site Team', child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Site Engineer'), const SizedBox(height: 8), _field(controller: _engineerCtrl, hint: 'Engineer in charge', icon: Icons.construction_outlined)])),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Contractor Name'), const SizedBox(height: 8), _field(controller: _contractorCtrl, hint: 'Main contractor', icon: Icons.engineering_outlined)])),
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // BUILDING TYPE
                      _buildAccordion(
                        title: 'Building Type',
                        isExpanded: _buildingExpanded,
                        onToggle: () => setState(() => _buildingExpanded = !_buildingExpanded),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('Main Type'), const SizedBox(height: 8),
                              _buildDropdown(
                                value: _mainBuildingType,
                                hint: 'Select type',
                                items: _buildingSubTypes.keys.toList(),
                                onChanged: (val) => setState(() {
                                  _mainBuildingType = val;
                                  _buildingTypeError = null;
                                  _buildingSubType = null;
                                  _isCustomSubType = false;
                                  _customSubTypeCtrl.clear();
                                }),
                              ),
                            ])),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('Sub Type'), const SizedBox(height: 8),
                              _buildDropdown(
                                value: _isCustomSubType ? 'Other (Custom)' : _buildingSubType,
                                hint: _mainBuildingType == null ? 'Select main first' : 'Select sub type',
                                items: _mainBuildingType != null ? (_buildingSubTypes[_mainBuildingType!] ?? []) : [],
                                onChanged: _mainBuildingType == null ? null : (val) => setState(() {
                                  if (val == 'Other (Custom)') { _isCustomSubType = true; _buildingSubType = null; }
                                  else { _isCustomSubType = false; _buildingSubType = val; _customSubTypeCtrl.clear(); }
                                }),
                              ),
                            ])),
                          ]),
                          if (_isCustomSubType) ...[
                            const SizedBox(height: 12),
                            _label('Custom Sub Type', icon: Icons.edit_rounded),
                            const SizedBox(height: 8),
                            _field(controller: _customSubTypeCtrl, hint: 'e.g. Duplex, Penthouse...', icon: Icons.category_outlined),
                          ],
                          if (_buildingTypeError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
                                  const SizedBox(width: 6),
                                  Text(
                                    _buildingTypeError!,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade400),
                                  ),
                                ],
                              ),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // LAND & FLOORS
                      _buildAccordion(
                        title: 'Land & Floors',
                        isExpanded: _landExpanded,
                        onToggle: () => setState(() => _landExpanded = !_landExpanded),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('Land Area'), const SizedBox(height: 8),
                              _field(controller: _landAreaCtrl, hint: 'e.g. 2400', keyboardType: TextInputType.number),
                            ])),
                            const SizedBox(width: 12),
                            Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('Unit'), const SizedBox(height: 8),
                              _buildDropdown(
                                value: _landUnit,
                                hint: 'Unit',
                                items: const ['Sq ft', 'Sq m', 'Acres', 'Hectares'],
                                onChanged: (val) => setState(() => _landUnit = val ?? 'Sq ft'),
                              ),
                            ])),
                          ]),
                          const SizedBox(height: 20),
                          _label('Floors Included'),
                          const SizedBox(height: 12),
                          // FIX: show all floors, highlight those that are selected
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: _floorChipOptions.map((f) {
                              final sel = _selectedFloorChips.contains(f);
                              return GestureDetector(
                                onTap: () => setState(() => sel ? _selectedFloorChips.remove(f) : _selectedFloorChips.add(f)),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel ? primaryBlue : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: sel ? primaryBlue : const Color(0xFFEEF0F5), width: 1.5),
                                  ),
                                  child: Text(f, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? Colors.white : textGray)),
                                ),
                              );
                            }).toList(),
                          ),
                          // FIX: show count of selected floors for clarity
                          if (_selectedFloorChips.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              '${_selectedFloorChips.length} floor${_selectedFloorChips.length > 1 ? 's' : ''} selected: ${_selectedFloorChips.join(', ')}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryBlue.withValues(alpha: 0.8)),
                            ),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // ROOMS & BATHROOMS
                      _buildAccordion(
                        title: 'Rooms & Bathrooms',
                        isExpanded: _roomsExpanded,
                        onToggle: () => setState(() => _roomsExpanded = !_roomsExpanded),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('ROOM TYPES', uppercase: true), const SizedBox(height: 16),
                          _counter('1 BHK', _room1BHKCount, onInc: () => setState(() => _room1BHKCount++), onDec: () => setState(() { if (_room1BHKCount > 0) _room1BHKCount--; })),
                          const SizedBox(height: 12),
                          _counter('2 BHK', _room2BHKCount, onInc: () => setState(() => _room2BHKCount++), onDec: () => setState(() { if (_room2BHKCount > 0) _room2BHKCount--; })),
                          const SizedBox(height: 12),
                          _counter('3 BHK', _room3BHKCount, onInc: () => setState(() => _room3BHKCount++), onDec: () => setState(() { if (_room3BHKCount > 0) _room3BHKCount--; })),
                          const SizedBox(height: 12),
                          _counter('Custom Room', _roomCustomCount, onInc: () => setState(() => _roomCustomCount++), onDec: () => setState(() { if (_roomCustomCount > 0) _roomCustomCount--; })),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFEEF0F5), height: 1)),
                          _label('BATHROOM TYPES', uppercase: true), const SizedBox(height: 16),
                          _counter('Western', _bathWesternCount, onInc: () => setState(() => _bathWesternCount++), onDec: () => setState(() { if (_bathWesternCount > 0) _bathWesternCount--; })),
                          const SizedBox(height: 12),
                          _counter('Indian', _bathIndianCount, onInc: () => setState(() => _bathIndianCount++), onDec: () => setState(() { if (_bathIndianCount > 0) _bathIndianCount--; })),
                          const SizedBox(height: 12),
                          _counter('Common', _bathCommonCount, onInc: () => setState(() => _bathCommonCount++), onDec: () => setState(() { if (_bathCommonCount > 0) _bathCommonCount--; })),
                          const SizedBox(height: 12),
                          _counter('Attached', _bathAttachedCount, onInc: () => setState(() => _bathAttachedCount++), onDec: () => setState(() { if (_bathAttachedCount > 0) _bathAttachedCount--; })),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // ADDITIONAL CONFIGURATION
                      _buildAccordion(
                        title: 'Additional Configuration',
                        isExpanded: _addlExpanded,
                        onToggle: () => setState(() => _addlExpanded = !_addlExpanded),
                        child: _buildCheckboxGrid(_kAddlConfigEdit),
                      ),
                      const SizedBox(height: 16),

                      // UTILITY & SERVICES
                      _buildAccordion(
                        title: 'Utility & Services',
                        isExpanded: _utilityExpanded,
                        onToggle: () => setState(() => _utilityExpanded = !_utilityExpanded),
                        child: _buildCheckboxGrid(_kUtilityEdit),
                      ),
                      const SizedBox(height: 16),

                      // GAS CONNECTION
                      _buildAccordion(
                        title: 'Gas Connection',
                        isExpanded: _gasExpanded,
                        onToggle: () => setState(() => _gasExpanded = !_gasExpanded),
                        child: _buildCheckboxGrid(_kGasEdit),
                      ),
                      const SizedBox(height: 16),

                      // KITCHEN REQUIREMENTS
                      _buildAccordion(
                        title: 'Kitchen Requirements',
                        isExpanded: _kitchenExpanded,
                        onToggle: () => setState(() => _kitchenExpanded = !_kitchenExpanded),
                        child: _buildCheckboxGrid(_kKitchenEdit),
                      ),
                      const SizedBox(height: 16),

                      // ELECTRICAL & PLUMBING
                      _buildAccordion(
                        title: 'Electrical & Plumbing',
                        isExpanded: _electricalExpanded,
                        onToggle: () => setState(() => _electricalExpanded = !_electricalExpanded),
                        child: _buildCheckboxGrid(_kElectricalEdit),
                      ),
                      const SizedBox(height: 16),

                      // TERRACE & INTERIOR
                      _buildAccordion(
                        title: 'Terrace & Interior',
                        isExpanded: _terraceExpanded,
                        onToggle: () => setState(() => _terraceExpanded = !_terraceExpanded),
                        child: _buildCheckboxGrid(_kTerraceEdit),
                      ),
                      const SizedBox(height: 16),

                      // DATES, BUDGET & STATUS
                      _buildAccordion(
                        title: 'Dates, Budget & Status',
                        isExpanded: _datesExpanded,
                        onToggle: () => setState(() => _datesExpanded = !_datesExpanded),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('PROJECT TIMELINE', uppercase: true),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('Start Date'), const SizedBox(height: 8),
                              _datePicker(
                                date: _startDate,
                                onSelect: () => _pickDate(initial: _startDate, onPicked: (d) => _startDate = d),
                              ),
                            ])),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('Expected End'), const SizedBox(height: 8),
                              _datePicker(
                                date: _expectedEndDate,
                                hint: 'dd/mm/yyyy',
                                onSelect: () => _pickDate(
                                  initial: _expectedEndDate ?? DateTime.now(),
                                  onPicked: (d) => _expectedEndDate = d,
                                ),
                              ),
                            ])),
                          ]),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFEEF0F5), height: 1)),
                          _label('BUDGET BREAKDOWN', uppercase: true),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Material (₹)'), const SizedBox(height: 8), _field(controller: _budgetMaterialCtrl, hint: '₹ 0', keyboardType: TextInputType.number)])),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Labour (₹)'), const SizedBox(height: 8), _field(controller: _budgetLabourCtrl, hint: '₹ 0', keyboardType: TextInputType.number)])),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Equipment (₹)'), const SizedBox(height: 8), _field(controller: _budgetEquipmentCtrl, hint: '₹ 0', keyboardType: TextInputType.number)])),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Misc (₹)'), const SizedBox(height: 8), _field(controller: _budgetMiscCtrl, hint: '₹ 0', keyboardType: TextInputType.number)])),
                          ]),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFEEF0F5), height: 1)),
                          _label('PROJECT STATUS', uppercase: true),
                          const SizedBox(height: 16),
                          Wrap(spacing: 8, runSpacing: 8, children: _statusOptions.map((opt) {
                            final isSel = _projectStatus == opt;
                            final isCancel = opt == 'Cancelled';
                            return GestureDetector(
                              onTap: () => setState(() => _projectStatus = opt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? (isCancel ? const Color(0xFFFFF0F0) : primaryBlue.withValues(alpha: 0.1)) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSel ? (isCancel ? Colors.red.withValues(alpha: 0.5) : primaryBlue) : const Color(0xFFEEF0F5), width: 1.5),
                                ),
                                child: Text(opt, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSel ? (isCancel ? Colors.red : primaryBlue) : textGray)),
                              ),
                            );
                          }).toList()),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // CONSTRUCTION PHASES — FIX 4c
                      _buildConstructionPhasesCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: (_saving || _mainBuildingType == null) ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                disabledBackgroundColor: primaryBlue.withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
            ),
          ),
        ),
      ),
    );
  }

  // ── UI HELPERS ──

  Widget _groupContainer({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 14, color: primaryBlue), const SizedBox(width: 6), Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textDark, letterSpacing: 0.3))]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: primaryBlue, size: 20)),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDark)),
        ])),
        const Divider(height: 1, color: Color(0xFFEEF0F5)),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ]),
    );
  }

  Widget _buildAccordion({required String title, required bool isExpanded, required VoidCallback onToggle, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)]),
      child: Column(children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
            AnimatedRotation(turns: isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.keyboard_arrow_down_rounded, color: textGray, size: 24)),
          ])),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Column(children: [const Divider(height: 1, color: Color(0xFFEEF0F5)), Padding(padding: const EdgeInsets.all(16), child: child)]),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ]),
    );
  }

  Widget _label(String text, {IconData? icon, bool uppercase = false}) {
    final tw = Text(
      uppercase ? text.toUpperCase() : text,
      style: TextStyle(
        fontSize: uppercase ? 12 : 13,
        fontWeight: FontWeight.w800,
        color: uppercase ? textDark.withValues(alpha: 0.5) : textGray,
        letterSpacing: uppercase ? 1.2 : 0.3,
      ),
    );
    if (icon == null) return tw;
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: primaryBlue), const SizedBox(width: 6), tw]);
  }

  Widget _field({required TextEditingController controller, required String hint, IconData? icon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textDark),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: textGray.withValues(alpha: 0.5), fontSize: 14),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: textGray) : null,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEF0F5), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400, width: 2)),
      ),
    );
  }

  Widget _buildDropdown({required String? value, required String hint, required List<String> items, ValueChanged<String?>? onChanged}) {
    final bool disabled = onChanged == null;
    // FIX: guard against value not being in items list (would crash DropdownButton)
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return Container(
      height: 48, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: disabled ? const Color(0xFFF5F5F8) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: safeValue, isExpanded: true,
        hint: Text(hint, style: TextStyle(color: disabled ? textGray.withValues(alpha: 0.3) : textGray.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w600)),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: disabled ? textGray.withValues(alpha: 0.3) : textGray),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
        items: items.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      )),
    );
  }

  Widget _counter(String title, int value, {required VoidCallback onInc, required VoidCallback onDec}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark)),
      Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5)),
        child: Row(children: [
          GestureDetector(onTap: onDec, child: Container(width: 36, height: 36, color: Colors.transparent, child: const Icon(Icons.remove, size: 16, color: textGray))),
          Container(width: 36, alignment: Alignment.center, decoration: const BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Color(0xFFEEF0F5), width: 1.5))), child: Text(value.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark))),
          GestureDetector(onTap: onInc, child: Container(width: 36, height: 36, color: Colors.transparent, child: const Icon(Icons.add, size: 16, color: primaryBlue))),
        ]),
      ),
    ]);
  }

  Widget _buildCheckboxGrid(List<String> options) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final halfWidth = (constraints.maxWidth - 16) / 2;
      return Wrap(
        spacing: 16,
        runSpacing: 12,
        children: options.map((opt) => SizedBox(
          width: halfWidth,
          child: Row(children: [
            SizedBox(
              width: 24, height: 24,
              child: Checkbox(
                value: _additionalConfigs.contains(opt),
                onChanged: (v) => setState(() =>
                    v == true ? _additionalConfigs.add(opt) : _additionalConfigs.remove(opt)),
                activeColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: Color(0xFFDDE0E8), width: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(
              opt,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
            )),
          ]),
        )).toList(),
      );
    });
  }

  Widget _datePicker({DateTime? date, String? hint, required VoidCallback onSelect}) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        height: 48, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(
            date != null
                ? '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}'
                : (hint ?? 'Select'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: date != null ? textDark : textGray.withValues(alpha: 0.5)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          )),
          Icon(Icons.calendar_month_rounded, size: 14, color: textGray.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }

  // ── FIX 4c: Construction Phases UI (mirrors AddProjectScreen) ──

  Widget _buildConstructionPhasesCard() {
    final int total = _phases.fold(0, (s, p) => s + p.allActivities.length);
    final int done = _phases.fold(0, (s, p) => s + p.selectedCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Flexible(
                    child: Text(
                      'CONSTRUCTION PHASES',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      for (var p in _phases) {
                        p.isSelected = true;
                        for (var a in p.allActivities) {
                          a.isSelected = true;
                        }
                      }
                    }),
                    child: const Text(
                      'Select All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '|',
                    style: TextStyle(
                      fontSize: 12,
                      color: textGray.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      for (var p in _phases) {
                        p.isSelected = false;
                        for (var a in p.allActivities) {
                          a.isSelected = false;
                        }
                      }
                    }),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textGray.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select phases and activities tracked for this project.',
                style: TextStyle(
                  fontSize: 12,
                  color: textGray.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$done of $total activities selected',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: List.generate(
            _phases.length,
            (i) => _buildPhaseAccordion(i, _phases[i]),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showAddCustomStageDialog,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '+ Add Custom Phase',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseAccordion(int index, ConstructionPhase phase) {
    return Container(
      key: ValueKey('phase_${phase.name}_$index'),
      margin: EdgeInsets.only(bottom: index < _phases.length - 1 ? 8 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => phase.isExpanded = !phase.isExpanded),
            borderRadius: phase.isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      phase.isSelected = !phase.isSelected;
                      for (var a in phase.allActivities) {
                        a.isSelected = phase.isSelected;
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: phase.isSelected
                            ? primaryBlue
                            : Colors.transparent,
                        border: Border.all(
                          color: phase.isSelected
                              ? primaryBlue
                              : const Color(0xFFCDD0DA),
                          width: 1.5,
                        ),
                      ),
                      child: phase.isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      phase.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: phase.isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: textGray,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Color(0xFFEEF0F5)),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) => AnimatedBuilder(
                    animation: animation,
                    builder: (_, _) => Material(
                      color: Colors.transparent,
                      shadowColor: Colors.transparent,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                  ),
                  onReorder: (oldIndex, newIndex) => setState(() {
                    final list = phase.activities;
                    list.insert(newIndex, list.removeAt(oldIndex));
                  }),
                  itemCount: phase.allActivities.length,
                  itemBuilder: (_, idx) {
                    final act = phase.allActivities[idx];
                    return InkWell(
                      key: ValueKey(act.key),
                      onTap: () => setState(() {
                        act.isSelected = !act.isSelected;
                        if (act.isSelected) {
                          phase.isSelected = true;
                        } else {
                          if (!phase.allActivities.any((a) => a.isSelected)) {
                            phase.isSelected = false;
                          }
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: act.isSelected
                                    ? primaryBlue
                                    : Colors.transparent,
                                border: Border.all(
                                  color: act.isSelected
                                      ? primaryBlue
                                      : const Color(0xFFCDD0DA),
                                  width: 1.5,
                                ),
                              ),
                              child: act.isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                act.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: act.isSelected
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: act.isSelected
                                      ? textDark
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            ReorderableDragStartListener(
                              index: idx,
                              child: const Icon(
                                Icons.drag_indicator_rounded,
                                size: 20,
                                color: Color(0xFFDDE0E8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () => _showAddCustomActivityDialog(phase),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryBlue.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '+ Add Custom Activity',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            crossFadeState: phase.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  void _showAddCustomStageDialog() {
    _customStageNameCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Custom Phase',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textDark,
          ),
        ),
        content: TextField(
          controller: _customStageNameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter name',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primaryBlue, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFDDE0E8)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: textGray.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _customStageNameCtrl.text.trim();
              if (name.isEmpty) return;
              setState(
                () =>
                    _phases.add(ConstructionPhase(name: name, isCustom: true)),
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Add',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomActivityDialog(ConstructionPhase phase) {
    final ctrl = TextEditingController();
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Custom Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textDark,
          ),
        ),
        content: TextField(
          controller: ctrl,
          focusNode: focusNode,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter name',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primaryBlue, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFDDE0E8)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: textGray.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              setState(
                () => phase.activities.add(
                  ConstructionActivity(
                    key: '${phase.name}::Custom::$name',
                    name: name,
                    isCustom: true,
                  ),
                ),
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Add',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      ctrl.dispose();
      focusNode.dispose();
    });
  }
}