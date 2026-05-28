import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';
import 'package:buildtrack_mobile/controller/entry_model.dart' as em;
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});
  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  // ── Execution context ────────────────────────────────────────────────────
  String? _selectedProjectId;
  String? _selectedFloor;
  dynamic _selectedPhase;
  String? _selectedActivity;

  // ── Resource detail controllers ──────────────────────────────────────────
  final _nameCtrl     = TextEditingController(); // Equipment Name
  final _typeCtrl     = TextEditingController(); // Equipment Type
  final _operatorCtrl = TextEditingController(); // Operator Name
  final _hoursCtrl    = TextEditingController(); // Usage Quantity
  final _fuelCtrl     = TextEditingController(); // Fuel Usage
  final _rateCtrl     = TextEditingController(); // Rate / Unit
  final _notesCtrl    = TextEditingController(); // Notes
  String? _selectedUnit;                         // Equipment unit

  // ── UI state ─────────────────────────────────────────────────────────────
  bool _isSaving   = false;
  bool _isEditing  = false;
  bool _argsLoaded = false;
  PickedAttachment? _attachment;

  // ── GST state ──────────────────────────────────────────────────
  bool _isWithGst = false;
  final _gstCtrl  = TextEditingController();

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
        _hoursCtrl.text =
            rawAmount.replaceAll('+', '').replaceAll('-', '').replaceAll(' hrs', '');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _operatorCtrl.dispose();
    _hoursCtrl.dispose();
    _fuelCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  // ── GST Calculation Helpers ─────────────────────────────────────
  double _subtotal() {
    final hours = double.tryParse(_hoursCtrl.text) ?? 0;
    final rate  = double.tryParse(_rateCtrl.text)  ?? 0;
    return hours * rate;
  }

  double _gstAmount() {
    if (!_isWithGst) return 0;
    final gstPct = double.tryParse(_gstCtrl.text) ?? 0;
    return _subtotal() * gstPct / 100;
  }

  double _finalTotal() => _subtotal() + _gstAmount();

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError  = _nameCtrl.text.trim().isEmpty ? 'Equipment name is required' : null;
      final hours = double.tryParse(_hoursCtrl.text);
      _hoursError = (hours == null || hours <= 0) ? 'Enter valid hours > 0' : null;
      final rate  = double.tryParse(_rateCtrl.text);
      _rateError  = (rate == null || rate <= 0) ? 'Enter valid cost > 0' : null;
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

    final entryId = 'EQP-${DateTime.now().millisecondsSinceEpoch}';
    ctx.read<ProjectProvider>().addEntry(
      EntryModel(
        id:          entryId,
        projectId:   _selectedProjectId!,
        type:        EntryType.equipment,
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
        'type': 'equipment',
        'name': _nameCtrl.text,
        'newEntry': em.Entry(
          id:        entryId,
          type:      em.EntryType.equipment,
          projectId: _selectedProjectId!,
          createdBy: UserSession.userId,
        ).toMap()
          ..addAll({
            'title':      _nameCtrl.text,
            'ref':        '#$entryId',
            'amount':     '+${_hoursCtrl.text} ${_selectedUnit ?? "Unit"}',
            'date':       'Today',
            'isPositive': true,
            'icon':       Icons.precision_manufacturing_outlined,
            'attachment': _attachment,
            'receipt':    _attachment?.name,
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

  Widget _calcRow(String label, String value, {bool muted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: muted ? const Color(0xFF9CA3AF) : const Color(0xFF374151),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            )),
        Text(value,
            style: TextStyle(
              color: muted ? const Color(0xFF6B7280) : const Color(0xFF111827),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            )),
      ],
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
              title:       _isEditing ? 'Edit Equipment' : 'Add Equipment',
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

                    // ── SECTION 2: EQUIPMENT DETAILS ───────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon:     Icons.precision_manufacturing_outlined,
                            title:    'Equipment Details',
                            subtitle: 'Specify the equipment being logged',
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF0EEF8)),
                          const SizedBox(height: 16),

                          // Equipment Name
                          const EntryFieldLabel('Equipment Name', required: true),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _nameCtrl,
                            hint: 'e.g. Tower Crane, Excavator',
                          ),
                          if (_nameError != null) EntryErrorText(_nameError!),
                          const SizedBox(height: 18),

                          // Equipment Type
                          const EntryFieldLabel('Equipment Type (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _typeCtrl,
                            hint: 'e.g. Heavy, Light, Mechanical',
                          ),
                          const SizedBox(height: 18),

                          // Operator Name
                          const EntryFieldLabel('Operator Name (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _operatorCtrl,
                            hint: 'Enter operator name',
                          ),
                        ],
                      ),
                    ),

                    // ── SECTION 3: USAGE DETAILS ───────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon:     Icons.av_timer_outlined,
                            title:    'Usage Details',
                            subtitle: 'Hours, fuel and rate for cost calculation',
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
                                    const EntryFieldLabel('Usage Quantity', required: true),
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
                          const EntryFieldLabel('Unit'),
                          const SizedBox(height: 8),
                          UnitSelectorField(
                            value: _selectedUnit,
                            units: kEquipmentUnits,
                            hint: 'Select unit (e.g. Hour, Day, Trip)',
                            onChanged: (u) => setState(() => _selectedUnit = u),
                          ),
                          const SizedBox(height: 22),

                          // ── GST PRICING MODULE ───────────────────────────
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFDDE0F8), width: 1.2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEEFFF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.percent_rounded,
                                          color: Color(0xFF173EEA), size: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('GST Configuration',
                                        style: TextStyle(
                                          color: Color(0xFF1E1E2E),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Refined segmented toggle
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECEDF8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFD5D7EF), width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _isWithGst = false;
                                            _gstCtrl.clear();
                                          }),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeInOut,
                                            decoration: BoxDecoration(
                                              color: !_isWithGst ? const Color(0xFF173EEA) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(9),
                                              boxShadow: !_isWithGst
                                                  ? [BoxShadow(color: const Color(0xFF173EEA).withValues(alpha: 0.22), blurRadius: 6, offset: const Offset(0, 2))]
                                                  : [],
                                            ),
                                            alignment: Alignment.center,
                                            child: Text('Without GST',
                                                style: TextStyle(
                                                  color: !_isWithGst ? Colors.white : const Color(0xFF6B7280),
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                )),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _isWithGst = true),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeInOut,
                                            decoration: BoxDecoration(
                                              color: _isWithGst ? const Color(0xFF173EEA) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(9),
                                              boxShadow: _isWithGst
                                                  ? [BoxShadow(color: const Color(0xFF173EEA).withValues(alpha: 0.22), blurRadius: 6, offset: const Offset(0, 2))]
                                                  : [],
                                            ),
                                            alignment: Alignment.center,
                                            child: Text('With GST',
                                                style: TextStyle(
                                                  color: _isWithGst ? Colors.white : const Color(0xFF6B7280),
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                )),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // GST % field
                                if (_isWithGst) ...[
                                  const SizedBox(height: 14),
                                  const Text('GST Percentage',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      )),
                                  const SizedBox(height: 6),
                                  EntryUnderlineField(
                                    controller: _gstCtrl,
                                    hint: 'e.g. 18',
                                    suffix: '%',
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],

                                // Live cost breakdown
                                const SizedBox(height: 14),
                                const Divider(color: Color(0xFFE2E4F6), thickness: 1),
                                const SizedBox(height: 10),
                                _calcRow('Subtotal', formatCurrency(_subtotal()), muted: true),
                                if (_isWithGst) ...[
                                  const SizedBox(height: 6),
                                  _calcRow(
                                      'GST (${_gstCtrl.text.isEmpty ? "0" : _gstCtrl.text}%)',
                                      '+ ${formatCurrency(_gstAmount())}',
                                      muted: true),
                                ],
                                const SizedBox(height: 8),
                                const Divider(color: Color(0xFFE2E4F6), thickness: 1),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _isWithGst ? 'Final Total (incl. GST)' : 'Total',
                                      style: const TextStyle(
                                        color: Color(0xFF173EEA),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      formatCurrency(_finalTotal()),
                                      style: const TextStyle(
                                        color: Color(0xFF173EEA),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Fuel Usage
                          const EntryFieldLabel('Fuel Usage (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _fuelCtrl,
                            hint: '0',
                            suffix: 'L',
                            keyboardType: TextInputType.number,
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
                      totalAmount: _finalTotal(),
                      label: _isWithGst ? 'Equipment Cost (incl. GST)' : 'Equipment Usage Cost',
                      subtotals: [
                        ('Usage × Rate', '${_hoursCtrl.text.isEmpty ? "—" : _hoursCtrl.text} ${_selectedUnit ?? "Unit"} × ₹${_rateCtrl.text.isEmpty ? "—" : _rateCtrl.text}'),
                        ('Fuel Used',   '${_fuelCtrl.text.isEmpty ? "—" : _fuelCtrl.text} L'),
                        ('Subtotal', formatCurrency(_subtotal())),
                        if (_isWithGst) ...[
                          ('GST (${_gstCtrl.text.isEmpty ? "0" : _gstCtrl.text}%)',
                           '+ ${formatCurrency(_gstAmount())}'),
                        ],
                      ],
                    ),

                    // ── LOG / RECEIPT UPLOAD ───────────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon:     Icons.attach_file_outlined,
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
                      label:     'Save Equipment Entry',
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
