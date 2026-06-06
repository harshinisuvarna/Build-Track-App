import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/common/widgets/autocomplete_name_field.dart';
import 'package:buildtrack_mobile/common/widgets/common_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/entry_widgets.dart';
import 'package:buildtrack_mobile/common/widgets/upload_box.dart';
import 'package:buildtrack_mobile/common/utils/image_pick_helper.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:buildtrack_mobile/controller/inventory_provider.dart';
import 'package:buildtrack_mobile/models/construction_models.dart';
import 'package:buildtrack_mobile/models/project_model.dart';


import 'package:buildtrack_mobile/controller/role_manager.dart';

class AddLabourScreen extends StatefulWidget {
  const AddLabourScreen({super.key});

  @override
  State<AddLabourScreen> createState() => _AddLabourScreenState();
}

class _AddLabourScreenState extends State<AddLabourScreen> {
  // ── Execution context ────────────────────────────────────────────────────
  String? _selectedProjectId;
  String? _selectedFloor;
  dynamic _selectedPhase;
  String? _selectedActivity;
  Map<String, dynamic>? _duplicateContext;
  bool _isDuplicate = false;
  String? _sourceTransactionId;
  List<String> _floors = [];
  List<String> _phases = [];
  List<String> _activities = [];

  // ── Resource detail controllers ──────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _workTypeCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _overtimeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedUnit;

  // ── UI states ────────────────────────────────────────────────────────────
  bool _isSaving = false;
  bool _isEditing = false;
  String? _editingTransactionId;
  bool _argsLoaded = false;
  bool _isDatePickerOpen = false;      // guards against dialog/card overlap
  PickedAttachment? _attachment;
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _recentEntries = [];
  bool _isLoadingRecent = false;

  // ── Autocomplete suggestion cache ───────────────────────────────────────
  List<Map<String, dynamic>> _suggestions = [];

  // ── Payment state ───────────────────────────────────────────────────────
  bool _isAddAndPay = false;
  bool _recordPaymentNow = false;
  Map<String, dynamic>? _paymentResult;
  final _paymentAmountCtrl = TextEditingController();
  final _paymentNoteCtrl = TextEditingController();
  String _paymentMethod = 'Cash';
  DateTime _paymentDate = DateTime.now();

  // ── Validation flags ─────────────────────────────────────────────────────
  String? _nameError;
  String? _qtyError;
  String? _rateError;

