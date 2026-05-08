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

class ReviewVoiceEntryScreen extends StatefulWidget {
  const ReviewVoiceEntryScreen({super.key});
  @override
  State<ReviewVoiceEntryScreen> createState() => _ReviewVoiceEntryScreenState();
}

class _ReviewVoiceEntryScreenState extends State<ReviewVoiceEntryScreen> {
  // ── Default transcript (pre-parsed on first load) ─────────────────────────
  String _transcript =
      'Hey SiteTrack, record a material entry for North District. '
      'We just received 12.5 cubic meters of C35 ready-mix concrete from UltraTech. '
      'Rate is fixed at 145 per unit. Log this under structural foundations on 1st Floor.';

  // ── Voice engine ──────────────────────────────────────────────────────────
  late final VoiceRecordingController _voiceCtrl;
  VoiceEntryState _voiceState = VoiceEntryState.processing; // start with processing animation
  bool _animateReveal = false;

  // ── Selection state ───────────────────────────────────────────────────────
  String? _selectedProjectId;
  String? _selectedFloor;
  dynamic _selectedPhase;
  String? _selectedActivity;

  // ── Field controllers ─────────────────────────────────────────────────────
  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _notesCtrl;

  bool _isConfirming = false;
  PickedAttachment? _attachment;

  // ── Processing stage labels ───────────────────────────────────────────────
  static const _extractionStages = [
    'Extracting material name…',
    'Detecting quantity & unit…',
    'Identifying brand…',
    'Matching project context…',
    'Resolving phase & activity…',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController();
    _brandCtrl    = TextEditingController();
    _categoryCtrl = TextEditingController();
    _qtyCtrl      = TextEditingController();
    _unitCtrl     = TextEditingController();
    _rateCtrl     = TextEditingController();
    _notesCtrl    = TextEditingController();

    _parseVoiceInput();

    _voiceCtrl = VoiceRecordingController();
    _voiceCtrl.addListener(_onVoiceChanged);

    // Initial "AI processing" animation on first load
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _voiceState    = VoiceEntryState.parsed;
        _animateReveal = true;
      });
    });
  }

  // ── Voice engine listener ─────────────────────────────────────────────────
  void _onVoiceChanged() {
    if (!mounted) return;
    final s = _voiceCtrl.engineState;

    // When engine transitions to parsed with real transcript, re-parse
    if (s == VoiceEntryState.parsed && _voiceCtrl.finalTranscript.isNotEmpty) {
      _transcript = _voiceCtrl.finalTranscript;
      _parseVoiceInput();
      _animateReveal = true;
    }

    setState(() => _voiceState = s);
  }

  // ── Parse transcript into field values ────────────────────────────────────
  void _parseVoiceInput() {
    final t = _transcript.toLowerCase();
    final numMatch = RegExp(r'(\d+\.\d+|\d+)').firstMatch(t);
    final double qty = numMatch != null
        ? (double.tryParse(numMatch.group(0) ?? '') ?? 0.0)
        : 0.0;

    String brand = '';
    if (t.contains('ultratech')) {
      brand = 'UltraTech';
    } else if (t.contains('tata')) {
      brand = 'Tata';
    }

    String floor = '1st Floor';
    if (t.contains('ground floor')) {
      floor = 'Ground Floor';
    } else if (t.contains('basement')) {
      floor = 'Basement';
    }

    _nameCtrl.text     = 'Premium Ready-Mix Concrete (C35)';
    _brandCtrl.text    = brand;
    _categoryCtrl.text = 'Structural';
    _qtyCtrl.text      = qty > 0 ? qty.toString() : '12.5';
    _unitCtrl.text     = 'm³';
    _rateCtrl.text     = '145';

    _selectedProjectId = UserSession.projectId;
    _selectedFloor     = floor;
    _selectedActivity  = 'PCC';
  }

  @override
  void dispose() {
    _voiceCtrl.removeListener(_onVoiceChanged);
    _voiceCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _categoryCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _computedTotal {
    final qty  = double.tryParse(_qtyCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    return qty * rate;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Voice actions ─────────────────────────────────────────────────────────
  Future<void> _handleMicTap() async {
    if (_voiceState == VoiceEntryState.error) {
      // Retry
      _voiceCtrl.reset();
      setState(() => _voiceState = VoiceEntryState.idle);
      return;
    }
    // Start fresh recording
    _animateReveal = false;
    await _voiceCtrl.startListening();
  }

  Future<void> _handleStopRecording() async {
    await _voiceCtrl.stopListening();
  }

  Future<void> _handleCancelRecording() async {
    await _voiceCtrl.cancelListening();
  }

  // ── Extracted fields ──────────────────────────────────────────────────────
  List<ExtractedField> get _extractedFields => [
    ExtractedField(
      icon: Icons.inventory_2_outlined,
      label: 'Material',
      value: _nameCtrl.text,
      isHighlight: true,
      confidence: 0.98,
    ),
    ExtractedField(
      icon: Icons.straighten_outlined,
      label: 'Quantity',
      value: '${_qtyCtrl.text} ${_unitCtrl.text}',
      confidence: 0.95,
    ),
    ExtractedField(
      icon: Icons.attach_money_outlined,
      label: 'Rate / Unit',
      value: '₹ ${_rateCtrl.text}',
      confidence: 0.92,
    ),
    ExtractedField(
      icon: Icons.branding_watermark_outlined,
      label: 'Brand',
      value: _brandCtrl.text,
      isEmpty: _brandCtrl.text.isEmpty,
      confidence: 0.88,
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
    if (_selectedProjectId == null) { _snack('Please select a project'); return; }
    if (_selectedFloor == null)     { _snack('Please select a floor / zone'); return; }
    if (_selectedPhase == null)     { _snack('Please select a phase'); return; }
    if (_selectedActivity == null)  { _snack('Please select an activity'); return; }

    setState(() => _isConfirming = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final entryId = 'VOICE-MAT-${DateTime.now().millisecondsSinceEpoch}';
    ctx.read<ProjectProvider>().addEntry(
      EntryModel(
        id:          entryId,
        projectId:   _selectedProjectId!,
        type:        EntryType.material,
        amount:      double.tryParse(_qtyCtrl.text) ?? 0.0,
        date:        DateTime.now(),
        description: _nameCtrl.text,
        brand:       _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        ratePerUnit: double.tryParse(_rateCtrl.text) ?? 0.0,
        floor:       _selectedFloor!,
        phaseId:     (_selectedPhase as PhaseModel?)?.id,
      ),
    );

    Navigator.pushNamed(
      ctx, '/logs',
      arguments: {
        'type': 'material',
        'name': _nameCtrl.text,
        'newEntry': em.Entry(
          id: entryId, type: em.EntryType.material,
          projectId: _selectedProjectId!, createdBy: UserSession.userId,
        ).toMap()..addAll({
          'title': _nameCtrl.text, 'ref': '#$entryId',
          'amount': '+${_qtyCtrl.text}', 'date': 'Today',
          'isPositive': true, 'icon': Icons.inventory_2_outlined,
        }),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = _voiceState == VoiceEntryState.processing;
    final isParsed     = _voiceState == VoiceEntryState.parsed;

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
              leftIcon:  Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  children: [
                    // ── Voice status header with live feedback ───────────
                    VoiceStatusHeader(
                      state:             _voiceState,
                      entryTypeLabel:    'Material',
                      confidence:        98.4,
                      onMicTap:          _handleMicTap,
                      partialTranscript: _voiceCtrl.partialTranscript,
                      elapsedDisplay:    _voiceCtrl.elapsedDisplay,
                      onStop:            _handleStopRecording,
                      onCancel:          _handleCancelRecording,
                    ),

                    // ── Processing: staged extraction card ──────────────
                    if (isProcessing)
                      const ExtractionProcessingCard(stages: _extractionStages),

                    // ── Parsed: progressive extraction reveal ───────────
                    if (isParsed)
                      ExtractedDataSummaryCard(
                        fields:        _extractedFields,
                        subtitle:      'Detected from your voice recording',
                        animateReveal: _animateReveal,
                      ),

                    if (isParsed)
                      ExpandableTranscript(transcript: _transcript),

                    // ── Rest of the form (only when parsed) ─────────────
                    if (isParsed) ...[
                      ExecutionContextCard(
                        selectedProjectId: _selectedProjectId,
                        selectedFloor:     _selectedFloor,
                        selectedPhase:     _selectedPhase,
                        selectedActivity:  _selectedActivity,
                        onProjectChanged: (v) => setState(() {
                          _selectedProjectId = v;
                          _selectedFloor     = null;
                          _selectedPhase     = null;
                          _selectedActivity  = null;
                        }),
                        onFloorChanged: (v) => setState(() {
                          _selectedFloor    = v;
                          _selectedPhase    = null;
                          _selectedActivity = null;
                        }),
                        onPhaseChanged: (v) => setState(() {
                          _selectedPhase    = v;
                          _selectedActivity = null;
                        }),
                        onActivityChanged: (v) => setState(() => _selectedActivity = v),
                      ),
                      EntrySectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EntryCardHeader(
                              icon:     Icons.inventory_2_outlined,
                              title:    'Material Details',
                              subtitle: 'AI extracted — review and edit if needed',
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFF0EEF8)),
                            const SizedBox(height: 16),
                            const EntryFieldLabel('Material Name', required: true),
                            const SizedBox(height: 8),
                            EntryUnderlineField(controller: _nameCtrl, hint: 'Material name'),
                            const SizedBox(height: 18),
                            const EntryFieldLabel('Brand'),
                            const SizedBox(height: 8),
                            EntryUnderlineField(controller: _brandCtrl, hint: 'Brand name'),
                            const SizedBox(height: 18),
                            const EntryFieldLabel('Category'),
                            const SizedBox(height: 8),
                            EntryUnderlineField(controller: _categoryCtrl, hint: 'e.g. Structural'),
                            const SizedBox(height: 18),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const EntryFieldLabel('Quantity', required: true),
                                      const SizedBox(height: 8),
                                      EntryUnderlineField(
                                        controller: _qtyCtrl,
                                        hint: '0',
                                        suffix: _unitCtrl.text.isEmpty ? 'units' : _unitCtrl.text,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const EntryFieldLabel('Rate / Unit', required: true),
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
                            const EntryFieldLabel('Unit'),
                            const SizedBox(height: 8),
                            EntryUnderlineField(
                              controller: _unitCtrl,
                              hint: 'e.g. m³, bags, kg',
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
                        label: 'Total Estimated Amount',
                        subtotals: [
                          ('Quantity', '${_qtyCtrl.text.isEmpty ? "—" : _qtyCtrl.text} ${_unitCtrl.text.isEmpty ? "units" : _unitCtrl.text}'),
                          ('Rate / Unit', '₹ ${_rateCtrl.text.isEmpty ? "—" : _rateCtrl.text}'),
                        ],
                      ),
                      EntrySectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EntryCardHeader(
                              icon:     Icons.receipt_long_outlined,
                              title:    'Attach Receipt (Optional)',
                              subtitle: 'Upload supporting document',
                            ),
                            const SizedBox(height: 16),
                            UploadBox(
                              attachment: _attachment,
                              emptyLabel: 'Tap to attach receipt',
                              onPicked: (a) => setState(() => _attachment = a),
                              onRemove:  () => setState(() => _attachment = null),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      EntrySubmitButton(
                        label:     'Confirm & Save Entry',
                        icon:      Icons.check_circle,
                        isLoading: _isConfirming,
                        onTap:     () => _confirm(context),
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
