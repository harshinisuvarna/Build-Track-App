import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';
import 'package:buildtrack_mobile/common/widgets/voice_review_widgets.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/controller/entry_model.dart' as em;
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:buildtrack_mobile/models/phase_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReviewLabourEntryScreen extends StatefulWidget {
  const ReviewLabourEntryScreen({super.key});
  @override
  State<ReviewLabourEntryScreen> createState() =>
      _ReviewLabourEntryScreenState();
}

class _ReviewLabourEntryScreenState extends State<ReviewLabourEntryScreen> {
  String _transcript =
      'Hey BuildTrack, log a labour entry for North District Phase 2. '
      'Rajesh Kumar and his masonry team worked 8 hours today. '
      'Rate is 18 rupees per hour. Total comes to 144 rupees. '
      'Log this under structural block work.';

  late final VoiceRecordingController _voiceCtrl;
  VoiceEntryState _voiceState = VoiceEntryState.processing;
  bool _animateReveal = false;

  String? _selectedProjectId;
  String? _selectedFloor;
  dynamic _selectedPhase;
  String? _selectedActivity;
  late TextEditingController _nameCtrl;
  late TextEditingController _workTypeCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _hoursCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _overtimeCtrl;
  late TextEditingController _notesCtrl;

  bool _isConfirming = false;
  PickedAttachment? _attachment;

  static const _extractionStages = [
    'Identifying worker / team…',
    'Detecting work type…',
    'Extracting hours & rate…',
    'Matching project context…',
    'Resolving phase & activity…',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _workTypeCtrl = TextEditingController();
    _categoryCtrl = TextEditingController();
    _hoursCtrl = TextEditingController();
    _rateCtrl = TextEditingController();
    _overtimeCtrl = TextEditingController();
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

    _nameCtrl.text = 'Rajesh Kumar & Team (Masonry)';
    _workTypeCtrl.text = 'Masonry';
    _categoryCtrl.text = 'Skilled Labour';
    _hoursCtrl.text = '8';
    _rateCtrl.text = '18.00';

    _selectedProjectId = UserSession.projectId;
    _selectedFloor = floor;
    _selectedActivity = 'Brick Laying';
  }

  @override
  void dispose() {
    _voiceCtrl.removeListener(_onVoiceChanged);
    _voiceCtrl.dispose();
    _nameCtrl.dispose();
    _workTypeCtrl.dispose();
    _categoryCtrl.dispose();
    _hoursCtrl.dispose();
    _rateCtrl.dispose();
    _overtimeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _computedTotal {
    final hours = double.tryParse(_hoursCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final overtime = double.tryParse(_overtimeCtrl.text) ?? 0;
    return (hours * rate) + overtime;
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
      icon: Icons.people_outlined,
      label: 'Worker / Team',
      value: _nameCtrl.text,
      isHighlight: true,
      confidence: 0.96,
    ),
    ExtractedField(
      icon: Icons.construction_outlined,
      label: 'Work Type',
      value: _workTypeCtrl.text,
      isEmpty: _workTypeCtrl.text.isEmpty,
      confidence: 0.90,
    ),
    ExtractedField(
      icon: Icons.schedule_outlined,
      label: 'Hours Worked',
      value: '${_hoursCtrl.text} hrs',
      confidence: 0.94,
    ),
    ExtractedField(
      icon: Icons.attach_money_outlined,
      label: 'Rate / Hour',
      value: '₹ ${_rateCtrl.text}',
      confidence: 0.92,
    ),
    ExtractedField(
      icon: Icons.layers_outlined,
      label: 'Floor / Zone',
      value: _selectedFloor ?? '',
      isEmpty: _selectedFloor == null,
      confidence: 0.70,
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
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final entryId = 'VOICE-LAB-${DateTime.now().millisecondsSinceEpoch}';
    ctx.read<ProjectProvider>().addEntry(
      EntryModel(
        id: entryId,
        projectId: _selectedProjectId!,
        type: EntryType.labour,
        amount: double.tryParse(_hoursCtrl.text) ?? 0.0,
        date: DateTime.now(),
        description: _nameCtrl.text,
        ratePerUnit: double.tryParse(_rateCtrl.text) ?? 0.0,
        floor: _selectedFloor!,
        phaseId: (_selectedPhase as PhaseModel?)?.id,
      ),
    );

    Navigator.pushNamed(
      // ignore: use_build_context_synchronously
      ctx,
      '/logs',
      arguments: {
        'type': 'labour',
        'name': _nameCtrl.text,
        'newEntry':
            em.Entry(
              id: entryId,
              type: em.EntryType.labour,
              projectId: _selectedProjectId!,
              createdBy: UserSession.userId,
            ).toMap()..addAll({
              'title': _nameCtrl.text,
              'ref': '#$entryId',
              'amount': '+${_hoursCtrl.text} hrs',
              'date': 'Today',
              'isPositive': true,
              'icon': Icons.people_outline,
              'attachment': _attachment,
              'receipt': _attachment?.name,
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
                      entryTypeLabel: 'Labour',
                      confidence: 96.7,
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
                              icon: Icons.people_outlined,
                              title: 'Labour Details',
                              subtitle:
                                  'AI extracted — review and edit if needed',
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFF0EEF8)),
                            const SizedBox(height: 16),
                            const EntryFieldLabel(
                              'Worker / Team Name',
                              required: true,
                            ),
                            const SizedBox(height: 8),
                            EntryUnderlineField(
                              controller: _nameCtrl,
                              hint: 'Worker or team name',
                            ),
                            const SizedBox(height: 18),
                            const EntryFieldLabel('Work Type'),
                            const SizedBox(height: 8),
                            EntryUnderlineField(
                              controller: _workTypeCtrl,
                              hint: 'e.g. Masonry, Plumbing',
                            ),
                            const SizedBox(height: 18),
                            const EntryFieldLabel('Labour Category'),
                            const SizedBox(height: 8),
                            EntryUnderlineField(
                              controller: _categoryCtrl,
                              hint: 'e.g. Skilled, Unskilled',
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
                                        'Hours Worked',
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
                            const EntryFieldLabel('Overtime (Optional)'),
                            const SizedBox(height: 8),
                            EntryUnderlineField(
                              controller: _overtimeCtrl,
                              hint: '0',
                              prefix: '₹',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
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
                        label: 'Total Labour Cost',
                        subtotals: [
                          (
                            'Hours × Rate',
                            '${_hoursCtrl.text.isEmpty ? "—" : _hoursCtrl.text} hrs × ₹${_rateCtrl.text.isEmpty ? "—" : _rateCtrl.text}',
                          ),
                          (
                            'Overtime',
                            '₹ ${_overtimeCtrl.text.isEmpty ? "0" : _overtimeCtrl.text}',
                          ),
                        ],
                      ),
                      EntrySectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EntryCardHeader(
                              icon: Icons.receipt_long_outlined,
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
