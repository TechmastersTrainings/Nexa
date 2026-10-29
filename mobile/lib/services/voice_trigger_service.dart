import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

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

  // Active safe words and trigger phrase variants
  final List<String> _safePhrases = [
    'help',
    'help me',
    'bachao',
    'save me',
    'nexa rescue',
    'emergency',
  ];
  List<String> get safePhrases => List.unmodifiable(_safePhrases);

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

  // Simulated audio stream monitor / background recognizer loop
  Timer? _recognitionLoopTimer;
  final bool _audioRemainsLocal = true;
  bool get audioRemainsLocal => _audioRemainsLocal;

  void addSafePhrase(String phrase) {
    final normalized = phrase.trim().toLowerCase();
    if (normalized.isNotEmpty && !_safePhrases.contains(normalized)) {
      _safePhrases.add(normalized);
    }
  }

  void removeSafePhrase(String phrase) {
    _safePhrases.remove(phrase.trim().toLowerCase());
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      return true;
    } else {
      _updateState(VoiceEngineState.permissionDenied);
      return false;
    }
  }

  Future<void> startListening() async {
    // If in cooldown, do not start immediately
    if (_isInCooldown()) {
      _updateState(VoiceEngineState.cooldown);
      return;
    }

    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) return;

    _updateState(VoiceEngineState.loadingModel);

    // Simulate local acoustic model load delay (validating local resource integrity)
    await Future.delayed(const Duration(milliseconds: 400));

    _updateState(VoiceEngineState.listening);
    _startLocalRecognitionPipeline();
  }

  void _startLocalRecognitionPipeline() {
    _recognitionLoopTimer?.cancel();
    // Keep local recognition loop running
    _recognitionLoopTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      // In production with Vosk, this connects to Vosk.recognizer.readAudioStream()
      // Zero audio is transmitted over network; frames are discarded after classification
    });
  }

  /// Evaluates speech recognized text against safe phrases with fuzzy match and confidence
  bool processRecognizedText(String recognizedText, {double simulatedConfidence = 0.92}) {
    if (_state != VoiceEngineState.listening) return false;
    if (_isInCooldown()) return false;

    final cleanText = recognizedText.toLowerCase().trim();
    if (cleanText.isEmpty) return false;

    for (final phrase in _safePhrases) {
      if (cleanText == phrase ||
          cleanText.contains(phrase) ||
          _wordsOverlap(cleanText, phrase)) {
        _handleTriggerDetected(phrase, simulatedConfidence);
        return true;
      }
    }
    return false;
  }

  bool _wordsOverlap(String text, String phrase) {
    final textWords = text.split(RegExp(r'\s+'));
    final phraseWords = phrase.split(RegExp(r'\s+'));
    return phraseWords.every((pw) => textWords.contains(pw));
  }

  void _handleTriggerDetected(String phrase, double confidence) {
    _lastTriggerTime = DateTime.now();
    _updateState(VoiceEngineState.triggerDetected);

    final event = TriggerEvent(
      matchedPhrase: phrase,
      confidence: confidence,
      timestamp: _lastTriggerTime!,
    );

    _triggerController.add(event);

    // Start 30-second cooldown to prevent cascading duplicate alarms
    _startCooldown();
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
        }
      }
    });
  }

  void stopListening() {
    _recognitionLoopTimer?.cancel();
    _recognitionLoopTimer = null;
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
