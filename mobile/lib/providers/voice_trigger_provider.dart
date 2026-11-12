import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../services/voice_trigger_service.dart';

class VoiceTriggerProvider extends ChangeNotifier {
  final VoiceTriggerService _service = VoiceTriggerService();
  StreamSubscription<VoiceEngineState>? _stateSub;
  StreamSubscription<TriggerEvent>? _triggerSub;

  VoiceEngineState _state = VoiceEngineState.stopped;
  TriggerEvent? _lastTrigger;
  String? _errorMessage;
  String? _activeGuardianPhone;

  Future<void> Function(TriggerEvent event)? _onDistressCallback;

  VoiceEngineState get state => _state;
  bool get isListening => _state == VoiceEngineState.listening;
  bool get isCooldown => _state == VoiceEngineState.cooldown;
  bool get isDetected => _state == VoiceEngineState.triggerDetected;
  int get cooldownSeconds => _service.cooldownSecondsRemaining;
  List<String> get safePhrases => _service.safePhrases;
  TriggerEvent? get lastTrigger => _lastTrigger;
  String? get errorMessage => _errorMessage;
  String? get activeGuardianPhone => _activeGuardianPhone;

  void attachDistressCallback(Future<void> Function(TriggerEvent event) callback) {
    _onDistressCallback = callback;
  }

  void syncCustomSafeWord(String? phrase) {
    if (phrase != null && phrase.trim().isNotEmpty) {
      _service.addSafePhrase(phrase.trim());
      notifyListeners();
    }
  }

  VoiceTriggerProvider() {
    _loadSavedSafeWord();

    _stateSub = _service.onStateChanged.listen((newState) {
      _state = newState;
      if (newState == VoiceEngineState.permissionDenied) {
        _errorMessage = 'Microphone permission is required for voice guardian mode.';
      } else {
        _errorMessage = null;
      }
      notifyListeners();
    });

    _triggerSub = _service.onTrigger.listen((event) async {
      _lastTrigger = event;
      notifyListeners();

      // Step 1: Capture GPS & transmit emergency incident to Cloud Server over Cellular
      // (with automatic local queue + GSM SMS fallback if internet is unavailable in isolated zone)
      if (_onDistressCallback != null) {
        try {
          await _onDistressCallback!(event);
        } catch (_) {}
      }

      // Step 2: Immediate direct GSM cellular call to registered Primary Guardian (zero internet needed)
      try {
        final prefs = await SharedPreferences.getInstance();
        final phone = prefs.getString(AppConstants.keyGuardianPhone) ??
            prefs.getString('nexa_emergency_contact_phone') ??
            prefs.getString(AppConstants.keyPreferredHelpline) ??
            '112';
        _activeGuardianPhone = phone;
        final Uri telUri = Uri.parse('tel:$phone');
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    });
  }

  Future<void> _loadSavedSafeWord() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhrase = prefs.getString(AppConstants.keySafeWordPhrase);
      if (savedPhrase != null && savedPhrase.trim().isNotEmpty) {
        _service.addSafePhrase(savedPhrase.trim());
        notifyListeners();
      }
    } catch (_) {}
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

  /// In-app verification hook to confirm safe-word matching and distress pipeline
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
