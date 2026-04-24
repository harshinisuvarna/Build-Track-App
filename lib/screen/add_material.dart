import 'package:flutter/material.dart';

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({super.key});

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);
  static const errorRed = Color(0xFFD32F2F);

  // ❌ FIX: removed hardcoded default values — controllers start empty
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _rateController = TextEditingController();

  bool _supplierError = false;
  bool _supplierSelected = false;
  int _selectedNavIndex = 2;
  bool _isEditing = false;
  // FIX: loading state to prevent double-tap
  bool _isSaving = false;

  // FIX: per-field error strings for inline validation feedback
  String? _nameError;
  String? _qtyError;
  String? _rateError;

  String? _receiptFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _isEditing = args['isEditing'] as bool? ?? false;
      if (_isEditing) {
        _nameController.text =
            args['title'] as String? ?? args['name'] as String? ?? '';
        final rawAmount = args['amount']?.toString() ?? '';
        _qtyController.text = rawAmount.replaceAll('+', '').replaceAll('-', '');
      } else {
        final prefill = args['prefill'] as String?;
        if (prefill != null) _nameController.text = prefill;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  String get _screenTitle => _isEditing ? 'Edit Material' : 'Add Material';

  String _computeTotal() {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    return (qty * rate).toStringAsFixed(2);
  }

  // ✅ FIX: centralised validation — returns true only when all fields are valid
  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameController.text.trim().isEmpty
          ? 'Item name is required'
          : null;
      final qty = double.tryParse(_qtyController.text);
      _qtyError = (qty == null || qty <= 0)
          ? 'Enter a valid quantity > 0'
          : null;
      final rate = double.tryParse(_rateController.text);
      _rateError = (rate == null || rate <= 0)
          ? 'Enter a valid rate > 0'
          : null;
      _supplierError = !_supplierSelected;
      ok =
          _nameError == null &&
          _qtyError == null &&
          _rateError == null &&
          _supplierSelected;
    });
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: keyboard-aware bottom padding so fields aren't hidden
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: bgColor,
      // ✅ FIX: resizeToAvoidBottomInset true (default) combined with padding below
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                // ✅ FIX: extra bottom padding equals keyboard height
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottomInset),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildFormCard(context),
                    const SizedBox(height: 28),
                    _buildSaveButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.maybePop(context),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.arrow_back, color: textDark, size: 22),
              ),
            ),
          ),
          Text(
            _screenTitle,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade800,
            child: const Icon(Icons.list_alt, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Form Card ─────────────────────────────────────────────────────────────

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name
          const Text(
            'Item name',
            style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _underlineField(
            Icons.inventory_2_outlined,
            _nameController,
            hint: 'Enter material name',
          ),
          // ✅ FIX: inline name error
          if (_nameError != null) ...[
            const SizedBox(height: 4),
            _errorText(_nameError!),
          ],
          const SizedBox(height: 20),

          // Quantity + Rate
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labeledUnderlineField(
                      'Quantity',
                      _qtyController,
                      'm³',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    // ✅ FIX: inline qty error
                    if (_qtyError != null) ...[
                      const SizedBox(height: 4),
                      _errorText(_qtyError!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labeledUnderlineFieldPrefix(
                      'Rate',
                      _rateController,
                      '₹',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    // ✅ FIX: inline rate error
                    if (_rateError != null) ...[
                      const SizedBox(height: 4),
                      _errorText(_rateError!),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Total
          _totalCard(),
          const SizedBox(height: 20),

          // Supplier
          _supplierField(),
          if (_supplierError) ...[
            const SizedBox(height: 6),
            const Text(
              'Please select a valid supplier from the database.',
              style: TextStyle(
                color: errorRed,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Upload Receipt
          const Text(
            'Upload Receipt / Bill',
            style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _uploadBox(
            context,
            label: 'Tap to upload bill',
            uploadedFile: _receiptFile,
            onTap: () {
              setState(
                () => _receiptFile =
                    'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt attached: receipt.pdf')),
              );
            },
            // ✅ FIX: remove receipt callback
            onRemove: () => setState(() => _receiptFile = null),
          ),
        ],
      ),
    );
  }

  // ── Save Button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      // ✅ FIX: validate first; disable during save to prevent double-tap
      onTap: _isSaving
          ? null
          : () async {
              if (!_validate()) return;
              setState(() => _isSaving = true);
              // Simulate async save (replace with real API call)
              await Future.delayed(const Duration(milliseconds: 600));
              if (!mounted) return;
              Navigator.pushNamed(
                // ignore: use_build_context_synchronously
                context,
                '/logs',
                arguments: {
                  'type': 'material',
                  'name': _nameController.text,
                  'newEntry': {
                    'title': _nameController.text,
                    'ref': '#MAT-${DateTime.now().millisecondsSinceEpoch}',
                    'amount': '+${_qtyController.text}',
                    'date': 'Today',
                    'isPositive': true,
                    'icon': Icons.inventory_2_outlined,
                    'receipt': _receiptFile,
                  },
                },
              );
              setState(() => _isSaving = false);
            },
      child: AnimatedOpacity(
        opacity: _isSaving ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2233DD), Color(0xFF5B3FE0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          // ✅ FIX: show CircularProgressIndicator while saving
          child: _isSaving
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Save entry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Reusable field helpers ────────────────────────────────────────────────

  Widget _underlineField(
    IconData icon,
    TextEditingController ctrl, {
    String hint = '',
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textGray, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: textGray),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledUnderlineField(
    String label,
    TextEditingController ctrl,
    String suffix, {
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
              Text(
                suffix,
                style: const TextStyle(
                  color: textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _labeledUnderlineFieldPrefix(
    String label,
    TextEditingController ctrl,
    String prefix, {
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
          ),
          child: Row(
            children: [
              Text(
                '$prefix ',
                style: const TextStyle(
                  color: textGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _totalCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL AMOUNT',
                style: TextStyle(
                  color: textGray,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹ ${_computeTotal()}',
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calculate_outlined,
              color: primaryBlue,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _supplierField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Supplier ID ',
            style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: '(Required)',
                style: TextStyle(color: errorRed),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSupplierPicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _supplierError ? errorRed : primaryBlue,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.business_outlined, color: textGray, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _supplierSelected
                        ? 'ABC Suppliers Ltd.'
                        : 'Select supplier',
                    style: TextStyle(
                      color: _supplierSelected ? textDark : textGray,
                      fontSize: 15,
                      fontWeight: _supplierSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (_supplierError)
                  const Icon(Icons.error, color: errorRed, size: 22),
                if (_supplierSelected)
                  const Icon(Icons.check_circle, color: Colors.green, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ FIX: added `onRemove` callback + remove (❌) button when file attached
  Widget _uploadBox(
    BuildContext context, {
    required String label,
    required String? uploadedFile,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: uploadedFile == null ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: uploadedFile != null
              ? const Color(0xFFEEF8EE)
              : const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploadedFile != null
                ? Colors.green.shade300
                : const Color(0xFFCCCFE8),
            width: 1.5,
          ),
        ),
        child: uploadedFile != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 26),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Receipt attached',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: textDark,
                          ),
                        ),
                        Text(
                          uploadedFile,
                          style: const TextStyle(color: textGray, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ✅ FIX: ❌ remove button — stops propagation via explicit callback
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: primaryBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'PNG, JPG OR PDF UP TO 10MB',
                    style: TextStyle(
                      color: textGray,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showSupplierPicker() {
    showModalBottomSheet(
      context: context,
      // ✅ FIX: white bg + SafeArea + rounded top (consistent bottom sheet)
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Supplier',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              // ✅ FIX: card-style list items
              ...[
                'ABC Suppliers Ltd.',
                'Metro Build Co.',
                'SteelWorks Inc.',
              ].map(
                (s) => Padding(
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
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.business,
                              color: primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              s,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _navItem(context, 0, Icons.home_rounded, 'HOME', route: '/home'),
              _navItem(
                context,
                1,
                Icons.architecture_outlined,
                'PROJECTS',
                route: '/projects',
              ),
              _navEntryButton(context),
              _navItem(
                context,
                3,
                Icons.inventory_2_outlined,
                'INVENTORY',
                route: '/inventory',
              ),
              _navItem(
                context,
                4,
                Icons.bar_chart_outlined,
                'REPORTS',
                route: '/reports',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int index,
    IconData icon,
    String label, {
    String? route,
  }) {
    final isActive = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = index);
        if (route != null) Navigator.pushNamed(context, route);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: isActive ? primaryBlue : textGray),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isActive ? primaryBlue : textGray,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navEntryButton(BuildContext context) {
    final isActive = _selectedNavIndex == 2;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 3),
          Text(
            'ENTRY',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isActive ? primaryBlue : textGray,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error text helper ─────────────────────────────────────────────────────
  Widget _errorText(String msg) => Text(
    msg,
    style: const TextStyle(
      color: errorRed,
      fontSize: 11.5,
      fontStyle: FontStyle.italic,
    ),
  );
}
