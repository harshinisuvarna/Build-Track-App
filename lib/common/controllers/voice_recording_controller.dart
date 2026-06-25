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

  /// Live partial transcript shown during listening (combined accumulated + current partial).
  String get partialTranscript {
    final acc = _finalTranscript.trim();
    final part = _partialTranscript.trim();
    if (acc.isEmpty) return part;
    if (part.isEmpty) return acc;
    return '$acc $part';
  }
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

  // Continuous listening / auto-restart logic
  String _accumulatedTranscript = '';
  DateTime? _lastResultTime;

  // ─── Init ──────────────────────────────────────────────────────────────────
  Future<bool> _ensureInitialised() async {
    if (_sttInitialised) return true;
    if (_initialising)   return false;
    _initialising = true;
    try {
      debugPrint('[VOICE INITIALIZATION] Starting SpeechToText initialization...');
      _sttInitialised = await _stt.initialize(
        onError:  _onSttError,
        onStatus: _onSttStatus,
        debugLogging: false,
      );
      if (_sttInitialised) {
        debugPrint('[VOICE INITIALIZATION] Speech successfully initialized.');
      } else {
        debugPrint('[VOICE INITIALIZATION] Speech initialization returned false.');
      }
    } catch (e) {
      debugPrint('[VOICE INITIALIZATION] Speech initialization crashed: $e');
      _sttInitialised = false;
    }
    _initialising = false;
    return _sttInitialised;
  }

  /// Pre-initialize the speech-to-text engine to minimize latency when recording starts.
  Future<bool> preInitialize() async {
    debugPrint('[VOICE INITIALIZATION] Pre-initialize triggered.');
    return _ensureInitialised();
  }

  void _onSoundLevel(double level) {
    _soundLevel = level;
    notifyListeners();
  }

  // ─── Start listening ───────────────────────────────────────────────────────
  Future<void> startListening() async {
    debugPrint('[VOICE START] startListening() requested. Current state: $_engineState');
    if (_engineState == VoiceEngineState.listening) {
      debugPrint('[VOICE START] Already listening. Request ignored.');
      return;
    }

    _forceParsedTimer?.cancel();
    _parsedEmitted = false;  // reset guard for new session

    _partialTranscript   = '';
    _finalTranscript     = '';
    _accumulatedTranscript = '';
    _lastResultTime      = DateTime.now();
    _errorMessage        = '';
    _elapsedSeconds      = 0;
    debugPrint('[VOICE TIMER] Reset: elapsedSeconds = 0, lastResultTime = $_lastResultTime');

    final ready = await _ensureInitialised();
    if (!ready) {
      _errorMessage = 'Microphone permission denied or not available.';
      debugPrint('[VOICE START] Speech not ready or permission denied.');
      _setEngineState(VoiceEngineState.error);
      return;
    }

    try {
      if (_stt.isListening) {
        debugPrint('[VOICE START] Cancelling active STT session before starting.');
        await _stt.cancel();
      } else {
        debugPrint('[VOICE START] STT is not listening. Skipping stt.cancel() to prevent startup lag.');
      }
    } catch (e) {
      debugPrint('[VOICE START] Failed to cancel active STT: $e');
    }

    _setEngineState(VoiceEngineState.listening);
    _sessionTimer?.cancel();
    debugPrint('[VOICE TIMER] Stop: previous timer cancelled if any.');

    debugPrint('[VOICE TIMER] Start: periodic 1s timer started.');
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _elapsedSeconds++;
      debugPrint('[VOICE TIMER] Tick: $_elapsedSeconds seconds. STT isListening: ${_stt.isListening}, EngineState: $_engineState');
      
      // Auto recovery check:
      if (_engineState == VoiceEngineState.listening && _elapsedSeconds > 1) {
        if (!_stt.isListening) {
          final silenceDuration = DateTime.now().difference(_lastResultTime ?? DateTime.now());
          if (silenceDuration < Duration(seconds: pauseForSeconds) && _elapsedSeconds < 90) {
            debugPrint('[VOICE TIMER] MISMATCH DETECTED: STT stopped but silence is brief (${silenceDuration.inSeconds}s). Auto-recovering...');
            _restartListeningInternal();
          } else {
            debugPrint('[VOICE TIMER] MISMATCH DETECTED: STT stopped and silence limit exceeded. Auto-recovering via stop...');
            _handleRecognitionStopped();
          }
        }
      }
      notifyListeners();
    });

    try {
      debugPrint('[VOICE START] Calling stt.listen()...');
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
      debugPrint('[VOICE START] stt.listen() completed successfully.');
    } catch (e) {
      _errorMessage = 'Could not start microphone: $e';
      debugPrint('[VOICE START] stt.listen() failed with error: $e');
      _sessionTimer?.cancel();
      debugPrint('[VOICE TIMER] Stop: timer cancelled due to listen failure.');
      _setEngineState(VoiceEngineState.error);
    }
  }

  // ─── Stop (manual) ────────────────────────────────────────────────────────
  Future<void> stopListening() async {
    debugPrint('[VOICE STOP] stopListening() requested. Current state: $_engineState');
    if (_engineState != VoiceEngineState.listening) {
      debugPrint('[VOICE STOP] Not listening. Request ignored.');
      return;
    }
    _sessionTimer?.cancel();
    debugPrint('[VOICE TIMER] Stop: timer stopped manually.');
    await _stt.stop();
    debugPrint('[VOICE STOP] stt.stop() called.');
    _setEngineState(VoiceEngineState.processing);
  }

  // ─── Cancel ───────────────────────────────────────────────────────────────
  Future<void> cancelListening() async {
    debugPrint('[VOICE CANCEL] cancelListening() requested. Current state: $_engineState');
    _forceParsedTimer?.cancel();
    _sessionTimer?.cancel();
    debugPrint('[VOICE TIMER] Stop: timer stopped due to cancellation.');
    _parsedEmitted = false;
    await _stt.cancel();
    debugPrint('[VOICE CANCEL] stt.cancel() called.');
    _partialTranscript = '';
    _finalTranscript   = '';
    _accumulatedTranscript = '';
    _elapsedSeconds    = 0;
    debugPrint('[VOICE TIMER] Reset: elapsedSeconds = 0');
    _setEngineState(VoiceEngineState.idle);
  }

  // ─── Reset to idle (for re-record flow) ───────────────────────────────────
  void reset() {
    debugPrint('[VOICE RESET] reset() requested. Current state: $_engineState');
    _forceParsedTimer?.cancel();
    _sessionTimer?.cancel();
    debugPrint('[VOICE TIMER] Stop: timer stopped due to reset.');
    _parsedEmitted     = false;
    _partialTranscript = '';
    _finalTranscript   = '';
    _accumulatedTranscript = '';
    _errorMessage      = '';
    _elapsedSeconds    = 0;
    debugPrint('[VOICE TIMER] Reset: elapsedSeconds = 0');
    _setEngineState(VoiceEngineState.idle);
  }

  // ─── Reset STT engine without changing state ─────────────────────────────
  // Calls stt.cancel() to properly reset the recognizer for the next listen()
  // without reverting the state machine. This avoids the stale recognizer bug
  // where notListening fires immediately after a new listen() call.
  Future<void> resetEngine() async {
    debugPrint('[VOICE RESET ENGINE] resetEngine() requested.');
    _forceParsedTimer?.cancel();
    _sessionTimer?.cancel();
    debugPrint('[VOICE TIMER] Stop: timer cancelled in resetEngine.');
    _parsedEmitted     = false;
    _partialTranscript = '';
    _finalTranscript   = '';
    _accumulatedTranscript = '';
    _errorMessage      = '';
    _elapsedSeconds    = 0;
    debugPrint('[VOICE TIMER] Reset: elapsedSeconds = 0');
    debugPrint('[VOICE RESET ENGINE] resetEngine: cancelling STT (state=$_engineState)');
    await _stt.cancel();
    debugPrint('[VOICE RESET ENGINE] resetEngine: done (state=$_engineState)');
  }

  // ─── STT Callbacks ────────────────────────────────────────────────────────

  void _onResult(SpeechRecognitionResult result) {
    if (_engineState != VoiceEngineState.listening && _engineState != VoiceEngineState.processing) return;

    final recognized = result.recognizedWords.trim();
    if (recognized.isNotEmpty) {
      _lastResultTime = DateTime.now();
      debugPrint('[VOICE RESULT] Speech detected! Updating _lastResultTime to $_lastResultTime');
    }

    if (result.finalResult) {
      debugPrint('[VOICE RESULT] Final segment result: "$recognized"');
      if (recognized.isNotEmpty) {
        if (_accumulatedTranscript.isEmpty) {
          _accumulatedTranscript = recognized;
        } else {
          final accWords = _accumulatedTranscript.split(' ');
          final recWords = recognized.split(' ');
          if (accWords.isNotEmpty && recWords.isNotEmpty && accWords.last.toLowerCase() == recWords.first.toLowerCase()) {
            recWords.removeAt(0);
          }
          if (recWords.isNotEmpty) {
            _accumulatedTranscript = '${_accumulatedTranscript.trim()} ${recWords.join(' ')}';
          }
        }
      }
      _finalTranscript = _accumulatedTranscript.trim();
      _partialTranscript = '';
      debugPrint('[VOICE RESULT] Accumulated final transcript: "$_finalTranscript"');
    } else {
      _partialTranscript = recognized;
      debugPrint('[VOICE RESULT] Current segment partial: "$recognized"');
    }
    notifyListeners();
  }

  void _onSttStatus(String status) {
    debugPrint('[VOICE STATUS CHANGES] Status changed: $status');
    if (status == 'done' || status == 'notListening' || status == 'timeout' || status == 'sessionEnded' || status == 'recognitionStopped') {
      debugPrint('[VOICE STATUS CHANGES] Non-listening status detected: $status. Checking if we should auto-restart...');
      
      if (_engineState == VoiceEngineState.listening) {
        final silenceDuration = DateTime.now().difference(_lastResultTime ?? DateTime.now());
        debugPrint('[VOICE STATUS CHANGES] Silence duration: ${silenceDuration.inSeconds}s (max allowed pauseFor: $pauseForSeconds s)');
        
        if (silenceDuration < Duration(seconds: pauseForSeconds) && _elapsedSeconds < 90) {
          debugPrint('[VOICE STATUS CHANGES] Pause is brief. Triggering Auto-Restart.');
          _restartListeningInternal();
        } else {
          debugPrint('[VOICE STATUS CHANGES] Silence exceeded $pauseForSeconds s. Genuinely ending session...');
          _handleRecognitionStopped();
        }
      } else {
        debugPrint('[VOICE STATUS CHANGES] Engine is in state $_engineState (not listening). Genuinely ending session...');
        _sessionTimer?.cancel();
        debugPrint('[VOICE TIMER] Stop: timer stopped via status callback.');
      }
    }
  }

  void _handleRecognitionStopped() {
    debugPrint('[VOICE STATUS CHANGES] _handleRecognitionStopped called. EngineState: $_engineState, isListening: ${_stt.isListening}');
    _sessionTimer?.cancel();
    debugPrint('[VOICE TIMER] Stop: timer stopped inside _handleRecognitionStopped.');
    _forceParsedTimer?.cancel();
    
    if (_finalTranscript.isEmpty && _partialTranscript.isNotEmpty) {
      debugPrint('[VOICE STATUS CHANGES] Using partial transcript as final: "$_partialTranscript"');
      _finalTranscript = _partialTranscript;
    }

    if (_finalTranscript.isNotEmpty) {
      _setEngineState(VoiceEngineState.processing);
      _emitParsed();
    } else {
      _setEngineState(VoiceEngineState.idle);
    }
  }

  Future<void> _restartListeningInternal() async {
    if (_engineState != VoiceEngineState.listening) {
      debugPrint('[VOICE AUTO RESTART] Not in listening state anymore. Skipping restart.');
      return;
    }

    debugPrint('[VOICE AUTO RESTART] Restarting native speech recognizer...');
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
      debugPrint('[VOICE AUTO RESTART] Native speech recognizer restarted successfully.');
    } catch (e) {
      debugPrint('[VOICE AUTO RESTART] Failed to restart STT: $e');
    }
  }

  void _onSttError(SpeechRecognitionError error) {
    debugPrint('[VOICE ERROR] Error callback: permanent=${error.permanent}, errorMsg=${error.errorMsg}');
    
    if (_engineState == VoiceEngineState.listening) {
      if (error.errorMsg == 'error_speech_timeout' || error.errorMsg == 'error_no_match') {
        final silenceDuration = DateTime.now().difference(_lastResultTime ?? DateTime.now());
        debugPrint('[VOICE TIMEOUT] Error ${error.errorMsg}. Silence duration: ${silenceDuration.inSeconds}s');
        
        if (silenceDuration < Duration(seconds: pauseForSeconds) && _elapsedSeconds < 90) {
          debugPrint('[VOICE TIMEOUT] Silence is brief. Auto-recovering error with Auto-Restart.');
          _restartListeningInternal();
          return;
        }
      }
    }

    _sessionTimer?.cancel();
    debugPrint('[VOICE TIMER] Stop: timer stopped due to error.');
    _forceParsedTimer?.cancel();
    
    if (error.errorMsg == 'error_no_match' ||
        error.errorMsg == 'error_speech_timeout') {
      debugPrint('[VOICE TIMEOUT] Ending session due to silence timeout.');
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
      debugPrint('[VOICE RESULT] _emitParsed: already emitted — ignoring duplicate');
      return;
    }
    _parsedEmitted = true;
    if (_finalTranscript.isEmpty && _partialTranscript.isNotEmpty) {
      debugPrint('[VOICE RESULT] _emitParsed: fallback transcript copied from partial: "$_partialTranscript"');
      _finalTranscript = _partialTranscript;
    }
    _setEngineState(VoiceEngineState.parsed);
  }

  void _setEngineState(VoiceEngineState s) {
    if (_engineState == s) return;
    debugPrint('[VOICE STATE TRANSITION] State change: $_engineState -> $s');
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
    debugPrint('[VOICE TIMER] Stop: timer stopped due to controller disposal.');
    _stt.cancel();
    super.dispose();
  }
}
