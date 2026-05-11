import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/subscription_provider.dart';
import 'package:buildtrack_mobile/models/construction_models.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});
  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  static const primaryBlue = AppColors.primary;
  static const bgColor = AppColors.gradientStart;
  static const textDark = AppColors.textDark;
  static const textGray = AppColors.textLight;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  String? _selectedProjectType;
  final _floorInputCtrl = TextEditingController();
  DateTime? _expectedEndDate;
  final List<String> _floors = [];
  // ignore: prefer_final_fields
  ProjectStage _selectedStage = ProjectStage.foundation;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;
  static const _stages = ProjectStage.values;
  static const _stageBg = <ProjectStage, Color>{
    ProjectStage.preConstruction: Color(0xFFE8EAF6),
    ProjectStage.sitePreparation: Color(0xFFFCE4EC),
    ProjectStage.foundation: Color(0xFFEEEFFF),
    ProjectStage.plinth: Color(0xFFE3F2FD),
    ProjectStage.superstructure: Color(0xFFF3E8FF),
    ProjectStage.masonry: Color(0xFFFFF3E0),
    ProjectStage.mep: Color(0xFFE0F7FA),
    ProjectStage.plastering: Color(0xFFF9FBE7),
    ProjectStage.finishing: Color(0xFFE8F5E9),
    ProjectStage.fixtures: Color(0xFFFFF8E1),
    ProjectStage.handover: Color(0xFFFFF8E1),
  };
  static const _stageFg = <ProjectStage, Color>{
    ProjectStage.preConstruction: Color(0xFF3949AB),
    ProjectStage.sitePreparation: Color(0xFFC62828),
    ProjectStage.foundation: Color(0xFF4455CC),
    ProjectStage.plinth: Color(0xFF1565C0),
    ProjectStage.superstructure: Color(0xFF9B59B6),
    ProjectStage.masonry: Color(0xFFE65100),
    ProjectStage.mep: Color(0xFF00838F),
    ProjectStage.plastering: Color(0xFF827717),
    ProjectStage.finishing: Color(0xFF2E7D32),
    ProjectStage.fixtures: Color(0xFFF9A825),
    ProjectStage.handover: Color(0xFFF57F17),
  };
  bool _saving = false;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final List<String> _selectedZones = [];

  final List<String> _defaultFloors = [
    'Basement',
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    'Terrace',
  ];
  final List<String> _defaultZones = [
    'Block A',
    'Block B',
    'Parking',
    'Staircase',
    'Lift Area',
  ];

  late final List<ConstructionPhase> _phases;

  @override
  void initState() {
    super.initState();
    _phases = buildDefaultPhases();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _sectorCtrl.dispose();
    _budgetCtrl.dispose();
    _clientCtrl.dispose();

    _floorInputCtrl.dispose();
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
                    style: TextStyle(
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
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Basic Information'),
                      _label('Project Name'),
                      const SizedBox(height: 10),
                      _field(
                        controller: _nameCtrl,
                        hint: 'e.g. Skyline Residences Phase II',
                        icon: Icons.business_rounded,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter project name'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _label('City'),
                      const SizedBox(height: 10),
                      _field(
                        controller: _cityCtrl,
                        hint: 'e.g. Mumbai',
                        icon: Icons.location_city_rounded,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter city' : null,
                      ),
                      const SizedBox(height: 20),
                      _label('Sector / Unit'),
                      const SizedBox(height: 10),
                      _field(
                        controller: _sectorCtrl,
                        hint: 'e.g. Andheri West',
                        icon: Icons.grid_view_rounded,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter sector' : null,
                      ),
                      const SizedBox(height: 24),

                      _sectionHeader('Financial Details'),
                      _label('Total Budget (₹)'),
                      const SizedBox(height: 10),
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
                          if (double.tryParse(v) == null)
                            return 'Invalid amount';
                          if (double.parse(v) <= 0) return 'Budget must be > 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      _sectionHeader('Timeline'),
                      _label('Start Date'),
                      const SizedBox(height: 10),
                      _datePicker(),
                      const SizedBox(height: 20),
                      _label('Expected End Date (Optional)'),
                      const SizedBox(height: 10),
                      _endDatePicker(),
                      const SizedBox(height: 24),

                      _sectionHeader('Client Details'),
                      _label('Client Name (Optional)'),
                      const SizedBox(height: 10),
                      _field(
                        controller: _clientCtrl,
                        hint: 'e.g. Rajan Builders Pvt. Ltd.',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 20),
                      _label('Project Type (Optional)'),
                      const SizedBox(height: 10),
                      _projectTypeDropdown(),
                      const SizedBox(height: 20),
                      const SizedBox(height: 12),
                      _buildProjectAreasCard(),
                      const SizedBox(height: 24),
                      _buildConstructionPhasesCard(),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            disabledBackgroundColor: primaryBlue.withValues(
                              alpha: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Add Project',
                                  style: TextStyle(
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

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: textGray,
      letterSpacing: 0.3,
    ),
  );
  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: textDark.withValues(alpha: 0.5),
        letterSpacing: 1.2,
      ),
    ),
  );
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    onChanged: (_) => setState(() {}),
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: textDark,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: textGray.withValues(alpha: 0.6),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEEF0F5), width: 1.5),
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
          border: const BorderSide(
            color: Color(0xFFEEF0F5),
            width: 1.5,
          ).merged(null),
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
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateStr,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: textDark,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _endDatePicker() {
    final hasDate = _expectedEndDate != null;
    final dateStr = hasDate
        ? '${_expectedEndDate!.day} ${_months[_expectedEndDate!.month - 1]} ${_expectedEndDate!.year}'
        : 'Select target completion date';
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              _expectedEndDate ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
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
        if (picked != null) setState(() => _expectedEndDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const BorderSide(
            color: Color(0xFFEEF0F5),
            width: 1.5,
          ).merged(null),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_outlined,
              color: hasDate ? primaryBlue : textGray,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateStr,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: hasDate ? textDark : textGray.withValues(alpha: 0.6),
                ),
              ),
            ),
            hasDate
                ? GestureDetector(
                    onTap: () => setState(() => _expectedEndDate = null),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: textGray,
                    ),
                  )
                : const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Keeping your existing subscription logic
    final projectProvider = context.read<ProjectProvider>();
    final subProvider = context.read<SubscriptionProvider>();
    if (!subProvider.canAddProject(projectProvider.projectCount)) {
      _showUpgradeDialog();
      return;
    }

    // Set loading state
    setState(() => _isLoading = true);

    // Format location from city and sector controllers
    final location = _sectorCtrl.text.trim().isNotEmpty
        ? '${_cityCtrl.text.trim()}, ${_sectorCtrl.text.trim()}'
        : _cityCtrl.text.trim();

    // Extract payload per requirements
    final payload = {
      'projectName': _nameCtrl.text.trim(),
      'clientName': _clientCtrl.text.trim(),
      'location': location,
      'projectType': _selectedProjectType,
    };

    try {
      final response = await ApiService.post('/projects', payload);

      if (!mounted) return;

      // Success
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        // Failure Response
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create project: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Caught Error
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while creating the project.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: primaryBlue,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Project Limit Reached',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Free plan allows up to 2 projects.\nUpgrade to Pro for unlimited projects.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: textGray, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/subscription');
                },
                child: Text(
                  'Upgrade to Pro',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe Later',
                style: TextStyle(color: textGray, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _projectTypes = [
    'Residential',
    'Commercial',
    'Villa',
    'Apartment',
  ];

  Widget _projectTypeDropdown() {
    final hasValue = _selectedProjectType != null;
    return GestureDetector(
      onTap: () => _showProjectTypeSheet(),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.category_outlined,
              color: hasValue ? primaryBlue : textGray,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedProjectType ?? 'Select project type',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: hasValue ? textDark : textGray.withValues(alpha: 0.6),
                ),
              ),
            ),
            hasValue
                ? GestureDetector(
                    onTap: () => setState(() => _selectedProjectType = null),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: textGray,
                    ),
                  )
                : const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: textGray,
                  ),
          ],
        ),
      ),
    );
  }

  void _showProjectTypeSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE0E8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Project Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            ..._projectTypes.map((type) {
              final isSelected = _selectedProjectType == type;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedProjectType = type);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryBlue.withValues(alpha: 0.08)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? primaryBlue : const Color(0xFFEEF0F5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? primaryBlue : textDark,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_rounded,
                          color: primaryBlue,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectAreasCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROJECT AREAS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Define floors, blocks, and execution zones.',
            style: TextStyle(
              fontSize: 13,
              color: textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'FLOORS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textDark.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._defaultFloors.map(
                (f) => _buildSelectableChip(
                  label: f,
                  isSelected: _floors.contains(f),
                  onTap: () {
                    setState(() {
                      if (_floors.contains(f)) {
                        _floors.remove(f);
                      } else {
                        _floors.add(f);
                      }
                    });
                  },
                ),
              ),
              _buildAddCustomChip(
                label: 'Add Custom Floor',
                onAdd: (val) {
                  setState(() {
                    if (!_defaultFloors.contains(val) &&
                        !_floors.contains(val)) {
                      _defaultFloors.add(val);
                      _floors.add(val);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'BLOCKS / ZONES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textDark.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._defaultZones.map(
                (z) => _buildSelectableChip(
                  label: z,
                  isSelected: _selectedZones.contains(z),
                  onTap: () {
                    setState(() {
                      if (_selectedZones.contains(z)) {
                        _selectedZones.remove(z);
                      } else {
                        _selectedZones.add(z);
                      }
                    });
                  },
                ),
              ),
              _buildAddCustomChip(
                label: 'Add Custom Zone',
                onAdd: (val) {
                  setState(() {
                    if (!_defaultZones.contains(val) &&
                        !_selectedZones.contains(val)) {
                      _defaultZones.add(val);
                      _selectedZones.add(val);
                    }
                  });
                },
              ),
            ],
          ),
          if (_floors.isNotEmpty || _selectedZones.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFEEF0F5), height: 1),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ..._floors.map((f) => _buildSummaryChip(f)),
                ..._selectedZones.map((z) => _buildSummaryChip(z)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFEEF0F5),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildAddCustomChip({
    required String label,
    required Function(String) onAdd,
  }) {
    return GestureDetector(
      onTap: () {
        _showCustomInputDialog(label, onAdd);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: primaryBlue),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomInputDialog(String title, Function(String) onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter name',
            hintStyle: TextStyle(color: textGray, fontSize: 14),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primaryBlue),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: textGray, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) onAdd(val);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Add',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConstructionPhasesCard() {
    int totalActivities = 0;
    int selectedActivities = 0;
    for (var p in _phases) {
      totalActivities += p.totalCount;
      selectedActivities += p.selectedCount;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONSTRUCTION PHASES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        for (var p in _phases) {
                          for (var a in p.activities) {
                            a.isSelected = true;
                          }
                          for (var g in p.groups) {
                            for (var a in g.activities) {
                              a.isSelected = true;
                            }
                          }
                        }
                      });
                    },
                    child: const Text(
                      'Select All',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        for (var p in _phases) {
                          for (var a in p.activities) {
                            a.isSelected = false;
                          }
                          for (var g in p.groups) {
                            for (var a in g.activities) {
                              a.isSelected = false;
                            }
                          }
                        }
                      });
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select phases and activities required.',
            style: TextStyle(
              fontSize: 13,
              color: textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$selectedActivities of $totalActivities activities selected',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          ..._phases.map((p) => _buildPhaseAccordion(p)),
          const SizedBox(height: 4),
          // ── Custom Phase CTA ──────────────────────────────────
          _buildAddCustomChip(
            label: 'Add Custom Phase',
            onAdd: (val) {
              setState(() {
                if (!_phases.any((p) => p.name == val)) {
                  _phases.add(
                    ConstructionPhase(
                      name: val,
                      isCustom: true,
                      isExpanded: true,
                    ),
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseAccordion(ConstructionPhase phase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                phase.isExpanded = !phase.isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      phase.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                  ),
                  if (phase.selectedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${phase.selectedCount}/${phase.totalCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    phase.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: textGray,
                  ),
                ],
              ),
            ),
          ),
          if (phase.isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFEEF0F5)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...phase.activities.map((a) => _buildActivityRow(a)),
                  ...phase.groups.map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: textGray,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...g.activities.map((a) => _buildActivityRow(a)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── Custom Activity CTA ────────────────────────
                  _buildAddCustomChip(
                    label: 'Add Custom Activity',
                    onAdd: (val) {
                      setState(() {
                        final key = '${phase.name}::Custom::$val';
                        if (!phase.allActivities.any((a) => a.name == val)) {
                          phase.activities.add(
                            ConstructionActivity(
                              key: key,
                              name: val,
                              isCustom: true,
                              isSelected: true,
                            ),
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityRow(ConstructionActivity activity) {
    return GestureDetector(
      onTap: () {
        setState(() {
          activity.isSelected = !activity.isSelected;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: activity.isSelected ? primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: activity.isSelected
                      ? primaryBlue
                      : textGray.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: activity.isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                activity.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ),
            if (activity.isCustom)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Custom',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension on BorderSide {
  Border? merged(Border? _) =>
      Border.all(color: color, width: width, style: style);
}
