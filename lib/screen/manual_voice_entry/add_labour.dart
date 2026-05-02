import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/widgets/app_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/entry_model.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';

class AddLabourScreen extends StatefulWidget {
  const AddLabourScreen({super.key});
  @override
  State<AddLabourScreen> createState() => _AddLabourScreenState();
}

class _AddLabourScreenState extends State<AddLabourScreen> {
  static const primaryBlue = AppColors.primary;
  static const bgColor = AppColors.gradientStart;
  static const textDark = AppColors.textDark;
  static const textGray = AppColors.textLight;
  static const errorRed = AppColors.error;

  final _hoursController = TextEditingController();
  final _rateController = TextEditingController();
  final _nameController = TextEditingController();
  final _workTypeController = TextEditingController();
  final _notesController = TextEditingController();

  PickedAttachment? _attachment;

  String? _receiptFile;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _argsLoaded = false;

  String? _nameError;
  String? _hoursError;
  String? _rateError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

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
        _hoursController.text = rawAmount
            .replaceAll('+', '')
            .replaceAll('-', '')
            .replaceAll(' hrs', '')
            .replaceAll(' workers', '');
      }
    }
  }

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
      _hoursError = (hours == null || hours <= 0)
          ? 'Enter valid hours > 0'
          : null;
      final rate = double.tryParse(_rateController.text);
      _rateError = (rate == null || rate <= 0) ? 'Enter valid rate > 0' : null;
      ok = _nameError == null && _hoursError == null && _rateError == null;
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
            AppTopBar(
              title: _isEditing ? 'Edit Labour' : 'Add Labour',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFCCCFE8),
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: 'Add any site notes or remarksâ€¦',
                                hintStyle: TextStyle(
                                  color: textGray,
                                  fontSize: 13.5,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              style: TextStyle(
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
                            const SnackBar(content: Text('Receipt attached')),
                          );
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
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '0',
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
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '0',
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

  Widget _uploadBox({
    required String uploadLabel,
    required String attachedLabel,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return UploadBox(
      attachment: _attachment,
      emptyLabel: uploadLabel,
      onPicked: (a) => setState(() => _attachment = a),
      onRemove: () => setState(() => _attachment = null),
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
                  'newEntry':
                      Entry(
                        id: 'LAB-${DateTime.now().millisecondsSinceEpoch}',
                        type: EntryType.labour,
                        projectId: UserSession.projectId,
                        createdBy: UserSession.userId,
                      ).toMap()..addAll({
                        'title': _nameController.text,
                        'ref': '#LAB-${DateTime.now().millisecondsSinceEpoch}',
                        'amount': '+${_hoursController.text} hrs',
                        'date': 'Today',
                        'isPositive': true,
                        'icon': Icons.people_outline,
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
}
