import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/controller/entry_model.dart' as em;
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddLabourScreen extends StatefulWidget {
  const AddLabourScreen({super.key});
  @override
  State<AddLabourScreen> createState() => _AddLabourScreenState();
}

class _AddLabourScreenState extends State<AddLabourScreen> {
  // ── Execution context ────────────────────────────────────────────────────
  String? _selectedProjectId;
  String? _selectedFloor;
  dynamic _selectedPhase;
  String? _selectedActivity;

  // ── Resource detail controllers ──────────────────────────────────────────
  final _nameCtrl     = TextEditingController(); // Worker / Team Name
  final _workTypeCtrl = TextEditingController(); // Work Type
  final _categoryCtrl = TextEditingController(); // Labour Category
  final _hoursCtrl    = TextEditingController(); // Quantity (hours/days/sqft etc)
  final _rateCtrl     = TextEditingController(); // Rate / Unit
  final _overtimeCtrl = TextEditingController(); // Overtime (optional)
  final _notesCtrl    = TextEditingController(); // Notes
  String? _selectedUnit;                         // Labour unit

  // ── UI state ─────────────────────────────────────────────────────────────
  bool _isSaving   = false;
  bool _isEditing  = false;
  bool _argsLoaded = false;
  PickedAttachment? _attachment;

  // ── Validation ────────────────────────────────────────────────────────────
  String? _nameError;
  String? _hoursError;
  String? _rateError;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = UserSession.projectId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _isEditing = args['isEditing'] as bool? ?? false;

