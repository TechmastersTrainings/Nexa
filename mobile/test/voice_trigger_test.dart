import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_safety/services/voice_trigger_service.dart';

void main() {
  group('VoiceTriggerService Keyword Matching & Cooldown Tests', () {
    late VoiceTriggerService service;

    setUp(() {
      service = VoiceTriggerService();
    });

    tearDown(() {
      service.dispose();
    });

    test('Safe phrases include help nexa and standard distress keywords', () {
      service.setListeningForTesting();
      expect(service.safePhrases.contains('help nexa'), isTrue);
      expect(service.safePhrases.contains('nexa help'), isTrue);
      expect(service.safePhrases.contains('help'), isTrue);
      expect(service.safePhrases.contains('bachao'), isTrue);
      expect(service.safePhrases.contains('save me'), isTrue);
    });

    test('Speech input with "help nexa" or registered safe word triggers distress', () async {
      service.setListeningForTesting();
      bool triggered = false;
      String? matched;

      final sub = service.onTrigger.listen((event) {
        triggered = true;
        matched = event.matchedPhrase;
      });

      final result = service.processRecognizedText('please help nexa immediately');
      expect(result, isTrue);

      await Future.delayed(const Duration(milliseconds: 20));
      expect(triggered, isTrue);
      expect(matched, equals('help nexa'));

      await sub.cancel();
    });

    test('Manual safe-word trigger functions with or without microphone active', () async {
      bool triggered = false;
      String? source;

      final sub = service.onTrigger.listen((event) {
        triggered = true;
        source = event.triggerSource;
      });

      service.triggerManualDistress(phrase: 'help nexa', source: 'no_mic_safe_word_action');

      await Future.delayed(const Duration(milliseconds: 20));
      expect(triggered, isTrue);
      expect(source, equals('no_mic_safe_word_action'));

      await sub.cancel();
    });

    test('Custom safe phrase can be added and matches input', () {
      service.setListeningForTesting();
      service.addSafePhrase('code red alpha');
      expect(service.safePhrases.contains('code red alpha'), isTrue);

      // Normalization check
      service.addSafePhrase('  NEXA SOS  ');
      expect(service.safePhrases.contains('nexa sos'), isTrue);

      final matched = service.processRecognizedText('emergency code red alpha');
      expect(matched, isTrue);
    });

    test('Removing safe phrase updates list', () {
      service.addSafePhrase('temporary code');
      expect(service.safePhrases.contains('temporary code'), isTrue);

      service.removeSafePhrase('temporary code');
      expect(service.safePhrases.contains('temporary code'), isFalse);
    });
  });
}
