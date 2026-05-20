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
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:buildtrack_mobile/controller/inventory_provider.dart';

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
  final _qtyCtrl      = TextEditingController(); // Quantity (hours/days/sqft etc)
  final _rateCtrl     = TextEditingController(); // Rate / Unit
  final _overtimeCtrl = TextEditingController(); // Overtime (optional)
  final _notesCtrl    = TextEditingController(); // Notes
  String? _selectedUnit;                         // Labour unit

  // ── UI states ────────────────────────────────────────────────────────────
  bool _isSaving    = false;
  bool _isEditing   = false;
  bool _argsLoaded  = false;
  PickedAttachment? _attachment;

  // ── Validation flags ─────────────────────────────────────────────────────
  String? _nameError;
  String? _workTypeError;
  String? _qtyError;
  String? _rateError;

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
        _qtyCtrl.text   = rawAmount.replaceAll('+', '').replaceAll('-', '');
        
        final String rawUnit = (args['unit'] ?? '').toString().trim().toLowerCase();
        if (rawUnit == 'day' || rawUnit == 'days') {
          _selectedUnit = 'Day';
        } else if (rawUnit == 'hour' || rawUnit == 'hours') {
          _selectedUnit = 'Hour';
        } else if (rawUnit == 'sqft' || rawUnit == 'sq.ft' || rawUnit == 'sq ft') {
          _selectedUnit = 'Sq.ft';
        } else if (rawUnit.isNotEmpty) {
          _selectedUnit = rawUnit[0].toUpperCase() + rawUnit.substring(1);
        }
      } else {
        final prefill = args['prefill'] as String?;
        if (prefill != null) _nameCtrl.text = prefill;
      }
    }
    _selectedProjectId ??= UserSession.projectId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _workTypeCtrl.dispose();
    _categoryCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _overtimeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double _totalCost() {
    final qty      = double.tryParse(_qtyCtrl.text) ?? 0;
    final rate     = double.tryParse(_rateCtrl.text)  ?? 0;
    final overtime = double.tryParse(_overtimeCtrl.text) ?? 0;
    return (qty * rate) + overtime;
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError  = _nameCtrl.text.trim().isEmpty ? 'Worker / team name is required' : null;
      final qty = double.tryParse(_qtyCtrl.text);
      _qtyError = (qty == null || qty <= 0) ? 'Enter valid quantity > 0' : null;
      final rate  = double.tryParse(_rateCtrl.text);
      _rateError  = (rate == null || rate <= 0) ? 'Enter valid rate > 0' : null;
      ok = _nameError == null && _qtyError == null && _rateError == null;
    });
    return ok;
  }

  Future<void> _save(BuildContext ctx) async {
    if (_selectedProjectId == null) { _snack('Please pick target working site execution context'); return; }
    if (!_validate()) return;

    setState(() => _isSaving = true);

    // 🌟 CHOSEN BACKEND STRUCTURE: Matches the Mongoose schema for Expenses/Labour
    final payload = {
      "title": _nameCtrl.text.trim(),
      "type": "Wages", 
      "category": _categoryCtrl.text.trim().isEmpty ? "General Labour" : _categoryCtrl.text.trim(),
      "quantity": double.tryParse(_qtyCtrl.text) ?? 0,
      "rate": double.tryParse(_rateCtrl.text) ?? 0,
      "unit": _selectedUnit == null
          ? "hour"
          : _selectedUnit == "Day" || _selectedUnit == "day"
              ? "day"
              : _selectedUnit == "Hour" || _selectedUnit == "hour"
                  ? "hour"
                  : _selectedUnit == "Sq ft" || _selectedUnit == "sqft" || _selectedUnit == "Sq.ft"
                      ? "sqft"
                      : "unit",
      "project": _selectedProjectId,
    };

    final success = await ApiService.addMaterial(payload);

    if (!mounted) return;

    if (success) {
      // 🌟 THE REFRESH FIX
      context.read<InventoryProvider>().loadInventory(_selectedProjectId!);
      context.read<ProjectProvider>().load();

      _snack('Labour entry logged to database!');
      Navigator.maybePop(context); 
    } else {
      _snack('Error saving to server. Please try again.');
    }

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
              title: _isEditing ? 'Modify Labour Log' : 'Log Labour Force',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── EXECUTION CONTEXT ─────────────────────────────────
                    ExecutionContextCard(
                      selectedProjectId: _selectedProjectId,
                      selectedFloor:     _selectedFloor,
                      selectedPhase:     _selectedPhase,
                      selectedActivity:  _selectedActivity,
                      onProjectChanged:  (v) => setState(() { _selectedProjectId = v; _selectedFloor = null; _selectedPhase = null; _selectedActivity = null; }),
                      onFloorChanged:    (v) => setState(() { _selectedFloor = v; _selectedPhase = null; _selectedActivity = null; }),
                      onPhaseChanged:    (v) => setState(() { _selectedPhase = v; _selectedActivity = null; }),
                      onActivityChanged: (v) => setState(() => _selectedActivity = v),
                    ),

                    // ── RESOURCE DETAIL PROFILE ────────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon:     Icons.people_outline,
                            title:    'Labour Allocation Details',
                            subtitle: 'Define working crew parameters or workforce units',
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF0EEF8)),
                          const SizedBox(height: 16),

                          const EntryFieldLabel('Labour / Crew Name', required: true),
                          const SizedBox(height: 8),
                          EntryUnderlineField(controller: _nameCtrl, hint: 'e.g. Rajesh Kumar Team, Steel Fixers Crew'),
                          if (_nameError != null) EntryErrorText(_nameError!),
                          const SizedBox(height: 18),

                          const EntryFieldLabel('Trade Classification', required: true),
                          const SizedBox(height: 8),
                          EntryUnderlineField(controller: _workTypeCtrl, hint: 'e.g. Masonry, Barbending, Concrete Crew'),
                          if (_workTypeError != null) EntryErrorText(_workTypeError!),
                          const SizedBox(height: 18),

                          const EntryFieldLabel('Subcontractor / Sub-Group Tag (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(controller: _categoryCtrl, hint: 'e.g. Vertex Infra Contractors'),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),

                    // ── WORK DONE METRIC QUANTIFICATION ─────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon:     Icons.timer_outlined,
                            title:    'Quantified Effort & Wages',
                            subtitle: 'Calculate deployment financials via timeline logs',
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
                                      controller: _qtyCtrl,
                                      hint: '0',
                                      suffix: _selectedUnit ?? 'Unit',
                                      keyboardType: TextInputType.number,
                                      onChanged:    (_) => setState(() {}),
                                    ),
                                    if (_qtyError != null) EntryErrorText(_qtyError!),
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
                                      controller:   _rateCtrl,
                                      hint:         '0',
                                      prefix:       '₹',
                                      keyboardType: TextInputType.number,
                                      onChanged:    (_) => setState(() {}),
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

                          const EntryFieldLabel('Operational Activity Notes (Optional)'),
                          const SizedBox(height: 8),
                          EntryNotesField(controller: _notesCtrl),
                        ],
                      ),
                    ),

                    // ── METRIC COST EVALUATION MATRIX ──────────────────────
                    CostSummaryCard(
                      totalAmount: _totalCost(),
                      label:       'Calculated Operational Labor Budget',
                      subtotals: [
                        ('Qty × Rate', '${_qtyCtrl.text.isEmpty ? "—" : _qtyCtrl.text} ${_selectedUnit ?? "Unit"} × ₹${_rateCtrl.text.isEmpty ? "—" : _rateCtrl.text}'),
                        ('Overtime', '₹ ${_overtimeCtrl.text.isEmpty ? "0" : _overtimeCtrl.text}'),
                      ],
                    ),

                    // ── SUPPORTING EVIDENCE CAPTURE ───────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon:     Icons.receipt_long_outlined,
                            title:    'Invoice / Bill',
                            subtitle: 'Attach invoice, bill, or supporting document (optional)',
                          ),
                          const SizedBox(height: 16),
                          UploadBox(
                            attachment: _attachment,
                            emptyLabel: 'Tap to upload invoice / bill',
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