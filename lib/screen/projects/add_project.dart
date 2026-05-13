import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/subscription_provider.dart';
import 'package:buildtrack_mobile/models/construction_models.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
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
  static const bgColor     = AppColors.gradientStart;
  static const textDark    = AppColors.textDark;
  static const textGray    = AppColors.textLight;

  final _formKey   = GlobalKey<FormState>();

  // ── Project Setup ──────────────────────────────────────────────
  final _nameCtrl  = TextEditingController();
  final _cityCtrl  = TextEditingController();
  final _sectorCtrl= TextEditingController();
  final _clientCtrl    = TextEditingController();
  final _contractorCtrl = TextEditingController();
  final _engineerCtrl   = TextEditingController();
  final _contactCtrl    = TextEditingController();
  
  // ── Dates, Budget & Status ─────────────────────────────────────
  DateTime _startDate = DateTime.now();
  DateTime? _expectedEndDate;
  DateTime? _actualEndDate;

  final _budgetMaterialCtrl = TextEditingController();
  final _budgetLabourCtrl = TextEditingController();
  final _budgetEquipmentCtrl = TextEditingController();
  final _budgetMiscCtrl = TextEditingController();

  String _projectStatus = 'Planning';
  final List<String> _statusOptions = [
    'Planning', 'In Progress', 'On Hold', 'Completed', 'Cancelled'
  ];

  // ── Accordion States ───────────────────────────────────────────
  bool _cfgLandExpanded = true;
  bool _cfgRoomsExpanded = false;
  bool _cfgAddlExpanded = false;
  bool _cfgUtilityExpanded = false;
  bool _cfgGasExpanded = false;
  bool _cfgKitchenExpanded = false;
  bool _cfgElectricalExpanded = false;
  bool _cfgTerraceExpanded = false;

  // ── Land & Floors ──────────────────────────────────────────────
  final _landAreaCtrl = TextEditingController();
  String _landUnit = 'Sq ft';
  final List<String> _selectedFloorChips = [];
  final List<String> _floorChipOptions = [
    'Ground', '1st', '2nd', '3rd', '4th', 'Terrace', 'Head Room'
  ];

  // ── Rooms & Bathrooms ──────────────────────────────────────────
  int _room1BHKCount = 0;
  int _room2BHKCount = 0;
  int _room3BHKCount = 0;
  int _roomCustomCount = 0;

  int _bathWesternCount = 0;
  int _bathIndianCount = 0;
  int _bathCommonCount = 0;
  int _bathAttachedCount = 0;

  // ── Additional Configuration & Services ────────────────────────
  final Set<String> _additionalConfigs = {};

  final List<String> _addlConfigOptions = [
    'Balcony', 'Car Parking',
    'Lift', 'Terrace Access',
    'Interior Work', 'Compound Wall',
    'Parapet Wall', 'Waterproofing',
    'Putty', 'False Ceiling',
    'Modular Kitchen', 'Wardrobes',
    'Sump', 'Septic Tank',
    'Rainwater', 'Borewell',
    'Solar', 'Generator',
    'CCTV', 'Intercom',
    'Landscaping', 'Paving',
    'Water Tanks', 'Stairs',
    'Security Room', 'Cladding',
    'Elevation', 'Gates',
    'Grills', 'Aluminium',
    'Glass',
  ];

  final List<String> _utilityOptions = [
    'Main Electricity', 'Temporary Connection', 'Generator Backup', 'Water Connection', 'Borewell Motor', 'Sump Motor'
  ];

  final List<String> _gasOptions = [
    'Piped Gas', 'Cylinder Bank', 'Gas Pipeline Routing'
  ];

  final List<String> _kitchenOptions = [
    'Granite Counter', 'Quartz Counter', 'Stainless Steel Sink', 'Chimney Provision', 'Exhaust Fan Provision'
  ];

  final List<String> _electricalOptions = [
    'Concealed Wiring', 'Open Wiring', '3-Phase Connection', 'AC Points', 'Geyser Points'
  ];

  final List<String> _terraceOptions = [
    'Weathering Course', 'Cool Roof Paint', 'Overhead Tank', 'Solar Panels'
  ];


  bool _saving = false;
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
    _clientCtrl.dispose();
    _contractorCtrl.dispose();
    _engineerCtrl.dispose();
    _contactCtrl.dispose();
    
    _budgetMaterialCtrl.dispose();
    _budgetLabourCtrl.dispose();
    _budgetEquipmentCtrl.dispose();
    _budgetMiscCtrl.dispose();
    _landAreaCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final subProv = context.read<SubscriptionProvider>();
      final projProv = context.read<ProjectProvider>();
      if (!subProv.canAddProject(projProv.projects.length)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project limit reached. Please upgrade plan.')),
        );
        setState(() => _saving = false);
        return;
      }

      double parseBudget(TextEditingController c) => double.tryParse(c.text) ?? 0.0;
      final budgetTotal = parseBudget(_budgetMaterialCtrl) + parseBudget(_budgetLabourCtrl) + parseBudget(_budgetEquipmentCtrl) + parseBudget(_budgetMiscCtrl);

      final newProject = ProjectModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        sector: _sectorCtrl.text.trim(),
        stage: ProjectStage.preConstruction,
        progress: 0.0,
        totalBudget: budgetTotal,
        spentAmount: 0.0,
        startDate: _startDate,
        clientName: _clientCtrl.text.trim(),
        expectedEndDate: _expectedEndDate,
        floors: _selectedFloorChips,
        selectedPhaseNames: _phases.map((e) => e.name).toList(),
      );

      await projProv.addProject(newProject);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                      child: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Project Setup',
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
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── PROJECT SETUP ──────────────────────────────────────
                      _buildSectionCard(
                        title: 'Project Setup',
                        icon: Icons.business_center_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Project Name'),
                            const SizedBox(height: 8),
                            _field(
                              controller: _nameCtrl,
                              hint: 'e.g. Skyline Towers',
                              icon: Icons.apartment_rounded,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _label('City'),
                                      const SizedBox(height: 8),
                                      _field(
                                        controller: _cityCtrl,
                                        hint: 'City',
                                        icon: Icons.location_city_rounded,
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _label('Sector / Area'),
                                      const SizedBox(height: 8),
                                      _field(
                                        controller: _sectorCtrl,
                                        hint: 'Sector',
                                        icon: Icons.map_rounded,
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _label('Client Name'),
                            const SizedBox(height: 8),
                            _field(
                              controller: _clientCtrl,
                              hint: 'Client Name (Optional)',
                              icon: Icons.person_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── LAND & FLOORS ──────────────────────────────────────
                      _buildAccordionCard(
                        title: 'Land & Floors',
                        isExpanded: _cfgLandExpanded,
                        onToggle: () => setState(() => _cfgLandExpanded = !_cfgLandExpanded),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _label('Total Land Area'),
                                      const SizedBox(height: 8),
                                      _field(
                                        controller: _landAreaCtrl,
                                        hint: 'e.g. 2400',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _label('Unit'),
                                      const SizedBox(height: 8),
                                      _buildDropdown(
                                        value: _landUnit,
                                        hint: 'Unit',
                                        items: const ['Sq ft', 'Sq m', 'Acres', 'Hectares'],
                                        onChanged: (val) => setState(() => _landUnit = val ?? 'Sq ft'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _label('Floors Included'),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: _floorChipOptions.map((f) => _buildSelectableChip(
                                label: f,
                                isSelected: _selectedFloorChips.contains(f),
                                onTap: () {
                                  setState(() {
                                    if (_selectedFloorChips.contains(f)) {
                                      _selectedFloorChips.remove(f);
                                    } else {
                                      _selectedFloorChips.add(f);
                                    }
                                  });
                                },
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── ROOMS & BATHROOMS ──────────────────────────────────
                      _buildAccordionCard(
                        title: 'Rooms & Bathrooms',
                        isExpanded: _cfgRoomsExpanded,
                        onToggle: () => setState(() => _cfgRoomsExpanded = !_cfgRoomsExpanded),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('ROOM TYPES', uppercase: true),
                            const SizedBox(height: 16),
                            _buildCounterRow('1 BHK', _room1BHKCount, 
                              onInc: () => setState(() => _room1BHKCount++), 
                              onDec: () => setState(() => _room1BHKCount > 0 ? _room1BHKCount-- : 0)),
                            const SizedBox(height: 16),
                            _buildCounterRow('2 BHK', _room2BHKCount, 
                              onInc: () => setState(() => _room2BHKCount++), 
                              onDec: () => setState(() => _room2BHKCount > 0 ? _room2BHKCount-- : 0)),
                            const SizedBox(height: 16),
                            _buildCounterRow('3 BHK', _room3BHKCount, 
                              onInc: () => setState(() => _room3BHKCount++), 
                              onDec: () => setState(() => _room3BHKCount > 0 ? _room3BHKCount-- : 0)),
                            const SizedBox(height: 16),
                            _buildCounterRow('Custom Room', _roomCustomCount, 
                              onInc: () => setState(() => _roomCustomCount++), 
                              onDec: () => setState(() => _roomCustomCount > 0 ? _roomCustomCount-- : 0)),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(color: Color(0xFFEEF0F5), height: 1),
                            ),

                            _label('BATHROOM TYPES', uppercase: true),
                            const SizedBox(height: 16),
                            _buildCounterRow('Western Toilet', _bathWesternCount, 
                              onInc: () => setState(() => _bathWesternCount++), 
                              onDec: () => setState(() => _bathWesternCount > 0 ? _bathWesternCount-- : 0)),
                            const SizedBox(height: 16),
                            _buildCounterRow('Indian Toilet', _bathIndianCount, 
                              onInc: () => setState(() => _bathIndianCount++), 
                              onDec: () => setState(() => _bathIndianCount > 0 ? _bathIndianCount-- : 0)),
                            const SizedBox(height: 16),
                            _buildCounterRow('Common Bath', _bathCommonCount, 
                              onInc: () => setState(() => _bathCommonCount++), 
                              onDec: () => setState(() => _bathCommonCount > 0 ? _bathCommonCount-- : 0)),
                            const SizedBox(height: 16),
                            _buildCounterRow('Attached Bath', _bathAttachedCount, 
                              onInc: () => setState(() => _bathAttachedCount++), 
                              onDec: () => setState(() => _bathAttachedCount > 0 ? _bathAttachedCount-- : 0)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── ADDITIONAL CONFIGURATION ───────────────────────────
                      _buildAccordionCard(
                        title: 'Additional Configuration',
                        isExpanded: _cfgAddlExpanded,
                        onToggle: () => setState(() => _cfgAddlExpanded = !_cfgAddlExpanded),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final halfWidth = (constraints.maxWidth - 16) / 2;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: _addlConfigOptions.map((opt) {
                                return SizedBox(
                                  width: halfWidth,
                                  child: _buildCheckboxRow(
                                    opt, 
                                    _additionalConfigs.contains(opt),
                                    (v) {
                                      setState(() {
                                        if (v == true) {
                                          _additionalConfigs.add(opt);
                                        } else {
                                          _additionalConfigs.remove(opt);
                                        }
                                      });
                                    }
                                  ),
                                );
                              }).toList(),
                            );
                          }
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── OTHER CONFIGS ──────────────────────────────────────
                      _buildAccordionCard(title: 'Utility & Services', isExpanded: _cfgUtilityExpanded, onToggle: () => setState(() => _cfgUtilityExpanded = !_cfgUtilityExpanded), child: _buildConfigList(_utilityOptions)),
                      const SizedBox(height: 16),
                      _buildAccordionCard(title: 'Gas Connection', isExpanded: _cfgGasExpanded, onToggle: () => setState(() => _cfgGasExpanded = !_cfgGasExpanded), child: _buildConfigList(_gasOptions)),
                      const SizedBox(height: 16),
                      _buildAccordionCard(title: 'Kitchen Requirements', isExpanded: _cfgKitchenExpanded, onToggle: () => setState(() => _cfgKitchenExpanded = !_cfgKitchenExpanded), child: _buildConfigList(_kitchenOptions)),
                      const SizedBox(height: 16),
                      _buildAccordionCard(title: 'Electrical & Plumbing', isExpanded: _cfgElectricalExpanded, onToggle: () => setState(() => _cfgElectricalExpanded = !_cfgElectricalExpanded), child: _buildConfigList(_electricalOptions)),
                      const SizedBox(height: 16),
                      _buildAccordionCard(title: 'Terrace & Interior', isExpanded: _cfgTerraceExpanded, onToggle: () => setState(() => _cfgTerraceExpanded = !_cfgTerraceExpanded), child: _buildConfigList(_terraceOptions)),
                      const SizedBox(height: 16),

                      // ── DATES, BUDGET & STATUS ─────────────────────────────
                      _buildSectionCard(
                        title: 'Dates, Budget & Status',
                        icon: Icons.calendar_today_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('PROJECT TIMELINE', uppercase: true),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Start Date'),
                                    const SizedBox(height: 8),
                                    _datePicker(
                                      date: _startDate,
                                      onSelect: () async {
                                        final picked = await showDatePicker(
                                          context: context, initialDate: _startDate, firstDate: DateTime(2000), lastDate: DateTime(2100),
                                        );
                                        if (picked != null) setState(() => _startDate = picked);
                                      }
                                    ),
                                  ],
                                )),
                                const SizedBox(width: 8),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Expected End'),
                                    const SizedBox(height: 8),
                                    _datePicker(
                                      date: _expectedEndDate,
                                      hint: 'dd/mm/yyyy',
                                      onSelect: () async {
                                        final picked = await showDatePicker(
                                          context: context, initialDate: _expectedEndDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100),
                                        );
                                        if (picked != null) setState(() => _expectedEndDate = picked);
                                      }
                                    ),
                                  ],
                                )),
                                const SizedBox(width: 8),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Actual End'),
                                    const SizedBox(height: 8),
                                    _datePicker(
                                      date: _actualEndDate,
                                      hint: 'dd/mm/yyyy',
                                      onSelect: () async {
                                        final picked = await showDatePicker(
                                          context: context, initialDate: _actualEndDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100),
                                        );
                                        if (picked != null) setState(() => _actualEndDate = picked);
                                      }
                                    ),
                                  ],
                                )),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(color: Color(0xFFEEF0F5), height: 1)),
                            
                            _label('BUDGET BREAKDOWN', uppercase: true),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _label('Material (\u20B9)'),
                                  const SizedBox(height: 8),
                                  _field(controller: _budgetMaterialCtrl, hint: '\u20B9 0', keyboardType: TextInputType.number),
                                ])),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _label('Labour (\u20B9)'),
                                  const SizedBox(height: 8),
                                  _field(controller: _budgetLabourCtrl, hint: '\u20B9 0', keyboardType: TextInputType.number),
                                ])),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _label('Equipment (\u20B9)'),
                                  const SizedBox(height: 8),
                                  _field(controller: _budgetEquipmentCtrl, hint: '\u20B9 0', keyboardType: TextInputType.number),
                                ])),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _label('Misc (\u20B9)'),
                                  const SizedBox(height: 8),
                                  _field(controller: _budgetMiscCtrl, hint: '\u20B9 0', keyboardType: TextInputType.number),
                                ])),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(color: Color(0xFFEEF0F5), height: 1)),
                            
                            _label('PROJECT STATUS', uppercase: true),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: _statusOptions.map((opt) {
                                final isSelected = _projectStatus == opt;
                                final isCancelled = opt == 'Cancelled';
                                return GestureDetector(
                                  onTap: () => setState(() => _projectStatus = opt),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                        ? (isCancelled ? const Color(0xFFFFF0F0) : primaryBlue.withValues(alpha: 0.1)) 
                                        : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected 
                                          ? (isCancelled ? Colors.red.withValues(alpha: 0.5) : primaryBlue) 
                                          : const Color(0xFFEEF0F5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      opt,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected 
                                          ? (isCancelled ? Colors.red : primaryBlue) 
                                          : textGray,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── CONSTRUCTION PHASES ────────────────────────────────
                      _buildConstructionPhasesCard(),

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _submit,
        backgroundColor: primaryBlue,
        elevation: 4,
        child: _saving 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildConfigList(List<String> options) {
    return Column(
      children: options.map((opt) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCheckboxRow(opt, _additionalConfigs.contains(opt), (v) {
            setState(() {
              if (v == true) { _additionalConfigs.add(opt); } else { _additionalConfigs.remove(opt); }
            });
          }),
        );
      }).toList(),
    );
  }

  Widget _buildAccordionCard({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: textGray, size: 24),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFEEF0F5)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: child,
                ),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF0F5)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {IconData? icon, bool uppercase = false}) {
    final textWidget = Text(
      uppercase ? text.toUpperCase() : text,
      style: TextStyle(
        fontSize: uppercase ? 12 : 13,
        fontWeight: FontWeight.w800,
        color: uppercase ? textDark.withValues(alpha: 0.5) : textGray,
        letterSpacing: uppercase ? 1.2 : 0.3,
      ),
    );

    if (icon == null) return textWidget;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: primaryBlue),
        const SizedBox(width: 6),
        textWidget,
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textGray.withValues(alpha: 0.5), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: textGray) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEF0F5), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(color: textGray.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w600),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textGray),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSelectableChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            color: isSelected ? Colors.white : textGray,
          ),
        ),
      ),
    );
  }

  Widget _buildCounterRow(String title, int value, {required VoidCallback onInc, required VoidCallback onDec}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onDec,
                child: Container(
                  width: 36, height: 36,
                  color: Colors.transparent,
                  child: const Icon(Icons.remove, size: 16, color: textGray),
                ),
              ),
              Container(
                width: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border.symmetric(vertical: BorderSide(color: Color(0xFFEEF0F5), width: 1.5)),
                ),
                child: Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark),
                ),
              ),
              GestureDetector(
                onTap: onInc,
                child: Container(
                  width: 36, height: 36,
                  color: Colors.transparent,
                  child: const Icon(Icons.add, size: 16, color: primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow(String title, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 24, height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: Color(0xFFDDE0E8), width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _datePicker({DateTime? date, String? hint, required VoidCallback onSelect}) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                date != null
                    ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                    : (hint ?? 'Select'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: date != null ? textDark : textGray.withValues(alpha: 0.5),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(Icons.calendar_month_rounded, size: 14, color: textGray.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildConstructionPhasesCard() {
    final int totalActivities    = _phases.fold(0, (s, p) => s + p.allActivities.length);
    final int selectedActivities = _phases.fold(0, (s, p) => s + p.selectedCount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.checklist_rounded, color: primaryBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Construction Phases',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDark),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '$selectedActivities/$totalActivities',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryBlue),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF0F5)),
          // ── Phase accordion list ────────────────────────────────────────
          ...List.generate(_phases.length, (i) => _buildPhaseAccordion(i, _phases[i])),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPhaseAccordion(int index, ConstructionPhase phase) {
    final total   = phase.allActivities.length;
    final done    = phase.selectedCount;
    final pct     = total == 0 ? 0 : ((done / total) * 100).round();

    return Column(
      children: [
        if (index > 0) const Divider(height: 1, color: Color(0xFFEEF0F5)),
        // Phase header row
        InkWell(
          onTap: () => setState(() => phase.isExpanded = !phase.isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: phase.isExpanded ? primaryBlue : Colors.transparent,
                    border: Border.all(
                      color: phase.isExpanded ? primaryBlue : const Color(0xFFDDE0E8),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: phase.isExpanded ? Colors.white : textGray,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phase.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: phase.isExpanded ? primaryBlue : textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$done/$total complete \u2022 $pct%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textGray),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: phase.isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: textGray, size: 22),
                ),
              ],
            ),
          ),
        ),
        // Activity list (animated)
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Container(
            color: const Color(0xFFF8F9FD),
            child: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFEEF0F5)),
                ...phase.allActivities.map((act) => _buildActivityRow(act)),
              ],
            ),
          ),
          crossFadeState: phase.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }

  Widget _buildActivityRow(ConstructionActivity act) {
    return InkWell(
      onTap: () => setState(() => act.isSelected = !act.isSelected),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            act.isSelected
                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18)
                : Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFCDD0DA), width: 1.5),
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                act.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: act.isSelected ? const Color(0xFF22C55E) : textDark,
                  decoration: act.isSelected ? TextDecoration.lineThrough : null,
                  decorationColor: const Color(0xFF22C55E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