      if (_isEditing && (args['status'] as String?) == 'approved') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.maybePop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Approved entries cannot be edited')),
          );
        });
        return;
      }

      if (_isEditing) {
        _nameCtrl.text = args['title'] as String? ?? args['name'] as String? ?? '';
        final rawAmount = args['amount']?.toString() ?? '';
        _hoursCtrl.text = rawAmount
            .replaceAll('+', '')
            .replaceAll('-', '')
            .replaceAll(' hrs', '')
            .replaceAll(' workers', '');
      }
    }
  }

  @override
  void dispose() {
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
    final qty      = double.tryParse(_hoursCtrl.text) ?? 0;
    final rate     = double.tryParse(_rateCtrl.text)  ?? 0;
    final overtime = double.tryParse(_overtimeCtrl.text) ?? 0;
    return (qty * rate) + overtime;
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError  = _nameCtrl.text.trim().isEmpty ? 'Worker / team name is required' : null;
      final qty = double.tryParse(_hoursCtrl.text);
      _hoursError = (qty == null || qty <= 0) ? 'Enter valid quantity > 0' : null;
      final rate  = double.tryParse(_rateCtrl.text);
      _rateError  = (rate == null || rate <= 0) ? 'Enter valid rate > 0' : null;
      ok = _nameError == null && _hoursError == null && _rateError == null;
    });
    return ok;
  }

  Future<void> _save(BuildContext ctx) async {
    if (_selectedProjectId == null) { _snack('Please select a project'); return; }
    if (_selectedFloor == null)     { _snack('Please select a floor / zone'); return; }
    if (_selectedPhase == null)     { _snack('Please select a phase'); return; }
    if (_selectedActivity == null)  { _snack('Please select an activity'); return; }
    if (!_validate()) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final entryId = 'LAB-${DateTime.now().millisecondsSinceEpoch}';
    ctx.read<ProjectProvider>().addEntry(
      EntryModel(
        id:          entryId,
        projectId:   _selectedProjectId!,
        type:        EntryType.labour,
        amount:      double.tryParse(_hoursCtrl.text) ?? 0.0,
        date:        DateTime.now(),
        description: _nameCtrl.text,
        ratePerUnit: double.tryParse(_rateCtrl.text) ?? 0.0,
        floor:       _selectedFloor!,
        phaseId:     _selectedPhase as String?,
      ),
    );

    Navigator.pushNamed(
      // ignore: use_build_context_synchronously
      ctx,
      '/logs',
      arguments: {
        'type': 'labour',
        'name': _nameCtrl.text,
        'newEntry': em.Entry(
          id:        entryId,
          type:      em.EntryType.labour,
          projectId: _selectedProjectId!,
          createdBy: UserSession.userId,
        ).toMap()
          ..addAll({
            'title':      _nameCtrl.text,
            'ref':        '#$entryId',
            'amount':     '+${_hoursCtrl.text} ${_selectedUnit ?? "Unit"}',
            'date':       'Today',
            'isPositive': true,
            'icon':       Icons.people_outline,
          }),
      },
    );
    setState(() => _isSaving = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title:       _isEditing ? 'Edit Labour' : 'Add Labour',
              isSubScreen: true,
              leftIcon:    Icons.arrow_back,
              onLeftTap:   () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── SECTION 1: EXECUTION CONTEXT ──────────────────────
                    ExecutionContextCard(
                      selectedProjectId: _selectedProjectId,
                      selectedFloor:     _selectedFloor,
                      selectedPhase:     _selectedPhase,
                      selectedActivity:  _selectedActivity,
                      onProjectChanged:  (v) => setState(() {
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

                    // ── SECTION 2: LABOUR DETAILS ──────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon:     Icons.people_outlined,
                            title:    'Labour Details',
                            subtitle: 'Specify the worker or team being logged',
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF0EEF8)),
                          const SizedBox(height: 16),

                          // Worker / Team Name
                          const EntryFieldLabel('Worker / Team Name', required: true),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _nameCtrl,
                            hint: 'Enter worker or team name',
                          ),
                          if (_nameError != null) EntryErrorText(_nameError!),
                          const SizedBox(height: 18),

                          // Work Type
                          const EntryFieldLabel('Work Type'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _workTypeCtrl,
                            hint: 'e.g. Masonry, Plumbing, Electrical',
                          ),
                          const SizedBox(height: 18),

                          // Labour Category
                          const EntryFieldLabel('Labour Category (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _categoryCtrl,
                            hint: 'e.g. Skilled, Unskilled, Supervisor',
                          ),
                        ],
                      ),
                    ),

                    // ── SECTION 3: WORK DETAILS ────────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon:     Icons.schedule_outlined,
                            title:    'Work Details',
                            subtitle: 'Hours and rate for cost calculation',
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF0EEF8)),
                          const SizedBox(height: 16),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const EntryFieldLabel('Work Quantity', required: true),
                                    const SizedBox(height: 8),
                                    EntryUnderlineField(
                                      controller: _hoursCtrl,
                                      hint: '0',
                                      suffix: _selectedUnit ?? 'Unit',
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    if (_hoursError != null) EntryErrorText(_hoursError!),
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
                                    if (_rateError != null) EntryErrorText(_rateError!),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Unit selector
                          const EntryFieldLabel('Unit', required: false),
                          const SizedBox(height: 8),
                          UnitSelectorField(
                            value: _selectedUnit,
                            units: kLabourUnits,
                            hint: 'Select unit (e.g. Day, Hour, Sq ft)',
                            onChanged: (u) => setState(() => _selectedUnit = u),
                          ),
                          const SizedBox(height: 18),

                          // Overtime
                          const EntryFieldLabel('Overtime Amount (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _overtimeCtrl,
                            hint: '0',
                            prefix: '₹',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 18),

                          // Notes
                          const EntryFieldLabel('Notes (Optional)'),
                          const SizedBox(height: 8),
                          EntryNotesField(controller: _notesCtrl),
                        ],
                      ),
                    ),

                    // ── SECTION 4: COST SUMMARY ────────────────────────────
                    CostSummaryCard(
                      totalAmount: _computedTotal,
                      label: 'Total Labour Cost',
                      subtotals: [
                        ('Qty × Rate', '${_hoursCtrl.text.isEmpty ? "—" : _hoursCtrl.text} ${_selectedUnit ?? "Unit"} × ₹${_rateCtrl.text.isEmpty ? "—" : _rateCtrl.text}'),
                        ('Overtime', '₹ ${_overtimeCtrl.text.isEmpty ? "0" : _overtimeCtrl.text}'),
                      ],
                    ),

                    // ── RECEIPT UPLOAD ─────────────────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon:     Icons.receipt_long_outlined,
                            title:    'Receipt / Bill',
                            subtitle: 'Attach labour bill (optional)',
                          ),
                          const SizedBox(height: 16),
                          UploadBox(
                            attachment: _attachment,
                            emptyLabel: 'Tap to upload bill',
                            onPicked: (a) => setState(() => _attachment = a),
                            onRemove:  () => setState(() => _attachment = null),
                          ),
                        ],
                      ),
                    ),

                    // ── SUBMIT ─────────────────────────────────────────────
                    const SizedBox(height: 4),
                    EntrySubmitButton(
                      label:     'Save Labour Entry',
                      icon:      Icons.check_circle,
                      isLoading: _isSaving,
                      onTap:     () => _save(context),
                    ),
                    const SizedBox(height: 24),
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
