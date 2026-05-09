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

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({super.key});
  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  // ── Execution context state ─────────────────────────────────────────────
  String? _selectedProjectId;
  String? _selectedFloor;
  dynamic _selectedPhase; // PhaseModel
  String? _selectedActivity;

  // ── Resource detail controllers ─────────────────────────────────────────
  final _nameCtrl     = TextEditingController();
  final _brandCtrl    = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _qtyCtrl      = TextEditingController();
  String? _selectedUnit;
  final _rateCtrl     = TextEditingController();
  final _notesCtrl    = TextEditingController();

  // ── Supplier ────────────────────────────────────────────────────────────
  bool _supplierSelected = false;
  bool _supplierError    = false;

  // ── UI state ────────────────────────────────────────────────────────────
  bool _isSaving  = false;
  bool _isEditing = false;
  bool _argsLoaded = false;
  PickedAttachment? _attachment;

  // ── Validation errors ───────────────────────────────────────────────────
  String? _nameError;
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
        _qtyCtrl.text = rawAmount.replaceAll('+', '').replaceAll('-', '');
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
    _brandCtrl.dispose();
    _categoryCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _computedTotal {
    final qty  = double.tryParse(_qtyCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    return qty * rate;
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty ? 'Material name is required' : null;
      final qty  = double.tryParse(_qtyCtrl.text);
      _qtyError  = (qty == null || qty <= 0) ? 'Enter a valid quantity > 0' : null;
      final rate = double.tryParse(_rateCtrl.text);
      _rateError = (rate == null || rate <= 0) ? 'Enter a valid rate > 0' : null;
      _supplierError = !_supplierSelected;
      ok = _nameError == null && _qtyError == null &&
           _rateError == null && _supplierSelected;
    });
    return ok;
  }

  Future<void> _save(BuildContext ctx) async {
    if (_selectedProjectId == null) {
      _snack('Please select a project'); return;
    }
    if (_selectedFloor == null) {
      _snack('Please select a floor / zone'); return;
    }
    if (_selectedPhase == null) {
      _snack('Please select a phase'); return;
    }
    if (_selectedActivity == null) {
      _snack('Please select an activity'); return;
    }
    if (!_validate()) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final entryId = 'MAT-${DateTime.now().millisecondsSinceEpoch}';
    ctx.read<ProjectProvider>().addEntry(
      EntryModel(
        id:          entryId,
        projectId:   _selectedProjectId!,
        type:        EntryType.material,
        amount:      double.tryParse(_qtyCtrl.text) ?? 0.0,
        date:        DateTime.now(),
        description: _nameCtrl.text,
        brand:       _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        ratePerUnit: double.tryParse(_rateCtrl.text),
        floor:       _selectedFloor,
        phaseId:     _selectedPhase?.id,
      ),
    );

    Navigator.pushNamed(
      ctx,
      '/logs',
      arguments: {
        'type': 'material',
        'name': _nameCtrl.text,
        'newEntry': em.Entry(
          id:        entryId,
          type:      em.EntryType.material,
          projectId: _selectedProjectId ?? UserSession.projectId,
          createdBy: UserSession.userId,
        ).toMap()
          ..addAll({
            'title':      _nameCtrl.text,
            'ref':        '#$entryId',
            'amount':     '+${_qtyCtrl.text}',
            'date':       'Today',
            'isPositive': true,
            'icon':       Icons.inventory_2_outlined,
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

  // ── SUPPLIER PICKER ────────────────────────────────────────────────────
  void _showSupplierPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE0F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Supplier',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              ...[
                'ABC Suppliers Ltd.', 'Metro Build Co.', 'SteelWorks Inc.',
              ].map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _supplierSelected = true;
                            _supplierError = false;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.business,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Text(s,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
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
              title: _isEditing ? 'Edit Material' : 'Add Material',
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
                    // ── SECTION 1: EXECUTION CONTEXT ──────────────────────
                    ExecutionContextCard(
                      selectedProjectId: _selectedProjectId,
                      selectedFloor:     _selectedFloor,
                      selectedPhase:     _selectedPhase,
                      selectedActivity:  _selectedActivity,
                      onProjectChanged:  (v) => setState(() {
                        _selectedProjectId = v;
                        _selectedFloor = null;
                        _selectedPhase = null;
                        _selectedActivity = null;
                      }),
                      onFloorChanged:    (v) => setState(() {
                        _selectedFloor = v;
                        _selectedPhase = null;
                        _selectedActivity = null;
                      }),
                      onPhaseChanged:    (v) => setState(() {
                        _selectedPhase = v;
                        _selectedActivity = null;
                      }),
                      onActivityChanged: (v) => setState(() => _selectedActivity = v),
                    ),

                    // ── SECTION 2: MATERIAL DETAILS ────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon: Icons.inventory_2_outlined,
                            title: 'Material Details',
                            subtitle: 'Specify the material being logged',
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF0EEF8)),
                          const SizedBox(height: 16),

                          // Material Name
                          const EntryFieldLabel('Material Name', required: true),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _nameCtrl,
                            hint: 'e.g. Ready-Mix Concrete M30',
                          ),
                          if (_nameError != null) EntryErrorText(_nameError!),
                          const SizedBox(height: 18),

                          // Brand
                          const EntryFieldLabel('Brand (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _brandCtrl,
                            hint: 'e.g. UltraTech, Tata Steel',
                          ),
                          const SizedBox(height: 18),

                          // Category
                          const EntryFieldLabel('Category (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _categoryCtrl,
                            hint: 'e.g. Structural, Finishing',
                          ),
                          const SizedBox(height: 18),

                          // Supplier
                          const EntryFieldLabel('Supplier', required: true),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showSupplierPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _supplierError
                                        ? AppColors.error
                                        : AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _supplierSelected
                                          ? 'ABC Suppliers Ltd.'
                                          : 'Select supplier',
                                      style: TextStyle(
                                        color: _supplierSelected
                                            ? AppColors.textDark
                                            : AppColors.textLight,
                                        fontSize: 15,
                                        fontWeight: _supplierSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (_supplierError)
                                    const Icon(Icons.error,
                                        color: AppColors.error, size: 22),
                                  if (_supplierSelected)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 22),
                                ],
                              ),
                            ),
                          ),
                          if (_supplierError)
                            const EntryErrorText(
                                'Please select a valid supplier from the database.'),
                        ],
                      ),
                    ),

                    // ── SECTION 3: QUANTITY & RATE ─────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon: Icons.straighten_outlined,
                            title: 'Quantity & Rate',
                            subtitle: 'Enter amounts for cost calculation',
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
                                    const EntryFieldLabel('Quantity', required: true),
                                    const SizedBox(height: 8),
                                    EntryUnderlineField(
                                      controller: _qtyCtrl,
                                      hint: '0',
                                      suffix: _selectedUnit ?? 'units',
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
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
                          const EntryFieldLabel('Unit (Optional)'),
                          const SizedBox(height: 8),
                          UnitSelectorField(
                            value: _selectedUnit,
                            onChanged: (u) => setState(() => _selectedUnit = u),
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
                      label: 'Total Estimated Amount',
                      subtotals: [
                        ('Quantity', '${_qtyCtrl.text.isEmpty ? "—" : _qtyCtrl.text} '
                            '${_selectedUnit ?? "units"}'),
                        ('Rate / Unit', '₹ ${_rateCtrl.text.isEmpty ? "—" : _rateCtrl.text}'),
                      ],
                    ),

                    // ── RECEIPT UPLOAD ─────────────────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon: Icons.receipt_long_outlined,
                            title: 'Receipt / Bill',
                            subtitle: 'Attach purchase document (optional)',
                          ),
                          const SizedBox(height: 16),
                          UploadBox(
                            attachment: _attachment,
                            emptyLabel: 'Tap to attach bill',
                            onPicked: (a) => setState(() => _attachment = a),
                            onRemove: ()  => setState(() => _attachment = null),
                          ),
                        ],
                      ),
                    ),

                    // ── SUBMIT ─────────────────────────────────────────────
                    const SizedBox(height: 4),
                    EntrySubmitButton(
                      label:     'Save Material Entry',
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
