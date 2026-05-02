import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';
import 'package:buildtrack_mobile/controller/entry_model.dart' as em;
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:provider/provider.dart';

class ReviewVoiceEntryScreen extends StatefulWidget {
  const ReviewVoiceEntryScreen({super.key});
  @override
  State<ReviewVoiceEntryScreen> createState() => _ReviewVoiceEntryScreenState();
}

class _ReviewVoiceEntryScreenState extends State<ReviewVoiceEntryScreen> {
  static const primaryBlue = AppColors.primary;
  static const purple      = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;

  PickedAttachment? _attachment;

  // âœ… FIX: receipt attachment state + confirm loading state
  bool _isConfirming = false;

  // ── STEP 6A: Voice Parse State ───────────────────────────────────────────
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _brandCtrl;
  
  String? _selectedProjectId;
  String? _selectedFloor;
  ProjectStage? _selectedPhase;

  final String transcript = 
      "Hey SiteTrack, record a material entry for North District. "
      "We just received 12.5 cubic meters of C35 ready-mix concrete from UltraTech. "
      "Rate is fixed at 145 per unit. Log this under structural foundations on 1st Floor.";

  @override
  void initState() {
    super.initState();
    _parseVoiceInput();
  }

  void _parseVoiceInput() {
    String t = transcript.toLowerCase();

    // 1. Amount fallback 0
    final numMatch = RegExp(r'(\d+\.\d+)').firstMatch(t);
    double amount = numMatch != null ? (double.tryParse(numMatch.group(0) ?? '') ?? 0.0) : 0.0;

    // 2. Rate fallback 0
    double rate = 145.0; // Hardcoded mock parsing for demo

    // 3. Brand fallback null
    String? brand;
    if (t.contains("ultratech")) {
      brand = "UltraTech";
    } else if (t.contains("tata")) {
      brand = "Tata";
    }

    // 4. Floor fallback "General"
    String floor = "General";
    if (t.contains("1st floor")) {
      floor = "1st Floor";
    } else if (t.contains("ground floor")) {
      floor = "Ground Floor";
    }

    // 5. Phase optional match
    ProjectStage? phase;
    if (t.contains("foundation")) {
      phase = ProjectStage.foundation;
    } else if (t.contains("structure")) {
      phase = ProjectStage.structure;
    }

    _nameCtrl = TextEditingController(text: "Premium Ready-Mix Concrete (C35)");
    _qtyCtrl = TextEditingController(text: amount > 0 ? amount.toString() : "");
    _rateCtrl = TextEditingController(text: rate.toString());
    _brandCtrl = TextEditingController(text: brand ?? "");
    
    _selectedProjectId = UserSession.projectId;
    _selectedFloor = floor;
    _selectedPhase = phase;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }
  // ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: 'Review voice entry',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    _buildParsedBanner(),
                    const SizedBox(height: 18),
                    _buildMaterialLogCard(),
                    const SizedBox(height: 22),
                    // âœ… FIX: receipt attachment section
                    _buildReceiptSection(),
                    const SizedBox(height: 22),
                    _buildTranscript(),
                    const SizedBox(height: 34),
                    _buildConfirmButton(context),
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

