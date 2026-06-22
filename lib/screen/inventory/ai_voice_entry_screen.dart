import 'dart:async';
import 'dart:math' as math;
import 'package:buildtrack_mobile/common/controllers/voice_recording_controller.dart';
import 'package:buildtrack_mobile/common/themes/app_colors.dart';
import 'package:buildtrack_mobile/controller/project_provider.dart';
import 'package:buildtrack_mobile/controller/user_session.dart';
import 'package:buildtrack_mobile/models/project_model.dart';
import 'package:buildtrack_mobile/services/api_service.dart';
import 'package:buildtrack_mobile/services/buildtrack_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─── Backend response model ────────────────────────────────────────────────────
// All UI renders from this model. Backend integration just replaces the
// population layer — the rendering pipeline stays identical.
class VoiceResponseModel {
  final String status; // idle | listening | processing | thinking | extracting |
                       // waiting_for_user | summary | saving | completed | error
  final String? entryType;
  final String? transcript;
  final String? partialTranscript;
  final Map<String, dynamic> detectedFields;
  final List<String> missingFields;
  final String? question;
  final List<String> suggestions;
  final int completedFields;
  final int totalFields;
  final double? confidence;
  final String? errorMessage;
  final String? welcomeMessage;

  const VoiceResponseModel({
    this.status = 'idle',
    this.entryType,
    this.transcript,
    this.partialTranscript,
    this.detectedFields = const {},
    this.missingFields = const [],
    this.question,
    this.suggestions = const [],
    this.completedFields = 0,
    this.totalFields = 0,
    this.confidence,
    this.errorMessage,
    this.welcomeMessage,
  });

  VoiceResponseModel copyWith({
    String? status,
    String? entryType,
    String? transcript,
    String? partialTranscript,
    Map<String, dynamic>? detectedFields,
    List<String>? missingFields,
    String? question,
    List<String>? suggestions,
    int? completedFields,
    int? totalFields,
    double? confidence,
    String? errorMessage,
    String? welcomeMessage,
  }) =>
      VoiceResponseModel(
        status: status ?? this.status,
        entryType: entryType ?? this.entryType,
        transcript: transcript ?? this.transcript,
        partialTranscript: partialTranscript ?? this.partialTranscript,
        detectedFields: detectedFields ?? this.detectedFields,
        missingFields: missingFields ?? this.missingFields,
        question: question ?? this.question,
        suggestions: suggestions ?? this.suggestions,
        completedFields: completedFields ?? this.completedFields,
        totalFields: totalFields ?? this.totalFields,
        confidence: confidence ?? this.confidence,
        errorMessage: errorMessage ?? this.errorMessage,
        welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      );

  bool get hasField => detectedFields.isNotEmpty;
  bool fieldHasValue(String key) =>
      detectedFields.containsKey(key) &&
      detectedFields[key] != null &&
      '${detectedFields[key]}'.trim().isNotEmpty;
}

// ─── Status constants (replaces _ConvStep enum) ───────────────────────────────
// These replace the hardcoded step enums. The backend returns a status string
// and the UI derives which view to show from it.
abstract final class VoiceStatus {
  static const String idle = 'idle';
  static const String listening = 'listening';
  static const String processing = 'processing';
  static const String thinking = 'thinking';
  static const String extracting = 'extracting';
  static const String waitingForUser = 'waiting_for_user';
  static const String summary = 'summary';
  static const String saving = 'saving';
  static const String completed = 'completed';
  static const String error = 'error';
}

// ─── Backward-compat enum mapping (will be removed when backend is connected) ──
// Translates between the old _ConvStep enum values and the new status strings
// so existing UI code continues working without modification.
enum _ConvStep {
  initialVoice,
  aiProcessing,
  extracted,
  askProject,
  askFloor,
  askPhase,
  askActivity,
  askQuantity,
  askUnit,
  askRate,
  askBrand,
  askLabourType,
  askWorkerCount,
  askHours,
  askEquipment,
  askFuel,
  summary,
  saving,
  success,
}

// ─── Backward-compat ExtractedData class ──────────────────────────────────────
// Thin wrapper over Map<String, dynamic> so all existing `_data.xxx` calls work.
class _ExtractedData {
  final Map<String, dynamic> _map;

  _ExtractedData(this._map);

  String? get itemName => _map['Item Name'] as String?;
  set itemName(String? v) => _map['Item Name'] = v;
  double? get quantity => _map['Quantity'] as double?;
  set quantity(double? v) => _map['Quantity'] = v;
  String? get unit => _map['Unit'] as String?;
  set unit(String? v) => _map['Unit'] = v;
  double? get rate => _map['Rate'] as double?;
  set rate(double? v) => _map['Rate'] = v;
  String? get brand => _map['Brand'] as String?;
  set brand(String? v) => _map['Brand'] = v;
  String? get projectId => _map['Project ID'] as String?;
  set projectId(String? v) => _map['Project ID'] = v;
  String? get projectName => _map['Project Name'] as String?;
  set projectName(String? v) => _map['Project Name'] = v;
  String? get floor => _map['Floor'] as String?;
  set floor(String? v) => _map['Floor'] = v;
  String? get phase => _map['Phase'] as String?;
  set phase(String? v) => _map['Phase'] = v;
  String? get phaseId => _map['Phase ID'] as String?;
  set phaseId(String? v) => _map['Phase ID'] = v;
  String? get activity => _map['Activity'] as String?;
  set activity(String? v) => _map['Activity'] = v;
  int? get workerCount => _map['Worker Count'] as int?;
  set workerCount(int? v) => _map['Worker Count'] = v;
  double? get hours => _map['Hours'] as double?;
  set hours(double? v) => _map['Hours'] = v;
  String? get contractor => _map['Contractor'] as String?;
  set contractor(String? v) => _map['Contractor'] = v;
  String? get workType => _map['Work Type'] as String?;
  set workType(String? v) => _map['Work Type'] = v;
  String? get category => _map['Category'] as String?;
  set category(String? v) => _map['Category'] = v;
  double? get fuelCost => _map['Fuel Cost'] as double?;
  set fuelCost(double? v) => _map['Fuel Cost'] = v;
  String? get operator0 => _map['Operator'] as String?;
  set operator0(String? v) => _map['Operator'] = v;
  String? get equipmentType => _map['Equipment Type'] as String?;
  set equipmentType(String? v) => _map['Equipment Type'] = v;
  String? get vendorName => _map['Vendor Name'] as String?;
  set vendorName(String? v) => _map['Vendor Name'] = v;

  double getComputedAmount(String entryType) {
    if (entryType == 'labour') {
      final qty = (workerCount ?? 1) * (hours ?? quantity ?? 0);
      return qty * (rate ?? 0);
    } else if (entryType == 'equipment') {
      final base = (quantity ?? 0) * (rate ?? 0);
      return base + (fuelCost ?? 0);
    }
    return (quantity ?? 0) * (rate ?? 0);
  }

  bool get hasItemName => itemName != null && itemName!.trim().isNotEmpty;
  bool get hasQuantity => quantity != null && quantity! > 0;
  bool get hasUnit => unit != null && unit!.trim().isNotEmpty;
  bool get hasRate => rate != null && rate! > 0;
  bool get hasBrand => brand != null && brand!.trim().isNotEmpty;
  bool get hasProject => projectId != null && projectId!.isNotEmpty;
  bool get hasFloor => floor != null && floor!.trim().isNotEmpty;
  bool get hasPhase => phase != null && phase!.trim().isNotEmpty;
  bool get hasActivity => activity != null && activity!.trim().isNotEmpty;
  bool get hasWorkerCount => workerCount != null && workerCount! > 0;
  bool get hasHours => hours != null && hours! > 0;
  bool get hasFuelCost => fuelCost != null;
}

// ─── Blinking Cursor Widget ───────────────────────────────────────────────────
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 18,
        color: AppColors.primary,
      ),
    );
  }
}

// ─── Detected Field Label Model ───────────────────────────────────────────────
class _DetectedField {
  final String label;
  final String value;
  _DetectedField({required this.label, required this.value});
}

// ─── Main screen widget ────────────────────────────────────────────────────────
class AiVoiceEntryScreen extends StatefulWidget {
  const AiVoiceEntryScreen({super.key});

  @override
  State<AiVoiceEntryScreen> createState() => _AiVoiceEntryScreenState();
}

