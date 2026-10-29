import 'package:flutter/foundation.dart';
import '../core/api_service.dart';
import '../services/incident_queue_service.dart';
import '../services/location_service.dart';

class IncidentProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final IncidentQueueService _queueService = IncidentQueueService();
  final ApiService _apiService = ApiService();

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool _isTriggering = false;
  bool get isTriggering => _isTriggering;

  int _lastDispatchedCount = 0;
  int get lastDispatchedCount => _lastDispatchedCount;

  LocationData? _lastLocation;
  LocationData? get lastLocation => _lastLocation;

  LocalIncidentItem? _lastIncident;
  LocalIncidentItem? get lastIncident => _lastIncident;

  IncidentProvider() {
    refreshQueueCount();
  }

  Future<void> refreshQueueCount() async {
    final queue = await _queueService.getPendingQueue();
    _pendingCount = queue.where((i) => !i.isSynced).length;
    notifyListeners();
  }

  /// Triggers an immediate emergency event: captures location, queues locally, syncs, and broadcasts alerts
  Future<LocalIncidentItem> triggerEmergency({
    required String? token,
    String triggerType = 'manual_panic',
  }) async {
    _isTriggering = true;
    _lastDispatchedCount = 0;
    notifyListeners();

    try {
      // 1. Retrieve real location (or explicit unavailable state)
      final loc = await _locationService.getCurrentLocation();
      _lastLocation = loc;

      // 2. Persist immediately to local offline queue (guaranteed durability)
      final item = await _queueService.enqueueIncident(
        triggerType: triggerType,
        location: loc,
      );
      _lastIncident = item;
      await refreshQueueCount();

      // 3. Try flushing queue if token available
      if (token != null) {
        await flushOfflineQueue(token);
      }

      return item;
    } finally {
      _isTriggering = false;
      notifyListeners();
    }
  }

  Future<int> flushOfflineQueue(String token) async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    notifyListeners();

    try {
      final result = await _queueService.flushQueue(token, _apiService);
      await refreshQueueCount();

      // Dispatch emergency telecom alerts for each synced incident
      int totalDispatched = 0;
      for (final incId in result.syncedIncidentIds) {
        try {
          final alertRes = await _apiService.dispatchAlerts(token, incidentId: incId);
          if (alertRes['dispatched_count'] != null) {
            totalDispatched += (alertRes['dispatched_count'] as num).toInt();
          }
        } catch (_) {
          // If dispatch fails, it will be retried on next sync or available in dashboard
        }
      }

      if (totalDispatched > 0) {
        _lastDispatchedCount = totalDispatched;
      }

      return result.syncedCount;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
