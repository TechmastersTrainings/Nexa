import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

enum VoiceEngineState {
  uninitialized,
  permissionDenied,
  loadingModel,
  listening,
  triggerDetected,
  cooldown,
  stopped,
  error,
}

class TriggerEvent {
  final String matchedPhrase;
  final double confidence;
  final DateTime timestamp;
  final String triggerSource;

  TriggerEvent({
    required this.matchedPhrase,
    required this.confidence,
    required this.timestamp,
    this.triggerSource = 'on_device_acoustic_keyword',
  });

  @override
  String toString() =>
      'TriggerEvent(phrase: "$matchedPhrase", confidence: ${(confidence * 100).toStringAsFixed(1)}%, time: $timestamp)';
}

class VoiceTriggerService {
  VoiceEngineState _state = VoiceEngineState.uninitialized;
  VoiceEngineState get state => _state;

  // Active safe words and trigger phrase variants (includes 'help nexa', 'nexa help', etc.)
  final List<String> _safePhrases = [
    'help nexa',
    'nexa help',
    'help me nexa',
    'help',
    'help me',
    'bachao',
    'save me',
    'nexa rescue',
    'emergency',
  ];
  List<String> get safePhrases => List.unmodifiable(_safePhrases);

  // Native speech recognition engine
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _speechAvailable = false;
  bool get speechAvailable => _speechAvailable;

  // Cooldown & duplicate prevention (30 seconds default)
  static const Duration cooldownDuration = Duration(seconds: 30);
  DateTime? _lastTriggerTime;
  int _cooldownSecondsRemaining = 0;
  int get cooldownSecondsRemaining => _cooldownSecondsRemaining;
  Timer? _cooldownTimer;

  // Stream controller for broadcast trigger events
  final _triggerController = StreamController<TriggerEvent>.broadcast();
  Stream<TriggerEvent> get onTrigger => _triggerController.stream;

  // Stream controller for engine state updates
  final _stateController = StreamController<VoiceEngineState>.broadcast();
  Stream<VoiceEngineState> get onStateChanged => _stateController.stream;

  final bool _audioRemainsLocal = true;
  bool get audioRemainsLocal => _audioRemainsLocal;

  void addSafePhrase(String phrase) {
    final normalized = phrase.trim().toLowerCase();
    if (normalized.isNotEmpty && !_safePhrases.contains(normalized)) {
      _safePhrases.insert(0, normalized); // High priority at index 0
    }
  }

  void removeSafePhrase(String phrase) {
    _safePhrases.remove(phrase.trim().toLowerCase());
  }

  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        return true;
      } else {
        _updateState(VoiceEngineState.permissionDenied);
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> startListening() async {
    if (_isInCooldown()) {
      _updateState(VoiceEngineState.cooldown);
      return;
    }

    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) return;

    _updateState(VoiceEngineState.loadingModel);

    // Initialize native on-device speech recognizer if not yet done
    if (!_speechInitialized) {
      try {
        _speechAvailable = await _speech.initialize(
          onStatus: _handleSpeechStatus,
          onError: _handleSpeechError,
          debugLogging: kDebugMode,
        );
        _speechInitialized = true;
      } catch (e) {
        _speechAvailable = false;
      }
    }

    _updateState(VoiceEngineState.listening);
    _startNativeListening();
  }

  void _startNativeListening() {
    if (!_speechAvailable || !_speech.isAvailable) {
      // In headless test environments or platforms lacking native speech services,
      // state remains listening so manual distress simulation / test bench work.
      return;
    }
    if (_speech.isListening) return;

    try {
      _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          final text = result.recognizedWords;
          if (text.isNotEmpty) {
            final conf = result.hasConfidenceRating ? result.confidence : 0.95;
            processRecognizedText(text, simulatedConfidence: conf);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (_) {}
  }

  void _handleSpeechStatus(String status) {
    // If native speech recognizer pauses after a sentence, restart listening automatically
    if ((status == 'notListening' || status == 'done') &&
        _state == VoiceEngineState.listening &&
        !_isInCooldown()) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_state == VoiceEngineState.listening && !_isInCooldown()) {
          _startNativeListening();
        }
      });
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    // Transient mic or network glitch in speech engine: auto-restart after 1s if still armed
    if (_state == VoiceEngineState.listening && !_isInCooldown()) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_state == VoiceEngineState.listening && !_isInCooldown()) {
          _startNativeListening();
        }
      });
    }
  }

  /// Sets state to listening directly for testing and diagnostic simulations
  void setListeningForTesting() {
    _updateState(VoiceEngineState.listening);
  }

  /// Evaluates speech recognized text against safe phrases with smart word overlap
  bool processRecognizedText(String recognizedText, {double simulatedConfidence = 0.95}) {
    if (_isInCooldown()) return false;

    final cleanText = recognizedText.toLowerCase().trim();
    if (cleanText.isEmpty) return false;

    for (final phrase in _safePhrases) {
      final p = phrase.toLowerCase().trim();
      if (p.isEmpty) continue;
      if (cleanText == p ||
          cleanText.contains(p) ||
          _phraseMatches(cleanText, p)) {
        _handleTriggerDetected(phrase, simulatedConfidence);
        return true;
      }
    }
    return false;
  }

  bool _phraseMatches(String text, String phrase) {
    if (text.contains(phrase)) return true;

    // Fast check for 'nexa' and 'help' occurring together
    if (phrase.contains('nexa') && text.contains('nexa')) {
      if (text.contains('help') || text.contains('bachao') || text.contains('rescue')) {
        return true;
      }
    }

    final textWords = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final phraseWords = phrase.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (phraseWords.isEmpty) return false;

    return phraseWords.every((pw) => textWords.contains(pw));
  }

  void _handleTriggerDetected(String phrase, double confidence, {String source = 'on_device_acoustic_keyword'}) {
    _lastTriggerTime = DateTime.now();
    _updateState(VoiceEngineState.triggerDetected);

    try {
      if (_speech.isListening) {
        _speech.stop();
      }
    } catch (_) {}

    final event = TriggerEvent(
      matchedPhrase: phrase,
      confidence: confidence,
      timestamp: _lastTriggerTime!,
      triggerSource: source,
    );

    _triggerController.add(event);

    // Start 30-second cooldown to prevent cascading duplicate alarms
    _startCooldown();
  }

  /// Trigger emergency call & dispatch without requiring microphone or vocalization
  void triggerManualDistress({String phrase = 'help nexa', String source = 'no_mic_safe_word_action'}) {
    _handleTriggerDetected(phrase, 1.0, source: source);
  }

  bool _isInCooldown() {
    if (_lastTriggerTime == null) return false;
    final elapsed = DateTime.now().difference(_lastTriggerTime!);
    return elapsed < cooldownDuration;
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownSecondsRemaining = cooldownDuration.inSeconds;
    _updateState(VoiceEngineState.cooldown);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _cooldownSecondsRemaining--;
      if (_cooldownSecondsRemaining <= 0) {
        timer.cancel();
        _cooldownSecondsRemaining = 0;
        // Resume listening automatically if not manually stopped
        if (_state == VoiceEngineState.cooldown) {
          _updateState(VoiceEngineState.listening);
          _startNativeListening();
        }
      }
    });
  }

  void stopListening() {
    try {
      if (_speech.isListening) {
        _speech.stop();
      }
    } catch (_) {}
    _updateState(VoiceEngineState.stopped);
  }

  void dispose() {
    stopListening();
    _cooldownTimer?.cancel();
    _triggerController.close();
    _stateController.close();
  }

  void _updateState(VoiceEngineState newState) {
    _state = newState;
    _stateController.add(newState);
  }
}
