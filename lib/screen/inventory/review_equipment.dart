import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';
import 'package:buildtrack_mobile/common/widgets/voice_review_widgets.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/controller/entry_model.dart' as em;
import 'package:buildtrack_mobile/controller/inventory_provider.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:buildtrack_mobile/models/phase_model.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReviewEquipmentEntryScreen extends StatefulWidget {
  const ReviewEquipmentEntryScreen({super.key});
  @override
  State<ReviewEquipmentEntryScreen> createState() =>
      _ReviewEquipmentEntryScreenState();
}

class _ReviewEquipmentEntryScreenState
    extends State<ReviewEquipmentEntryScreen> {
  String _transcript =
      'Hey BuildTrack, log an equipment entry for the North District site. '
      'We used a JCB excavator for 6 hours today. Operator was Sunil Mehta. '
      'Rate is 850 rupees per hour. Fuel consumption was 45 litres. '
      'Log under foundation excavation on Ground Floor.';

  late final VoiceRecordingController _voiceCtrl;
  VoiceEntryState _voiceState = VoiceEntryState.processing;
  bool _animateReveal = false;

  String? _selectedProjectId;
  String? _selectedFloor;
  dynamic _selectedPhase;
  String? _selectedActivity;
  late TextEditingController _nameCtrl;
  late TextEditingController _vendorCtrl; // ← NEW: Vendor / Supplier
  late TextEditingController _ownershipCtrl; // ← NEW: Ownership Type (Owned / Rented / Leased)
  late TextEditingController _typeCtrl;
  late TextEditingController _operatorCtrl;
  late TextEditingController _hoursCtrl;
  late TextEditingController _fuelCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _notesCtrl;

  bool _isConfirming = false;
  PickedAttachment? _attachment;

  static const _extractionStages = [
    'Identifying equipment…',
    'Detecting usage hours…',
    'Extracting operator & fuel…',
    'Matching project context…',
    'Resolving phase & activity…',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _vendorCtrl = TextEditingController();
    _ownershipCtrl = TextEditingController(text: 'Owned');
    _typeCtrl = TextEditingController();
    _operatorCtrl = TextEditingController();
    _hoursCtrl = TextEditingController();
    _fuelCtrl = TextEditingController();
    _rateCtrl = TextEditingController();
    _notesCtrl = TextEditingController();

    _parseVoiceInput();

    _voiceCtrl = VoiceRecordingController();
    _voiceCtrl.addListener(_onVoiceChanged);

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _voiceState = VoiceEntryState.parsed;
        _animateReveal = true;
      });
    });
  }

  void _onVoiceChanged() {
    if (!mounted) return;
    final s = _voiceCtrl.engineState;
    if (s == VoiceEntryState.parsed && _voiceCtrl.finalTranscript.isNotEmpty) {
      _transcript = _voiceCtrl.finalTranscript;
      _parseVoiceInput();
      _animateReveal = true;
    }
    setState(() => _voiceState = s);
  }

  void _parseVoiceInput() {
    final t = _transcript.toLowerCase();

    String floor = 'Ground Floor';
    if (t.contains('1st floor')) floor = '1st Floor';
    if (t.contains('2nd floor')) floor = '2nd Floor';
    if (t.contains('basement')) floor = 'Basement';

    _nameCtrl.text = 'JCB Excavator';
    _vendorCtrl.text = 'JCB India Ltd';
    _ownershipCtrl.text = 'Rented';
    _typeCtrl.text = 'Heavy Equipment';
    _operatorCtrl.text = 'Sunil Mehta';
    _hoursCtrl.text = '6';
    _fuelCtrl.text = '45';
    _rateCtrl.text = '850';

    _selectedProjectId = UserSession.projectId;
    _selectedFloor = floor;
    _selectedActivity = 'Excavation';
  }

  @override
  void dispose() {
    _voiceCtrl.removeListener(_onVoiceChanged);
    _voiceCtrl.dispose();
    _nameCtrl.dispose();
    _vendorCtrl.dispose();
    _ownershipCtrl.dispose();
    _typeCtrl.dispose();
    _operatorCtrl.dispose();
    _hoursCtrl.dispose();
    _fuelCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _computedTotal {
    final hours = double.tryParse(_hoursCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    return hours * rate;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _handleMicTap() async {
    if (_voiceState == VoiceEntryState.error) {
      _voiceCtrl.reset();
      setState(() => _voiceState = VoiceEntryState.idle);
      return;
    }
    _animateReveal = false;
    await _voiceCtrl.startListening();
  }

  Future<void> _handleStopRecording() async => await _voiceCtrl.stopListening();
  Future<void> _handleCancelRecording() async =>
      await _voiceCtrl.cancelListening();

  List<ExtractedField> get _extractedFields => [
    ExtractedField(
      icon: Icons.precision_manufacturing_outlined,
      label: 'Equipment',
      value: _nameCtrl.text,
      isHighlight: true,
      confidence: 0.97,
    ),
    ExtractedField(
      icon: Icons.category_outlined,
      label: 'Type',
      value: _typeCtrl.text,
      isEmpty: _typeCtrl.text.isEmpty,
      confidence: 0.88,
    ),
    ExtractedField(
      icon: Icons.person_outlined,
      label: 'Operator',
      value: _operatorCtrl.text,
      isEmpty: _operatorCtrl.text.isEmpty,
      confidence: 0.85,
    ),
    ExtractedField(
      icon: Icons.av_timer_outlined,
      label: 'Usage Hours',
      value: '${_hoursCtrl.text} hrs',
      confidence: 0.94,
    ),
    ExtractedField(
      icon: Icons.local_gas_station_outlined,
      label: 'Fuel Used',
      value: '${_fuelCtrl.text} L',
      isEmpty: _fuelCtrl.text.isEmpty,
      confidence: 0.82,
    ),
    ExtractedField(
      icon: Icons.attach_money_outlined,
      label: 'Rate / Hour',
      value: '₹ ${_rateCtrl.text}',
      confidence: 0.93,
    ),
    ExtractedField(
      icon: Icons.layers_outlined,
      label: 'Floor / Zone',
      value: _selectedFloor ?? '',
      isEmpty: _selectedFloor == null,
      confidence: 0.72,
    ),
    ExtractedField(
      icon: Icons.task_alt_outlined,
      label: 'Activity',
      value: _selectedActivity ?? '',
      isEmpty: _selectedActivity == null,
      confidence: 0.65,
    ),
  ];

  Future<void> _confirm(BuildContext ctx) async {
    if (_selectedProjectId == null) {
      _snack('Please select a project');
      return;
    }
    if (_selectedFloor == null) {
      _snack('Please select a floor / zone');
      return;
    }
    if (_selectedPhase == null) {
      _snack('Please select a phase');
      return;
    }
    if (_selectedActivity == null) {
      _snack('Please select an activity');
      return;
    }

    setState(() => _isConfirming = true);
    if (!mounted) return;

    String entryId = 'VOICE-EQP-${DateTime.now().millisecondsSinceEpoch}';
    final double qty = double.tryParse(_hoursCtrl.text) ?? 0.0;
    final double rate = double.tryParse(_rateCtrl.text) ?? 0.0;

    final response = await ApiService.addTransaction({
      "title": _nameCtrl.text.trim(),
      "type": "Expense",
      "category": "Equipment",
      "quantity": qty,
      "rate": rate,
      "unit": "day",
      "project": _selectedProjectId!,
    });

    if (response != null && response['transaction'] != null) {
      final serverTx = response['transaction'];
      final sId = serverTx['_id']?.toString();
      if (sId != null && sId.isNotEmpty) {
        entryId = sId;
      }
    }

    // Save to inventory so the Inventory screen updates
    await ctx.read<InventoryProvider>().addToInventory(
      materialName: _nameCtrl.text.trim(),
      quantity: qty,
      unit: 'day',
      projectId: _selectedProjectId!,
      category: 'equipment',
    );

    final projectProvider = Provider.of<ProjectProvider>(ctx, listen: false);
    final ProjectModel? project = _selectedProjectId == null
        ? null
        : projectProvider.projects.cast<ProjectModel?>().firstWhere(
            (p) => p?.id == _selectedProjectId,
            orElse: () => null,
          );

    String? phaseId;
    if (_selectedPhase is PhaseModel) {
      phaseId = (_selectedPhase as PhaseModel).id;
    } else if (_selectedPhase is String) {
      final phaseStr = _selectedPhase as String;
      final match = project?.selectedPhases?.cast<ProjectPhase?>().firstWhere(
        (p) => p?.phaseName == phaseStr,
        orElse: () => null,
      );
      phaseId = match?.id;
    } else if (_selectedPhase is Map) {
      phaseId = (_selectedPhase['id'] ?? _selectedPhase['_id'])?.toString();
    }

    if (!mounted) return;
    ctx.read<ProjectProvider>().addEntry(
      EntryModel(
        id: entryId,
        projectId: _selectedProjectId!,
        type: EntryType.equipment,
        amount: qty,
        date: DateTime.now(),
        description: _nameCtrl.text,
        ratePerUnit: rate,
        floor: _selectedFloor!,
        phaseId: phaseId,
        unit: 'day',
      ),
    );

    Navigator.pushNamed(
      ctx,
      '/logs',
      arguments: {
        'type': 'equipment',
        'name': _nameCtrl.text,
        'newEntry':
            em.Entry(
              id: entryId,
              type: em.EntryType.equipment,
              projectId: _selectedProjectId!,
              createdBy: UserSession.userId,
            ).toMap()..addAll({
              'title': _nameCtrl.text,
              'ref': entryId.length > 4
                  ? '#${entryId.substring(entryId.length - 4)}'
                  : '#$entryId',
              'amount': '+$qty',
              'date': 'Today',
              'isPositive': true,
              'icon': Icons.precision_manufacturing_outlined,
              'attachment': _attachment,
              'receipt': _attachment?.name,
              'unit': 'day',
              'category': 'equipment',
              'billAmount': qty * rate,
              'paidAmount': 0.0,
              'paymentStatus': 'Pending',
              'paymentHistory': [],
            }),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = _voiceState == VoiceEntryState.processing;
    final isParsed = _voiceState == VoiceEntryState.parsed;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Review Voice Entry',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  children: [
                    VoiceStatusHeader(
                      state: _voiceState,
                      entryTypeLabel: 'Equipment',
                      confidence: 94.2,
                      onMicTap: _handleMicTap,
                      partialTranscript: _voiceCtrl.partialTranscript,
                      elapsedDisplay: _voiceCtrl.elapsedDisplay,
                      onStop: _handleStopRecording,
                      onCancel: _handleCancelRecording,
                    ),
                    if (isProcessing)
                      const ExtractionProcessingCard(stages: _extractionStages),
                    if (isParsed)
                      ExtractedDataSummaryCard(
                        fields: _extractedFields,
                        subtitle: 'Detected from your voice recording',
                        animateReveal: _animateReveal,
                      ),
                    if (isParsed) ExpandableTranscript(transcript: _transcript),
                    if (isParsed) ...[
                      ExecutionContextCard(
                        selectedProjectId: _selectedProjectId,
                        selectedFloor: _selectedFloor,
                        selectedPhase: _selectedPhase,
                        selectedActivity: _selectedActivity,
                        onProjectChanged: (v) => setState(() {
                          _selectedProjectId = v;
                          _selectedFloor = null;
                          _selectedPhase = null;
                          _selectedActivity = null;
                        }),
                        onFloorChanged: (v) => setState(() {
                          _selectedFloor = v;
                          _selectedPhase = null;
                          _selectedActivity = null;
                        }),
                        onPhaseChanged: (v) => setState(() {
                          _selectedPhase = v;
                          _selectedActivity = null;
                        }),
                        onActivityChanged: (v) =>
                            setState(() => _selectedActivity = v),
                      ),
                      EntrySectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EntryCardHeader(
                              icon: Icons.precision_manufacturing_outlined,
                              title: 'Equipment Details',
                              subtitle:
                                  'AI extracted — review and edit if needed',
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFF0EEF8)),
                            const SizedBox(height: 16),
                            const EntryFieldLabel(
                              'Equipment Name',
                              required: true,
                            ),
                            const SizedBox(height: 8),
                            EntryUnderlineField(
                              controller: _nameCtrl,
                              hint: 'Equipment name',
                            ),
                            const SizedBox(height: 18),
                            // ── Vendor (ERP requirement) ─────────────────
                            Row(
                              children: [
                                const Icon(Icons.store_outlined,
                                    size: 13, color: AppColors.textLight),
                                const SizedBox(width: 6),
                                const EntryFieldLabel('Vendor / Supplier'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            EntryUnderlineField(
                              controller: _vendorCtrl,
                              hint: 'e.g. JCB India Ltd.',
                            ),
                            const SizedBox(height: 18),
                            // ── Ownership Type (ERP requirement) ─────────
                            Row(
                              children: [
                                const Icon(Icons.assignment_outlined,
                                    size: 13, color: AppColors.textLight),
                                const SizedBox(width: 6),
                                const EntryFieldLabel('Ownership Type'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: ['Owned', 'Rented', 'Leased'].map((type) {
                                final isSelected = _ownershipCtrl.text == type;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _ownershipCtrl.text = type;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : const Color(0xFFD6D1F0),
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),
                            const EntryFieldLabel('Equipment Type'),
                            const SizedBox(height: 8),
                            EntryUnderlineField(
                              controller: _typeCtrl,
                              hint: 'e.g. Heavy, Light',
                            ),
                            const SizedBox(height: 18),
                            const EntryFieldLabel('Operator Name'),
                            const SizedBox(height: 8),
                            EntryUnderlineField(
                              controller: _operatorCtrl,
                              hint: 'Operator name',
                            ),
                            const SizedBox(height: 18),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const EntryFieldLabel(
                                        'Usage Hours',
                                        required: true,
                                      ),
                                      const SizedBox(height: 8),
                                      EntryUnderlineField(
                                        controller: _hoursCtrl,
                                        hint: '0',
                                        suffix: 'hrs',
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const EntryFieldLabel(
                                        'Rate / Hour',
                                        required: true,
                                      ),
                                      const SizedBox(height: 8),
                                      EntryUnderlineField(
                                        controller: _rateCtrl,
                                        hint: '0',
                                        prefix: '₹',
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const EntryFieldLabel('Fuel Consumption'),
                            const SizedBox(height: 8),
                            EntryUnderlineField(
                              controller: _fuelCtrl,
                              hint: '0',
                              suffix: 'L',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 18),
                            const EntryFieldLabel('Notes (Optional)'),
                            const SizedBox(height: 8),
                            EntryNotesField(controller: _notesCtrl),
                          ],
                        ),
                      ),
                      CostSummaryCard(
                        totalAmount: _computedTotal,
                        label: 'Equipment Usage Cost',
                        subtotals: [
                          (
                            'Usage Hours',
                            '${_hoursCtrl.text.isEmpty ? "—" : _hoursCtrl.text} hrs',
                          ),
                          (
                            'Rate / Hour',
                            '₹ ${_rateCtrl.text.isEmpty ? "—" : _rateCtrl.text}',
                          ),
                          (
                            'Fuel Used',
                            '${_fuelCtrl.text.isEmpty ? "—" : _fuelCtrl.text} L',
                          ),
                        ],
                      ),
                      EntrySectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EntryCardHeader(
                              icon: Icons.attach_file_outlined,
                              title: 'Invoice / Bill',
                              subtitle:
                                  'Attach invoice, bill, or supporting document (optional)',
                            ),
                            const SizedBox(height: 16),
                            UploadBox(
                              attachment: _attachment,
                              emptyLabel: 'Tap to upload invoice / bill',
                              onPicked: (a) => setState(() => _attachment = a),
                              onRemove: () =>
                                  setState(() => _attachment = null),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      EntrySubmitButton(
                        label: 'Confirm & Save Entry',
                        icon: Icons.check_circle,
                        isLoading: _isConfirming,
                        onTap: () => _confirm(context),
                      ),
                      const SizedBox(height: 24),
                    ],
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
