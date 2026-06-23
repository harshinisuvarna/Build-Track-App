// voice_recording_controller.dart
// Shared speech engine lifecycle for BuildTrack voice review screens.
// Wraps speech_to_text with a full state machine, live partial feedback,
// session timer, and clean dispose semantics.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

// ─── State machine enum ────────────────────────────────────────────────────────
enum VoiceEngineState { idle, listening, processing, parsed, error }

// ─── Controller ───────────────────────────────────────────────────────────────
class VoiceRecordingController extends ChangeNotifier {
  VoiceRecordingController({
    this.listenForSeconds = 45,
    this.pauseForSeconds  = 6,
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

  /// Live microphone sound level.
  double get soundLevel => _soundLevel;
  double _soundLevel = 0.0;

  // ── Internal ──────────────────────────────────────────────────────────────
  Timer? _sessionTimer;
  Timer? _forceParsedTimer;
  // Guard: prevents multiple competing code paths from all emitting 'parsed'.
  // Reset to false at the start of every new recording session.
  bool _parsedEmitted = false;

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
      if (_sttInitialised) {
        debugPrint('Speech Initialized');
      }
    } catch (_) {
      _sttInitialised = false;
    }
    _initialising = false;
    return _sttInitialised;
  }

  /// Pre-initialize the speech-to-text engine to minimize latency when recording starts.
  Future<bool> preInitialize() async {
    return _ensureInitialised();
  }

  void _onSoundLevel(double level) {
    _soundLevel = level;
    notifyListeners();
  }

  // ─── Start listening ───────────────────────────────────────────────────────
  Future<void> startListening() async {
    if (_engineState == VoiceEngineState.listening) return;

    _forceParsedTimer?.cancel();
    _parsedEmitted = false;  // reset guard for new session

    _partialTranscript   = '';
    _finalTranscript     = '';
    _errorMessage        = '';
    _elapsedSeconds      = 0;

    final ready = await _ensureInitialised();
    if (!ready) {
      _errorMessage = 'Microphone permission denied or not available.';
      _setEngineState(VoiceEngineState.error);
      return;
    }

    try {
      await _stt.cancel();
    } catch (_) {}

    _setEngineState(VoiceEngineState.listening);
    _sessionTimer?.cancel();

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _elapsedSeconds++;
      notifyListeners();
    });

    try {
      await _stt.listen(
        onResult: _onResult,
        listenFor: Duration(seconds: listenForSeconds),
        pauseFor:  Duration(seconds: pauseForSeconds),
        onSoundLevelChange: _onSoundLevel,
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
    // Force transition to processing immediately
    _setEngineState(VoiceEngineState.processing);
  }

  // ─── Cancel ───────────────────────────────────────────────────────────────
  Future<void> cancelListening() async {
    _forceParsedTimer?.cancel();
    _sessionTimer?.cancel();
    _parsedEmitted = false;
    await _stt.cancel();
    _partialTranscript = '';
    _finalTranscript   = '';
    _setEngineState(VoiceEngineState.idle);
  }

  // ─── Reset to idle (for re-record flow) ───────────────────────────────────
  void reset() {
    _forceParsedTimer?.cancel();
    _sessionTimer?.cancel();
    _parsedEmitted     = false;
    _partialTranscript = '';
    _finalTranscript   = '';
    _errorMessage      = '';
    _elapsedSeconds    = 0;
    _setEngineState(VoiceEngineState.idle);
  }

  // ─── Reset STT engine without changing state ─────────────────────────────
  // Calls stt.cancel() to properly reset the recognizer for the next listen()
  // without reverting the state machine. This avoids the stale recognizer bug
  // where notListening fires immediately after a new listen() call.
  Future<void> resetEngine() async {
    _forceParsedTimer?.cancel();
    _sessionTimer?.cancel();
    _parsedEmitted     = false;
    _partialTranscript = '';
    _finalTranscript   = '';
    _errorMessage      = '';
    _elapsedSeconds    = 0;
    debugPrint('[VOICE] resetEngine: cancelling STT (state=$_engineState)');
    await _stt.cancel();
    debugPrint('[VOICE] resetEngine: done (state=$_engineState)');
  }

  // ─── STT Callbacks ────────────────────────────────────────────────────────

  void _onResult(SpeechRecognitionResult result) {
    if (_engineState != VoiceEngineState.listening && _engineState != VoiceEngineState.processing) return;

    if (result.finalResult) {
      debugPrint('[VOICE] Final result: "${result.recognizedWords}"');
      _finalTranscript   = result.recognizedWords;
      _partialTranscript = result.recognizedWords;
      _sessionTimer?.cancel();
      _forceParsedTimer?.cancel();  // stop competing timer
      if (_engineState != VoiceEngineState.processing) {
        _setEngineState(VoiceEngineState.processing);
      }
      // Short delay so UI can show 'processing' briefly before parsed
      Future.delayed(const Duration(milliseconds: 300), () {
        _emitParsed();
      });
    } else {
      _partialTranscript = result.recognizedWords;
      debugPrint('[VOICE] Partial: "${result.recognizedWords}"');
    }
    notifyListeners();
  }

  void _onSttStatus(String status) {
    debugPrint('[VOICE] Status: $status');
    if (status == 'done' || status == 'notListening') {
      _sessionTimer?.cancel();
      if (_engineState == VoiceEngineState.listening) {
        _setEngineState(VoiceEngineState.processing);
        _forceParsedTimer?.cancel();
        // FIX: Use _emitParsed() so if _onResult already fired parsed,
        // this timer is a no-op (guard prevents double emission).
        _forceParsedTimer = Timer(const Duration(milliseconds: 600), () {
          if (_engineState == VoiceEngineState.processing) {
            _emitParsed();
          }
        });
      }
    }
  }

  void _onSttError(SpeechRecognitionError error) {
    _sessionTimer?.cancel();
    _forceParsedTimer?.cancel();
    if (error.errorMsg == 'error_no_match' ||
        error.errorMsg == 'error_speech_timeout') {
      if (_engineState == VoiceEngineState.listening ||
          _engineState == VoiceEngineState.processing) {
        _setEngineState(VoiceEngineState.processing);
        _emitParsed();
      }
      return;
    }

    _errorMessage = _friendlyError(error.errorMsg);
    _setEngineState(VoiceEngineState.error);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  // Single parsed emitter — all code paths must call this instead of
  // _setEngineState(parsed) directly. The _parsedEmitted flag ensures
  // only the FIRST caller wins; all subsequent calls are ignored.
  void _emitParsed() {
    if (_parsedEmitted) {
      debugPrint('[VOICE] _emitParsed: already emitted — ignoring duplicate');
      return;
    }
    _parsedEmitted = true;
    if (_finalTranscript.isEmpty && _partialTranscript.isNotEmpty) {
      debugPrint('[VOICE] _emitParsed: fallback transcript copied from partial: "$_partialTranscript"');
      _finalTranscript = _partialTranscript;
    }
    _setEngineState(VoiceEngineState.parsed);
  }

  void _setEngineState(VoiceEngineState s) {
    if (_engineState == s) return;
    debugPrint('[VOICE] State: $_engineState -> $s');
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
    _forceParsedTimer?.cancel();
    _sessionTimer?.cancel();
    _stt.cancel();
    super.dispose();
  }
}
