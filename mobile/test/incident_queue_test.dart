import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexa_safety/services/incident_queue_service.dart';
import 'package:nexa_safety/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IncidentQueueService Offline Persistence Tests', () {
    late IncidentQueueService queueService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      queueService = IncidentQueueService();
    });

    test('Enqueuing incident persists item in local offline buffer', () async {
      final initialQueue = await queueService.getPendingQueue();
      expect(initialQueue.isEmpty, isTrue);

      final loc = LocationData(
        latitude: 28.6139,
        longitude: 77.2090,
        accuracyMeters: 5.0,
        timestamp: DateTime.now().toUtc(),
        isUnavailable: false,
      );

      final item = await queueService.enqueueIncident(
        triggerType: 'safe_word_keyword',
        location: loc,
        batteryLevel: 80,
      );

      expect(item.clientIncidentId.isNotEmpty, isTrue);
      expect(item.latitude, 28.6139);
      expect(item.longitude, 77.2090);
      expect(item.accuracyMeters, 5.0);
      expect(item.isSynced, isFalse);

      final pending = await queueService.getPendingQueue();
      expect(pending.length, 1);
      expect(pending.first.clientIncidentId, item.clientIncidentId);
    });

    test('Enqueuing with unavailable location handles explicit state', () async {
      final unavailLoc = LocationData.unavailable('GPS signal lost');

      final item = await queueService.enqueueIncident(
        triggerType: 'manual_sos',
        location: unavailLoc,
      );

      expect(item.locationUnavailable, isTrue);
      expect(item.latitude, isNull);
      expect(item.longitude, isNull);

      final pending = await queueService.getPendingQueue();
      expect(pending.length, 1);
      expect(pending.first.locationUnavailable, isTrue);
    });
  });
}
