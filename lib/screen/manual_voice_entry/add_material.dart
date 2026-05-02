import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/controller/entry_model.dart' hide EntryType;
// Alias for entry_model's EntryType used only by Entry() constructor
import 'package:buildtrack_mobile/controller/entry_model.dart' as em;
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';
import 'package:provider/provider.dart';

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({super.key});
  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  static const primaryBlue = AppColors.primary;
  static const bgColor = AppColors.gradientStart;
  static const textDark = AppColors.textDark;
  static const textGray = AppColors.textLight;
  static const errorRed = AppColors.error;

  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _rateController = TextEditingController();
  // ── STEP 5A: New state for dependent dropdowns + brand ───────────────────
  String?       _selectedProjectId;
  String?       _selectedFloor;
  ProjectStage? _selectedPhase;
  final _brandCtrl = TextEditingController();
  // ─────────────────────────────────────────────────────────────────

  bool _supplierError = false;
  bool _supplierSelected = false;

  bool _isEditing = false;
  bool _isSaving = false;

  String? _nameError;
  String? _qtyError;
  String? _rateError;

  PickedAttachment? _attachment;

  String? _receiptFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _isEditing = args['isEditing'] as bool? ?? false;

      // Block editing approved entries
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
    _brandCtrl.dispose(); // STEP 5A
    super.dispose();
  }

  String get _screenTitle => _isEditing ? 'Edit Material' : 'Add Material';

  String _computeTotal() {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    return (qty * rate).toStringAsFixed(2);
  }

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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(title: 'Basic Details'),
                    // ── STEP 5B/5C/5D: Dependent dropdowns ────────────────────────
                    Builder(builder: (context) {
                      final provider = context.watch<ProjectProvider>();
                      final projects = provider.projects;
                      // Find selected project safely
                      final selProject = _selectedProjectId == null
                          ? null
                          : projects.cast<ProjectModel?>().firstWhere(
                              (p) => p?.id == _selectedProjectId,
                              orElse: () => null,
                            );
                      final floors = selProject?.floors ?? ['Ground Floor'];

                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // STEP 5B — Project dropdown
                            _sectionLabel('Project'),
                            const SizedBox(height: 8),
                            _dropdownField<String>(
                              value: _selectedProjectId,
                              hint: 'Select project',
                              items: projects.map((p) =>
                                DropdownMenuItem(value: p.id, child: Text(p.name))
                              ).toList(),
                              onChanged: (val) => setState(() {
                                _selectedProjectId = val;
                                _selectedFloor = null;  // reset children
                                _selectedPhase = null;
                              }),
                            ),
                            const SizedBox(height: 16),

                            // STEP 5C — Floor dropdown (enabled only when project selected)
                            _sectionLabel('Floor / Zone'),
                            const SizedBox(height: 8),
                            _dropdownField<String>(
                              value: _selectedFloor,
                              hint: _selectedProjectId == null
                                  ? 'Select project first'
                                  : 'Select floor',
                              enabled: _selectedProjectId != null,
                              items: floors.map((f) =>
                                DropdownMenuItem(value: f, child: Text(f))
                              ).toList(),
                              onChanged: _selectedProjectId == null
                                  ? null
                                  : (val) => setState(() {
                                      _selectedFloor = val;
                                      _selectedPhase = null; // reset phase
                                    }),
                            ),
                            const SizedBox(height: 16),

                            // STEP 5D — Phase dropdown (enabled only when floor selected)
                            _sectionLabel('Phase (Optional)'),
                            const SizedBox(height: 8),
                            _dropdownField<ProjectStage>(
                              value: _selectedPhase,
                              hint: _selectedFloor == null
                                  ? 'Select floor first'
                                  : 'Select phase',
                              enabled: _selectedFloor != null,
                              items: ProjectStage.values.map((s) =>
                                DropdownMenuItem(value: s, child: Text(s.label))
                              ).toList(),
                              onChanged: _selectedFloor == null
                                  ? null
                                  : (val) => setState(() => _selectedPhase = val),
                            ),
                          ],
                        ),
                      );
                    }),
                    // ─────────────────────────────────────────────────────────────────

                    const AppSectionHeader(title: 'Basic Details'),
                    AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Material Name
                          _sectionLabel('Material Name'),
                          const SizedBox(height: 8),
                          _underlineField(
                            _nameController,
                            hint: 'Enter material name',
                          ),
                          if (_nameError != null) ...[
                            const SizedBox(height: 4),
                            _errorText(_nameError!),
                          ],
                          const SizedBox(height: 16),

                          // STEP 5E — Brand field
                          _sectionLabel('Brand (Optional)'),
                          const SizedBox(height: 8),
                          _underlineField(
                            _brandCtrl,
                            hint: 'e.g. UltraTech, Tata Steel',
                          ),
                          const SizedBox(height: 16),

                          // Supplier
                          _supplierField(),
                          if (_supplierError) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Please select a valid supplier from the database.',
                              style: TextStyle(
                                color: errorRed,
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const AppSectionHeader(title: 'Purchase Details'),
                    AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quantity + Rate row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      'Rate per Unit',
                                      _rateController,
                                      '₹',
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                    ),
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

                          // Total amount auto-computed
                          _totalCard(),
                        ],
                      ),
                    ),

                    const AppSectionHeader(title: 'Receipt / Bill'),
                    AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: _uploadBox(),
                    ),

                    const SizedBox(height: 4),
                    _buildSaveButton(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            style: AppTheme.heading3.copyWith(color: primaryBlue),
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

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () async {
              // ── STEP 5G: Validate project + floor ─────────────────────────
              if (_selectedProjectId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a project'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              if (_selectedFloor == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a floor / zone'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              // ──────────────────────────────────────────────────────────────
              if (!_validate()) return;
              setState(() => _isSaving = true);
              await Future.delayed(const Duration(milliseconds: 600));
              if (!mounted) return;
              // ── STEP 5F: Persist to ProjectProvider ────────────────────────
              final entryId = 'MAT-${DateTime.now().millisecondsSinceEpoch}';
              context.read<ProjectProvider>().addEntry(
                EntryModel(
                  id:          entryId,
                  projectId:   _selectedProjectId!,
                  type:        EntryType.material,
                  amount:      double.tryParse(_qtyController.text) ?? 0.0,
                  date:        DateTime.now(),
                  description: _nameController.text,
                  brand:       _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
                  ratePerUnit: double.tryParse(_rateController.text),
                  floor:       _selectedFloor,
                  phase:       _selectedPhase,
                ),
              );
              // ──────────────────────────────────────────────────────────────
              Navigator.pushNamed(
                // ignore: use_build_context_synchronously
                context,
                '/logs',
                arguments: {
                  'type': 'material',
                  'name': _nameController.text,
                  'newEntry':
                      Entry(
                        id: entryId,
                        type: em.EntryType.material,
                        projectId: _selectedProjectId ?? UserSession.projectId,
                        createdBy: UserSession.userId,
                      ).toMap()..addAll({
                        'title': _nameController.text,
                        'ref': '#$entryId',
                        'amount': '+${_qtyController.text}',
                        'date': 'Today',
                        'isPositive': true,
                        'icon': Icons.inventory_2_outlined,
                        'receipt': _receiptFile,
                      }),
                },
              );
              setState(() => _isSaving = false);
            },
      child: AnimatedOpacity(
        opacity: _isSaving ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: AppGradients.primaryButton,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Save Entry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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

  Widget _underlineField(
    TextEditingController ctrl, {
    String hint = '',
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
      ),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: textGray),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
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
        _sectionLabel(label),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    keyboardType: keyboardType,
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ),
                Text(
                  suffix,
                  style: TextStyle(
                    color: textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
        _sectionLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
          ),
          child: Row(
            children: [
              Text(
                '$prefix ',
                style: TextStyle(
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
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 10,
                    ),
                  ),
                  style: TextStyle(
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
              Text(
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
                style: TextStyle(
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
              borderRadius: BorderRadius.circular(16),
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
          text: TextSpan(
            text: 'Supplier ',
            style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.5,
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
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
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

  Widget _uploadBox() {
    return UploadBox(
      attachment: _attachment,
      emptyLabel: 'Tap to attach bill',
      onPicked: (a) => setState(() => _attachment = a),
      onRemove: () => setState(() => _attachment = null),
    );
  }

  void _showSupplierPicker() {
    showModalBottomSheet(
      context: context,
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE0F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Supplier',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
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
                              style: TextStyle(
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

  Widget _sectionLabel(String label) => Text(
    label,
    style: TextStyle(
      color: primaryBlue,
      fontWeight: FontWeight.w700,
      fontSize: 13,
      letterSpacing: 0.5,
    ),
  );

  Widget _errorText(String msg) => Text(
    msg,
    style: TextStyle(
      color: errorRed,
      fontSize: 11.5,
      fontStyle: FontStyle.italic,
    ),
  );

  // ── STEP 5B/5C/5D: Reusable dropdown helper (matches underline design) ──────
  Widget _dropdownField<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: enabled ? primaryBlue : textGray,
              width: 2,
            ),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled ? primaryBlue : textGray,
            ),
            hint: Text(
              hint,
              style: TextStyle(
                color: textGray,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
            items: enabled ? items : [],
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ),
    );
  }
  // ─────────────────────────────────────────────────────────────────
}
