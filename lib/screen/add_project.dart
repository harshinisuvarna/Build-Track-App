// lib/screen/add_project.dart
// Persists new project via ProjectProvider → SharedPreferences.

import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  static const primaryBlue = AppColors.primary;
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;

  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _cityCtrl  = TextEditingController();
  final _sectorCtrl= TextEditingController();
  final _budgetCtrl= TextEditingController();

  ProjectStage _selectedStage = ProjectStage.foundation;
  DateTime     _startDate     = DateTime.now();
  bool         _saving        = false;

  static const _stages = ProjectStage.values;

  static const _stageBg = <ProjectStage, Color>{
    ProjectStage.foundation: Color(0xFFEEEFFF),
    ProjectStage.structure:  Color(0xFFF3E8FF),
    ProjectStage.finishing:  Color(0xFFE8F5E9),
    ProjectStage.handover:   Color(0xFFFFF8E1),
  };

  static const _stageFg = <ProjectStage, Color>{
    ProjectStage.foundation: Color(0xFF4455CC),
    ProjectStage.structure:  Color(0xFF9B59B6),
    ProjectStage.finishing:  Color(0xFF2E7D32),
    ProjectStage.handover:   Color(0xFFF57F17),
  };

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _sectorCtrl.dispose();
    _budgetCtrl.dispose();
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
            // ── Back header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8, offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: textDark, size: 18),
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

            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _chip('PROJECT DETAILS'),
                      const SizedBox(height: 20),

                      // Project Name
                      _label('Project Name'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _nameCtrl,
                        hint: 'e.g. Skyline Residences Phase II',
                        icon: Icons.business_rounded,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter project name' : null,
                      ),
                      const SizedBox(height: 18),

                      // City
                      _label('City'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _cityCtrl,
                        hint: 'e.g. Mumbai',
                        icon: Icons.location_city_rounded,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter city' : null,
                      ),
                      const SizedBox(height: 18),

                      // Sector
                      _label('Sector / Unit'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _sectorCtrl,
                        hint: 'e.g. Andheri West',
                        icon: Icons.grid_view_rounded,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter sector' : null,
                      ),
                      const SizedBox(height: 18),

                      // Total Budget (NEW)
                      _label('Total Budget (₹)'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _budgetCtrl,
                        hint: 'e.g. 45000000',
                        icon: Icons.account_balance_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter budget';
                          if (double.tryParse(v) == null) return 'Invalid amount';
                          if (double.parse(v) <= 0) return 'Budget must be > 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Start Date (NEW)
                      _label('Start Date'),
                      const SizedBox(height: 8),
                      _datePicker(),
                      const SizedBox(height: 24),

                      // Stage chips
                      _label('Build Stage'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: _stages.map((s) {
                          final sel = s == _selectedStage;
                          final bg  = _stageBg[s]!;
                          final fg  = _stageFg[s]!;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedStage = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? fg : bg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel ? fg : fg.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                s.label,
                                style: GoogleFonts.inter(
                                  color: sel ? Colors.white : fg,
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

                      // Preview card
                      _label('Preview'),
                      const SizedBox(height: 12),
                      _previewCard(),
                      const SizedBox(height: 32),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            disabledBackgroundColor:
                                primaryBlue.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
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

  // ── Widget builders ─────────────────────────────────────────────────────────

  Widget _chip(String text) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: primaryBlue,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: textGray,
          letterSpacing: 0.3,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
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
            borderSide: const BorderSide(
                color: Color(0xFFEEF0F5), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      );

  Widget _datePicker() {
    final dateStr =
        '${_startDate.day} ${_months[_startDate.month - 1]} ${_startDate.year}';
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _startDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: primaryBlue,
                onPrimary: Colors.white,
                onSurface: textDark,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _startDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const BorderSide(color: Color(0xFFEEF0F5), width: 1.5)
              .merged(null),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined,
                color: primaryBlue, size: 20),
            const SizedBox(width: 10),
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewCard() {
    final name   = _nameCtrl.text.isEmpty ? 'Project Name' : _nameCtrl.text;
    final city   = _cityCtrl.text.isEmpty ? 'City' : _cityCtrl.text;
    final sector = _sectorCtrl.text.isEmpty ? 'Sector' : _sectorCtrl.text;
    final bg     = _stageBg[_selectedStage]!;
    final fg     = _stageFg[_selectedStage]!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12, offset: const Offset(0, 2),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedStage.label,
                  style: GoogleFonts.inter(
                    color: fg,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$city • $sector',
              style: GoogleFonts.inter(
                  color: textGray, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          // Budget preview
          if (_budgetCtrl.text.isNotEmpty)
            Text(
              'Budget: ₹${_fmt(double.tryParse(_budgetCtrl.text) ?? 0)}',
              style: GoogleFonts.inter(
                  color: primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(2)} Cr';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)} M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)} k';
    return v.toStringAsFixed(0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final project = ProjectModel(
        id:          DateTime.now().millisecondsSinceEpoch.toString(),
        name:        _nameCtrl.text.trim(),
        city:        _cityCtrl.text.trim(),
        sector:      _sectorCtrl.text.trim(),
        stage:       _selectedStage,
        progress:    0.0,
        totalBudget: double.parse(_budgetCtrl.text),
        spentAmount: 0.0,
        startDate:   _startDate,
      );

      if (!mounted) return;
      await context.read<ProjectProvider>().addProject(project);

      if (!mounted) return;
      // Navigate directly to project detail for the newly created project
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/project-detail',
        (route) => route.settings.name == '/projects' || route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save project: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Extension to simplify Border on a Container ────────────────────────────

extension on BorderSide {
  Border? merged(Border? _) => Border.all(
        color: color,
        width: width,
        style: style,
      );
}