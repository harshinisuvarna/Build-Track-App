import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceEngineState { idle, listening, processing, parsed, error }

// ─── Controller ───────────────────────────────────────────────────────────────
class VoiceRecordingController extends ChangeNotifier {
  VoiceRecordingController({
    this.listenForSeconds = 45,
    this.pauseForSeconds  = 4,
  });

  // Configuration
  final int listenForSeconds;
  final int pauseForSeconds;

  // Internal STT engine
  final SpeechToText _stt = SpeechToText();
  bool _sttInitialised = false;
  bool _initialising   = false;

  // ── Exposed state ─────────────────────────────────────────────────────────
  VoiceEngineState get engineState => _engineState;
  VoiceEngineState _engineState = VoiceEngineState.idle;

  /// Live partial transcript shown during listening.
  String get partialTranscript => _partialTranscript;
  String _partialTranscript = '';

  /// Final confirmed transcript after session ends.
  String get finalTranscript => _finalTranscript;
  String _finalTranscript = '';

  /// Elapsed seconds since recording started.
  int get elapsedSeconds => _elapsedSeconds;
  int _elapsedSeconds = 0;

  /// Human-readable error message (non-empty only in error state).
  String get errorMessage => _errorMessage;
  String _errorMessage = '';

  /// True while the engine is actively in a listen session.
  bool get isListening => _engineState == VoiceEngineState.listening;

  // ── Internal ──────────────────────────────────────────────────────────────
  Timer? _sessionTimer;

  // ─── Init ──────────────────────────────────────────────────────────────────
  Future<bool> _ensureInitialised() async {
    if (_sttInitialised) return true;
    if (_initialising)   return false;
    _initialising = true;
    try {
      _sttInitialised = await _stt.initialize(
        onError:  _onSttError,
        onStatus: _onSttStatus,
        debugLogging: false,
      );
    } catch (_) {
      _sttInitialised = false;
    }
    _initialising = false;
    return _sttInitialised;
  }

  // ─── Start listening ───────────────────────────────────────────────────────
  Future<void> startListening() async {
    // Prevent duplicate sessions
    if (_engineState == VoiceEngineState.listening) return;

    _partialTranscript   = '';
    _finalTranscript     = '';
    _errorMessage        = '';
    _elapsedSeconds      = 0;
    _setEngineState(VoiceEngineState.listening);

    final ready = await _ensureInitialised();
    if (!ready) {
      _errorMessage = 'Microphone permission denied or not available.';
      _setEngineState(VoiceEngineState.error);
      return;
    }

    // Cancel any stale timers
    _sessionTimer?.cancel();

    // Start elapsed-time ticker
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _elapsedSeconds++;
      notifyListeners();
    });

    try {
      await _stt.listen(
        onResult: _onResult,
        listenFor: Duration(seconds: listenForSeconds),
        pauseFor:  Duration(seconds: pauseForSeconds),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
        localeId: 'en_IN',
      );
    } catch (e) {
      _errorMessage = 'Could not start microphone: $e';
      _sessionTimer?.cancel();
      _setEngineState(VoiceEngineState.error);
    }
  }

  // ─── Stop (manual) ────────────────────────────────────────────────────────
  Future<void> stopListening() async {
    if (_engineState != VoiceEngineState.listening) return;
    _sessionTimer?.cancel();
    await _stt.stop();
    // _onSttStatus('done') will fire and transition state
  }

  // ─── Cancel ───────────────────────────────────────────────────────────────
  Future<void> cancelListening() async {
    _sessionTimer?.cancel();
    await _stt.cancel();
    _partialTranscript = '';
    _finalTranscript   = '';
    _setEngineState(VoiceEngineState.idle);
  }

  // ─── Reset to idle (for re-record flow) ───────────────────────────────────
  void reset() {
    _sessionTimer?.cancel();
    _partialTranscript = '';
    _finalTranscript   = '';
    _errorMessage      = '';
    _elapsedSeconds    = 0;
    _setEngineState(VoiceEngineState.idle);
  }

  // ─── STT Callbacks ────────────────────────────────────────────────────────

  void _onResult(SpeechRecognitionResult result) {
    if (_engineState != VoiceEngineState.listening) return;

    if (result.finalResult) {
      _finalTranscript   = result.recognizedWords;
      _partialTranscript = result.recognizedWords;
    } else {
      _partialTranscript = result.recognizedWords;
    }
    notifyListeners();
  }

  void _onSttStatus(String status) {
    // Statuses: listening, notListening, done, error, cancelled
    if (status == 'done' || status == 'notListening') {
      _sessionTimer?.cancel();

      if (_engineState == VoiceEngineState.listening) {
        // Natural end or manual stop — move to processing
        _setEngineState(VoiceEngineState.processing);

        // Simulate brief processing delay then emit parsed
        Future.delayed(const Duration(milliseconds: 800), () {
          if (_engineState == VoiceEngineState.processing) {
            _setEngineState(VoiceEngineState.parsed);
          }
        });
      }
    }
  }

  void _onSttError(SpeechRecognitionError error) {
    _sessionTimer?.cancel();
    // Transient network/no-speech errors during active session
    if (error.errorMsg == 'error_no_match' ||
        error.errorMsg == 'error_speech_timeout') {
      // Treat as natural end of speech — still emit parsed if we have text
      if (_engineState == VoiceEngineState.listening) {
        _setEngineState(VoiceEngineState.processing);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (_engineState == VoiceEngineState.processing) {
            _setEngineState(VoiceEngineState.parsed);
          }
        });
      }
      return;
    }

    _errorMessage = _friendlyError(error.errorMsg);
    _setEngineState(VoiceEngineState.error);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _setEngineState(VoiceEngineState s) {
    if (_engineState == s) return;
    _engineState = s;
    notifyListeners();
  }

  String _friendlyError(String raw) {
    switch (raw) {
      case 'error_audio':
        return 'Audio recording failed. Check microphone permissions.';
      case 'error_insufficient_permissions':
        return 'Microphone permission denied.';
      case 'error_network':
        return 'Network error. Check your connection.';
      case 'error_recognizer_busy':
        return 'Microphone is busy. Please try again.';
      default:
        return 'Voice error: $raw';
    }
  }

  // ── Timer display helper ──────────────────────────────────────────────────
  String get elapsedDisplay {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds  % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _stt.cancel();
    super.dispose();
  }
}
