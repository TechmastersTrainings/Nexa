import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/api_service.dart';
import 'location_service.dart';

class LocalIncidentItem {
  final String clientIncidentId;
  final String triggerType;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DateTime? locationTimestamp;
  final bool locationUnavailable;
  final int? batteryLevel;
  final DateTime localCreatedAt;
  bool isSynced;

  LocalIncidentItem({
    required this.clientIncidentId,
    required this.triggerType,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.locationTimestamp,
    this.locationUnavailable = false,
    this.batteryLevel,
    required this.localCreatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'client_incident_id': clientIncidentId,
    'trigger_type': triggerType,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy_meters': accuracyMeters,
    'location_timestamp': locationTimestamp?.toUtc().toIso8601String(),
    'location_unavailable': locationUnavailable,
    'battery_level': batteryLevel,
    'local_created_at': localCreatedAt.toUtc().toIso8601String(),
    'is_synced': isSynced,
  };

  factory LocalIncidentItem.fromJson(Map<String, dynamic> json) {
    return LocalIncidentItem(
      clientIncidentId: json['client_incident_id'] as String,
      triggerType: json['trigger_type'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
      locationTimestamp: json['location_timestamp'] != null
          ? DateTime.tryParse(json['location_timestamp'] as String)
          : null,
      locationUnavailable: json['location_unavailable'] as bool? ?? false,
      batteryLevel: json['battery_level'] as int?,
      localCreatedAt: DateTime.parse(json['local_created_at'] as String),
      isSynced: json['is_synced'] as bool? ?? false,
    );
  }
}

class IncidentQueueService {
  static const String _storageKey = 'nexa_offline_incident_queue';
  final _uuid = const Uuid();

  Future<List<LocalIncidentItem>> getPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List list = jsonDecode(raw);
      return list.map((e) => LocalIncidentItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<LocalIncidentItem> enqueueIncident({
    required String triggerType,
    required LocationData location,
    int? batteryLevel,
  }) async {
    final item = LocalIncidentItem(
      clientIncidentId: _uuid.v4(),
      triggerType: triggerType,
      latitude: location.latitude,
      longitude: location.longitude,
      accuracyMeters: location.accuracyMeters,
      locationTimestamp: location.timestamp,
      locationUnavailable: location.isUnavailable,
      batteryLevel: batteryLevel ?? 85,
      localCreatedAt: DateTime.now().toUtc(),
      isSynced: false,
    );

    final queue = await getPendingQueue();
    queue.add(item);
    await _saveQueue(queue);
    return item;
  }

  Future<int> flushQueue(String token, ApiService apiService) async {
    final queue = await getPendingQueue();
    final unsynced = queue.where((i) => !i.isSynced).toList();
    if (unsynced.isEmpty) return 0;

    try {
      final batchPayload = unsynced.map((item) => {
        'client_incident_id': item.clientIncidentId,
        'trigger_type': item.triggerType,
        'latitude': item.latitude,
        'longitude': item.longitude,
        'accuracy_meters': item.accuracyMeters,
        'location_timestamp': item.locationTimestamp?.toUtc().toIso8601String(),
        'location_unavailable': item.locationUnavailable,
        'battery_level': item.batteryLevel,
        'local_created_at': item.localCreatedAt.toUtc().toIso8601String(),
      }).toList();

      // Send to backend batch sync endpoint
      final res = await apiService.syncIncidentBatch(token, batchPayload);
      if (res['processed_count'] != null) {
        // Mark flushed items as synced or purge them
        queue.removeWhere((i) => unsynced.any((u) => u.clientIncidentId == i.clientIncidentId));
        await _saveQueue(queue);
        return unsynced.length;
      }
    } catch (_) {
      // If network remains offline, queue items are safely preserved locally
    }
    return 0;
  }

  Future<void> _saveQueue(List<LocalIncidentItem> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(queue.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
