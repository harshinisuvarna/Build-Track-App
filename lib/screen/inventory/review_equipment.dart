import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_mobile/controller/entry_model.dart' as em;
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:provider/provider.dart';

class ReviewEquipmentEntryScreen extends StatefulWidget {
  const ReviewEquipmentEntryScreen({super.key});

  @override
  State<ReviewEquipmentEntryScreen> createState() => _ReviewEquipmentEntryScreenState();
}

class _ReviewEquipmentEntryScreenState extends State<ReviewEquipmentEntryScreen> {

  static const primaryBlue = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;
  static const voicePurple = AppColors.primary;

  bool _isConfirming = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _hoursCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _fuelCtrl;

  String? _selectedProjectId;
  String? _selectedFloor;
  ProjectStage? _selectedPhase;

  final String transcript = 
      "Hey SiteTrack, log equipment usage for North District. Excavator JCB 3CX unit 04 ran for 6 hours today. Rate is 85 rupees per hour. Fuel consumed was 42 liters. Total cost is 510 rupees. Log under earthworks and excavation.";

  @override
  void initState() {
    super.initState();
    _parseVoiceInput();
  }

  void _parseVoiceInput() {
    String t = transcript.toLowerCase();
    
    _nameCtrl = TextEditingController(text: "Excavator JCB 3CX (Unit 04)");
    _hoursCtrl = TextEditingController(text: "6");
    _rateCtrl = TextEditingController(text: "85.00");
    _fuelCtrl = TextEditingController(text: "42 L");
    
    _selectedProjectId = UserSession.projectId;
    
    String floor = "General";
    if (t.contains("1st floor")) floor = "1st Floor";
    _selectedFloor = floor;
    
    _selectedPhase = ProjectStage.foundation;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hoursCtrl.dispose();
    _rateCtrl.dispose();
    _fuelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(Icons.arrow_back, color: textDark, size: 22),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Review voice entry',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildVoiceBanner(),
                    const SizedBox(height: 20),
                    _buildEquipmentCard(context),
                    const SizedBox(height: 20),
                    _buildTranscript(),
                    const SizedBox(height: 32),
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

  Widget _buildVoiceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: voicePurple,
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
                    color: voicePurple,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Confidence: 97.2% • Voice timestamp 11:30 AM',
                  style: TextStyle(
                    color: voicePurple.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

  Widget _buildEquipmentCard(BuildContext context) {
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
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Equipment Log',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Site: North District Phase 2',
                    style: TextStyle(
                      fontSize: 13,
                      color: textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voice input active'),
                    duration: Duration(seconds: 1),
                  ),
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.mic, color: primaryBlue, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _label("PROJECT"),
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
                    _label('FLOOR / ZONE'),
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
                    _label('PHASE (OPTIONAL)'),
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
          const SizedBox(height: 18),
          _label('EQUIPMENT NAME'),
          const SizedBox(height: 8),
          _box(_nameCtrl),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('USAGE HOURS'),
                    const SizedBox(height: 8),
                    _box(_hoursCtrl),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('COST / HOUR'),
                    const SizedBox(height: 8),
                    _box(_rateCtrl),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _label('FUEL CONSUMPTION'),
          const SizedBox(height: 8),
          _box(_fuelCtrl),
          const SizedBox(height: 18),
          _label('TOTAL ESTIMATED'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹510.00',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryBlue.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'AUTO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
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

  Widget _buildTranscript() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.subject, color: primaryBlue, size: 18),
            const SizedBox(width: 8),
            Text(
              'ORIGINAL AUDIO TRANSCRIPT',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '"Hey SiteTrack, log equipment usage for North District. Excavator JCB 3CX unit 04 ran for 6 hours today. Rate is 85 rupees per hour. Fuel consumed was 42 liters. Total cost is 510 rupees. Log under earthworks and excavation."',
          style: TextStyle(
            fontSize: 14,
            color: textGray,
            fontStyle: FontStyle.italic,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

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

              final entryId = 'VOICE-EQP-${DateTime.now().millisecondsSinceEpoch}';

              context.read<ProjectProvider>().addEntry(
                EntryModel(
                  id:          entryId,
                  projectId:   _selectedProjectId!,
                  type:        EntryType.equipment,
                  amount:      double.tryParse(_hoursCtrl.text) ?? 0.0,
                  date:        DateTime.now(),
                  description: _nameCtrl.text,
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
                  'type': 'equipment',
                  'name': _nameCtrl.text,
                  'newEntry': em.Entry(
                    id: entryId,
                    type: em.EntryType.equipment,
                    projectId: _selectedProjectId!,
                    createdBy: UserSession.userId,
                  ).toMap()..addAll({
                    'title': _nameCtrl.text,
                    'ref': '#$entryId',
                    'amount': '+${_hoursCtrl.text} hrs',
                    'date': 'Today',
                    'isPositive': true,
                    'icon': Icons.construction_outlined,
                  }),
                },
              );

              Navigator.pop(context);
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
                      size: 20,
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

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textGray,
          letterSpacing: 0.8,
        ),
      );

  Widget _box(TextEditingController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryBlue, width: 2)),
      ),
      child: TextField(
        controller: ctrl,
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
