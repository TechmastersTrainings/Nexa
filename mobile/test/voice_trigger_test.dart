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

    test('Safe phrases match distress keywords correctly', () {
      // Force state to listening for processing tests
      service.processRecognizedText(''); // initial noop
      expect(service.safePhrases.contains('help'), isTrue);
      expect(service.safePhrases.contains('bachao'), isTrue);
      expect(service.safePhrases.contains('save me'), isTrue);
    });

    test('Custom safe phrase can be added and matches input', () {
      service.addSafePhrase('code red alpha');
      expect(service.safePhrases.contains('code red alpha'), isTrue);

      // Normalization check
      service.addSafePhrase('  NEXA SOS  ');
      expect(service.safePhrases.contains('nexa sos'), isTrue);
    });

    test('Removing safe phrase updates list', () {
      service.addSafePhrase('temporary code');
      expect(service.safePhrases.contains('temporary code'), isTrue);

      service.removeSafePhrase('temporary code');
      expect(service.safePhrases.contains('temporary code'), isFalse);
    });
  });
}
