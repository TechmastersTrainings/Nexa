// Nexa AI Women Safety Platform - Constants & Configuration
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  static const String appName = 'Nexa AI Safety';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyToken = 'nexa_jwt_token';
  static const String keyUserCache = 'nexa_cached_user';
  static const String keyCustomApiBase = 'nexa_custom_api_base';

  // Default Endpoints
  static const String defaultRenderUrl = 'https://nexa-safety-api.onrender.com/api/v1';
  static const String defaultLocalWifiUrl = 'http://192.168.1.10:8000/api/v1';

  static String? _cachedApiBase;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedApiBase = prefs.getString(keyCustomApiBase);
    } catch (_) {}
  }

  static String get defaultApiBase {
    if (_cachedApiBase != null && _cachedApiBase!.trim().isNotEmpty) {
      return _cachedApiBase!.trim();
    }
    // Default to the live Render cloud deployment URL
    return defaultRenderUrl;
  }

  static Future<void> setApiBase(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.isNotEmpty) {
      if (!cleanUrl.endsWith('/api/v1')) {
        if (cleanUrl.endsWith('/')) {
          cleanUrl = '${cleanUrl}api/v1';
        } else {
          cleanUrl = '$cleanUrl/api/v1';
        }
      }
    }
    _cachedApiBase = cleanUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyCustomApiBase, cleanUrl);
    } catch (_) {}
  }
}
