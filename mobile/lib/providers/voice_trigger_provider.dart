import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/voice_trigger_service.dart';

class VoiceTriggerProvider extends ChangeNotifier {
  final VoiceTriggerService _service = VoiceTriggerService();
  StreamSubscription<VoiceEngineState>? _stateSub;
  StreamSubscription<TriggerEvent>? _triggerSub;

  VoiceEngineState _state = VoiceEngineState.stopped;
  TriggerEvent? _lastTrigger;
  String? _errorMessage;

  VoiceEngineState get state => _state;
  bool get isListening => _state == VoiceEngineState.listening;
  bool get isCooldown => _state == VoiceEngineState.cooldown;
  bool get isDetected => _state == VoiceEngineState.triggerDetected;
  int get cooldownSeconds => _service.cooldownSecondsRemaining;
  List<String> get safePhrases => _service.safePhrases;
  TriggerEvent? get lastTrigger => _lastTrigger;
  String? get errorMessage => _errorMessage;

  VoiceTriggerProvider() {
    _stateSub = _service.onStateChanged.listen((newState) {
      _state = newState;
      if (newState == VoiceEngineState.permissionDenied) {
        _errorMessage = 'Microphone permission is required for voice guardian mode.';
      } else {
        _errorMessage = null;
      }
      notifyListeners();
    });

    _triggerSub = _service.onTrigger.listen((event) {
      _lastTrigger = event;
      notifyListeners();
    });
  }

  Future<void> toggleListening() async {
    if (isListening || _state == VoiceEngineState.loadingModel) {
      _service.stopListening();
    } else {
      await _service.startListening();
    }
  }

  void addSafePhrase(String phrase) {
    _service.addSafePhrase(phrase);
    notifyListeners();
  }

  void removeSafePhrase(String phrase) {
    _service.removeSafePhrase(phrase);
    notifyListeners();
  }

  /// In-app testing hook to verify phrase matching and trigger pipeline
  bool testAudioInput(String inputPhrase) {
    return _service.processRecognizedText(inputPhrase);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _triggerSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
