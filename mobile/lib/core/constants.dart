// Nexa AI Women Safety Platform - Constants & Configuration
import 'dart:io';

class AppConstants {
  static const String appName = 'Nexa AI Safety';
  static const String appVersion = '1.0.0';

  // In Android Emulator, 10.0.2.2 points to host machine localhost.
  // On desktop / test environments, 127.0.0.1 is used.
  static String get defaultApiBase {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  // Storage Keys
  static const String keyToken = 'nexa_jwt_token';
  static const String keyUserCache = 'nexa_cached_user';
}
