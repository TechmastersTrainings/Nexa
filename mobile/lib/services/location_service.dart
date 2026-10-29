import 'package:geolocator/geolocator.dart';

class LocationData {
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DateTime? timestamp;
  final bool isUnavailable;
  final String? unavailableReason;

  LocationData({
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.timestamp,
    this.isUnavailable = false,
    this.unavailableReason,
  });

  factory LocationData.unavailable(String reason) {
    return LocationData(
      isUnavailable: true,
      unavailableReason: reason,
      timestamp: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy_meters': accuracyMeters,
    'location_timestamp': timestamp?.toUtc().toIso8601String(),
    'location_unavailable': isUnavailable,
  };
}

class LocationService {
  Future<LocationData> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationData.unavailable('Device location service is disabled');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationData.unavailable('Location permission denied by user');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationData.unavailable('Location permission denied permanently in OS settings');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        timestamp: position.timestamp.toUtc(),
        isUnavailable: false,
      );
    } catch (e) {
      return LocationData.unavailable('GPS fix failed: ${e.toString()}');
    }
  }
}
