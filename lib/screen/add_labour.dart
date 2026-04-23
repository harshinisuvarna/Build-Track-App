import 'package:flutter/material.dart';

class AddLabourScreen extends StatefulWidget {
  const AddLabourScreen({super.key});

  @override
  State<AddLabourScreen> createState() => _AddLabourScreenState();
}

class _AddLabourScreenState extends State<AddLabourScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const purple     = Color(0xFF6B3FE7);
  static const bgColor    = Color(0xFFF4F6FB);
  static const textDark   = Color(0xFF0F1724);
  static const textGray   = Color(0xFF7B8A9E);
  static const errorRed   = Color(0xFFD32F2F);

  final _nameController        = TextEditingController(text: 'Concrete Form Workers');
  final _workerCountController = TextEditingController(text: '8');
  final _rateController        = TextEditingController(text: '450');
  final _notesController       = TextEditingController();

  bool _supervisorError    = false;
  bool _supervisorSelected = false;
  int  _selectedNavIndex   = 2;
  int  _shiftTypeIndex     = 0;
  bool _isEditing          = false;

  // FIX 2: receipt stored in state
  String? _receiptFile;

  final _shiftTypes = ['Daily', 'Hourly'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _isEditing = args['isEditing'] as bool? ?? false;
      // FIX 3: edit mode pre-fills with _workerCountController
      if (_isEditing) {
        _nameController.text =
            args['title'] as String? ?? args['name'] as String? ?? '';
        final rawAmount = args['amount']?.toString() ?? '';
        _workerCountController.text =
            rawAmount.replaceAll('+', '').replaceAll('-', '');
      } else {
        final prefill = args['prefill'] as String?;
        if (prefill != null) _nameController.text = prefill;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _workerCountController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // FIX 7: null-safe total
  String _computeTotal() {
    final count = double.tryParse(_workerCountController.text) ?? 0;
    final rate  = double.tryParse(_rateController.text)        ?? 0;
    return (count * rate).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: textDark, size: 22),
          ),
          Text(_isEditing ? 'Edit Labour' : 'Add Labour',
              style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
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
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker / Team Name
          const Text('Worker / Team Name',
              style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: primaryBlue, width: 2))),
            child: Row(children: [
              const Icon(Icons.engineering_outlined,
                  color: textGray, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10)),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textDark),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Shift type toggle
          const Text('Work Type',
              style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
                border:
                    Border.all(color: const Color(0xFFDDE0F0)),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: _shiftTypes.asMap().entries.map((e) {
                final sel = e.key == _shiftTypeIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _shiftTypeIndex = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                          color: sel
                              ? primaryBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(e.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : textGray,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Workers count + Rate
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      _shiftTypeIndex == 0
                          ? 'No. of Workers'
                          : 'Hours Worked',
                      style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: primaryBlue, width: 2))),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _workerCountController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 10)),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textDark),
                        ),
                      ),
                      Text(
                          _shiftTypeIndex == 0 ? 'ppl' : 'hrs',
                          style: const TextStyle(
                              color: textGray,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      _shiftTypeIndex == 0
                          ? 'Rate / Day'
                          : 'Rate / Hour',
                      style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: primaryBlue, width: 2))),
                    child: Row(children: [
                      const Text('\$ ',
                          style: TextStyle(
                              color: textGray,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                      Expanded(
                        child: TextField(
                          controller: _rateController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 10)),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textDark),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 18),

          // Total
          _totalCard(),
          const SizedBox(height: 20),

          // Notes
          const Text('Notes (Optional)',
              style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFFDDE0F0), width: 1.5),
                borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Add any site notes or remarks...',
                  hintStyle: TextStyle(color: textGray, fontSize: 13.5),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12)),
              style: const TextStyle(fontSize: 14, color: textDark),
            ),
          ),
          const SizedBox(height: 20),

          // Supervisor
          _supervisorField(),
          if (_supervisorError) ...[
            const SizedBox(height: 6),
            const Text(
              'Please select a valid supervisor from the database.',
              style: TextStyle(
                  color: errorRed,
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 20),

          // Upload Timesheet
          const Text('Upload Timesheet',
              style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 10),
          _uploadBox(context,
              label: 'Tap to upload timesheet',
              uploadedFile: _receiptFile,
              onTap: () {
                // FIX 2: stores receipt on tap
                setState(() => _receiptFile =
                    'timesheet_${DateTime.now().millisecondsSinceEpoch}.pdf');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Timesheet attached')),
                );
              }),
        ],
      ),
    );
  }

  // ── Save Button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_supervisorSelected) {
          setState(() => _supervisorError = true);
          return;
        }
        // FIX 1: save passes newEntry to /logs
        Navigator.pushNamed(
          context,
          '/logs',
          arguments: {
            'type': 'labour',
            'name': _nameController.text,
            'newEntry': {
              'title': _nameController.text,
              'ref':
                  '#LAB-${DateTime.now().millisecondsSinceEpoch}',
              'amount': '+${_workerCountController.text}',
              'date': 'Today',
              'isPositive': true,
              'icon': Icons.people_outline,
              // FIX 5: receipt consistently passed
              'receipt': _receiptFile,
            },
          },
        );
      },
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
                offset: const Offset(0, 5)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Save entry',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            SizedBox(width: 8),
            Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Reusable helpers ──────────────────────────────────────────────────────

  Widget _totalCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(14)),
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
                  Text('\$ ${_computeTotal()}',
                      style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3)),
                ]),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.calculate_outlined,
                  color: primaryBlue, size: 20),
            ),
          ]),
    );
  }

  Widget _supervisorField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
        text: const TextSpan(
          text: 'Supervisor ID ',
          style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 14),
          children: [
            TextSpan(
                text: '(Required)',
                style: TextStyle(color: errorRed))
          ],
        ),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () => _showSupervisorPicker(),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: _supervisorError ? errorRed : primaryBlue,
                  width: 2),
            ),
          ),
          child: Row(children: [
            const Icon(Icons.badge_outlined,
                color: textGray, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _supervisorSelected
                    ? 'John Miller (SUP-042)'
                    : 'Select supervisor',
                style: TextStyle(
                    color: _supervisorSelected ? textDark : textGray,
                    fontSize: 15,
                    fontWeight: _supervisorSelected
                        ? FontWeight.w600
                        : FontWeight.w400),
              ),
            ),
            if (_supervisorError)
              const Icon(Icons.error, color: errorRed, size: 22),
            if (_supervisorSelected)
              const Icon(Icons.check_circle,
                  color: Colors.green, size: 22),
          ]),
        ),
      ),
    ]);
  }

  // FIX 2: upload box shows receipt confirmation
  Widget _uploadBox(BuildContext context,
      {required String label,
      required String? uploadedFile,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
              width: 1.5),
        ),
        child: uploadedFile != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 26),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Timesheet attached',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: textDark)),
                      Text(uploadedFile,
                          style: const TextStyle(
                              color: textGray, fontSize: 12)),
                    ],
                  ),
                ],
              )
            : Column(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.upload_file_outlined,
                      color: primaryBlue, size: 26),
                ),
                const SizedBox(height: 10),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: textDark)),
                const SizedBox(height: 4),
                const Text('PNG, JPG OR PDF UP TO 10MB',
                    style: TextStyle(
                        color: textGray,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)),
              ]),
      ),
    );
  }

  void _showSupervisorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Supervisor',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            ...[
              'John Miller (SUP-042)',
              'Sarah Chen (SUP-017)',
              'David Kumar (SUP-089)',
            ].map((s) => ListTile(
                  title: Text(s,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  leading: const Icon(Icons.badge_outlined,
                      color: primaryBlue),
                  onTap: () {
                    setState(() {
                      _supervisorSelected = true;
                      _supervisorError = false;
                    });
                    Navigator.pop(ctx);
                  },
                )),
          ],
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
              offset: const Offset(0, -2))
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
              _navItem(context, 0, Icons.home_rounded, 'HOME',
                  route: '/home'),
              _navItem(context, 1, Icons.architecture_outlined,
                  'PROJECTS', route: '/projects'),
              _navEntryButton(context),
              _navItem(context, 3, Icons.inventory_2_outlined,
                  'INVENTORY', route: '/inventory'),
              _navItem(context, 4, Icons.bar_chart_outlined,
                  'REPORTS', route: '/reports'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon,
      String label,
      {String? route}) {
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
          children: [
            Icon(icon,
                size: 22,
                color: isActive ? primaryBlue : textGray),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isActive ? primaryBlue : textGray,
                    letterSpacing: 0.3)),
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
                    offset: const Offset(0, 4))
              ],
            ),
            child:
                const Icon(Icons.add, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 3),
          Text('ENTRY',
              style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isActive ? primaryBlue : textGray,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}