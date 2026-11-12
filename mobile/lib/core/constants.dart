// Nexa AI Women Safety Platform - Constants & Configuration
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  static const String appName = 'Nexa AI Safety';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyToken = 'nexa_jwt_token';
  static const String keyUserCache = 'nexa_cached_user';
  static const String keyCustomApiBase = 'nexa_custom_api_base';
  static const String keyGuardianPhone = 'nexa_registered_guardian_phone';
  static const String keyGuardianName = 'nexa_registered_guardian_name';
  static const String keyPreferredHelpline = 'nexa_preferred_helpline';
  static const String keySafeWordPhrase = 'nexa_safe_word_phrase';

  // Cloud Endpoint (Cellular Mobile Data / Public Internet)
  static const String defaultRenderUrl = 'https://nexa-safety-api.onrender.com/api/v1';

  static String? _cachedApiBase;

  /// Returns true if the URL targets a local/private network (e.g. Local Wi-Fi / LAN / localhost),
  /// which is disabled because emergency protection operates over Cellular Data + Cloud Server.
  static bool isLocalOrPrivateUrl(String url) {
    final lower = url.trim().toLowerCase();
    if (lower.isEmpty) return false;
    final uri = Uri.tryParse(lower);
    final host = (uri?.host ?? lower).toLowerCase();
    if (host.isEmpty) return false;

    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '10.0.2.2' ||
        host.endsWith('.local') ||
        host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.').hasMatch(host)) {
      return true;
    }
    return false;
  }

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(keyCustomApiBase);
      if (saved != null && saved.trim().isNotEmpty) {
        if (isLocalOrPrivateUrl(saved)) {
          // Purge any legacy Local Wi-Fi address and enforce Cloud Cellular Server
          await prefs.remove(keyCustomApiBase);
          _cachedApiBase = null;
        } else {
          _cachedApiBase = saved.trim();
        }
      }
    } catch (_) {}
  }

  static String get defaultApiBase {
    if (_cachedApiBase != null &&
        _cachedApiBase!.trim().isNotEmpty &&
        !isLocalOrPrivateUrl(_cachedApiBase!)) {
      return _cachedApiBase!.trim();
    }
    return defaultRenderUrl;
  }

  static Future<bool> setApiBase(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.isEmpty || isLocalOrPrivateUrl(cleanUrl)) {
      return false;
    }
    if (!cleanUrl.startsWith('https://') && !cleanUrl.startsWith('http://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    if (!cleanUrl.endsWith('/api/v1')) {
      if (cleanUrl.endsWith('/')) {
        cleanUrl = '${cleanUrl}api/v1';
      } else {
        cleanUrl = '$cleanUrl/api/v1';
      }
    }
    _cachedApiBase = cleanUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyCustomApiBase, cleanUrl);
    } catch (_) {}
    return true;
  }
}
