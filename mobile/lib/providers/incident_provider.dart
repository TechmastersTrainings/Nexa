import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
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

  bool _lastSyncedToServer = false;
  bool get lastSyncedToServer => _lastSyncedToServer;

  bool _gsmFallbackUsed = false;
  bool get gsmFallbackUsed => _gsmFallbackUsed;

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

  /// Resolves the best available phone number for direct GSM rescue in isolated places:
  /// registered primary guardian -> legacy cached contact -> user helpline (112).
  Future<String> resolveEmergencyTargetPhone({UserProfile? user}) async {
    if (user?.emergencyContactPhone != null && user!.emergencyContactPhone!.trim().isNotEmpty) {
      return user.emergencyContactPhone!.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    final savedGuardian = prefs.getString(AppConstants.keyGuardianPhone);
    if (savedGuardian != null && savedGuardian.trim().isNotEmpty) {
      return savedGuardian.trim();
    }
    final legacyPhone = prefs.getString('nexa_emergency_contact_phone');
    if (legacyPhone != null && legacyPhone.trim().isNotEmpty) {
      return legacyPhone.trim();
    }
    return user?.preferredPoliceHelpline ??
        prefs.getString(AppConstants.keyPreferredHelpline) ??
        '112';
  }

  /// Places a direct GSM cellular call (requires voice cellular bars, zero mobile internet).
  Future<bool> launchGuardianCall({UserProfile? user, String? overridePhone}) async {
    try {
      final phone = (overridePhone != null && overridePhone.trim().isNotEmpty)
          ? overridePhone.trim()
          : await resolveEmergencyTargetPhone(user: user);
      final Uri telUri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(telUri)) {
        return await launchUrl(telUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  /// Opens native SMS composer pre-populated with exact GPS coordinates for zero-data isolated zones.
  Future<bool> launchOfflineEmergencySms({
    required LocalIncidentItem incident,
    UserProfile? user,
  }) async {
    try {
      final phone = await resolveEmergencyTargetPhone(user: user);
      final hasCoords = incident.latitude != null && incident.longitude != null && !incident.locationUnavailable;
      final locText = hasCoords
          ? 'GPS: https://maps.google.com/?q=${incident.latitude!.toStringAsFixed(6)},${incident.longitude!.toStringAsFixed(6)}'
          : 'GPS lock pending';
      final userName = (user != null && user.fullName.isNotEmpty) ? user.fullName : 'Nexa User';
      final bloodInfo = (user?.bloodGroup != null && user!.bloodGroup!.isNotEmpty)
          ? ' | Blood: ${user.bloodGroup}'
          : '';
      final body = 'EMERGENCY SOS! $userName needs urgent help ($locText$bloodInfo). Please contact or dispatch emergency services immediately.';

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: {'body': body},
      );
      if (await canLaunchUrl(smsUri)) {
        return await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  /// Server-first Cellular Working Procedure with Zero-Internet Isolated Fallback:
  /// 1. Locks satellite GPS coordinates on device.
  /// 2. Persists emergency telemetry durably on device.
  /// 3. Immediately transmits to Cloud Server over Cellular Internet & triggers Server-Side Twilio alerts.
  /// 4. If Cellular Internet is down/unreachable in an isolated dead-zone, triggers direct GSM SMS fallback.
  Future<LocalIncidentItem> triggerEmergency({
    required String? token,
    UserProfile? user,
    String triggerType = 'manual_panic',
    bool triggerGsmFallbackIfOffline = true,
  }) async {
    _isTriggering = true;
    _lastDispatchedCount = 0;
    _lastSyncedToServer = false;
    _gsmFallbackUsed = false;
    notifyListeners();

    try {
      // 1. Satellite GPS fix (works in isolated places without Wi-Fi or cellular data)
      final loc = await _locationService.getCurrentLocation();
      _lastLocation = loc;

      // 2. Durable local record before network call
      final item = await _queueService.enqueueIncident(
        triggerType: triggerType,
        location: loc,
      );
      _lastIncident = item;
      await refreshQueueCount();

      // 3. Server-side Cloud Sync & Server-side Twilio SMS Dispatch over Cellular Internet
      int synced = 0;
      if (token != null) {
        synced = await flushOfflineQueue(token);
      }
      _lastSyncedToServer = synced > 0;

      // 4. Isolated dead-zone GSM SMS fallback if server is unreachable / offline
      if (!_lastSyncedToServer && triggerGsmFallbackIfOffline) {
        _gsmFallbackUsed = await launchOfflineEmergencySms(
          incident: item,
          user: user,
        );
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

      // Server-side emergency SMS/Voice alert broadcast for each synced incident
      int totalDispatched = 0;
      for (final incId in result.syncedIncidentIds) {
        try {
          final alertRes = await _apiService.dispatchAlerts(token, incidentId: incId);
          if (alertRes['dispatched_count'] != null) {
            totalDispatched += (alertRes['dispatched_count'] as num).toInt();
          }
        } catch (_) {
          // Server will retry or display in Guardian portal
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
