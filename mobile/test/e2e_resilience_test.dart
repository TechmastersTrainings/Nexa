import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexa_safety/services/voice_trigger_service.dart';
import 'package:nexa_safety/services/incident_queue_service.dart';
import 'package:nexa_safety/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Mobile End-to-End Resilience Pipeline Tests', () {
    test('Simulated Voice Distress -> Local Queue Buffer -> Location Persistence', () async {
      final voiceService = VoiceTriggerService();
      voiceService.setListeningForTesting();
      final queueService = IncidentQueueService();

      // 1. Simulate on-device voice detection of distress keyword
      bool triggerFired = false;
      String? detectedPhrase;

      final sub = voiceService.onTrigger.listen((event) {
        triggerFired = true;
        detectedPhrase = event.matchedPhrase;
      });

      final matched = voiceService.processRecognizedText('bachao');
      expect(matched, isTrue);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(triggerFired, isTrue);
      expect(detectedPhrase, equals('bachao'));

      // 2. Capture location telemetry
      final location = LocationData(
        latitude: 12.971598,
        longitude: 77.594566,
        accuracyMeters: 4.2,
        timestamp: DateTime.now().toUtc(),
      );

      // 3. Enqueue incident immediately in offline durable buffer
      final queuedItem = await queueService.enqueueIncident(
        triggerType: 'voice_trigger_$detectedPhrase',
        location: location,
        batteryLevel: 79,
      );

      expect(queuedItem.clientIncidentId, isNotEmpty);
      expect(queuedItem.triggerType, equals('voice_trigger_bachao'));
      expect(queuedItem.latitude, equals(12.971598));
      expect(queuedItem.batteryLevel, equals(79));

      // 4. Verify durable persistence across app reboot
      final pendingList = await queueService.getPendingQueue();
      expect(pendingList.length, equals(1));
      expect(pendingList.first.clientIncidentId, equals(queuedItem.clientIncidentId));
      expect(pendingList.first.isSynced, isFalse);

      await sub.cancel();
      voiceService.dispose();
    });

    test('Cooldown prevents flood of repetitive distress triggers', () async {
      final voiceService = VoiceTriggerService();
      voiceService.setListeningForTesting();
      int triggerCount = 0;

      final sub = voiceService.onTrigger.listen((_) {
        triggerCount++;
      });

      // First detection fires
      final firstMatch = voiceService.processRecognizedText('help');
      expect(firstMatch, isTrue);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(triggerCount, equals(1));

      // Immediate repeated detection within 30-sec cooldown is suppressed
      final secondMatch = voiceService.processRecognizedText('help');
      expect(secondMatch, isFalse);
      expect(triggerCount, equals(1));

      await sub.cancel();
      voiceService.dispose();
    });
  });
}