  String _safeString(dynamic val) {
    if (val == null) return '';
    if (val is String) return val;
    if (val is Map) {
      return (val['name'] ?? val['title'] ?? val['phaseName'] ?? val['id'] ?? val['_id'] ?? '').toString();
    }
    return val.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _isEditing = args['isEditing'] as bool? ?? false;

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
        debugPrint('EDIT RECORD args');
        debugPrint(args.toString());
        _editingTransactionId = args['id']?.toString();

        final txId = _editingTransactionId!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchAndRestoreEdit(txId);
        });
      } else {
        // ── New entry — default project from session ───────────────────
        _selectedProjectId ??= UserSession.projectId;

        // ── Detect duplicate / Add More mode ──────────────────────────
        _isDuplicate = args['isDuplicate'] as bool? ?? false;
        _sourceTransactionId = args['sourceTransactionId']?.toString();

        final prefill = args['prefill'] as String?;
        if (prefill != null) _nameCtrl.text = prefill;

        if (_isDuplicate && _sourceTransactionId != null) {
          final txId = _sourceTransactionId!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchAndRestoreDuplicate(txId);
          });
        }
      }

      if (args['openPayment'] == true) {
        _isAddAndPay = true;
      }
    } else {
      _selectedProjectId ??= UserSession.projectId;
    }

    if (_selectedProjectId != null && !_isEditing) {
      _loadRecentEntries();
    }

    if (_duplicateContext != null) {
      final contextToRestore = Map<String, dynamic>.from(_duplicateContext!);
      _duplicateContext = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreDuplicateEntry(contextToRestore);
      });
    }
  }

  Future<void> _selectProject(String? projectId) async {
    _selectedProjectId = projectId;
  }

  Future<void> _loadFloors(String? projectId) async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final ProjectModel? project = projectId == null ? null : projectProvider.projects.cast<ProjectModel?>().firstWhere(
      (p) => p?.id == projectId,
      orElse: () => null,
    );

    const List<String> defaultFloors = [
      'Basement',
      'Ground Floor',
      '1st Floor',
      '2nd Floor',
      '3rd Floor',
      'Terrace',
    ];

    if (project != null) {
      _floors = (project.floors?.isNotEmpty == true)
          ? List<String>.from(project.floors!)
          : defaultFloors;
    } else {
      _floors = [];
    }
  }

  Future<void> _loadPhases(String? floor) async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final ProjectModel? project = _selectedProjectId == null ? null : projectProvider.projects.cast<ProjectModel?>().firstWhere(
      (p) => p?.id == _selectedProjectId,
      orElse: () => null,
    );

    if (project == null) {
      _phases = [];
      return;
    }

    final List<ProjectPhase>? projectPhases = project.selectedPhases;
    final bool hasNewWorkflow = projectPhases != null && projectPhases.isNotEmpty;

    if (hasNewWorkflow) {
      _phases = projectPhases
          .where((p) => p.activities.isNotEmpty)
          .map((p) => p.phaseName)
          .toList();
    } else {
      final List<ConstructionPhase> allPhases = buildDefaultPhases();
      final List<String>? legacyPhaseNames = project.selectedPhaseNames != null
          ? List<String>.from(project.selectedPhaseNames!)
          : null;
      final List<ConstructionPhase> visiblePhases = (legacyPhaseNames == null || legacyPhaseNames.isEmpty)
          ? allPhases
          : allPhases.where((p) => legacyPhaseNames.contains(p.name)).toList();
      _phases = visiblePhases.map((p) => p.name).toList();
    }
  }

  Future<void> _loadActivities(dynamic phase) async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final ProjectModel? project = _selectedProjectId == null ? null : projectProvider.projects.cast<ProjectModel?>().firstWhere(
      (p) => p?.id == _selectedProjectId,
      orElse: () => null,
    );

    if (project == null || phase == null) {
      _activities = [];
      return;
    }

    final String phaseName = phase is String
        ? phase
        : (phase is Map ? (phase['phaseName'] ?? phase['name'] ?? phase['id'])?.toString() ?? '' : phase.toString());

    final List<ProjectPhase>? projectPhases = project.selectedPhases;
    final bool hasNewWorkflow = projectPhases != null && projectPhases.isNotEmpty;

    if (hasNewWorkflow) {
      final ProjectPhase? selPhase = projectPhases.cast<ProjectPhase?>().firstWhere(
        (p) => p?.phaseName == phaseName,
        orElse: () => null,
      );
      _activities = selPhase != null
          ? selPhase.activities.map((a) => a.name).toList()
          : <String>[];
    } else {
      final List<ConstructionPhase> allPhases = buildDefaultPhases();
      final ConstructionPhase? selPhase = allPhases.cast<ConstructionPhase?>().firstWhere(
        (p) => p?.name == phaseName,
        orElse: () => null,
      );
      _activities = selPhase != null
          ? selPhase.allActivities.map<String>((a) => a.name).toList()
          : <String>[];
    }
  }

  Future<void> _fetchAndRestoreEdit(String txId) async {
    // 1. Search locally in InventoryProvider
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    Map<String, dynamic>? latest;
    for (var item in inventoryProvider.inventory) {
      for (var tx in item.transactions) {
        if (tx is Map && (tx['_id']?.toString() == txId || tx['id']?.toString() == txId)) {
          latest = Map<String, dynamic>.from(tx);
          break;
        }
      }
      if (latest != null) break;
    }

    // 2. Fallback to API if not found
    if (latest == null) {
      debugPrint('Edit lookup: ID $txId not found in local inventory, calling ApiService...');
      latest = await ApiService.fetchTransactionById(txId);
    }

    if (latest == null) {
      debugPrint('Edit lookup: Failed to fetch transaction details for ID $txId');
      return;
    }

    debugPrint('========================');
    debugPrint('RESOLVED EDIT PAYLOAD');
    debugPrint(latest.toString());
    debugPrint('========================');

    // Prefill fields
    final pId = latest['projectId'] ?? latest['project'];
    if (pId != null) {
      _selectedProjectId = pId is Map ? pId['_id']?.toString() : pId.toString();
    }
    
    _nameCtrl.text = _safeString(latest['title'] ?? latest['name'] ?? latest['materialName']);
    
    final double qty = (latest['quantity'] as num?)?.toDouble() ?? 0.0;
    _qtyCtrl.text = qty > 0
        ? (qty % 1 == 0 ? qty.toInt().toString() : qty.toString())
        : '';

    final double rate = (latest['rate'] as num?)?.toDouble() ?? 0.0;
    _rateCtrl.text = rate > 0
        ? (rate % 1 == 0 ? rate.toInt().toString() : rate.toString())
        : '';
    
    final rawUnit = _safeString(latest['unit']).trim().toLowerCase();
    if (rawUnit == 'day' || rawUnit == 'days') {
      _selectedUnit = 'Day';
    } else if (rawUnit == 'hour' || rawUnit == 'hours') {
      _selectedUnit = 'Hour';
    } else if (rawUnit == 'sqft' || rawUnit == 'sq.ft' || rawUnit == 'sq ft') {
      _selectedUnit = 'Sq.ft';
    } else if (rawUnit.isNotEmpty) {
      _selectedUnit = rawUnit[0].toUpperCase() + rawUnit.substring(1);
    }
    
    _categoryCtrl.text = _safeString(latest['categoryName'] ?? latest['category']);
    _workTypeCtrl.text = _safeString(latest['workType'] ?? latest['remarks'] ?? latest['notes']);
    _notesCtrl.text = _safeString(latest['notes']);

    if (latest['date'] != null) {
      try {
        _selectedDate = DateTime.parse(latest['date'].toString());
      } catch (_) {}
    }

    // Restore payment fields
    final pStatus = latest['paymentStatus']?.toString().toLowerCase() ?? latest['status']?.toString().toLowerCase();
    if (pStatus != null && pStatus != 'pending' && pStatus != '') {
      _isAddAndPay = true;
      _paymentMethod = latest['paymentMode'] ?? latest['paymentMethod'] ?? 'Cash';
      final double paid = (latest['paidAmount'] as num?)?.toDouble() ?? 0.0;
      _paymentAmountCtrl.text = paid > 0 ? paid.toString() : '';
    }

    // Sequential restoration of context: Project -> Floor -> Phase -> Activity
    final contextToRestore = {
      'projectId': _selectedProjectId,
      'floor': latest['floor'] ?? latest['zone'],
      'phase': latest['phase'],
      'activity': latest['activity'],
    };

    await _restoreDuplicateEntry(contextToRestore);
  }

  Future<void> _fetchAndRestoreDuplicate(String txId) async {
    // 1. Search locally in InventoryProvider
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    Map<String, dynamic>? latest;
    for (var item in inventoryProvider.inventory) {
      for (var tx in item.transactions) {
        if (tx is Map && (tx['_id']?.toString() == txId || tx['id']?.toString() == txId)) {
          latest = Map<String, dynamic>.from(tx);
          break;
        }
      }
      if (latest != null) break;
    }

    // 2. Fallback to API if not found
    if (latest == null) {
      debugPrint('Duplicate lookup: ID $txId not found in local inventory, calling ApiService...');
      latest = await ApiService.fetchTransactionById(txId);
    }

    if (latest == null) {
      debugPrint('Duplicate lookup: Failed to fetch transaction details for ID $txId');
      return;
    }

    debugPrint('========================');
    debugPrint('RESOLVED DUPLICATE PAYLOAD');
    debugPrint(latest.toString());
    debugPrint('========================');

    // Prefill fields
    final pId = latest['projectId'] ?? latest['project'];
    if (pId != null) {
      _selectedProjectId = pId is Map ? pId['_id']?.toString() : pId.toString();
    }
    
    _nameCtrl.text = _safeString(latest['title'] ?? latest['name'] ?? latest['materialName']);
    
    final rawUnit = _safeString(latest['unit']).trim().toLowerCase();
    if (rawUnit == 'day' || rawUnit == 'days') {
      _selectedUnit = 'Day';
    } else if (rawUnit == 'hour' || rawUnit == 'hours') {
      _selectedUnit = 'Hour';
    } else if (rawUnit == 'sqft' || rawUnit == 'sq.ft' || rawUnit == 'sq ft') {
      _selectedUnit = 'Sq.ft';
    } else if (rawUnit.isNotEmpty) {
      _selectedUnit = rawUnit[0].toUpperCase() + rawUnit.substring(1);
    }
    
    _categoryCtrl.text = _safeString(latest['categoryName'] ?? latest['category']);
    _workTypeCtrl.text = _safeString(latest['workType'] ?? latest['remarks'] ?? latest['notes']);
    _notesCtrl.text = _safeString(latest['notes']);

    final double rateVal = (latest['rate'] as num?)?.toDouble()
        ?? (latest['dailyWage'] as num?)?.toDouble()
        ?? (latest['hourlyRate'] as num?)?.toDouble()
        ?? 0.0;
    if (rateVal > 0) {
      _rateCtrl.text = rateVal % 1 == 0
          ? rateVal.toInt().toString()
          : rateVal.toString();
    }

    // Payment fields are intentionally left blank (clean slate) for duplicates

    // Sequential restoration of context: Project -> Floor -> Phase -> Activity
    final contextToRestore = {
      'projectId': _selectedProjectId,
      'floor': latest['floor'] ?? latest['zone'],
      'phase': latest['phase'],
      'activity': latest['activity'],
    };

    await _restoreDuplicateEntry(contextToRestore);
  }

  Future<void> _restoreDuplicateEntry(Map<String, dynamic> latest) async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    if (projectProvider.projects.isEmpty) {
      await projectProvider.load();
    }

    final pId = latest['projectId'] ?? latest['project'];
    String? resolvedProjectId;
    if (pId != null) {
      resolvedProjectId = pId is Map ? (pId['_id'] ?? pId['id'])?.toString() : pId.toString();
    }

    final String floor = _safeString(latest['floor'] ?? latest['zone']);
    final String phase = _safeString(latest['phase']);
    final String activity = _safeString(latest['activity']);

    final ProjectModel? project = resolvedProjectId == null ? null : projectProvider.projects.cast<ProjectModel?>().firstWhere(
      (p) => p?.id == resolvedProjectId,
      orElse: () => null,
    );

    if (project != null) {
      debugPrint('========================');
      debugPrint('PROJECT JSON MODEL');
      debugPrint(project.toJson().toString());
      debugPrint('========================');
    }

    // 1. Project
    await _selectProject(resolvedProjectId);

    // 2. Floors
    await _loadFloors(resolvedProjectId);

    // 3. Floor
    if (floor.isNotEmpty) {
      if (!_floors.contains(floor)) {
        _floors.insert(0, floor);
      }
      _selectedFloor = floor;
    }

    // 4. Phases
    await _loadPhases(_selectedFloor);

    // 5. Phase
    if (phase.isNotEmpty) {
      if (!_phases.contains(phase)) {
        _phases.insert(0, phase);
      }
      _selectedPhase = phase;
    }

    // 6. Activities
    await _loadActivities(_selectedPhase);

    // 7. Activity
    if (activity.isNotEmpty) {
      if (!_activities.contains(activity)) {
        _activities.insert(0, activity);
      }
      _selectedActivity = activity;
    }

    // STEP 5 - ADD VERIFICATION LOGS
    debugPrint('Selected Project: $_selectedProjectId');
    debugPrint('Selected Floor: $_selectedFloor');
    debugPrint('Selected Phase: $_selectedPhase');
    debugPrint('Selected Activity: $_selectedActivity');

    debugPrint('Floors Loaded: ${_floors.length}');
    debugPrint('Phases Loaded: ${_phases.length}');
    debugPrint('Activities Loaded: ${_activities.length}');

    // Temporary logs from prompt:
    debugPrint('Project restored: $resolvedProjectId');
    debugPrint('Floor restored: $floor');
    debugPrint('Phase restored: $phase');
    debugPrint('Activity restored: $activity');

    debugPrint('Available Floors: ${_floors.length}');
    debugPrint('Available Phases: ${_phases.length}');
    debugPrint('Available Activities: ${_activities.length}');

    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _workTypeCtrl.dispose();
    _categoryCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _overtimeCtrl.dispose();
    _notesCtrl.dispose();
    _paymentAmountCtrl.dispose();
    _paymentNoteCtrl.dispose();
    super.dispose();
  }

  double _totalCost() {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final overtime = double.tryParse(_overtimeCtrl.text) ?? 0;
    return (qty * rate) + overtime;
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty
          ? 'Worker / team name is required'
          : null;
      final qty = double.tryParse(_qtyCtrl.text);
      _qtyError =
          (qty == null || qty <= 0) ? 'Enter valid quantity > 0' : null;
      final rate = double.tryParse(_rateCtrl.text);
      _rateError =
          (rate == null || rate <= 0) ? 'Enter valid rate > 0' : null;
      ok = _nameError == null && _qtyError == null && _rateError == null;
    });
    return ok;
  }

  Future<void> _save(BuildContext ctx) async {
    if (_selectedProjectId == null) {
      _snack('Please pick target working site execution context');
      return;
    }
    if (!_validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      "title": _nameCtrl.text.trim(),
      "type": "Wages",
      "category": _categoryCtrl.text.trim().isEmpty
          ? "General Labour"
          : _categoryCtrl.text.trim(),
      "quantity": double.tryParse(_qtyCtrl.text) ?? 0,
      "rate": double.tryParse(_rateCtrl.text) ?? 0,
      "unit": _selectedUnit == null
          ? "hour"
          : _selectedUnit == "Day" || _selectedUnit == "day"
              ? "day"
              : _selectedUnit == "Hour" || _selectedUnit == "hour"
                  ? "hour"
                  : _selectedUnit == "Sq ft" ||
                          _selectedUnit == "sqft" ||
                          _selectedUnit == "Sq.ft"
                      ? "sqft"
                      : "unit",
      "project": _selectedProjectId,
      "date": _selectedDate.toIso8601String(),
      "floor": _selectedFloor,
      "phase": _selectedPhase,
      if (_selectedActivity != null && _selectedActivity!.isNotEmpty)
        "activity": _selectedActivity,
      if (_sourceTransactionId != null)
        "sourceTransactionId": _sourceTransactionId,
    };

    if (_isAddAndPay) {
      final paid = double.tryParse(_paymentAmountCtrl.text) ?? 0.0;
      String apiMode = _paymentMethod;
      if (apiMode == 'Bank Transfer' || apiMode == 'Card') apiMode = 'Bank';
      payload["paidAmount"] = paid;
      payload["paymentMode"] = apiMode;
      payload["paymentStatus"] =
          paid >= _totalCost() ? "Paid" : paid > 0 ? "Partial" : "Pending";
      payload["paymentDate"] = _paymentDate.toIso8601String();
      if (_paymentNoteCtrl.text.trim().isNotEmpty) {
        payload["notes"] = _paymentNoteCtrl.text.trim();
      }
    } else if (_recordPaymentNow && _paymentResult != null) {
      final paid = (_paymentResult!['amount'] as double?) ?? 0.0;
      final method = (_paymentResult!['method'] as String?) ?? 'Cash';
      final payDate =
          (_paymentResult!['paymentDate'] as DateTime?) ?? DateTime.now();
      String apiMode = method;
      if (apiMode == 'Bank Transfer' || apiMode == 'Card') apiMode = 'Bank';
      payload["paidAmount"] = paid;
      payload["paymentMode"] = apiMode;
      payload["paymentStatus"] =
          paid >= _totalCost() ? "Paid" : paid > 0 ? "Partial" : "Pending";
      payload["paymentDate"] = payDate.toIso8601String();
      if ((_paymentResult!['note'] as String?)?.isNotEmpty == true) {
        payload["notes"] = _paymentResult!['note'];
      }
    }

    debugPrint('===== SAVE PAYLOAD =====');
    debugPrint(payload.toString());
    debugPrint('========================');

    final bool success;
    if (_isEditing && _editingTransactionId != null) {
      success =
          await ApiService.updateTransaction(_editingTransactionId!, payload);
    } else {
      success = await ApiService.addMaterial(payload);
    }

    if (!mounted) return;

    if (success) {
      context.read<InventoryProvider>().loadInventory(_selectedProjectId!);
      context.read<ProjectProvider>().load();

      _snack(_isEditing
          ? 'Labour entry updated successfully!'
          : 'Labour entry logged to database!');
      Navigator.maybePop(context);
    } else {
      _snack('Error saving to server. Please try again.');
    }

    setState(() => _isSaving = false);
  }

  Widget _buildPaymentSection() {
    if (_isAddAndPay) return _buildInlinePaymentForm();

    return EntrySectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF15803D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Optionally log payment while adding',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _recordPaymentNow,
                activeThumbColor: AppColors.primary,
                onChanged: (v) async {
                  if (v) {
                    final result = await showPaymentSheet(
                      context,
                      entryTitle: _nameCtrl.text.trim().isEmpty
                          ? 'Labour'
                          : _nameCtrl.text.trim(),
                      entryRef: '',
                      totalAmount: _totalCost(),
                      alreadyPaid: 0,
                      vendorName: '',
                      category: _categoryCtrl.text.trim().isEmpty
                          ? 'Labour'
                          : _categoryCtrl.text.trim(),
                    );
                    if (mounted) {
                      setState(() {
                        if (result != null) {
                          _recordPaymentNow = true;
                          _paymentResult = result;
                        }
                      });
                    }
                  } else {
                    setState(() {
                      _recordPaymentNow = false;
                      _paymentResult = null;
                    });
                  }
                },
              ),
            ],
          ),
          if (_recordPaymentNow && _paymentResult != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF0EEF8)),
            const SizedBox(height: 12),
            _buildPaymentSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final amount = (_paymentResult!['amount'] as double?) ?? 0.0;
    final method = (_paymentResult!['method'] as String?) ?? 'Cash';
    final payDate =
        (_paymentResult!['paymentDate'] as DateTime?) ?? DateTime.now();
    final note = (_paymentResult!['note'] as String?) ?? '';
    return GestureDetector(
      onTap: () async {
        final result = await showPaymentSheet(
          context,
          entryTitle: _nameCtrl.text.trim().isEmpty
              ? 'Labour'
              : _nameCtrl.text.trim(),
          entryRef: '',
          totalAmount: _totalCost(),
          alreadyPaid: 0,
          vendorName: '',
          category: _categoryCtrl.text.trim().isEmpty
              ? 'Labour'
              : _categoryCtrl.text.trim(),
        );
        if (result != null && mounted) setState(() => _paymentResult = result);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 8),
                const Text('Payment Recorded',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D))),
                const Spacer(),
                const Text('Tap to edit',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _summaryChip(Icons.currency_rupee,
                      '₹${amount.toStringAsFixed(0)}', 'Amount'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      _summaryChip(Icons.payment_outlined, method, 'Method'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryChip(
                      Icons.calendar_today_outlined,
                      '${payDate.day}/${payDate.month}/${payDate.year}',
                      'Date'),
                ),
              ],
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Note: $note',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1FAE5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(icon, size: 11, color: const Color(0xFF15803D)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlinePaymentForm() {
    const methods = ['Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Card'];
    return EntrySectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: Color(0xFF15803D), size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Record Payment',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    SizedBox(height: 2),
                    Text('Log payment details for this entry',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF0EEF8)),
          const SizedBox(height: 16),
          const EntryFieldLabel('Amount Paid', required: false),
          const SizedBox(height: 8),
          EntryUnderlineField(
            controller: _paymentAmountCtrl,
            hint: '0',
            prefix: '₹',
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          const EntryFieldLabel('Payment Method'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: methods.map((m) {
              final sel = _paymentMethod == m;
              return GestureDetector(
                onTap: () => setState(() => _paymentMethod = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            sel ? AppColors.primary : const Color(0xFFDDE0F0),
                        width: 1.5),
                  ),
                  child: Text(m,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : AppColors.textDark)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const EntryFieldLabel('Payment Date'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _paymentDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          onSurface: AppColors.textDark)),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _paymentDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: const Color(0xFFE0E5FF), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      color: AppColors.primary, size: 19),
                  const SizedBox(width: 8),
                  Text(
                      '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textDark)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const EntryFieldLabel('Notes', required: false),
          const SizedBox(height: 8),
          EntryUnderlineField(
            controller: _paymentNoteCtrl,
            hint: 'e.g. Paid by site manager',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Recent Entries bottom sheet ────────────────────────────────
  void _showRecentEntriesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.60,
          minChildSize: 0.40,
          maxChildSize: 0.90,
          expand: false,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.history_rounded,
                              color: Color(0xFF2E7D32), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recent Labour Entries',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                    letterSpacing: -0.3)),
                            Text(
                              '${_recentEntries.length} similar entr${_recentEntries.length == 1 ? "y" : "ies"} found',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Divider(color: Color(0xFFF0EEF8)),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: _recentEntries.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final tx = _recentEntries[i] as Map<String, dynamic>;
                        final String title = tx['title']?.toString() ?? 'Untitled';
                        final double rate = (tx['rate'] as num?)?.toDouble() ?? 0.0;
                        final String unit = tx['unit']?.toString() ?? '';
                        final String category = tx['category']?.toString() ?? '';
                        final String workType = tx['workType']?.toString() ?? tx['remarks']?.toString() ?? '';

                        String dateStr = '';
                        final rawDate = tx['date'] ?? tx['createdAt'];
                        if (rawDate != null) {
                          try {
                            final d = DateTime.parse(rawDate.toString());
                            dateStr = '${d.day} ${_monthName(d.month)} ${d.year}';
                          } catch (_) {}
                        }

                        final String rateStr = rate > 0
                            ? '₹${rate % 1 == 0 ? rate.toInt() : rate}/$unit'
                            : '';

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pop(ctx);
                              _prefillFromRecent(tx);
                              _snack('Prefilled from "$title"');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFFEEEFF8), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32)
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.people_outlined,
                                        color: Color(0xFF2E7D32), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(title,
                                            style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textDark),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 3),
                                        Text(
                                          [
                                            if (rateStr.isNotEmpty) rateStr,
                                            if (category.isNotEmpty) category,
                                            if (workType.isNotEmpty) workType,
                                            if (dateStr.isNotEmpty) dateStr,
                                          ].join(' · '),
                                          style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textLight,
                                              fontWeight: FontWeight.w500),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32)
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Use',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2E7D32))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadRecentEntries() async {
    if (_selectedProjectId == null) {
      setState(() {
        _recentEntries = [];
        _suggestions = [];
      });
      return;
    }
    setState(() => _isLoadingRecent = true);

    // Load recent entries and autocomplete suggestions in parallel
    final recentFuture = ApiService.fetchRecentTransactions(
      projectId: _selectedProjectId!,
      type: 'Wages', // or 'Materials' / 'Expense'
      userId: UserSession.userId, // ADD THIS
    );
    final suggestionFuture = ApiService.fetchSuggestions(
      projectId: _selectedProjectId!,
      type: 'Wages',
      userId: UserSession.userId, // ADD THIS
    );
    final recentTxs = await recentFuture;
    final suggestions = await suggestionFuture;

    if (mounted) {
      setState(() {
        _recentEntries = recentTxs.take(5).toList();
        _suggestions = suggestions;
        _isLoadingRecent = false;
      });
    }
  }

  void _prefillFromRecent(Map<String, dynamic> tx) {
    setState(() {
      _nameCtrl.text = tx['title']?.toString() ?? '';
      
      final rawUnit = (tx['unit'] ?? '').toString().trim().toLowerCase();
      if (rawUnit == 'day' || rawUnit == 'days') {
        _selectedUnit = 'Day';
      } else if (rawUnit == 'hour' || rawUnit == 'hours') {
        _selectedUnit = 'Hour';
      } else if (rawUnit == 'sqft' || rawUnit == 'sq.ft' || rawUnit == 'sq ft') {
        _selectedUnit = 'Sq.ft';
      } else if (rawUnit.isNotEmpty) {
        _selectedUnit = rawUnit[0].toUpperCase() + rawUnit.substring(1);
      }
      
      _categoryCtrl.text = tx['category']?.toString() ?? '';
      _workTypeCtrl.text = tx['remarks']?.toString() ?? '';
      
      final double rateVal = (tx['rate'] as num?)?.toDouble() ?? 0.0;
      _rateCtrl.text = rateVal > 0 ? (rateVal % 1 == 0 ? rateVal.toInt().toString() : rateVal.toString()) : '';
      
      final pStatus = tx['paymentStatus']?.toString().toLowerCase();
      if (pStatus != null && pStatus != 'pending' && pStatus != '') {
        _isAddAndPay = true;
        _paymentMethod = tx['paymentMode'] ?? 'Cash';
        final double paid = (tx['paidAmount'] as num?)?.toDouble() ?? 0.0;
        _paymentAmountCtrl.text = paid > 0 ? paid.toString() : '';
      }
    });
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }



  @override
  Widget build(BuildContext context) {
    context.watch<ProjectProvider>().projects;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              title: _isEditing
                  ? 'Modify Labour Log'
                  : _isDuplicate
                      ? 'Repeat Entry'
                      : 'Log Labour Force',
              isSubScreen: true,
              leftIcon: Icons.arrow_back,
              onLeftTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    ExecutionContextCard(
                      selectedProjectId: _selectedProjectId,
                      selectedFloor: _selectedFloor,
                      selectedPhase: _selectedPhase,
                      selectedActivity: _selectedActivity,
                      onProjectChanged: (v) => setState(() {
                        _selectedProjectId = v;
                        _selectedFloor = null;
                        _selectedPhase = null;
                        _selectedActivity = null;
                        _loadRecentEntries();
                      }),
                      onFloorChanged: (v) => setState(() {
                        _selectedFloor = v;
                        _selectedPhase = null;
                        _selectedActivity = null;
                      }),
                      onPhaseChanged: (v) => setState(() {
                        _selectedPhase = v;
                        _selectedActivity = null;
                      }),
                      onActivityChanged: (v) =>
                          setState(() => _selectedActivity = v),
                    ),

                    // ── SECTION 2: LABOUR ENTRY ───────────────────────────
                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon: Icons.people_outline,
                            title: 'Labour Entry',
                            subtitle: 'Date · Labour Type · Unit · Qty · Rate · Amount',
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF0EEF8)),
                          const SizedBox(height: 16),

                          // ── 1. DATE ────────────────────────────────────────
                          const EntryFieldLabel('Date', required: true),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              setState(() => _isDatePickerOpen = true);
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                      onSurface: AppColors.textDark,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (!mounted) return;
                              setState(() {
                                _isDatePickerOpen = false;
                                if (picked != null) _selectedDate = picked;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color(0xFF173EEA), width: 2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      color: AppColors.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.primary, size: 22),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── 2. LABOUR TYPE ─────────────────────────────────
                          const EntryFieldLabel('Labour Type', required: true),
                          const SizedBox(height: 8),
                          AutocompleteNameField(
                            controller: _nameCtrl,
                            hint: 'e.g. Mason, Carpenter, Steel Fixer',
                            suggestions: _suggestions,
                            onChanged: (_) => setState(() {}),
                            onSuggestionSelected: _prefillFromRecent,
                          ),
                          if (_nameError != null) EntryErrorText(_nameError!),
                          const SizedBox(height: 20),


                          // ── 3. UNIT ────────────────────────────────────────
                          const EntryFieldLabel('Unit', required: true),
                          const SizedBox(height: 8),
                          UnitSelectorField(
                            value: _selectedUnit,
                            units: kLabourUnits,
                            hint: 'Select unit (e.g. Day, Hour, Sq ft)',
                            onChanged: (u) =>
                                setState(() => _selectedUnit = u),
                          ),
                          const SizedBox(height: 20),

                          // ── 4. QUANTITY ────────────────────────────────────
                          const EntryFieldLabel('Quantity', required: true),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _qtyCtrl,
                            hint: '0',
                            suffix: _selectedUnit ?? 'Unit',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_qtyError != null) EntryErrorText(_qtyError!),
                          const SizedBox(height: 20),

                          // ── 5. RATE ────────────────────────────────────────
                          const EntryFieldLabel('Rate (₹)', required: true),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _rateCtrl,
                            hint: '0',
                            prefix: '₹',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_rateError != null) EntryErrorText(_rateError!),
                          const SizedBox(height: 20),

                          // ── 6. AMOUNT (auto-calculated) ────────────────────
                          const EntryFieldLabel('Amount (₹)'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFCDD1F0), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.currency_rupee_rounded,
                                    size: 16, color: Color(0xFF173EEA)),
                                const SizedBox(width: 4),
                                Text(
                                  (() {
                                    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
                                    final rate = double.tryParse(_rateCtrl.text) ?? 0;
                                    final sub = qty * rate;
                                    return sub > 0
                                        ? sub.toStringAsFixed(sub % 1 == 0 ? 0 : 2)
                                        : '—';
                                  })(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF173EEA),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E3FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Auto',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF173EEA),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── OPTIONAL DETAILS ───────────────────────────────
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(color: Color(0xFFF0EEF8))),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Text(
                                  'OPTIONAL DETAILS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textLight,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const Expanded(
                                  child: Divider(color: Color(0xFFF0EEF8))),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── 7. TRADE / WORK TYPE ───────────────────────────
                          const EntryFieldLabel('Trade / Work Type (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _workTypeCtrl,
                            hint: 'e.g. Masonry, Barbending, Concrete Crew',
                          ),
                          const SizedBox(height: 20),

                          // ── 8. CONTRACTOR / TEAM ──────────────────────────
                          const EntryFieldLabel('Contractor / Team (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _categoryCtrl,
                            hint: 'e.g. Vertex Infra Contractors',
                          ),
                          const SizedBox(height: 20),

                          // ── 9. OVERTIME ────────────────────────────────────
                          const EntryFieldLabel('Overtime Amount (Optional)'),
                          const SizedBox(height: 8),
                          EntryUnderlineField(
                            controller: _overtimeCtrl,
                            hint: '0',
                            prefix: '₹',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 20),

                          // ── 10. NOTES ──────────────────────────────────────
                          const EntryFieldLabel('Notes (Optional)'),
                          const SizedBox(height: 8),
                          EntryNotesField(controller: _notesCtrl),
                        ],
                      ),
                    ),



                    CostSummaryCard(
                      totalAmount: _totalCost(),
                      label: 'Calculated Operational Labor Budget',
                      subtotals: [
                        (
                          'Qty × Rate',
                          '${_qtyCtrl.text.isEmpty ? "—" : _qtyCtrl.text} ${_selectedUnit ?? "Unit"} × ₹${_rateCtrl.text.isEmpty ? "—" : _rateCtrl.text}',
                        ),
                        (
                          'Overtime',
                          '₹ ${_overtimeCtrl.text.isEmpty ? "0" : _overtimeCtrl.text}',
                        ),
                      ],
                    ),

                    EntrySectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EntryCardHeader(
                            icon: Icons.receipt_long_outlined,
                            title: 'Invoice / Bill',
                            subtitle:
                                'Attach invoice, bill, or supporting document (optional)',
                          ),
                          const SizedBox(height: 16),
                          UploadBox(
                            attachment: _attachment,
                            emptyLabel: 'Tap to upload invoice / bill',
                            onPicked: (a) => setState(() => _attachment = a),
                            onRemove: () => setState(() => _attachment = null),
                          ),
                        ],
                      ),
                    ),

                    if (RoleManager.canApprovePayments)
                      _buildPaymentSection(),
                    const SizedBox(height: 4),

                    // ── RECENT ENTRIES COMPACT BANNER (bottom-sheet) ────
                    if (_selectedProjectId != null &&
                        !_isEditing &&
                        !_isDatePickerOpen) ...[
                      if (_isLoadingRecent)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2)),
                        )
                      else if (_recentEntries.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _showRecentEntriesSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFD1EDD4), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32)
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(Icons.history_rounded,
                                      color: Color(0xFF2E7D32), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Recent Labour Entries',
                                          style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textDark)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_recentEntries.length} similar entr${_recentEntries.length == 1 ? "y" : "ies"} found · Tap to view',
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textLight,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textLight, size: 22),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],


                    EntrySubmitButton(
                      label: 'Save Labour Entry',
                      icon: Icons.check_circle,
                      isLoading: _isSaving,
                      onTap: () => _save(context),
                    ),
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
}