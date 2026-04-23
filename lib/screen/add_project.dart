import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _sectorController = TextEditingController();
  String _selectedStage = 'FOUNDATION';

  final List<String> _stages = [
    'FOUNDATION',
    'STRUCTURE',
    'FINISHING',
    'HANDOVER',
  ];

  final Map<String, Color> _stageBgColors = {
    'FOUNDATION': const Color(0xFFEEEFFF),
    'STRUCTURE': const Color(0xFFF3E8FF),
    'FINISHING': const Color(0xFFE8F5E9),
    'HANDOVER': const Color(0xFFFFF8E1),
  };

  final Map<String, Color> _stageColors = {
    'FOUNDATION': const Color(0xFF4455CC),
    'STRUCTURE': const Color(0xFF9B59B6),
    'FINISHING': const Color(0xFF2E7D32),
    'HANDOVER': const Color(0xFFF57F17),
  };

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _sectorController.dispose();
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
            // ── Top Bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: textDark,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'New Project',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Form ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PROJECT DETAILS',
                          style: GoogleFonts.inter(
                            color: primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel('Project Name'),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: _nameController,
                        hint: 'e.g. Northwest Tech Park',
                        icon: Icons.business_rounded,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter project name' : null,
                      ),
                      const SizedBox(height: 18),

                      _sectionLabel('City & State'),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: _locationController,
                        hint: 'e.g. Bellingham, WA',
                        icon: Icons.location_on_rounded,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter location' : null,
                      ),
                      const SizedBox(height: 18),

                      _sectionLabel('Sector / Unit'),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: _sectorController,
                        hint: 'e.g. Sector 04',
                        icon: Icons.grid_view_rounded,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter sector' : null,
                      ),
                      const SizedBox(height: 24),

                      // Stage chips
                      _sectionLabel('Build Stage'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _stages.map((stage) {
                          final isSelected = _selectedStage == stage;
                          final bg = _stageBgColors[stage]!;
                          final color = _stageColors[stage]!;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedStage = stage),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? color : bg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : color.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                stage,
                                style: GoogleFonts.inter(
                                  color: isSelected ? Colors.white : color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Live preview card
                      _sectionLabel('Preview'),
                      const SizedBox(height: 12),
                      _previewCard(),
                      const SizedBox(height: 32),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add Project',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: textGray,
          letterSpacing: 0.3,
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: textGray.withValues(alpha: 0.6),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: primaryBlue, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEEF0F5), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _previewCard() {
    final name = _nameController.text.isEmpty ? 'Project Name' : _nameController.text;
    final location = _locationController.text.isEmpty ? 'City, State' : _locationController.text;
    final sector = _sectorController.text.isEmpty ? 'Sector' : _sectorController.text;
    final stageBg = _stageBgColors[_selectedStage]!;
    final stageColor = _stageColors[_selectedStage]!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: stageBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedStage,
                  style: GoogleFonts.inter(
                    color: stageColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '$location • $sector',
            style: GoogleFonts.inter(
              color: textGray,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Progress',
                  style: GoogleFonts.inter(
                      color: textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              Text('0%',
                  style: GoogleFonts.inter(
                      color: primaryBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0,
              backgroundColor: Color(0xFFE8ECF8),
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Project "${_nameController.text}" added!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }
}