  Widget _buildParsedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: purple,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parsed from voice',
                  style: TextStyle(
                    color: purple,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Confidence: 98.4% • Voice timestamp 10:42 AM',
                  style: TextStyle(
                    color: const Color(0xFF9B7FD6),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialLogCard() {
    return Builder(builder: (context) {
      final provider = context.watch<ProjectProvider>();
      final projects = provider.projects;
      final selProject = _selectedProjectId == null
          ? null
          : projects.cast<ProjectModel?>().firstWhere(
              (p) => p?.id == _selectedProjectId,
              orElse: () => null,
            );
      final List<String> floors = List.from(selProject?.floors ?? ['Ground Floor']);
      if (_selectedFloor != null && !floors.contains(_selectedFloor)) {
        floors.add(_selectedFloor!);
      }

      return Container(
        padding: const EdgeInsets.all(20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Material Log',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Site: North District Phase 2',
                      style: TextStyle(color: textGray, fontSize: 12.5),
                    ),
                  ],
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EEFF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.mic, color: purple, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 20),
          _fieldLabel('NAME'),
          const SizedBox(height: 6),
          _fieldBox(_nameCtrl),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('QUANTITY'),
                    const SizedBox(height: 6),
                    _fieldBox(_qtyCtrl),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('RATE'),
                    const SizedBox(height: 6),
                    _fieldBox(_rateCtrl),
                  ],
                ),
              ),
            ],
          ),
            const SizedBox(height: 16),
            _fieldLabel('PROJECT'),
            const SizedBox(height: 6),
            _dropdownField<String>(
              value: _selectedProjectId,
              hint: 'Select project',
              items: projects.map((p) =>
                DropdownMenuItem(value: p.id, child: Text(p.name))
              ).toList(),
              onChanged: (val) => setState(() {
                _selectedProjectId = val;
                _selectedFloor = null;
                _selectedPhase = null;
              }),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('FLOOR / ZONE'),
                      const SizedBox(height: 6),
                      _dropdownField<String>(
                        value: _selectedFloor,
                        hint: _selectedProjectId == null ? 'Select project first' : 'Select floor',
                        enabled: _selectedProjectId != null,
                        items: floors.map((f) =>
                          DropdownMenuItem(value: f, child: Text(f))
                        ).toList(),
                        onChanged: _selectedProjectId == null ? null : (val) => setState(() {
                          _selectedFloor = val;
                          _selectedPhase = null;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('PHASE (OPTIONAL)'),
                      const SizedBox(height: 6),
                      _dropdownField<ProjectStage>(
                        value: _selectedPhase,
                        hint: _selectedFloor == null ? 'Select floor first' : 'Select phase',
                        enabled: _selectedFloor != null,
                        items: ProjectStage.values.map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.label))
                        ).toList(),
                        onChanged: _selectedFloor == null ? null : (val) => setState(() => _selectedPhase = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _fieldLabel('BRAND'),
            const SizedBox(height: 6),
            _fieldBox(_brandCtrl),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            _fieldLabel('TOTAL ESTIMATED'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDE0F0), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    r'₹1,812.50',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: primaryBlue,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'AUTO',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // âœ… FIX: receipt attachment section identical to manual entry screens
  Widget _buildReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attach Receipt (Optional)',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        UploadBox(
          attachment: _attachment,
          emptyLabel: 'Tap to attach receipt',
          onPicked: (a) => setState(() => _attachment = a),
          onRemove: () => setState(() => _attachment = null),
        ),
      ],
    );
  }

  Widget _buildTranscript() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.format_align_left, color: primaryBlue, size: 15),
            const SizedBox(width: 7),
            Text(
              'ORIGINAL AUDIO TRANSCRIPT',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '"$transcript"',
          style: TextStyle(
            color: textDark,
            fontSize: 14,
            fontStyle: FontStyle.italic,
            height: 1.65,
          ),
        ),
      ],
    );
  }

  // âœ… FIX: loading state prevents double-tap
  Widget _buildConfirmButton(BuildContext context) {
    return GestureDetector(
      onTap: _isConfirming
          ? null
          : () async {
              if (_selectedProjectId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a project')),
                );
                return;
              }
              if (_selectedFloor == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a floor')),
                );
                return;
              }

              setState(() => _isConfirming = true);
              await Future.delayed(const Duration(milliseconds: 600));
              if (!mounted) return;

              // ── STEP 6B/6C: Map to EntryModel & save via Provider ───────────
              final entryId = 'VOICE-${DateTime.now().millisecondsSinceEpoch}';
              
              context.read<ProjectProvider>().addEntry(
                EntryModel(
                  id:          entryId,
                  projectId:   _selectedProjectId!,
                  type:        EntryType.material,
                  amount:      double.tryParse(_qtyCtrl.text) ?? 0.0,
                  date:        DateTime.now(),
                  description: _nameCtrl.text,
                  brand:       _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
                  ratePerUnit: double.tryParse(_rateCtrl.text) ?? 0.0,
                  floor:       _selectedFloor!,
                  phase:       _selectedPhase,
                ),
              );

              // Update legacy log tracking
              Navigator.pushNamed(
                context,
                '/logs',
                arguments: {
                  'type': 'material',
                  'name': _nameCtrl.text,
                  'newEntry': em.Entry(
                    id: entryId,
                    type: em.EntryType.material,
                    projectId: _selectedProjectId!,
                    createdBy: UserSession.userId,
                  ).toMap()..addAll({
                    'title': _nameCtrl.text,
                    'ref': '#$entryId',
                    'amount': '+${_qtyCtrl.text}',
                    'date': 'Today',
                    'isPositive': true,
                    'icon': Icons.inventory_2_outlined,
                  }),
                },
              );
              // ──────────────────────────────────────────────────────────────
            },
      child: AnimatedOpacity(
        opacity: _isConfirming ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
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
          child: _isConfirming
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
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Confirm and save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: textGray,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _fieldBox(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
      ),
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
    );
  }

  // ── Reusable dropdown helper (matches underline design) ──────
  Widget _dropdownField<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool enabled = true,
  }) {
    // âœ… FIX: Prevent Flutter DropdownButton crash if value is not in items
    final bool hasValue = items.any((item) => item.value == value);
    final T? safeValue = hasValue ? value : null;

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
            value: safeValue,
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
            style: const TextStyle(
              fontSize: 16,
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
}
