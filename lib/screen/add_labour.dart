import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:flutter/material.dart';

class AddLabourScreen extends StatefulWidget {
  const AddLabourScreen({super.key});
  @override
  State<AddLabourScreen> createState() => _AddLabourScreenState();
}

class _AddLabourScreenState extends State<AddLabourScreen> {

  static const primaryBlue = Color(0xFF2233DD);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);
  static const errorRed = Color(0xFFD32F2F);

  final _hoursController = TextEditingController();
  final _rateController = TextEditingController();
  final _nameController = TextEditingController();
  final _workTypeController = TextEditingController();
  final _notesController = TextEditingController();

  String? _receiptFile;
  bool _isSaving = false;

  String? _nameError;
  String? _hoursError;
  String? _rateError;

  @override
  void dispose() {
    _hoursController.dispose();
    _rateController.dispose();
    _nameController.dispose();
    _workTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _computeTotal() {
    final hours = double.tryParse(_hoursController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    return (hours * rate).toStringAsFixed(2);
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameController.text.trim().isEmpty
          ? 'Worker / team name is required'
          : null;
      final hours = double.tryParse(_hoursController.text);
      _hoursError =
          (hours == null || hours <= 0) ? 'Enter valid hours > 0' : null;
      final rate = double.tryParse(_rateController.text);
      _rateError =
          (rate == null || rate <= 0) ? 'Enter valid rate > 0' : null;
      ok = _nameError == null && _hoursError == null && _rateError == null;
    });
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Add Labour',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
              rightWidget: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, color: Colors.grey, size: 18),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const AppSectionHeader(title: 'Labour Details'),
                    AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Worker / Team Name
                          _sectionLabel('Worker / Team Name'),
                          const SizedBox(height: 8),
                          _underlineField(
                            Icons.person_outline,
                            _nameController,
                            hint: 'Enter worker or team name',
                          ),
                          if (_nameError != null) ...[
                            const SizedBox(height: 4),
                            _errorText(_nameError!),
                          ],
                          const SizedBox(height: 20),

                          // Work Type
                          _sectionLabel('Work Type'),
                          const SizedBox(height: 8),
                          _underlineField(
                            Icons.work_outline,
                            _workTypeController,
                            hint: 'e.g. Masonry, Plumbing',
                          ),
                        ],
                      ),
                    ),

                    const AppSectionHeader(title: 'Work Details'),
                    AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hours + Rate row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel('Hours Worked'),
                                    const SizedBox(height: 8),
                                    _suffixUnderlineField(
                                      _hoursController,
                                      suffix: 'hrs',
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    if (_hoursError != null) ...[
                                      const SizedBox(height: 4),
                                      _errorText(_hoursError!),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel('Rate / Hour'),
                                    const SizedBox(height: 8),
                                    _prefixUnderlineField(
                                      _rateController,
                                      prefix: '₹',
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

                          // Total auto-computed
                          _totalCard(),
                        ],
                      ),
                    ),

                    const AppSectionHeader(title: 'Remarks'),
                    AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Notes (Optional)'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFCCCFE8), width: 1.5),
                            ),
                            child: TextField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Add any site notes or remarks…',
                                hintStyle:
                                    TextStyle(color: textGray, fontSize: 13.5),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const AppSectionHeader(title: 'Receipt / Bill'),
                    AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: _uploadBox(
                        uploadLabel: 'Tap to upload bill',
                        attachedLabel: 'Receipt attached',
                        onTap: () {
                          setState(
                            () => _receiptFile =
                                'labour_receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Receipt attached')));
                        },
                        onRemove: () => setState(() => _receiptFile = null),
                      ),
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
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _underlineField(
    IconData icon,
    TextEditingController ctrl, {
    String hint = '',
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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
                  fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suffixUnderlineField(
    TextEditingController ctrl, {
    required String suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              ),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: textDark),
            ),
          ),
          Text(suffix,
              style: const TextStyle(
                  color: textGray, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _prefixUnderlineField(
    TextEditingController ctrl, {
    required String prefix,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
      ),
      child: Row(
        children: [
          Text('$prefix ',
              style: const TextStyle(
                  color: textGray, fontSize: 16, fontWeight: FontWeight.w500)),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              ),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: textDark),
            ),
          ),
        ],
      ),
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
              const Text('TOTAL AMOUNT',
                  style: TextStyle(
                      color: textGray,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text('₹ ${_computeTotal()}',
                  style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3)),
            ],
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calculate_outlined,
                color: primaryBlue, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _uploadBox({
    required String uploadLabel,
    required String attachedLabel,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: _receiptFile == null ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: _receiptFile != null
              ? const Color(0xFFEEF8EE)
              : const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _receiptFile != null
                ? Colors.green.shade300
                : const Color(0xFFCCCFE8),
            width: 1.5,
          ),
        ),
        child: _receiptFile != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 26),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(attachedLabel,
                            style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700, color: textDark)),
                        Text(_receiptFile!,
                            style:
                                AppTheme.caption.copyWith(color: textGray),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          color: Colors.redAccent, size: 18),
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
                    child: const Icon(Icons.cloud_upload_outlined,
                        color: primaryBlue, size: 26),
                  ),
                  const SizedBox(height: 10),
                  Text(uploadLabel,
                      style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700, color: textDark)),
                  const SizedBox(height: 4),
                  Text('PNG, JPG OR PDF UP TO 10MB',
                      style: AppTheme.caption
                          .copyWith(color: textGray, fontSize: 11)),
                ],
              ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () async {
              if (!_validate()) return;
              setState(() => _isSaving = true);
              await Future.delayed(const Duration(milliseconds: 600));
              if (!mounted) return;
              Navigator.pushNamed(
                // ignore: use_build_context_synchronously
                context,
                '/logs',
                arguments: {
                  'type': 'labour',
                  'name': _nameController.text,
                  'newEntry': {
                    'title': _nameController.text,
                    'ref': '#LAB-${DateTime.now().millisecondsSinceEpoch}',
                    'amount': '+${_hoursController.text} hrs',
                    'date': 'Today',
                    'isPositive': true,
                    'icon': Icons.people_outline,
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
          padding: const EdgeInsets.symmetric(vertical: 17),
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
          child: _isSaving
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Save Entry',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.5),
      );

  Widget _errorText(String msg) => Text(
        msg,
        style: const TextStyle(
            color: errorRed, fontSize: 11.5, fontStyle: FontStyle.italic),
      );
}