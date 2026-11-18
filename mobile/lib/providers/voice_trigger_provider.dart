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
        _errorMessage = 'Microphone permission is required for automatic voice guardian mode.';
      } else {
        _errorMessage = null;
      }
      notifyListeners();
    });

    _triggerSub = _service.onTrigger.listen((event) async {
      _lastTrigger = event;
      notifyListeners();

      // Step 1: Immediate Direct GSM Cellular Call to registered Primary Guardian (zero internet needed)
      await triggerGuardianCall();

      // Step 2: Capture GPS & queue/transmit emergency telemetry to Cloud Server
      if (_onDistressCallback != null) {
        try {
          await _onDistressCallback!(event);
        } catch (_) {}
      }
    });
  }

  /// Automatically arm voice listening upon screen/app launch
  Future<void> autoArmListening() async {
    if (!isListening && _state != VoiceEngineState.loadingModel && !isCooldown) {
      await _service.startListening();
    }
  }

  Future<void> _loadSavedSafeWord() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhrase = prefs.getString(AppConstants.keySafeWordPhrase);
      if (savedPhrase != null && savedPhrase.trim().isNotEmpty) {
        _service.addSafePhrase(savedPhrase.trim());
      } else {
        _service.addSafePhrase('help nexa');
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Direct GSM Voice Call to Primary Guardian: operates with or without microphone active
  Future<bool> triggerGuardianCall({String? overridePhone}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String phone = (overridePhone != null && overridePhone.trim().isNotEmpty)
          ? overridePhone.trim()
          : (prefs.getString(AppConstants.keyGuardianPhone) ??
             prefs.getString('nexa_emergency_contact_phone') ??
             prefs.getString(AppConstants.keyPreferredHelpline) ??
             '112');

      _activeGuardianPhone = phone;

      // Sanitize phone number: strip any whitespace, dashes, parentheses
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (cleanPhone.isEmpty) return false;

      final Uri telUri = Uri.parse('tel:$cleanPhone');
      if (await canLaunchUrl(telUri)) {
        return await launchUrl(telUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  /// Trigger guardian call & emergency SOS using registered safe word WITHOUT microphone turned on
  Future<void> triggerSafeWordEmergency({String? phrase}) async {
    final triggerWord = phrase ?? (safePhrases.isNotEmpty ? safePhrases.first : 'help nexa');
    _service.triggerManualDistress(phrase: triggerWord, source: 'no_mic_safe_word_action');
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
