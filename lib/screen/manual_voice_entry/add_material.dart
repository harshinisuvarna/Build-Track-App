import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/common/utils/currency_formatter.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildtrack_mobile/controller/inventory_provider.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';

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
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  String? _selectedUnit;
  final _rateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // ── Supplier ────────────────────────────────────────────────────────────
  final _supplierCtrl = TextEditingController();

  // ── UI state ────────────────────────────────────────────────────────────
  bool _isSaving = false;
  bool _isEditing = false;
  String? _editingTransactionId;
  bool _argsLoaded = false;
  PickedAttachment? _attachment;
  DateTime _selectedDate = DateTime.now();

  // ── GST state ──────────────────────────────────────────────────
  bool _isWithGst = false;
  final _gstCtrl = TextEditingController();

  // ── Payment state ───────────────────────────────────────────────────────
  bool _recordPaymentNow = false;
  String _paymentMethod = 'Cash';
  final _paymentAmountCtrl = TextEditingController();
  DateTime _paymentDate = DateTime.now();

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
        _editingTransactionId = args['id'] as String?;
        _nameCtrl.text =
            args['title'] as String? ?? args['name'] as String? ?? '';

        final double qty = (args['quantity'] as num?)?.toDouble() ?? 0.0;
        _qtyCtrl.text = qty > 0
            ? (qty % 1 == 0 ? qty.toInt().toString() : qty.toString())
            : '';

        final double rate = (args['rate'] as num?)?.toDouble() ?? 0.0;
        _rateCtrl.text = rate > 0
            ? (rate % 1 == 0 ? rate.toInt().toString() : rate.toString())
            : '';

        _brandCtrl.text = args['brand'] as String? ?? '';
        _categoryCtrl.text = args['categoryName'] as String? ?? '';
        _notesCtrl.text = args['notes'] as String? ?? '';

        final String rawUnit =
            (args['unit'] ?? '').toString().trim().toLowerCase();
        if (rawUnit == 'bag' || rawUnit == 'bags') {
          _selectedUnit = 'bag';
        } else if (rawUnit == 'sqft' || rawUnit == 'sq.ft') {
          _selectedUnit = 'Sq.ft';
        } else if (rawUnit == 'ton' || rawUnit == 'tons') {
          _selectedUnit = 'ton';
        } else if (rawUnit == 'kg' || rawUnit == 'kgs') {
          _selectedUnit = 'kg';
        } else if (rawUnit == 'unit' || rawUnit == 'pcs') {
          _selectedUnit = 'unit';
        } else if (rawUnit.isNotEmpty) {
          _selectedUnit = rawUnit;
        }

        if (args['date'] != null) {
          try {
            _selectedDate = DateTime.parse(args['date'].toString());
          } catch (_) {}
        }
      } else {
        final prefill = args['prefill'] as String?;
        if (prefill != null) _nameCtrl.text = prefill;
      }

      // Auto-open payment section if navigated via "Add & Pay"
      if (args['openPayment'] == true) {
        _recordPaymentNow = true;
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
    _gstCtrl.dispose();
    _supplierCtrl.dispose();
    _paymentAmountCtrl.dispose();
    super.dispose();
  }

  // ── GST Calculation Helpers ─────────────────────────────────────
  double _subtotal() {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    return qty * rate;
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
      _nameError = _nameCtrl.text.trim().isEmpty
          ? 'Material name is required'
          : null;

      final qty = double.tryParse(_qtyCtrl.text);
      _qtyError =
          (qty == null || qty <= 0) ? 'Enter a valid quantity > 0' : null;

      final rate = double.tryParse(_rateCtrl.text);
      _rateError =
          (rate == null || rate <= 0) ? 'Enter a valid rate > 0' : null;

      ok = _nameError == null && _qtyError == null && _rateError == null;
    });

    return ok;
  }

  Future<void> _save(BuildContext ctx) async {
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
    if (!_validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      "title": _nameCtrl.text.trim(),
      "type": "Materials",
      "subType": "Purchase",
      "category": _categoryCtrl.text.trim().isEmpty
          ? "General"
          : _categoryCtrl.text.trim(),
      "brand": _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      "supplier": _supplierCtrl.text.trim(),
      "quantity": double.tryParse(_qtyCtrl.text) ?? 0,
      "rate": double.tryParse(_rateCtrl.text) ?? 0,
      "unit": _selectedUnit == null
          ? "unit"
          : _selectedUnit == "bags" || _selectedUnit == "bag"
              ? "bag"
              : _selectedUnit == "sq.ft" ||
                      _selectedUnit == "sqft" ||
                      _selectedUnit == "Sq.ft"
                  ? "sqft"
                  : _selectedUnit == "ton" || _selectedUnit == "tons"
                      ? "ton"
                      : _selectedUnit == "kg" || _selectedUnit == "kgs"
                          ? "kg"
                          : _selectedUnit == "pcs" || _selectedUnit == "unit"
                              ? "unit"
                              : "unit",
      "project": _selectedProjectId,
      "notes": _notesCtrl.text.trim(),
      "date": _selectedDate.toIso8601String(),
    };

    if (_recordPaymentNow) {
      final paid = double.tryParse(_paymentAmountCtrl.text) ?? 0;
      payload["paidAmount"] = paid;
      payload["paymentMode"] = _paymentMethod;
      payload["paymentStatus"] =
          paid >= _finalTotal() ? "Paid" : paid > 0 ? "Partial" : "Pending";
      payload["paymentDate"] = _paymentDate.toIso8601String();
    }

    final bool success;
    if (_isEditing && _editingTransactionId != null) {
      success =
          await ApiService.updateTransaction(_editingTransactionId!, payload);
    } else {
      success = await ApiService.addMaterial(payload);
    }

    if (!mounted) return;

    if (success) {
      context.read<InventoryProvider>().loadInventory(_selectedProjectId!);
      context.read<ProjectProvider>().load();

      _snack(_isEditing
          ? 'Material entry updated successfully!'
          : 'Material logged and inventory stock synchronized!');
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

  Widget _calcRow(String label, String value, {bool muted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: muted ? const Color(0xFF9CA3AF) : const Color(0xFF374151),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: muted ? const Color(0xFF6B7280) : const Color(0xFF111827),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final methods = ['Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Card'];
    return EntrySectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: Color(0xFF15803D), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Record Payment Now',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text('Optionally log payment while adding',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
              Switch(
                value: _recordPaymentNow,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _recordPaymentNow = v),
              ),
            ],
          ),
          if (_recordPaymentNow) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF0EEF8)),
            const SizedBox(height: 16),
            const EntryFieldLabel('Amount Paid', required: false),
            const SizedBox(height: 8),
            EntryUnderlineField(
              controller: _paymentAmountCtrl,
              hint: '0',
              prefix: '₹',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            const EntryFieldLabel('Payment Method'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: methods.map((m) {
                final sel = _paymentMethod == m;
                return GestureDetector(
                  onTap: () => setState(() => _paymentMethod = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel
                              ? AppColors.primary
                              : const Color(0xFFDDE0F0),
                          width: 1.5),
                    ),
                    child: Text(m,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                sel ? Colors.white : AppColors.textDark)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const EntryFieldLabel('Payment Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _paymentDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            onSurface: AppColors.textDark)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _paymentDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFE0E5FF), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined,
                        color: AppColors.primary, size: 19),
                    const SizedBox(width: 8),
                    Text(
                        '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textDark)),
                  ],
                ),
              ),
            ),
          ],
        ],
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
                          const EntryFieldLabel(
                            'Material Name',
                            required: true,
                          ),
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
                          const EntryFieldLabel('Supplier (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _supplierCtrl,
                            hint: 'e.g. ABC Suppliers Ltd.',
                          ),
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
                                    const EntryFieldLabel(
                                      'Quantity',
                                      required: true,
                                    ),
                                    const SizedBox(height: 8),
                                    EntryUnderlineField(
                                      controller: _qtyCtrl,
                                      hint: '0',
                                      suffix: _selectedUnit ?? 'units',
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    if (_qtyError != null)
                                      EntryErrorText(_qtyError!),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const EntryFieldLabel(
                                      'Rate / Unit',
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
                                    if (_rateError != null)
                                      EntryErrorText(_rateError!),
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
                          const SizedBox(height: 22),

                          // ── GST PRICING MODULE ───────────────────────────
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFDDE0F8),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section label
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEEFFF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.percent_rounded,
                                        color: Color(0xFF173EEA),
                                        size: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'GST Configuration',
                                      style: TextStyle(
                                        color: Color(0xFF1E1E2E),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Refined toggle
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECEDF8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFD5D7EF),
                                      width: 1,
                                    ),
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
                                            duration: const Duration(
                                                milliseconds: 200),
                                            curve: Curves.easeInOut,
                                            decoration: BoxDecoration(
                                              color: !_isWithGst
                                                  ? const Color(0xFF173EEA)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              boxShadow: !_isWithGst
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFF173EEA)
                                                            .withValues(
                                                                alpha: 0.22),
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                            0, 2),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Without GST',
                                              style: TextStyle(
                                                color: !_isWithGst
                                                    ? Colors.white
                                                    : const Color(0xFF6B7280),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _isWithGst = true),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            curve: Curves.easeInOut,
                                            decoration: BoxDecoration(
                                              color: _isWithGst
                                                  ? const Color(0xFF173EEA)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              boxShadow: _isWithGst
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFF173EEA)
                                                            .withValues(
                                                                alpha: 0.22),
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                            0, 2),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'With GST',
                                              style: TextStyle(
                                                color: _isWithGst
                                                    ? Colors.white
                                                    : const Color(0xFF6B7280),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // GST % field (only when With GST)
                                if (_isWithGst) ...[
                                  const SizedBox(height: 14),
                                  const Text(
                                    'GST Percentage',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
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
                                const Divider(
                                    color: Color(0xFFE2E4F6), thickness: 1),
                                const SizedBox(height: 10),
                                _calcRow(
                                  'Subtotal',
                                  formatCurrency(_subtotal()),
                                  muted: true,
                                ),
                                if (_isWithGst) ...[
                                  const SizedBox(height: 6),
                                  _calcRow(
                                    'GST (${_gstCtrl.text.isEmpty ? "0" : _gstCtrl.text}%)',
                                    '+ ${formatCurrency(_gstAmount())}',
                                    muted: true,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                const Divider(
                                    color: Color(0xFFE2E4F6), thickness: 1),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _isWithGst
                                          ? 'Final Total (incl. GST)'
                                          : 'Total',
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

                          // Notes
                          const EntryFieldLabel('Notes (Optional)'),
                          const SizedBox(height: 8),
                          EntryNotesField(controller: _notesCtrl),
                        ],
                      ),
                    ),

                    // ── PURCHASING DATE ────────────────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon: Icons.calendar_month_outlined,
                            title: 'Purchasing Date',
                            subtitle:
                                'Select when this purchase or transaction took place',
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF0EEF8)),
                          const SizedBox(height: 16),
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
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                      onSurface: AppColors.textDark,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE0E5FF),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    color: AppColors.primary,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── SECTION 4: COST SUMMARY ────────────────────────────
                    CostSummaryCard(
                      totalAmount: _finalTotal(),
                      label: _isWithGst
                          ? 'Total (incl. GST)'
                          : 'Total Estimated Amount',
                      subtotals: [
                        (
                          'Quantity',
                          '${_qtyCtrl.text.isEmpty ? "—" : _qtyCtrl.text} '
                              '${_selectedUnit ?? "units"}',
                        ),
                        (
                          'Rate / Unit',
                          '₹ ${_rateCtrl.text.isEmpty ? "—" : _rateCtrl.text}',
                        ),
                        ('Subtotal', formatCurrency(_subtotal())),
                        if (_isWithGst) ...[
                          (
                            'GST (${_gstCtrl.text.isEmpty ? "0" : _gstCtrl.text}%)',
                            '+ ${formatCurrency(_gstAmount())}',
                          ),
                        ],
                      ],
                    ),

                    // ── RECEIPT UPLOAD ─────────────────────────────────────
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
                            onRemove: () => setState(() => _attachment = null),
                          ),
                        ],
                      ),
                    ),

                    // ── PAYMENT SECTION ────────────────────────────────────
                    _buildPaymentSection(),
                    const SizedBox(height: 4),

                    // ── SUBMIT ─────────────────────────────────────────────
                    EntrySubmitButton(
                      label: 'Save Material Entry',
                      icon: Icons.check_circle,
                      isLoading: _isSaving,
                      onTap: () => _save(context),
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