import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
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
  final _nameCtrl = TextEditingController();
  final _workTypeCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _overtimeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedUnit;

  // ── UI states ────────────────────────────────────────────────────────────
  bool _isSaving = false;
  bool _isEditing = false;
  String? _editingTransactionId;
  bool _argsLoaded = false;
  PickedAttachment? _attachment;
  DateTime _selectedDate = DateTime.now();

  // ── Payment state ───────────────────────────────────────────────────────
  bool _isAddAndPay = false;
  bool _recordPaymentNow = false;
  Map<String, dynamic>? _paymentResult;
  final _paymentAmountCtrl = TextEditingController();
  final _paymentNoteCtrl = TextEditingController();
  String _paymentMethod = 'Cash';
  DateTime _paymentDate = DateTime.now();

  // ── Validation flags ─────────────────────────────────────────────────────
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

        // ── Restore execution context ──────────────────────────────────
        final projectId = args['projectId'] as String? ??
            args['project'] as String? ??
            UserSession.projectId;
        _selectedProjectId = projectId;

        final floor = args['floor'] as String? ?? args['zone'] as String?;
        if (floor != null && floor.isNotEmpty) _selectedFloor = floor;

        final phase = args['phase'];
        if (phase != null) _selectedPhase = phase;

        final activity = args['activity'] as String?;
        if (activity != null && activity.isNotEmpty) {
          _selectedActivity = activity;
        }

        // ── Restore detail fields ──────────────────────────────────────
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

        _categoryCtrl.text = args['categoryName'] as String? ?? '';
        _notesCtrl.text = args['notes'] as String? ?? '';
        _workTypeCtrl.text =
            args['workType'] as String? ?? args['remarks'] as String? ?? '';

        final String rawUnit =
            (args['unit'] ?? '').toString().trim().toLowerCase();
        if (rawUnit == 'day' || rawUnit == 'days') {
          _selectedUnit = 'Day';
        } else if (rawUnit == 'hour' || rawUnit == 'hours') {
          _selectedUnit = 'Hour';
        } else if (rawUnit == 'sqft' ||
            rawUnit == 'sq.ft' ||
            rawUnit == 'sq ft') {
          _selectedUnit = 'Sq.ft';
        } else if (rawUnit.isNotEmpty) {
          _selectedUnit =
              rawUnit[0].toUpperCase() + rawUnit.substring(1);
        }

        if (args['date'] != null) {
          try {
            _selectedDate = DateTime.parse(args['date'].toString());
          } catch (_) {}
        }
      } else {
        _selectedProjectId ??= UserSession.projectId;
        final prefill = args['prefill'] as String?;
        if (prefill != null) _nameCtrl.text = prefill;
      }

      if (args['openPayment'] == true) {
        _isAddAndPay = true;
      }
    } else {
      _selectedProjectId ??= UserSession.projectId;
    }
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
    _paymentAmountCtrl.dispose();
    _paymentNoteCtrl.dispose();
    super.dispose();
  }

  double _totalCost() {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final overtime = double.tryParse(_overtimeCtrl.text) ?? 0;
    return (qty * rate) + overtime;
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty
          ? 'Worker / team name is required'
          : null;
      final qty = double.tryParse(_qtyCtrl.text);
      _qtyError =
          (qty == null || qty <= 0) ? 'Enter valid quantity > 0' : null;
      final rate = double.tryParse(_rateCtrl.text);
      _rateError =
          (rate == null || rate <= 0) ? 'Enter valid rate > 0' : null;
      ok = _nameError == null && _qtyError == null && _rateError == null;
    });
    return ok;
  }

  Future<void> _save(BuildContext ctx) async {
    if (_selectedProjectId == null) {
      _snack('Please pick target working site execution context');
      return;
    }
    if (!_validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      "title": _nameCtrl.text.trim(),
      "type": "Wages",
      "category": _categoryCtrl.text.trim().isEmpty
          ? "General Labour"
          : _categoryCtrl.text.trim(),
      "quantity": double.tryParse(_qtyCtrl.text) ?? 0,
      "rate": double.tryParse(_rateCtrl.text) ?? 0,
      "unit": _selectedUnit == null
          ? "hour"
          : _selectedUnit == "Day" || _selectedUnit == "day"
              ? "day"
              : _selectedUnit == "Hour" || _selectedUnit == "hour"
                  ? "hour"
                  : _selectedUnit == "Sq ft" ||
                          _selectedUnit == "sqft" ||
                          _selectedUnit == "Sq.ft"
                      ? "sqft"
                      : "unit",
      "project": _selectedProjectId,
      "date": _selectedDate.toIso8601String(),
      if (_selectedActivity != null && _selectedActivity!.isNotEmpty)
        "activity": _selectedActivity,
    };

    if (_isAddAndPay) {
      final paid = double.tryParse(_paymentAmountCtrl.text) ?? 0.0;
      String apiMode = _paymentMethod;
      if (apiMode == 'Bank Transfer' || apiMode == 'Card') apiMode = 'Bank';
      payload["paidAmount"] = paid;
      payload["paymentMode"] = apiMode;
      payload["paymentStatus"] =
          paid >= _totalCost() ? "Paid" : paid > 0 ? "Partial" : "Pending";
      payload["paymentDate"] = _paymentDate.toIso8601String();
      if (_paymentNoteCtrl.text.trim().isNotEmpty) {
        payload["notes"] = _paymentNoteCtrl.text.trim();
      }
    } else if (_recordPaymentNow && _paymentResult != null) {
      final paid = (_paymentResult!['amount'] as double?) ?? 0.0;
      final method = (_paymentResult!['method'] as String?) ?? 'Cash';
      final payDate =
          (_paymentResult!['paymentDate'] as DateTime?) ?? DateTime.now();
      String apiMode = method;
      if (apiMode == 'Bank Transfer' || apiMode == 'Card') apiMode = 'Bank';
      payload["paidAmount"] = paid;
      payload["paymentMode"] = apiMode;
      payload["paymentStatus"] =
          paid >= _totalCost() ? "Paid" : paid > 0 ? "Partial" : "Pending";
      payload["paymentDate"] = payDate.toIso8601String();
      if ((_paymentResult!['note'] as String?)?.isNotEmpty == true) {
        payload["notes"] = _paymentResult!['note'];
      }
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
          ? 'Labour entry updated successfully!'
          : 'Labour entry logged to database!');
      Navigator.maybePop(context);
    } else {
      _snack('Error saving to server. Please try again.');
    }

    setState(() => _isSaving = false);
  }

  Widget _buildPaymentSection() {
    if (_isAddAndPay) return _buildInlinePaymentForm();

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
                child: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF15803D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Optionally log payment while adding',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _recordPaymentNow,
                activeThumbColor: AppColors.primary,
                onChanged: (v) async {
                  if (v) {
                    final result = await showPaymentSheet(
                      context,
                      entryTitle: _nameCtrl.text.trim().isEmpty
                          ? 'Labour'
                          : _nameCtrl.text.trim(),
                      entryRef: '',
                      totalAmount: _totalCost(),
                      alreadyPaid: 0,
                      vendorName: '',
                      category: _categoryCtrl.text.trim().isEmpty
                          ? 'Labour'
                          : _categoryCtrl.text.trim(),
                    );
                    if (mounted) {
                      setState(() {
                        if (result != null) {
                          _recordPaymentNow = true;
                          _paymentResult = result;
                        }
                      });
                    }
                  } else {
                    setState(() {
                      _recordPaymentNow = false;
                      _paymentResult = null;
                    });
                  }
                },
              ),
            ],
          ),
          if (_recordPaymentNow && _paymentResult != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF0EEF8)),
            const SizedBox(height: 12),
            _buildPaymentSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final amount = (_paymentResult!['amount'] as double?) ?? 0.0;
    final method = (_paymentResult!['method'] as String?) ?? 'Cash';
    final payDate =
        (_paymentResult!['paymentDate'] as DateTime?) ?? DateTime.now();
    final note = (_paymentResult!['note'] as String?) ?? '';
    return GestureDetector(
      onTap: () async {
        final result = await showPaymentSheet(
          context,
          entryTitle: _nameCtrl.text.trim().isEmpty
              ? 'Labour'
              : _nameCtrl.text.trim(),
          entryRef: '',
          totalAmount: _totalCost(),
          alreadyPaid: 0,
          vendorName: '',
          category: _categoryCtrl.text.trim().isEmpty
              ? 'Labour'
              : _categoryCtrl.text.trim(),
        );
        if (result != null && mounted) setState(() => _paymentResult = result);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 8),
                const Text('Payment Recorded',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D))),
                const Spacer(),
                const Text('Tap to edit',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _summaryChip(Icons.currency_rupee,
                      '₹${amount.toStringAsFixed(0)}', 'Amount'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      _summaryChip(Icons.payment_outlined, method, 'Method'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryChip(
                      Icons.calendar_today_outlined,
                      '${payDate.day}/${payDate.month}/${payDate.year}',
                      'Date'),
                ),
              ],
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Note: $note',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1FAE5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(icon, size: 11, color: const Color(0xFF15803D)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlinePaymentForm() {
    const methods = ['Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Card'];
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Record Payment',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    SizedBox(height: 2),
                    Text('Log payment details for this entry',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            sel ? AppColors.primary : const Color(0xFFDDE0F0),
                        width: 1.5),
                  ),
                  child: Text(m,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : AppColors.textDark)),
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
                border:
                    Border.all(color: const Color(0xFFE0E5FF), width: 1.5),
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
          const SizedBox(height: 18),
          const EntryFieldLabel('Notes', required: false),
          const SizedBox(height: 8),
          EntryUnderlineField(
            controller: _paymentNoteCtrl,
            hint: 'e.g. Paid by site manager',
            maxLines: 2,
          ),
        ],
      ),
    );
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

                    // ── SECTION 2: LABOUR ENTRY ───────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon: Icons.people_outline,
                            title: 'Labour Entry',
                            subtitle: 'Date · Labour Type · Unit · Qty · Rate · Amount',
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF0EEF8)),
                          const SizedBox(height: 16),

                          // ── 1. DATE ────────────────────────────────────────
                          const EntryFieldLabel('Date', required: true),
                          const SizedBox(height: 8),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color(0xFF173EEA), width: 2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      color: AppColors.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.primary, size: 22),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── 2. LABOUR TYPE ─────────────────────────────────
                          const EntryFieldLabel('Labour Type', required: true),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _nameCtrl,
                            hint: 'e.g. Mason, Carpenter, Steel Fixer',
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_nameError != null) EntryErrorText(_nameError!),
                          const SizedBox(height: 20),

                          // ── 3. UNIT ────────────────────────────────────────
                          const EntryFieldLabel('Unit', required: true),
                          const SizedBox(height: 8),
                          UnitSelectorField(
                            value: _selectedUnit,
                            units: kLabourUnits,
                            hint: 'Select unit (e.g. Day, Hour, Sq ft)',
                            onChanged: (u) =>
                                setState(() => _selectedUnit = u),
                          ),
                          const SizedBox(height: 20),

                          // ── 4. QUANTITY ────────────────────────────────────
                          const EntryFieldLabel('Quantity', required: true),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _qtyCtrl,
                            hint: '0',
                            suffix: _selectedUnit ?? 'Unit',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_qtyError != null) EntryErrorText(_qtyError!),
                          const SizedBox(height: 20),

                          // ── 5. RATE ────────────────────────────────────────
                          const EntryFieldLabel('Rate (₹)', required: true),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _rateCtrl,
                            hint: '0',
                            prefix: '₹',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_rateError != null) EntryErrorText(_rateError!),
                          const SizedBox(height: 20),

                          // ── 6. AMOUNT (auto-calculated) ────────────────────
                          const EntryFieldLabel('Amount (₹)'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFCDD1F0), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.currency_rupee_rounded,
                                    size: 16, color: Color(0xFF173EEA)),
                                const SizedBox(width: 4),
                                Text(
                                  (() {
                                    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
                                    final rate = double.tryParse(_rateCtrl.text) ?? 0;
                                    final sub = qty * rate;
                                    return sub > 0
                                        ? sub.toStringAsFixed(sub % 1 == 0 ? 0 : 2)
                                        : '—';
                                  })(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF173EEA),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E3FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Auto',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF173EEA),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── OPTIONAL DETAILS ───────────────────────────────
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(color: Color(0xFFF0EEF8))),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Text(
                                  'OPTIONAL DETAILS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textLight,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const Expanded(
                                  child: Divider(color: Color(0xFFF0EEF8))),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── 7. TRADE / WORK TYPE ───────────────────────────
                          const EntryFieldLabel('Trade / Work Type (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _workTypeCtrl,
                            hint: 'e.g. Masonry, Barbending, Concrete Crew',
                          ),
                          const SizedBox(height: 20),

                          // ── 8. CONTRACTOR / TEAM ──────────────────────────
                          const EntryFieldLabel('Contractor / Team (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _categoryCtrl,
                            hint: 'e.g. Vertex Infra Contractors',
                          ),
                          const SizedBox(height: 20),

                          // ── 9. OVERTIME ────────────────────────────────────
                          const EntryFieldLabel('Overtime Amount (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _overtimeCtrl,
                            hint: '0',
                            prefix: '₹',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 20),

                          // ── 10. NOTES ──────────────────────────────────────
                          const EntryFieldLabel('Notes (Optional)'),
                          const SizedBox(height: 8),
                          EntryNotesField(controller: _notesCtrl),
                        ],
                      ),
                    ),



                    CostSummaryCard(
                      totalAmount: _totalCost(),
                      label: 'Calculated Operational Labor Budget',
                      subtotals: [
                        (
                          'Qty × Rate',
                          '${_qtyCtrl.text.isEmpty ? "—" : _qtyCtrl.text} ${_selectedUnit ?? "Unit"} × ₹${_rateCtrl.text.isEmpty ? "—" : _rateCtrl.text}',
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
                            onRemove: () => setState(() => _attachment = null),
                          ),
                        ],
                      ),
                    ),

                    _buildPaymentSection(),
                    const SizedBox(height: 4),
                    EntrySubmitButton(
                      label: 'Save Labour Entry',
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