class _AiVoiceEntryScreenState extends State<AiVoiceEntryScreen>
    with TickerProviderStateMixin {
  // ── Conversational Session Memory ──────────────────────────────────────────
  static final Map<String, dynamic> _sessionMemory = {
    'projectId': null,
    'projectName': null,
    'floor': null,
    'phase': null,
    'phaseId': null,
    'activity': null,
  };

  // ── Entry type ───────────────────────────────────────────────────────────────
  late String _entryType; // 'material' | 'labour' | 'equipment'

  // ── Backend-driven model state ────────────────────────────────────────────────
  // _response holds the current view state. Every UI element renders from it.
  // The local-parsing methods (_parseTranscriptInto etc.) populate this model.
  // When the real backend is connected, only the population layer changes.
  VoiceResponseModel _response = const VoiceResponseModel();

  // ── Detected fields (replaces _ExtractedData's individual fields) ─────────────
  final Map<String, dynamic> _detectedFields = {};

  // ── Backward-compat wrappers so existing UI code continues working ────────────
  // _data wraps _detectedFields; _step derives from _status.
  // DELETE THESE AND ALL `_data.` / `_step` / `_ConvStep` REFERENCES
  // WHEN THE BACKEND IS CONNECTED.
  _ExtractedData get _data => _ExtractedData(_detectedFields);
  String _rawTranscript = '';

  // ── Conversation status (replaces _ConvStep) ──────────────────────────────────
  String _status = VoiceStatus.idle;
  _ConvStep get _step => _convStepFromStatus(_status);
  set _step(_ConvStep value) {
    _status = _statusFromConvStep(value);
  }

  // Map from old _ConvStep to new status string (for backward compat assignments)
  static String _statusFromConvStep(_ConvStep step) {
    switch (step) {
      case _ConvStep.initialVoice:
        return VoiceStatus.listening;
      case _ConvStep.aiProcessing:
        return VoiceStatus.processing;
      case _ConvStep.extracted:
        return VoiceStatus.extracting;
      case _ConvStep.askProject:
      case _ConvStep.askFloor:
      case _ConvStep.askPhase:
      case _ConvStep.askActivity:
      case _ConvStep.askQuantity:
      case _ConvStep.askUnit:
      case _ConvStep.askRate:
      case _ConvStep.askBrand:
      case _ConvStep.askLabourType:
      case _ConvStep.askWorkerCount:
      case _ConvStep.askHours:
      case _ConvStep.askEquipment:
      case _ConvStep.askFuel:
        return VoiceStatus.waitingForUser;
      case _ConvStep.summary:
        return VoiceStatus.summary;
      case _ConvStep.saving:
        return VoiceStatus.saving;
      case _ConvStep.success:
        return VoiceStatus.completed;
    }
  }

  // Map from status string to old _ConvStep (for backward compat getter)
  static _ConvStep _convStepFromStatus(String status) {
    switch (status) {
      case VoiceStatus.listening:
      case VoiceStatus.idle:
        return _ConvStep.initialVoice;
      case VoiceStatus.processing:
      case VoiceStatus.thinking:
        return _ConvStep.aiProcessing;
      case VoiceStatus.extracting:
        return _ConvStep.extracted;
      case VoiceStatus.summary:
        return _ConvStep.summary;
      case VoiceStatus.saving:
        return _ConvStep.saving;
      case VoiceStatus.completed:
        return _ConvStep.success;
      case VoiceStatus.error:
        return _ConvStep.initialVoice;
      case VoiceStatus.waitingForUser:
        // NOTE: Do NOT use this to derive the question.
        // Use _nextMissingFieldStep() which reads fresh missing fields.
        return _ConvStep.askProject;
      default:
        return _ConvStep.initialVoice;
    }
  }

  // ── BUG 5 FIX: Convert the FIRST missing field label → the correct _ConvStep ──
  // This is the single function that decides which question to ask next.
  // It reads fresh missing fields every time — never stale state.
  _ConvStep _nextMissingFieldStep() {
    final missing = _getStillNeededFieldsFor(_data);
    debugPrint('[AI DEBUG] _nextMissingFieldStep: missingFields=$missing');
    if (missing.isEmpty) return _ConvStep.summary;
    final first = missing.first;
    switch (first) {
      case 'Project':      return _ConvStep.askProject;
      case 'Floor':        return _ConvStep.askFloor;
      case 'Phase':        return _ConvStep.askPhase;
      case 'Activity':     return _ConvStep.askActivity;
      case 'Labour Type':  return _ConvStep.askLabourType;
      case 'Worker Count': return _ConvStep.askWorkerCount;
      case 'Hours':        return _entryType == 'labour' ? _ConvStep.askHours : _ConvStep.askHours;
      case 'Equipment':    return _ConvStep.askEquipment;
      case 'Fuel':         return _ConvStep.askFuel;
      case 'Quantity':     return _ConvStep.askQuantity;
      case 'Unit':         return _ConvStep.askUnit;
      case 'Rate':         return _ConvStep.askRate;
      case 'Brand':        return _ConvStep.askBrand;
      default:             return _ConvStep.askProject;
    }
  }

  String? _saveError;
  String? _savedEntryId;

  // ── Backend-driven question & suggestions ─────────────────────────────────────
  String _backendQuestion = '';
  List<String> _backendSuggestions = const [];

  // ── Field progress (computed via _rebuildResponse, read from _response) ────────

  // ── Voice engine ──────────────────────────────────────────────────────────────
  late final VoiceRecordingController _voiceCtrl;
  bool _isListeningForAnswer = false;
  bool _showAnalyzingLabel = false;
  String _partialAnswer = '';

  // ── Text input toggle & controllers ───────────────────────────────────────────
  bool _showKeyboardInput = false;
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  // ── Scroll ────────────────────────────────────────────────────────────────────
  final _scrollCtrl = ScrollController();

  // ── Animations ────────────────────────────────────────────────────────────────
  late final AnimationController _micPulseCtrl;
  late final AnimationController _bubbleCtrl;
  late final AnimationController _micOrbCtrl;
  late final AnimationController _waveCtrl;

  // ── Projects ──────────────────────────────────────────────────────────────────
  List<ProjectModel> get _projects =>
      Provider.of<ProjectProvider>(context, listen: false).projects;

  // ── Processing stages ─────────────────────────────────────────────────────────
  int _processingStage = 0;
  Timer? _processingTimer;

  @override
  void initState() {
    super.initState();

    _micPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _micOrbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _voiceCtrl = VoiceRecordingController();
    _voiceCtrl.addListener(_onVoiceChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _entryType = (args?['type'] as String?) ?? 'material';

    // Pre-populate project and other context from static session memory first
    if (_sessionMemory['projectId'] != null) {
      _detectedFields['Project ID'] = _sessionMemory['projectId'];
      _detectedFields['Project Name'] = _sessionMemory['projectName'];
    } else {
      final pid = UserSession.projectId;
      if (pid.isNotEmpty) {
        _detectedFields['Project ID'] = pid;
        final match = _projects.cast<ProjectModel?>().firstWhere(
              (p) => p?.id == pid,
              orElse: () => null,
            );
        _detectedFields['Project Name'] = match?.name;
      }
    }
    if (_sessionMemory['floor'] != null) _detectedFields['Floor'] = _sessionMemory['floor'];
    if (_sessionMemory['phase'] != null) _detectedFields['Phase'] = _sessionMemory['phase'];
    if (_sessionMemory['phaseId'] != null) _detectedFields['Phase ID'] = _sessionMemory['phaseId'];
    if (_sessionMemory['activity'] != null) _detectedFields['Activity'] = _sessionMemory['activity'];

    // Build initial response model from session
    _rebuildResponse();

    // Auto-start initial voice entry recording on screen load
    if (_rawTranscript.isEmpty && _voiceCtrl.engineState == VoiceEngineState.idle) {
      setState(() => _status = VoiceStatus.listening);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _startInitialRecording();
      });
    }
  }

  @override
  void dispose() {
    _voiceCtrl.removeListener(_onVoiceChanged);
    _voiceCtrl.dispose();
    _micPulseCtrl.dispose();
    _bubbleCtrl.dispose();
    _micOrbCtrl.dispose();
    _waveCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    _processingTimer?.cancel();
    super.dispose();
  }

  // ─── Example Phrases ──────────────────────────────────────────────────────────
  String get _examplePhrase {
    if (_entryType == 'material') {
      return '20 bags of UltraTech cement for foundation work on first floor';
    } else if (_entryType == 'labour') {
      return '8 masons worked today for 6 hours on brick laying';
    } else {
      return 'JCB worked 5 hours today for excavation';
    }
  }

  // ─── Voice engine listener ─────────────────────────────────────────────────────
  void _onVoiceChanged() {
    if (!mounted) return;
    final state = _voiceCtrl.engineState;

    setState(() {
      _partialAnswer = _voiceCtrl.partialTranscript;
    });

    debugPrint('[AI DEBUG] _onVoiceChanged: engineState=$state, isListeningForAnswer=$_isListeningForAnswer, step=$_step');

    if (state == VoiceEngineState.parsed) {
      final text = _voiceCtrl.finalTranscript.trim();
      debugPrint('[AI DEBUG] finalTranscript: "$text"');
      if (_step == _ConvStep.initialVoice) {
        if (text.isNotEmpty) {
          _rawTranscript = text;
        }
      } else if (_isListeningForAnswer) {
        _isListeningForAnswer = false;
        setState(() {});
        if (text.isNotEmpty) {
          _handleVoiceAnswer(text);
        } else {
          // BUG 3 FIX: Empty result after listening — unstick the UI
          debugPrint('[AI DEBUG] Empty transcript after listening — resetting listening state');
          _unstickListening();
        }
      }
    } else if (state == VoiceEngineState.idle || state == VoiceEngineState.error) {
      // BUG 3 FIX: Engine went idle/error without a parsed result
      if (_isListeningForAnswer) {
        debugPrint('[AI DEBUG] Engine went $state while listening for answer — resetting');
        _isListeningForAnswer = false;
        _unstickListening();
      }
    }
  }

  // BUG 3 FIX: Force-reset the listening UI without losing detected fields
  void _unstickListening() {
    if (!mounted) return;
    setState(() {
      _partialAnswer = '';
      _rebuildResponse();
    });
  }

  // ─── Recording control helpers ────────────────────────────────────────────────
  Future<void> _startInitialRecording() async {
    await _voiceCtrl.startListening();
    if (mounted) setState(() {});
  }

  Future<void> _stopInitialRecording() async {
    await _voiceCtrl.stopListening();
  }

  // ─── Stop & Analyze ───────────────────────────────────────────────────────────
  // Single-button flow: stops recording, waits for the transcript to finalize,
  // then immediately starts AI processing. No second "Continue" tap needed.
  Future<void> _stopAndAnalyze() async {
    setState(() => _showAnalyzingLabel = true);

    // Step 1 — stop the microphone (voice engine transitions processing → parsed)
    await _voiceCtrl.stopListening();
    if (!mounted) return;

    // Step 2 — wait for the voice engine's internal 800ms pipeline to finish
    // and for _onVoiceChanged to capture the final transcript into _rawTranscript.
    // (We keep _status at listening/idle during this wait so that
    //  _onVoiceChanged still sees _step == _ConvStep.initialVoice.)
    const maxWait = Duration(seconds: 3);
    final start = DateTime.now();
    while (_rawTranscript.isEmpty &&
        DateTime.now().difference(start) < maxWait) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    // Fallback: read direct from controller if listener missed it
    if (_rawTranscript.isEmpty) {
      _rawTranscript = _voiceCtrl.finalTranscript;
    }

    setState(() => _showAnalyzingLabel = false);

    // Step 3 — now flip to processing state and fire the AI chain
    if (mounted && _rawTranscript.isNotEmpty) {
      _beginAiProcessing();
    }
  }

  // ─── Reset Data ────────────────────────────────────────────────────────────────
  void _resetCurrentEntryData() {
    setState(() {
      _data.itemName = null;
      _data.quantity = null;
      _data.unit = null;
      _data.rate = null;
      _data.brand = null;
      _data.workerCount = null;
      _data.hours = null;
      _data.fuelCost = null;
      _data.contractor = null;
      _data.workType = null;
      _data.category = null;
      _data.operator0 = null;
      _data.equipmentType = null;
      _data.vendorName = null;
      _rawTranscript = '';
      _partialAnswer = '';
      _rebuildResponse();
    });
  }

  // ─── AI Processing transition ──────────────────────────────────────────────────
  void _beginAiProcessing() {
    setState(() {
      _status = VoiceStatus.processing;
      _processingStage = 0;
      _rebuildResponse();
    });

    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _processingStage++;
        _rebuildResponse();
      });
      if (_processingStage >= 6) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _finishExtraction();
        });
      }
    });
  }

  void _finishExtraction() {
    _parseTranscriptInto(_data, _rawTranscript);
    _advanceToNextMissingField();
  }

  // ─── Live Extraction logic ─────────────────────────────────────────────────────
  _ExtractedData get _currentData {
    if (_step == _ConvStep.initialVoice && _voiceCtrl.isListening && _partialAnswer.isNotEmpty) {
      final tempMap = <String, dynamic>{};
      final temp = _ExtractedData(tempMap);
      if (_sessionMemory['projectId'] != null) {
        temp.projectId = _sessionMemory['projectId'];
        temp.projectName = _sessionMemory['projectName'];
      }
      if (_sessionMemory['floor'] != null) temp.floor = _sessionMemory['floor'];
      if (_sessionMemory['phase'] != null) temp.phase = _sessionMemory['phase'];
      if (_sessionMemory['phaseId'] != null) temp.phaseId = _sessionMemory['phaseId'];
      if (_sessionMemory['activity'] != null) temp.activity = _sessionMemory['activity'];

      _parseTranscriptInto(temp, _partialAnswer);
      return temp;
    }
    return _data;
  }

  void _parseTranscriptInto(_ExtractedData data, String text) {
    final t = text.toLowerCase().trim();

    // ── Auto-detect entry type from conversation ──────────────────────────────
    if (_entryType == 'material') {
      const labourKeywords = [
        'mason', 'masons', 'worker', 'workers', 'carpenter', 'carpenters',
        'plumber', 'plumbers', 'electrician', 'electricians', 'helper',
        'helpers', 'labour', 'labourer', 'labourers', 'welder', 'welders',
        'painter', 'painters', 'foreman', 'engineer', 'engineers',
        'supervisor', 'supervisors', 'driver', 'drivers',
      ];
      const equipmentKeywords = [
        'jcb', 'excavator', 'crane', 'concrete mixer', 'generator',
        'road roller', 'roller', 'dumper', 'dumptruck', 'bulldozer',
        'forklift', 'tractor', 'compressor', 'drill', 'water pump',
        'hoist', 'lift', 'vibrator',
      ];
      for (final kw in labourKeywords) {
        if (t.contains(kw)) {
          _entryType = 'labour';
          break;
        }
      }
      if (_entryType == 'material') {
        for (final kw in equipmentKeywords) {
          if (t.contains(kw)) {
            _entryType = 'equipment';
            break;
          }
        }
      }
    }

    // ── Quantity ─────────────────────────────────────────────────────────────
    final numMatch = RegExp(r'(\d+\.?\d*)').firstMatch(t);
    if (numMatch != null) {
      data.quantity = double.tryParse(numMatch.group(0) ?? '');
    }

    // ── Unit ─────────────────────────────────────────────────────────────────
    const unitMap = {
      'bag': 'Bags', 'bags': 'Bags',
      'kg': 'Kg', 'kilo': 'Kg', 'kilos': 'Kg',
      'ton': 'Tons', 'tons': 'Tons',
      'cft': 'CFT', 'cubic feet': 'CFT',
      'sqft': 'Sqft', 'square feet': 'Sqft',
      'nos': 'Nos', 'number': 'Nos', 'piece': 'Nos', 'pieces': 'Nos',
      'ltr': 'Ltrs', 'litre': 'Ltrs', 'litres': 'Ltrs', 'liter': 'Ltrs',
      'cum': 'Cum', 'cubic meter': 'Cum', 'cubic metres': 'Cum',
      'hour': 'Hours', 'hours': 'Hours', 'hr': 'Hours', 'hrs': 'Hours',
      'day': 'Days', 'days': 'Days',
      'rft': 'Rft', 'running feet': 'Rft',
      'trip': 'Trips', 'trips': 'Trips',
    };
    for (final entry in unitMap.entries) {
      if (t.contains(entry.key)) {
        data.unit = entry.value;
        break;
      }
    }

    // ── Rate ─────────────────────────────────────────────────────────────────
    final rateMatch =
        RegExp(r'(?:rate|at|per unit|@)\s*(?:rs\.?|rupees?|₹)?\s*(\d+\.?\d*)')
            .firstMatch(t);
    if (rateMatch != null) {
      data.rate = double.tryParse(rateMatch.group(1) ?? '');
    } else {
      final priceMatch = RegExp(r'(?:₹|rs\.?|rupees?)\s*(\d+\.?\d*)').firstMatch(t);
      if (priceMatch != null) {
        data.rate = double.tryParse(priceMatch.group(1) ?? '');
      }
    }

    // ── Brand ─────────────────────────────────────────────────────────────────
    const brands = [
      'ultratech', 'ambuja', 'acc', 'india cement', 'tata',
      'jk cement', 'dalmia', 'ramco', 'jsw', 'steel authority',
      'birla', 'shree', 'jcb', 'caterpillar', 'l&t', 'volvo',
      'mahindra', 'atlas copco', 'komatsu',
    ];
    for (final b in brands) {
      if (t.contains(b)) {
        data.brand = b
            .split(' ')
            .map((w) => w.isNotEmpty
                ? w[0].toUpperCase() + w.substring(1)
                : w)
            .join(' ');
        break;
      }
    }

    // ── Material name ─────────────────────────────────────────────────────────
    if (_entryType == 'material') {
      const materials = {
        'cement': 'Cement', 'concrete': 'Ready-Mix Concrete',
        'steel': 'Steel', 'rod': 'Steel Rod', 'rebar': 'Steel Rebar',
        'brick': 'Brick', 'sand': 'Sand', 'aggregate': 'Aggregate',
        'gravel': 'Gravel', 'tile': 'Tiles', 'paint': 'Paint',
        'pipe': 'PVC Pipe', 'wire': 'Wire', 'plywood': 'Plywood',
        'timber': 'Timber', 'wood': 'Wood', 'glass': 'Glass',
        'marble': 'Marble', 'granite': 'Granite', 'block': 'Block',
        'drywall': 'Drywall', 'plaster': 'Plaster',
      };
      for (final entry in materials.entries) {
        if (t.contains(entry.key)) {
          data.itemName = data.brand != null
              ? '${data.brand} ${entry.value}'
              : entry.value;
          break;
        }
      }
    }

    // ── Labour details ───────────────────────────────────────────────────────
    if (_entryType == 'labour') {
      const trades = {
        'masonry': 'Masonry', 'mason': 'Masonry',
        'plumbing': 'Plumbing', 'plumber': 'Plumbing',
        'electrical': 'Electrical', 'electrician': 'Electrical',
        'carpentry': 'Carpentry', 'carpenter': 'Carpentry',
        'welding': 'Welding', 'welder': 'Welding',
        'painting': 'Painting', 'painter': 'Painting',
        'helper': 'Helper', 'labourer': 'General Labour',
        'driver': 'Driver', 'supervisor': 'Supervisor',
        'foreman': 'Foreman', 'engineer': 'Engineer',
      };
      for (final entry in trades.entries) {
        if (t.contains(entry.key)) {
          data.workType = entry.value;
          break;
        }
      }

      final workerMatch = RegExp(r'(\d+)\s*(?:mason|worker|carpenter|plumber|electrician|helper|labor|labour|painter|welder|man|men)s?').firstMatch(t);
      if (workerMatch != null) {
        data.workerCount = int.tryParse(workerMatch.group(1) ?? '');
      }

      final hoursMatch = RegExp(r'(\d+\.?\d*)\s*(?:hour|hr)s?').firstMatch(t);
      if (hoursMatch != null) {
        data.hours = double.tryParse(hoursMatch.group(1) ?? '');
        data.unit = 'Hours';
      }

      final nameMatch = RegExp(r'\b([A-Z][a-z]+ [A-Z][a-z]+)\b').firstMatch(text);
      if (nameMatch != null) {
        data.itemName = nameMatch.group(0);
      } else if (data.workerCount != null && data.workType != null) {
        data.itemName = '${data.workerCount} ${data.workType}s';
      } else if (data.workType != null) {
        data.itemName = '${data.workType} Team';
      } else if (data.workerCount != null) {
        data.itemName = '${data.workerCount} Workers';
      }
    }

    // ── Equipment details ────────────────────────────────────────────────────
    if (_entryType == 'equipment') {
      const equipment = {
        'jcb': 'JCB Excavator', 'excavator': 'Excavator',
        'crane': 'Crane', 'mixer': 'Concrete Mixer',
        'generator': 'Generator', 'roller': 'Road Roller',
        'dumper': 'Dumper', 'truck': 'Truck',
        'bulldozer': 'Bulldozer', 'forklift': 'Forklift',
        'tractor': 'Tractor', 'compressor': 'Compressor',
        'drill': 'Drill Machine', 'pump': 'Water Pump',
        'lift': 'Hoist / Lift', 'vibrator': 'Vibrator',
      };
      for (final entry in equipment.entries) {
        if (t.contains(entry.key)) {
          data.itemName = entry.value;
          break;
        }
      }

      final hoursMatch = RegExp(r'(\d+\.?\d*)\s*(?:hour|hr)s?').firstMatch(t);
      if (hoursMatch != null) {
        data.quantity = double.tryParse(hoursMatch.group(1) ?? '');
        data.unit = 'Hours';
      }

      final fuelMatch = RegExp(r'(?:fuel|diesel)\s*(?:of|cost|rate|is)?\s*(?:rs\.?|rupees?|₹)?\s*(\d+\.?\d*)').firstMatch(t);
      if (fuelMatch != null) {
        data.fuelCost = double.tryParse(fuelMatch.group(1) ?? '');
      } else {
        final fuelMatch2 = RegExp(r'(?:rs\.?|rupees?|₹)?\s*(\d+\.?\d*)\s*(?:for)?\s*(?:fuel|diesel)').firstMatch(t);
        if (fuelMatch2 != null) {
          data.fuelCost = double.tryParse(fuelMatch2.group(1) ?? '');
        }
      }
    }

    // ── Floor ─────────────────────────────────────────────────────────────────
    if (t.contains('basement')) {
      data.floor = 'Basement';
    } else if (t.contains('ground floor') || t.contains('g floor')) {
      data.floor = 'Ground Floor';
    } else if (t.contains('1st') || t.contains('first floor')) {
      data.floor = '1st Floor';
    } else if (t.contains('2nd') || t.contains('second floor')) {
      data.floor = '2nd Floor';
    } else if (t.contains('3rd') || t.contains('third floor')) {
      data.floor = '3rd Floor';
    } else if (t.contains('terrace') || t.contains('roof')) {
      data.floor = 'Terrace';
    }

    // ── Phase / Activity ──────────────────────────────────────────────────────
    const phaseKeywords = [
      'foundation', 'structural', 'plumbing', 'electrical',
      'finishing', 'roofing', 'excavation', 'superstructure',
      
    ];
    for (final p in phaseKeywords) {
      if (t.contains(p)) {
        data.phase = '${p[0].toUpperCase()}${p.substring(1)} Work';
        break;
      }
    }

    const activityKeywords = {
      'column casting': 'Column Casting',
      'beam casting': 'Beam Casting',
      'slab': 'Slab Work',
      'pcc': 'PCC',
      'footing': 'Footing Work',
      'block work': 'Block Work',
      'brick laying': 'Brick Laying',
      'plastering': 'Plastering',
      'tile': 'Tiling',
      'plumbing': 'Plumbing',
      'wiring': 'Wiring',
      'painting': 'Painting',
      'excavation': 'Excavation',
      'backfilling': 'Backfilling',
    };
    for (final entry in activityKeywords.entries) {
      if (t.contains(entry.key)) {
        data.activity = entry.value;
        break;
      }
    }

    // ── Project matching ──────────────────────────────────────────────────────
    if (!data.hasProject) {
      for (final proj in _projects) {
        if (t.contains(proj.name.toLowerCase())) {
          data.projectId = proj.id;
          data.projectName = proj.name;
          break;
        }
      }
    }
  }

  // ─── Conversation field navigation ─────────────────────────────────────────────
  // BUG 1 & 5 FIX: Always re-derive from fresh missing fields — never from stale _step
  void _advanceToNextMissingField() {
    // Step 1: Re-parse full transcript to catch any newly detected fields
    if (_rawTranscript.isNotEmpty) {
      _parseTranscriptInto(_data, _rawTranscript);
    }

    // Step 2: Get fresh missing fields (single source of truth)
    final missing = _getStillNeededFieldsFor(_data);
    debugPrint('[AI DEBUG] _advanceToNextMissingField: transcript="$_rawTranscript"');
    debugPrint('[AI DEBUG] _advanceToNextMissingField: detectedFields=$_detectedFields');
    debugPrint('[AI DEBUG] _advanceToNextMissingField: missingFields=$missing');

    if (missing.isEmpty) {
      debugPrint('[AI DEBUG] All fields collected → going to summary');
      _goToSummary();
      return;
    }

    // Step 3: Convert first missing label → correct _ConvStep
    final nextStep = _nextMissingFieldStep();
    debugPrint('[AI DEBUG] _advanceToNextMissingField: nextStep=$nextStep, question=${_questionFor(nextStep)}');

    setState(() {
      _step = nextStep;
      _status = VoiceStatus.waitingForUser;
      _rebuildResponse();
    });
    _scrollToBottom();

    // Step 4: Auto-start listening for the next answer
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _status == VoiceStatus.waitingForUser) {
        _startAnswerListening();
      }
    });
  }

  // ─── Rebuild _response model from internal state ──────────────────────────────
  // BUG 4 FIX: Single source of truth — _getStillNeededFieldsFor() drives everything.
  // _response.missingFields and the "Still Needed" panel always match.
  void _rebuildResponse() {
    // Always derive missing from the single authoritative function
    final missing = _getStillNeededFieldsFor(_data);

    // Total = all fields for this entry type (from _getStillNeededFieldsFor when nothing detected)
    final allFields = _getAllFieldsFor();
    final total = allFields.length;
    final completed = total - missing.length;

    // BUG 1 & 5 FIX: Question derived from FIRST missing field — never from stale _step
    String? question;
    List<String> suggestions = [];
    if (_status == VoiceStatus.waitingForUser && missing.isNotEmpty) {
      final nextStep = _nextMissingFieldStep();
      question = _questionFor(nextStep);
      if (question.isEmpty) {
        question = 'Please provide the ${missing.first}.';
      }
      suggestions = _suggestionsForStep(nextStep);
      debugPrint('[AI DEBUG] _rebuildResponse: question="$question" for step=$nextStep');
    }

    _backendQuestion = question ?? '';
    _backendSuggestions = suggestions;

    debugPrint('[AI DEBUG] _rebuildResponse: status=$_status, detected=$_detectedFields, missing=$missing');

    _response = VoiceResponseModel(
      status: _status,
      entryType: _entryType,
      transcript: _rawTranscript.isNotEmpty ? _rawTranscript : null,
      partialTranscript: _partialAnswer.isNotEmpty ? _partialAnswer : null,
      detectedFields: Map.from(_detectedFields),
      missingFields: missing,
      question: question ?? _backendQuestion,
      suggestions: _backendSuggestions,
      completedFields: completed,
      totalFields: total,
      errorMessage: _saveError,
    );
  }

  // Returns the full list of field labels for this entry type (used for total count)
  List<String> _getAllFieldsFor() {
    final list = <String>['Project'];
    if (_entryType == 'labour') {
      list.addAll(['Labour Type', 'Worker Count', 'Hours']);
    } else if (_entryType == 'equipment') {
      list.addAll(['Equipment', 'Hours', 'Fuel']);
    } else {
      list.addAll(['Material', 'Quantity', 'Unit']);
    }
    list.addAll(['Floor', 'Activity', 'Rate']);
    if (_entryType == 'material') list.add('Phase');
    return list;
  }

  // ignore: unused_element
  static String _fieldLabelToDetectedKey(String label) {
    switch (label) {
      case 'Project': return 'Project ID';
      case 'Project Name': return 'Project Name';
      case 'Floor': return 'Floor';
      case 'Phase': return 'Phase';
      case 'Activity': return 'Activity';
      case 'Labour Type': return 'Work Type';
      case 'Worker Count': return 'Worker Count';
      case 'Hours': return 'Hours';
      case 'Equipment Type': return 'Item Name';
      case 'Fuel Cost': return 'Fuel Cost';
      case 'Quantity': return 'Quantity';
      case 'Unit': return 'Unit';
      case 'Rate': return 'Rate';
      case 'Brand': return 'Brand';
      default: return label;
    }
  }

  // ignore: unused_element
  bool _isStepMissing(_ConvStep step) {
    switch (step) {
      case _ConvStep.askProject:
        return !_data.hasProject;
      case _ConvStep.askFloor:
        return !_data.hasFloor;
      case _ConvStep.askPhase:
        if (_entryType != 'material') return false;
        return !_data.hasPhase;
      case _ConvStep.askActivity:
        return !_data.hasActivity;
      case _ConvStep.askLabourType:
        if (_entryType != 'labour') return false;
        return !_data.hasItemName;
      case _ConvStep.askWorkerCount:
        if (_entryType != 'labour') return false;
        return !_data.hasWorkerCount;
      case _ConvStep.askHours:
        if (_entryType == 'material') return false;
        if (_entryType == 'labour') return !_data.hasHours;
        return !_data.hasQuantity;
      case _ConvStep.askEquipment:
        if (_entryType != 'equipment') return false;
        return !_data.hasItemName;
      case _ConvStep.askFuel:
        if (_entryType != 'equipment') return false;
        return !_data.hasFuelCost;
      case _ConvStep.askQuantity:
        if (_entryType != 'material') return false;
        return !_data.hasQuantity;
      case _ConvStep.askUnit:
        if (_entryType != 'material') return false;
        return !_data.hasUnit;
      case _ConvStep.askRate:
        return !_data.hasRate;
      case _ConvStep.askBrand:
        if (_entryType != 'material') return false;
        return !_data.hasBrand;
      default:
        return false;
    }
  }

  String _questionFor(_ConvStep step) {
    switch (step) {
      case _ConvStep.askProject:
        return 'Which project is this for?';
      case _ConvStep.askFloor:
        return 'Which floor or zone is this work happening on?';
      case _ConvStep.askPhase:
        return 'Under which phase of the project is this scheduled?';
      case _ConvStep.askActivity:
        return 'And what\'s the specific activity we are working on?';
      case _ConvStep.askLabourType:
        return 'What is the trade or labor category? (e.g. Mason, Plumber, Helper)';
      case _ConvStep.askWorkerCount:
        return 'How many workers were in this team?';
      case _ConvStep.askHours:
        return _entryType == 'labour'
            ? 'How many hours did they work today?'
            : 'How many hours was the machine operated?';
      case _ConvStep.askEquipment:
        return 'Which equipment or machinery was used? (e.g. JCB, Crane)';
      case _ConvStep.askFuel:
        return 'What was the fuel or diesel cost for this operation? (Enter 0 if none)';
      case _ConvStep.askQuantity:
        return 'What\'s the total quantity we should enter?';
      case _ConvStep.askUnit:
        return 'What unit of measurement are we tracking this in? (e.g. Bags, Kg, Tons)';
      case _ConvStep.askRate:
        final unitLabel = _data.unit ?? (_entryType == 'material' ? 'unit' : 'hour');
        return 'Got that. What purchase rate per $unitLabel should I log in ₹?';
      case _ConvStep.askBrand:
        return 'What brand is it? (e.g. UltraTech, Ambuja)';
      default:
        return '';
    }
  }

  // BUG 5 FIX: Renamed and made explicit — takes the step parameter directly
  List<String> _suggestionsForStep(_ConvStep step) {
    switch (step) {
      case _ConvStep.askProject:
        return _projects.take(5).map((p) => p.name).toList();
      case _ConvStep.askFloor:
        return ['Ground Floor', '1st Floor', '2nd Floor', '3rd Floor', 'Basement', 'Terrace'];
      case _ConvStep.askPhase:
        return ['Foundation Work', 'Structural Work', 'Finishing', 'Roofing', 'Plumbing Work', 'Electrical Work'];
      case _ConvStep.askActivity:
        return ['Column Casting', 'Slab Work', 'PCC', 'Brick Laying', 'Plastering', 'Excavation'];
      case _ConvStep.askUnit:
        return ['Bags', 'Kg', 'Tons', 'Sqft', 'Nos', 'Ltrs', 'Hours'];
      case _ConvStep.askBrand:
        return ['UltraTech', 'Ambuja', 'ACC', 'JK Cement', 'Tata', 'JSW'];
      case _ConvStep.askLabourType:
        return ['Mason', 'Helper', 'Carpenter', 'Plumber', 'Electrician', 'Painter'];
      case _ConvStep.askWorkerCount:
        return ['2', '4', '6', '8', '10', '12'];
      case _ConvStep.askHours:
        return ['4', '6', '8', '10', '12'];
      case _ConvStep.askEquipment:
        return ['JCB Excavator', 'Crane', 'Concrete Mixer', 'Dumper', 'Generator', 'Road Roller'];
      default:
        return [];
    }
  }

  // ignore: unused_element
  List<String> _suggestionsForCurrentStep() => _suggestionsForStep(_step);

  // ─── Answer voice listener ────────────────────────────────────────────────────
  Future<void> _startAnswerListening() async {
    _isListeningForAnswer = true;
    await _voiceCtrl.startListening();
    if (mounted) setState(() {});
    debugPrint('[AI DEBUG] _startAnswerListening: started, step=$_step');
  }

  // BUG 2 FIX: "Done Answering" — fully stops listening and refreshes all state
  Future<void> _stopAnswerListening() async {
    debugPrint('[AI DEBUG] _stopAnswerListening tapped');

    // 1. Stop the microphone
    await _voiceCtrl.stopListening();

    if (!mounted) return;

    // 2. Grab whatever partial transcript we have (if any)
    final partial = _voiceCtrl.partialTranscript.trim().isNotEmpty
        ? _voiceCtrl.partialTranscript.trim()
        : _voiceCtrl.finalTranscript.trim();

    // 3. If there's something useful, apply it as the answer
    if (partial.isNotEmpty && _isListeningForAnswer) {
      debugPrint('[AI DEBUG] _stopAnswerListening: applying partial answer "$partial"');
      _isListeningForAnswer = false;
      _applyAnswer(_step, partial);
      // Re-extract from full accumulated transcript too
      _parseTranscriptInto(_data, _rawTranscript);
    } else {
      _isListeningForAnswer = false;
    }

    // 4. Recalculate everything and refresh UI — BUG 2, 4, 6 fix
    setState(() {
      _partialAnswer = '';
      // Recompute extracted fields from full transcript
      if (_rawTranscript.isNotEmpty) {
        _parseTranscriptInto(_data, _rawTranscript);
      }
      _rebuildResponse();
    });

    debugPrint('[AI DEBUG] _stopAnswerListening done: detectedFields=$_detectedFields, missing=${_getStillNeededFieldsFor(_data)}');

    // 5. Advance conversation to next missing field
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _advanceToNextMissingField();
    });
  }

  void _handleVoiceAnswer(String text) {
    debugPrint('[AI DEBUG] _handleVoiceAnswer: "$text", step=$_step');
    _applyAnswer(_step, text);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _advanceToNextMissingField();
    });
  }

  void _handleTypedAnswer(String text) {
    if (text.trim().isEmpty) return;
    _textCtrl.clear();
    _applyAnswer(_step, text.trim());
    _focusNode.unfocus();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _advanceToNextMissingField();
    });
  }

  void _applyAnswer(_ConvStep step, String text) {
    final t = text.toLowerCase().trim();
    setState(() {
      switch (step) {
        case _ConvStep.askProject:
          final match = _projects.cast<ProjectModel?>().firstWhere(
                (p) =>
                    p!.name.toLowerCase().contains(t) ||
                    t.contains(p.name.toLowerCase()),
                orElse: () => null,
              );
          if (match != null) {
            _data.projectId = match.id;
            _data.projectName = match.name;
          } else {
            _data.projectName = text.trim();
          }
          break;

        case _ConvStep.askFloor:
          if (t.contains('ground') || t == 'g') {
            _data.floor = 'Ground Floor';
          } else if (t.contains('basement') || t == 'b') {
            _data.floor = 'Basement';
          } else if (t.contains('1') || t.contains('first') || t == '1st') {
            _data.floor = '1st Floor';
          } else if (t.contains('2') || t.contains('second') || t == '2nd') {
            _data.floor = '2nd Floor';
          } else if (t.contains('3') || t.contains('third') || t == '3rd') {
            _data.floor = '3rd Floor';
          } else if (t.contains('terrace') || t.contains('roof')) {
            _data.floor = 'Terrace';
          } else {
            _data.floor = text.trim();
          }
          break;

        case _ConvStep.askPhase:
          _data.phase = text.trim();
          break;

        case _ConvStep.askActivity:
          _data.activity = text.trim();
          break;

        case _ConvStep.askLabourType:
          _data.workType = text.trim();
          if (_data.workerCount != null) {
            _data.itemName = '${_data.workerCount} ${_data.workType}s';
          } else {
            _data.itemName = '${_data.workType} Team';
          }
          break;

        case _ConvStep.askWorkerCount:
          final num = RegExp(r'(\d+)').firstMatch(t);
          if (num != null) {
            _data.workerCount = int.tryParse(num.group(1) ?? '');
          }
          if (_data.workType != null && _data.workerCount != null) {
            _data.itemName = '${_data.workerCount} ${_data.workType}s';
          }
          break;

        case _ConvStep.askHours:
          final num = RegExp(r'(\d+\.?\d*)').firstMatch(t);
          if (num != null) {
            final val = double.tryParse(num.group(1) ?? '');
            if (_entryType == 'labour') {
              _data.hours = val;
            } else {
              _data.quantity = val;
            }
          }
          break;

        case _ConvStep.askEquipment:
          _data.itemName = text.trim();
          break;

        case _ConvStep.askFuel:
          if (t.contains('no') || t.contains('none') || t.contains('zero') || t == '0') {
            _data.fuelCost = 0;
          } else {
            final num = RegExp(r'(\d+\.?\d*)').firstMatch(t);
            if (num != null) {
              _data.fuelCost = double.tryParse(num.group(1) ?? '');
            }
          }
          break;

        case _ConvStep.askQuantity:
          final num = RegExp(r'(\d+\.?\d*)').firstMatch(t);
          if (num != null) {
            _data.quantity = double.tryParse(num.group(0) ?? '');
          }
          break;

        case _ConvStep.askUnit:
          const unitMap = {
            'bag': 'Bags', 'bags': 'Bags',
            'kg': 'Kg', 'kilo': 'Kg',
            'ton': 'Tons', 'tons': 'Tons',
            'sqft': 'Sqft', 'square feet': 'Sqft',
            'hour': 'Hours', 'hours': 'Hours', 'hr': 'Hours', 'hrs': 'Hours',
            'day': 'Days', 'days': 'Days',
            'nos': 'Nos', 'piece': 'Nos', 'pieces': 'Nos',
            'ltr': 'Ltrs', 'litres': 'Ltrs', 'liters': 'Ltrs',
            'cum': 'Cum', 'cubic': 'Cum',
          };
          bool found = false;
          for (final entry in unitMap.entries) {
            if (t.contains(entry.key)) {
              _data.unit = entry.value;
              found = true;
              break;
            }
          }
          if (!found) _data.unit = text.trim();
          break;

        case _ConvStep.askRate:
          final rateNum = RegExp(r'(\d+\.?\d*)').firstMatch(t);
          if (rateNum != null) {
            _data.rate = double.tryParse(rateNum.group(0) ?? '');
          }
          break;

        case _ConvStep.askBrand:
          _data.brand = text.trim();
          break;

        default:
          break;
      }
      // BUG 6 FIX: Always re-parse the full transcript after any answer to catch fields
      if (_rawTranscript.isNotEmpty) {
        _parseTranscriptInto(_data, _rawTranscript);
      }
      _rebuildResponse();
      debugPrint('[AI DEBUG] _applyAnswer done: detectedFields=$_detectedFields, missing=${_getStillNeededFieldsFor(_data)}');
    });
  }

  // ─── Go to summary ────────────────────────────────────────────────────────────
  void _goToSummary() {
    setState(() {
      _status = VoiceStatus.summary;
      _rebuildResponse();
    });
    _scrollToBottom();
  }

  // ─── Database helpers ─────────────────────────────────────────────────────────
  String? _derivePhaseId(String? phaseName) {
    if (phaseName == null || phaseName.isEmpty || _data.projectId == null) return null;
    final project = _projects.cast<ProjectModel?>().firstWhere(
      (p) => p?.id == _data.projectId,
      orElse: () => null,
    );
    if (project?.selectedPhases == null) return null;
    for (final p in project!.selectedPhases!) {
      if (p.phaseName == phaseName) return p.id;
    }
    return null;
  }

  String? _deriveActivityId(String? activityName) {
    if (activityName == null || activityName.isEmpty || _data.projectId == null) return null;
    final project = _projects.cast<ProjectModel?>().firstWhere(
      (p) => p?.id == _data.projectId,
      orElse: () => null,
    );
    if (project?.selectedPhases == null) return null;
    for (final phase in project!.selectedPhases!) {
      for (final act in phase.activities) {
        if (act.name == activityName) return act.id;
      }
    }
    return null;
  }

  // ─── Save entry ───────────────────────────────────────────────────────────────
  Future<void> _saveEntry() async {
    setState(() {
      _status = VoiceStatus.saving;
      _saveError = null;
      _rebuildResponse();
    });

    try {
      final String txType = _entryType == 'labour'
          ? 'Wages'
          : _entryType == 'equipment'
              ? 'Expense'
              : 'Materials';

      final double qty = _entryType == 'labour'
          ? ((_data.workerCount ?? 1) * (_data.hours ?? 1)).toDouble()
          : (_data.quantity ?? 0);
      final double rate = _data.rate ?? 0;
      final double fuel = _data.fuelCost ?? 0;
      final double totalAmount = (qty * rate) + fuel;

      final payload = <String, dynamic>{
        'title': _data.itemName ??
            (_entryType == 'labour'
                ? 'Labour Log'
                : _entryType == 'equipment'
                    ? 'Equipment Rental'
                    : 'Material Delivery'),
        'type': txType,
        'project': _data.projectId ?? '',
        'floor': _data.floor ?? '',
        'phase': _data.phase ?? '',
        'phaseId': _derivePhaseId(_data.phase),
        'activity': _data.activity ?? '',
        'activityId': _deriveActivityId(_data.activity),
        'category': _entryType == 'labour'
            ? (_data.workType ?? 'General Labour')
            : _entryType == 'equipment'
                ? (_data.itemName ?? 'Equipment')
                : 'Materials',
        'unit': _data.unit ?? (_entryType == 'material' ? 'Bags' : 'hour'),
        'quantity': qty,
        'rate': rate,
        'amount': totalAmount,
        'paymentStatus': 'Pending',
        'paymentMode': 'Cash',
        'paidAmount': 0,
        'date': DateTime.now().toIso8601String(),
        if (_entryType == 'material' && _data.hasBrand) 'brand': _data.brand,
        if (_entryType == 'equipment' && _data.fuelCost != null) 'fuelCost': fuel,
      };

      final result = await ApiService.addTransaction(payload);

      if (result != null) {
        final serverTx = result['transaction'] ?? result;
        _savedEntryId = serverTx?['_id']?.toString() ??
            'VOICE-${DateTime.now().millisecondsSinceEpoch}';

        // Update session memory
        _sessionMemory['projectId'] = _data.projectId;
        _sessionMemory['projectName'] = _data.projectName;
        _sessionMemory['floor'] = _data.floor;
        _sessionMemory['phase'] = _data.phase;
        _sessionMemory['phaseId'] = _data.phaseId;
        _sessionMemory['activity'] = _data.activity;

        // Refresh project data
        if (mounted) {
          await Provider.of<ProjectProvider>(context, listen: false).load();
        }

        setState(() {
          _status = VoiceStatus.completed;
          _savedEntryId = serverTx?['_id']?.toString() ??
              'VOICE-${DateTime.now().millisecondsSinceEpoch}';
          _rebuildResponse();
        });
      } else {
        setState(() {
          _status = VoiceStatus.summary;
          _saveError = 'Failed to save. Please try again.';
          _rebuildResponse();
        });
      }
    } catch (e) {
      setState(() {
        _status = VoiceStatus.summary;
        _saveError = 'Error: ${e.toString()}';
        _rebuildResponse();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 250,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Field labels and required count helpers ─────────────────────────────────
  List<String> _getStillNeededFieldsFor(_ExtractedData d) {
    final list = <String>[];
    if (!d.hasProject) list.add('Project');
    if (_entryType == 'labour') {
      if (!d.hasItemName) list.add('Labour Type');
      if (!d.hasWorkerCount) list.add('Worker Count');
      if (!d.hasHours) list.add('Hours');
    }
    if (_entryType == 'equipment') {
      if (!d.hasItemName) list.add('Equipment');
      if (!d.hasQuantity) list.add('Hours');
    }
    if (!d.hasFloor) list.add('Floor');
    if (_entryType == 'material') {
      if (!d.hasPhase) list.add('Phase');
    }
    if (!d.hasActivity) list.add('Activity');
    if (_entryType == 'material') {
      if (!d.hasQuantity) list.add('Quantity');
      if (!d.hasUnit) list.add('Unit');
    }
    if (_entryType == 'equipment') {
      if (!d.hasFuelCost) list.add('Fuel');
    }
    if (!d.hasRate) list.add('Rate');
    return list;
  }

  List<_DetectedField> _getDetectedFieldsWithLabels(_ExtractedData d) {
    final list = <_DetectedField>[];
    if (d.hasProject) {
      list.add(_DetectedField(label: 'Project', value: d.projectName ?? d.projectId!));
    }
    if (_entryType == 'material') {
      if (d.hasItemName) list.add(_DetectedField(label: 'Material', value: d.itemName!));
      if (d.hasBrand) list.add(_DetectedField(label: 'Brand', value: d.brand!));
      if (d.hasQuantity) list.add(_DetectedField(label: 'Quantity', value: '${d.quantity}'));
      if (d.hasUnit) list.add(_DetectedField(label: 'Unit', value: d.unit!));
    } else if (_entryType == 'labour') {
      if (d.hasItemName) list.add(_DetectedField(label: 'Labour Type', value: d.workType ?? d.itemName!));
      if (d.hasWorkerCount) list.add(_DetectedField(label: 'Worker Count', value: '${d.workerCount}'));
      if (d.hasHours) list.add(_DetectedField(label: 'Hours', value: '${d.hours}'));
    } else {
      if (d.hasItemName) list.add(_DetectedField(label: 'Equipment', value: d.itemName!));
      if (d.hasQuantity) list.add(_DetectedField(label: 'Hours', value: '${d.quantity}'));
      if (d.hasFuelCost) list.add(_DetectedField(label: 'Fuel Cost', value: '₹ ${d.fuelCost!.toStringAsFixed(0)}'));
    }
    if (d.hasFloor) list.add(_DetectedField(label: 'Floor', value: d.floor!));
    if (d.hasPhase) list.add(_DetectedField(label: 'Phase', value: d.phase!));
    if (d.hasActivity) list.add(_DetectedField(label: 'Activity', value: d.activity!));
    if (d.hasRate) list.add(_DetectedField(label: 'Rate', value: '₹ ${d.rate!.toStringAsFixed(0)}'));
    return list;
  }

  int _getTotalFieldsCount() {
    if (_entryType == 'material') return 8;
    if (_entryType == 'labour') return 8;
    return 7;
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Stack(
                children: [
                  _buildMainBody(),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomInputArea(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    String title = 'BuildTrack AI';
    String subtitle = 'AI Voice Entry';

    switch (_response.status) {
      case VoiceStatus.listening:
      case VoiceStatus.idle:
        title = 'BuildTrack AI';
        final label = _entryType == 'material' ? 'Material' : _entryType == 'labour' ? 'Labour' : 'Equipment';
        subtitle = 'AI Voice Entry • $label';
        break;
      case VoiceStatus.processing:
      case VoiceStatus.thinking:
        title = 'AI is Thinking...';
        subtitle = 'Analyzing voice input';
        break;
      case VoiceStatus.extracting:
        title = 'Extracted Information';
        subtitle = 'Review details';
        break;
      case VoiceStatus.waitingForUser:
      case VoiceStatus.summary:
      case VoiceStatus.saving:
        title = 'AI Assistant';
        subtitle = 'Smart conversational flow';
        break;
      case VoiceStatus.completed:
        title = 'Success';
        subtitle = 'Entry saved';
        break;
      case VoiceStatus.error:
        title = 'Error';
        subtitle = 'Something went wrong';
        break;
    }

    final isListening = _voiceCtrl.engineState == VoiceEngineState.listening;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEBF8))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, size: 18, color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                    letterSpacing: 0.3,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isListening && _step == _ConvStep.initialVoice)
            _buildLiveChip(),
        ],
      ),
    );
  }

  Widget _buildLiveChip() {
    return AnimatedBuilder(
      animation: _micPulseCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1 + _micPulseCtrl.value * 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 4),
            const Text('LIVE',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  // ─── Main Body Selector ───────────────────────────────────────────────────────
  Widget _buildMainBody() {
    Widget content;
    final curData = _currentData;

    switch (_response.status) {
      case VoiceStatus.processing:
      case VoiceStatus.thinking:
        content = _buildProcessingCard();
        break;
      case VoiceStatus.completed:
        content = Column(
          children: [
            _buildSuccessCard(),
            if (_saveError != null) _buildErrorCard(),
          ],
        );
        break;
      case VoiceStatus.summary:
      case VoiceStatus.saving:
        content = _buildSummaryCard();
        break;
      default:
        final isInitial = _response.status == VoiceStatus.listening || _response.status == VoiceStatus.idle;
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAiStatusCard(),
            if (isInitial || _voiceCtrl.isListening) ...[
              _buildLiveTranscript(),
            ],
            _buildAiUnderstandingPanel(curData),
            _buildMissingInformationPanel(curData),
            _buildAiQuestionCard(),
          ],
        );
        break;
    }

    return SingleChildScrollView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      child: content,
    );
  }

  // ─── Section 1: AI Status Banner ─────────────────────────────────────────────
  Widget _buildAiStatusCard() {
    final isListening = _voiceCtrl.engineState == VoiceEngineState.listening;
    final isProcessing = _response.status == VoiceStatus.processing || _response.status == VoiceStatus.thinking;
    final isAsking = _response.status == VoiceStatus.waitingForUser;
    final isSummary = _response.status == VoiceStatus.summary || _response.status == VoiceStatus.saving;
    final typeLabel = _entryType == 'material'
        ? 'Material Entry'
        : _entryType == 'labour'
            ? 'Labour Entry'
            : 'Equipment Entry';

    Color dotColor;
    String stateLabel;
    Color stateLabelColor;

    if (isListening) {
      dotColor = const Color(0xFF22C55E);
      stateLabel = 'Listening';
      stateLabelColor = const Color(0xFF16A34A);
    } else if (isProcessing) {
      dotColor = AppColors.primaryPurple;
      stateLabel = 'Understanding';
      stateLabelColor = AppColors.primaryPurple;
    } else if (isAsking) {
      dotColor = AppColors.primary;
      stateLabel = 'AI is Asking';
      stateLabelColor = AppColors.primary;
    } else if (isSummary) {
      dotColor = const Color(0xFF22C55E);
      stateLabel = 'Ready to Save';
      stateLabelColor = const Color(0xFF16A34A);
    } else {
      dotColor = AppColors.textLight;
      stateLabel = 'Ready';
      stateLabelColor = AppColors.textLight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF173EEA).withValues(alpha: 0.06),
            const Color(0xFFB137FF).withValues(alpha: 0.04),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD8F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'BuildTrack AI',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isListening && !isProcessing && !isAsking && !isSummary) ...[
                    const SizedBox(height: 2),
                    Text(
                      _examplePhrase,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _micPulseCtrl,
              builder: (_, __) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: dotColor.withValues(
                      alpha: isListening ? 0.10 + _micPulseCtrl.value * 0.06 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: dotColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor.withValues(
                            alpha: isListening
                                ? 0.6 + _micPulseCtrl.value * 0.4
                                : 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        stateLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: stateLabelColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section 2 & 3: Live Transcript & Waveform Card ───────────────────────────
  Widget _buildLiveTranscript() {
    final isListening = _voiceCtrl.engineState == VoiceEngineState.listening;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD8F5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOU SAID',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
              if (isListening) _buildLiveTranscriptIndicator(),
            ],
          ),
          const SizedBox(height: 12),
          if (isListening && _partialAnswer.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: AnimatedBuilder(
                animation: _micPulseCtrl,
                builder: (_, __) {
                  final timer = _voiceCtrl.elapsedDisplay;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Listening',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timer,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary.withValues(alpha: 0.6),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 6),
                      ...List.generate(3, (i) {
                        final phase = ((_micPulseCtrl.value * 3) - i).clamp(0.0, 1.0);
                        return Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Opacity(
                            opacity: 0.3 + phase * 0.7,
                            child: const Text(
                              '.',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                height: 1.0,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            )
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _partialAnswer.isNotEmpty
                      ? _partialAnswer
                      : (_rawTranscript.isNotEmpty ? _rawTranscript : 'Speak naturally...'),
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: _partialAnswer.isEmpty && _rawTranscript.isEmpty
                        ? AppColors.textLight
                        : AppColors.textDark,
                    height: 1.4,
                  ),
                ),
                if (isListening && _partialAnswer.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  const _BlinkingCursor(),
                ],
              ],
            ),
          const SizedBox(height: 16),
          _buildLiveWaveform(),
        ],
      ),
    );
  }

  Widget _buildLiveTranscriptIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _micPulseCtrl,
          builder: (_, __) {
            return Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withValues(alpha: 0.4 + _micPulseCtrl.value * 0.6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    blurRadius: 5 * _micPulseCtrl.value,
                    spreadRadius: 1,
                  )
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 6),
        const Text(
          'LIVE TRANSCRIPT',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF22C55E),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveWaveform() {
    final isListening = _voiceCtrl.engineState == VoiceEngineState.listening;
    if (!isListening) return const SizedBox.shrink();

    final level = _voiceCtrl.soundLevel;
    final vol = ((level + 2.0) / 12.0).clamp(0.1, 1.0);

    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, __) {
        return SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(24, (i) {
              final phase = _waveCtrl.value * 2 * math.pi;
              final offset = i * (math.pi / 10);
              final baseHeight = 5.0 + (math.sin(phase + offset).abs() * 16.0);
              final randNoise = math.sin(phase * 4.0 + i).abs() * 5.0;
              final finalHeight = ((baseHeight + randNoise) * vol).clamp(4.0, 36.0);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.symmetric(horizontal: 2.2),
                width: 3.5,
                height: finalHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF173EEA), Color(0xFFB137FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ─── Section 4 & 6: AI Understanding Panel (Live Vertical List + Progress Bar) ──
  Widget _buildAiUnderstandingPanel(_ExtractedData currentData) {
    final detected = _getDetectedFieldsWithLabels(currentData);
    final count = _response.completedFields;
    final total = _response.totalFields > 0 ? _response.totalFields : _getTotalFieldsCount();
    final progress = total > 0 ? count / total : 0.0;
    final isComplete = count >= total;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEBF8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete ? 'AI Understanding' : 'AI Understanding Entry...',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isComplete ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isComplete ? 'Complete' : '$count / $total',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isComplete ? const Color(0xFF16A34A) : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFF0EDFF),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? const Color(0xFF22C55E) : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (detected.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Waiting for voice input...',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: detected
                  .map((field) => _buildDetectedFieldRow(field))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetectedFieldRow(_DetectedField field) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, val, child) {
        return Transform.translate(
          offset: Offset(-10 * (1 - val), 0),
          child: Opacity(opacity: val, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFDCFCE7),
              ),
              child: const Icon(Icons.check, size: 12, color: Color(0xFF16A34A)),
            ),
            const SizedBox(width: 10),
            Text(
              '${field.label}:',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                field.value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section 5 & 7: Still Needed Panel (Active-Step Aware) ──────────────────
  Widget _buildMissingInformationPanel(_ExtractedData currentData) {
    final needed = _getStillNeededFieldsFor(currentData);
    if (needed.isEmpty) return const SizedBox.shrink();

    // Map current step to the field name being collected
    String? activeField;
    switch (_step) {
      case _ConvStep.askProject: activeField = 'Project'; break;
      case _ConvStep.askFloor: activeField = 'Floor'; break;
      case _ConvStep.askPhase: activeField = 'Phase'; break;
      case _ConvStep.askActivity: activeField = 'Activity'; break;
      case _ConvStep.askQuantity: activeField = 'Quantity'; break;
      case _ConvStep.askUnit: activeField = 'Unit'; break;
      case _ConvStep.askRate: activeField = 'Rate'; break;
      case _ConvStep.askBrand: activeField = 'Brand'; break;
      case _ConvStep.askLabourType: activeField = 'Labour Type'; break;
      case _ConvStep.askWorkerCount: activeField = 'Worker Count'; break;
      case _ConvStep.askHours: activeField = 'Hours'; break;
      case _ConvStep.askEquipment: activeField = 'Equipment'; break;
      case _ConvStep.askFuel: activeField = 'Fuel'; break;
      default: activeField = null;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEBF8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Still Needed',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  '${needed.length} field${needed.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: needed.map((field) {
              final isActive = field == activeField;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : const Color(0xFFFEF3C7),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isActive ? AppColors.primary : const Color(0xFFD97706),
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      field,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.primary : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Section 8: AI Question Card (Premium Gradient Chat Bubble) ─────────────
  Widget _buildAiQuestionCard() {
    final isAskingStep = _response.status == VoiceStatus.waitingForUser;
    if (!isAskingStep) return const SizedBox.shrink();

    // BUG 1 FIX: Always derive question from fresh missing fields — never stale _step
    final nextStep = _nextMissingFieldStep();
    final question = _response.question?.isNotEmpty == true
        ? _response.question!
        : _questionFor(nextStep);
    final suggestions = _backendSuggestions.isNotEmpty
        ? _backendSuggestions
        : _suggestionsForStep(nextStep);
    debugPrint('[AI DEBUG] _buildAiQuestionCard: showing question="$question" for step=$nextStep');
    final confirmed = _getDetectedFieldsWithLabels(_data).take(3).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173EEA), Color(0xFF7B3FE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173EEA).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Text(
                  'BuildTrack AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // ── Confirmed context ──
          if (confirmed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    confirmed.length == 1 ? 'Great. I found:' : 'I have:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ...confirmed.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${f.label}: ${f.value}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          // ── Divider ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.15),
              height: 1,
            ),
          ),
          // ── Question ──
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, suggestions.isEmpty ? 16 : 0),
            child: Text(
              question,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          // ── Quick replies ──
          if (suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick answers:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSuggestionsChips(suggestions),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsChips(List<String> options) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((opt) => GestureDetector(
        onTap: () => _handleTypedAnswer(opt),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            opt,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      )).toList(),
    );
  }

  // ─── Section 10 & 11: AI Thinking State Card (Checklist checking off) ─────────
  Widget _buildProcessingCard() {
    final stages = <String>[];
    final states = <bool>[];

    final hasMaterial = _data.hasItemName;
    final hasBrand = _data.hasBrand;
    final hasQuantity = _data.hasQuantity;
    final hasProject = _data.hasProject;
    final hasFloor = _data.hasFloor;
    final hasPhase = _data.hasPhase;
    final hasActivity = _data.hasActivity;

    if (_entryType == 'material') {
      stages.add(hasMaterial ? 'Material identified' : 'Finding material');
      states.add(hasMaterial);
      stages.add(hasBrand ? 'Brand identified' : 'Finding brand');
      states.add(hasBrand);
      stages.add(hasQuantity ? 'Quantity detected' : 'Detecting quantity');
      states.add(hasQuantity);
    } else if (_entryType == 'labour') {
      stages.add(hasMaterial ? 'Labour type identified' : 'Finding labour type');
      states.add(hasMaterial);
      stages.add(_data.hasWorkerCount ? 'Worker count detected' : 'Extracting worker count');
      states.add(_data.hasWorkerCount);
      stages.add(_data.hasHours ? 'Hours detected' : 'Extracting hours');
      states.add(_data.hasHours);
    } else {
      stages.add(hasMaterial ? 'Equipment identified' : 'Finding equipment');
      states.add(hasMaterial);
      stages.add(hasQuantity ? 'Hours detected' : 'Extracting hours');
      states.add(hasQuantity);
    }

    stages.add(hasFloor ? 'Floor detected' : 'Resolving floor');
    states.add(hasFloor);
    stages.add(hasProject ? 'Project matched' : 'Matching project');
    states.add(hasProject);
    stages.add(hasPhase ? 'Phase matched' : 'Finding phase');
    states.add(hasPhase);
    stages.add(hasActivity ? 'Activity matched' : 'Finding activity');
    states.add(hasActivity);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEEBF8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0EDFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'BuildTrack AI',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _entryType.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analyzing Entry...',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEEBF8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Extracting details...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(stages.length, (i) {
                final label = stages[i];
                final isCompleted = i < _processingStage;
                final isCurrent = i == _processingStage;

                Widget indicator;
                Color textColor;
                FontWeight fontWeight;

                if (isCompleted) {
                  if (states[i]) {
                    indicator = const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18);
                    textColor = AppColors.textDark;
                    fontWeight = FontWeight.w600;
                  } else {
                    indicator = const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 18);
                    textColor = AppColors.textLight;
                    fontWeight = FontWeight.w500;
                  }
                } else if (isCurrent) {
                  indicator = const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                  textColor = AppColors.primary;
                  fontWeight = FontWeight.bold;
                } else {
                  indicator = Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.textLight.withValues(alpha: 0.5), width: 1.5),
                    ),
                  );
                  textColor = AppColors.textLight;
                  fontWeight = FontWeight.w500;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    children: [
                      SizedBox(width: 20, child: Center(child: indicator)),
                      const SizedBox(width: 12),
                      Text(
                        isCompleted
                            ? (states[i] ? label : 'Finding ${stages[i].split(" ").last}...')
                            : (isCurrent ? '$label...' : label),
                        style: TextStyle(
                          fontSize: 13.5,
                          color: textColor,
                          fontWeight: fontWeight,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F8FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEBE8FF)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: You can keep the app open. We\'ll notify you when ready.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Section 14: Final Entry Summary ──────────────────────────────────────────
  Widget _buildSummaryCard() {
    final isSaving = _response.status == VoiceStatus.saving;
    final amount = _data.getComputedAmount(_entryType);

    final details = <Map<String, String>>[
      {
        'label': 'Project',
        'value': _data.projectName ?? _data.projectId ?? '—',
      },
      {
        'label': 'Floor',
        'value': _data.floor ?? '—',
      },
      if (_entryType == 'material') {
        'label': 'Phase',
        'value': _data.phase ?? '—',
      },
      {
        'label': 'Activity',
        'value': _data.activity ?? '—',
      },
      if (_entryType == 'material') ...[
        {
          'label': 'Material',
          'value': _data.itemName ?? '—',
        },
        {
          'label': 'Quantity',
          'value': _data.hasQuantity ? '${_data.quantity} ${_data.unit ?? ''}' : '—',
        },
      ] else if (_entryType == 'labour') ...[
        {
          'label': 'Labour Type',
          'value': _data.workType ?? '—',
        },
        {
          'label': 'Worker Count',
          'value': _data.hasWorkerCount ? '${_data.workerCount}' : '—',
        },
        {
          'label': 'Hours',
          'value': _data.hasHours ? '${_data.hours} ${_data.unit ?? 'Hours'}' : '—',
        },
      ] else ...[
        {
          'label': 'Equipment',
          'value': _data.itemName ?? '—',
        },
        {
          'label': 'Hours',
          'value': _data.hasQuantity ? '${_data.quantity} ${_data.unit ?? 'Hours'}' : '—',
        },
      ],
      {
        'label': 'Rate',
        'value': _data.hasRate ? '₹ ${_data.rate!.toStringAsFixed(0)}' : '—',
      },
      if (_entryType == 'equipment' && _data.hasFuelCost) {
        'label': 'Fuel Cost',
        'value': '₹ ${_data.fuelCost!.toStringAsFixed(0)}',
      },
      {
        'label': 'Amount',
        'value': amount > 0 ? '₹ ${amount.toStringAsFixed(0)}' : '—',
        'highlight': 'true',
      },
      {
        'label': 'Confidence',
        'value': '98%',
      }
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD8F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF173EEA), Color(0xFF7B3FE4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'ENTRY SUMMARY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: Color(0xFF86EFAC), size: 12),
                          SizedBox(width: 4),
                          Text(
                            '98% Confidence',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF86EFAC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (amount > 0) ...[
                  const SizedBox(height: 14),
                  Text(
                    '\u20b9 ${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _data.itemName ??
                        (_entryType == 'labour'
                            ? 'Labour Log'
                            : _entryType == 'equipment'
                                ? 'Equipment Entry'
                                : 'Material Entry'),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEBF8)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: List.generate(details.length, (idx) {
                final item = details[idx];
                final isHighlight = item['highlight'] == 'true';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['label']!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['value']!,
                        style: TextStyle(
                          fontSize: isHighlight ? 18 : 14.5,
                          fontWeight: FontWeight.w700,
                          color: isHighlight
                              ? AppColors.primary
                              : item['label'] == 'Confidence'
                                  ? const Color(0xFF16A34A)
                                  : AppColors.textDark,
                        ),
                      ),
                      if (idx < details.length - 1) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFF7F5FC)),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            setState(() {
                              _step = _ConvStep.askProject;
                              _saveError = null;
                            });
                            _startAnswerListening();
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: Color(0xFFDDD8F5), width: 1.5),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Edit Details',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Confirm & Save',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dynamic Bottom Input Panel ───────────────────────────────────────────────
  Widget _buildBottomInputArea() {
    if (_response.status == VoiceStatus.completed) return const SizedBox.shrink();
    if (_response.status == VoiceStatus.summary || _response.status == VoiceStatus.saving) return const SizedBox.shrink();
    if (_response.status == VoiceStatus.processing || _response.status == VoiceStatus.thinking) return const SizedBox.shrink();

    final isListening = _voiceCtrl.engineState == VoiceEngineState.listening;
    final isProcessing = _voiceCtrl.engineState == VoiceEngineState.processing;
    final isInitialVoice = _response.status == VoiceStatus.listening || _response.status == VoiceStatus.idle;
    final isAskingStep = _response.status == VoiceStatus.waitingForUser;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: Color(0xFFEEEBF8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isListening && _partialAnswer.isNotEmpty && isInitialVoice)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    _partialAnswer,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (isProcessing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      const Text('Processing speech...', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ),
              if (isInitialVoice) ...[
                if (_showAnalyzingLabel) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Analyzing voice entry...',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ] else if (isListening) ...[
                  AnimatedBuilder(
                    animation: _waveCtrl,
                    builder: (_, __) {
                      final timer = _voiceCtrl.elapsedDisplay;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(5, (i) {
                            final h = 8.0 + math.sin(_waveCtrl.value * 2 * math.pi + i * math.pi / 3).abs() * 12.0;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2.2),
                              width: 3.5,
                              height: h,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                          const SizedBox(width: 10),
                          Text(
                            timer,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary.withValues(alpha: 0.6),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Listening',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _stopAndAnalyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Stop & Analyze', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ] else if (_rawTranscript.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _resetCurrentEntryData();
                            _startInitialRecording();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Re-record', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _beginAiProcessing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildBigMicButton(false),
                  const SizedBox(height: 10),
                  const Text(
                    'Speak naturally. I\'ll handle the rest.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ],
              if (isAskingStep) ...[
                if (isListening) ...[
                  _buildSmallMicListening(),
                  const SizedBox(height: 12),
                  // BUG 2 FIX: onPressed is verified connected to _stopAnswerListening
                  OutlinedButton.icon(
                    onPressed: () {
                      debugPrint('[AI DEBUG] Done Answering button tapped');
                      _stopAnswerListening();
                    },
                    icon: const Icon(Icons.stop_circle_outlined, size: 16),
                    label: const Text('Done Answering', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  if (_showKeyboardInput) ...[
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _showKeyboardInput = false),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDDD8F5)),
                            ),
                            child: TextField(
                              controller: _textCtrl,
                              focusNode: _focusNode,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: _hintForCurrentStep,
                                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              onSubmitted: _handleTypedAnswer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _handleTypedAnswer(_textCtrl.text),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF173EEA), Color(0xFFB137FF)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() => _showKeyboardInput = true);
                            _focusNode.requestFocus();
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDDD8F5)),
                            ),
                            child: const Icon(Icons.keyboard_outlined, color: AppColors.textDark, size: 20),
                          ),
                        ),
                        Expanded(
                          child: _buildMicWithWaves(),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section 9: Microphone Redesign (BuildTrack Gradient, pulsing, glow) ───────
  Widget _buildBigMicButton(bool isListening) {
    return Center(
      child: GestureDetector(
        onTap: isListening ? _stopInitialRecording : _startInitialRecording,
        child: AnimatedBuilder(
          animation: _micPulseCtrl,
          builder: (_, child) {
            final pulse = isListening ? _micPulseCtrl.value : 0.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96 + pulse * 20,
                  height: 96 + pulse * 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFB137FF).withValues(alpha: isListening ? 0.06 : 0.02),
                  ),
                ),
                Container(
                  width: 84 + pulse * 10,
                  height: 84 + pulse * 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF173EEA).withValues(alpha: isListening ? 0.10 : 0.04),
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF173EEA), Color(0xFFB137FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB137FF).withValues(alpha: 0.35),
                        blurRadius: 18 + pulse * 10,
                        spreadRadius: 2 + pulse * 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMicWithWaves() {
    final isListening = _voiceCtrl.engineState == VoiceEngineState.listening;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isListening) _buildWaveSide(isLeft: true) else const SizedBox(width: 50),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: isListening ? _stopAnswerListening : _startAnswerListening,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF173EEA), Color(0xFFB137FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB137FF).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(
              isListening ? Icons.stop : Icons.mic_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 14),
        if (isListening) _buildWaveSide(isLeft: false) else const SizedBox(width: 50),
      ],
    );
  }

  Widget _buildWaveSide({required bool isLeft}) {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final idx = isLeft ? i : 3 - i;
            final phase = _waveCtrl.value * 2 * math.pi;
            final h = 6.0 + math.sin(phase + idx * math.pi / 4).abs() * 16.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSmallMicListening() {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, __) {
        final timer = _voiceCtrl.elapsedDisplay;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            ...List.generate(5, (i) {
              final height = 8.0 + math.sin(_waveCtrl.value * 2 * math.pi + i * math.pi / 3).abs() * 12.0;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.2),
                width: 3.5,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            const SizedBox(width: 8),
            Text(
              timer,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary.withValues(alpha: 0.6),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Listening',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ],
        );
      },
    );
  }

  // ─── Success screen ──────────────────────────────────────────────────────────
  Widget _buildSuccessCard() {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')} ${_monthName(now.month)}'
        ' ${now.year}, '
        '${(now.hour % 12 == 0 ? 12 : now.hour % 12)}'
        ':${now.minute.toString().padLeft(2, '0')}'
        ' ${now.hour >= 12 ? 'PM' : 'AM'}';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCFCE7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
                  ),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 18),
              const Text(
                'Entry Saved Successfully!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your $_entryType entry has been saved and added to today\'s log.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    _successDetailRow(
                      'Entry ID',
                      '#${_savedEntryId?.substring(math.max(0, (_savedEntryId?.length ?? 4) - 8)) ?? 'NEW'}',
                    ),
                    const Divider(height: 12, color: Color(0xFFDCFCE7)),
                    _successDetailRow('Date & Time', dateStr),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/add-entry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Add Another Entry', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/logs'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('View All Entries', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_saveError ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }

  Widget _successDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ],
    );
  }

  String get _hintForCurrentStep {
    switch (_step) {
      case _ConvStep.askProject:
        return 'Type or say project name...';
      case _ConvStep.askFloor:
        return 'e.g. Ground Floor, 1st Floor...';
      case _ConvStep.askPhase:
        return 'e.g. Foundation Work...';
      case _ConvStep.askActivity:
        return 'e.g. Column Casting, PCC...';
      case _ConvStep.askLabourType:
        return 'e.g. Mason, Helper, Carpenter...';
      case _ConvStep.askWorkerCount:
        return 'e.g. 5, 8, 12...';
      case _ConvStep.askHours:
        return 'e.g. 6, 8, 10 hours...';
      case _ConvStep.askEquipment:
        return 'e.g. JCB Excavator, Crane...';
      case _ConvStep.askFuel:
        return 'e.g. 500, 1200 or 0 for none...';
      case _ConvStep.askQuantity:
        return 'Enter quantity...';
      case _ConvStep.askUnit:
        return 'e.g. Bags, Kg, Hours...';
      case _ConvStep.askRate:
        return 'Rate in ₹ per unit...';
      case _ConvStep.askBrand:
        return 'e.g. UltraTech, Tata...';
      default:
        return 'Type your answer...';
    }
  }

  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[(m - 1).clamp(0, 11)];
  }
}
