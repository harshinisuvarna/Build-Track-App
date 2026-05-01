import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/themes/app_gradients.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';
import 'package:provider/provider.dart';

class UpdateProgressScreen extends StatefulWidget {
  const UpdateProgressScreen({super.key});
  @override
  State<UpdateProgressScreen> createState() => _UpdateProgressScreenState();
}

class _UpdateProgressScreenState extends State<UpdateProgressScreen> {
  static const primaryBlue = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;

  int _stageIndex = 0;
  final _stages = ['Reinforcement', 'Formwork', 'Curing'];
  final TextEditingController _progressCtrl = TextEditingController();

  late double _completionProgress;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initialize slider from the currently selected project's progress
    final provider = context.read<ProjectProvider>();
    _completionProgress = provider.selectedProject?.progress ?? 0.65;
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  PickedAttachment? _attachment;

  @override
  void dispose() {
    _progressCtrl.dispose();
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
            AppTopBar(
              title: 'Update progress',
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
                    _buildCurrentStageCard(),
                    const SizedBox(height: 22),
                    _buildSelectStage(),
                    const SizedBox(height: 22),
                    _buildProgressDetailsField(),
                    const SizedBox(height: 20),
                    _buildDateField(),
                    const SizedBox(height: 20),
                    _buildDocumentation(),
                    const SizedBox(height: 20),
                    _buildMaterialConsumption(context),
                    const SizedBox(height: 30),
                    _buildSaveButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // ← fixed: bottom nav was missing
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _buildCurrentStageCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,                          // ← explicit white bg
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "CURRENT ACTIVE STAGE" pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'CURRENT ACTIVE STAGE',
              style: GoogleFonts.inter(
                color: primaryBlue,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Stage name row + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Reinforcement Work',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.architecture, color: textGray, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: textGray, size: 14),
              const SizedBox(width: 4),
              Text(
                'Sector B-12 • Level 04',
                style: GoogleFonts.inter(
                  color: textGray,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Completion bar + avatars
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'COMPLETION',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: textGray,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${(_completionProgress * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            color: primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 7,
                        activeTrackColor: primaryBlue,
                        inactiveTrackColor: const Color(0xFFE8ECF8),
                        thumbColor: primaryBlue,
                        overlayColor: primaryBlue.withValues(alpha: 0.1),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _completionProgress,
                        onChanged: (val) {
                          setState(() {
                            _completionProgress = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _avatarStack(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarStack() {
    const colors = [Color(0xFF5B6CF6), Color(0xFF9C59B5)];
    return Row(
      children: [
        ...List.generate(2, (i) {
          return Transform.translate(
            offset: Offset(i * -9.0, 0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: colors[i],
              child: const Icon(Icons.person, color: Colors.white, size: 14),
            ),
          );
        }),
        Transform.translate(
          offset: const Offset(-18, 0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFFEEF0FF),
            child: Text(
              '+4',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Stage',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _stages.asMap().entries.map((e) {
            final sel = e.key == _stageIndex;
            return GestureDetector(
                onTap: () => setState(() => _stageIndex = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    // ← fixed: unselected chips now have a visible border
                    border: Border.all(
                      color: sel ? primaryBlue : const Color(0xFFDDE0F0),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    e.value,
                    style: GoogleFonts.inter(
                      color: sel ? Colors.white : textGray,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgressDetailsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work progress details',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE0F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextField(
            controller: _progressCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe the tasks completed today...',
              hintStyle: GoogleFonts.inter(color: textGray, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final dateStr = '${_months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Update Date',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: primaryBlue, // header background color
                      onPrimary: Colors.white, // header text color
                      onSurface: textDark, // body text color
                    ),
                  ),
                  child: child!,
                );
              },
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
              border: Border.all(color: const Color(0xFFDDE0F0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: primaryBlue,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentation',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 10),
        UploadBox(
          attachment: _attachment,
          emptyLabel: 'Tap to add site photo',
          onPicked: (a) => setState(() => _attachment = a),
          onRemove: () => setState(() => _attachment = null),
        ),
      ],
    );
  }

  Widget _buildMaterialConsumption(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MATERIAL CONSUMPTION',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textGray,
                  letterSpacing: 0.7,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/add-material',
                  arguments: {'type': 'material'},
                ),
                child: Text(
                  'ADD MATERIAL',
                  style: GoogleFonts.inter(
                    color: primaryBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _materialTag('Rebar 12mm', '120 kg'),
          const SizedBox(height: 8),
          _materialTag('Concrete M30', '12 m³'),
        ],
      ),
    );
  }

  Widget _materialTag(String label, String qty) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: primaryBlue,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            color: textDark,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF0FF),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            qty,
            style: GoogleFonts.inter(
              color: primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final provider = context.read<ProjectProvider>();
        final project  = provider.selectedProject;
        if (project != null) {
          await provider.updateProjectProgress(
              project.id, _completionProgress);
        }
        if (context.mounted) Navigator.maybePop(context);
      },
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Save progress update',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}