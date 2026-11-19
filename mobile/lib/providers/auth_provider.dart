import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../core/constants.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AuthStatus _status = AuthStatus.initial;
  String? _token;
  UserProfile? _user;
  String? _errorMessage;
  bool _isOfflineSession = false;

  AuthStatus get status => _status;
  String? get token => _token;
  UserProfile? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isOfflineSession => _isOfflineSession;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isTokenOffline => _token == null || _token!.startsWith('offline-') || _token!.contains('cached');

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _persistUserSafetyCache(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserCache, jsonEncode(profile.toJson()));

      if (profile.emergencyContactPhone != null && profile.emergencyContactPhone!.trim().isNotEmpty) {
        await prefs.setString(AppConstants.keyGuardianPhone, profile.emergencyContactPhone!.trim());
      }
      if (profile.emergencyContactName != null && profile.emergencyContactName!.trim().isNotEmpty) {
        await prefs.setString(AppConstants.keyGuardianName, profile.emergencyContactName!.trim());
      }
      if (profile.preferredPoliceHelpline.trim().isNotEmpty) {
        await prefs.setString(AppConstants.keyPreferredHelpline, profile.preferredPoliceHelpline.trim());
      }
      if (profile.safeWordPhrase != null && profile.safeWordPhrase!.trim().isNotEmpty) {
        await prefs.setString(AppConstants.keySafeWordPhrase, profile.safeWordPhrase!.trim());
      }
    } catch (_) {}
  }

  Future<void> initializeAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(AppConstants.keyToken);

      if (savedToken != null && savedToken.isNotEmpty && !savedToken.startsWith('offline-')) {
        _token = savedToken;
        try {
          _user = await _apiService.getProfile(savedToken);
          _isOfflineSession = false;
          await _persistUserSafetyCache(_user!);
          _status = AuthStatus.authenticated;
          notifyListeners();
          return;
        } on ApiException catch (e) {
          if (e.statusCode == 401 || e.statusCode == 403) {
            // Token expired or invalid: attempt automatic background re-authentication
            final reauthed = await syncOrReauthenticate();
            if (reauthed) return;
          }
          await _restoreCachedProfile(prefs);
        } catch (_) {
          await _restoreCachedProfile(prefs);
        }
      } else {
        // If offline token or cached session, attempt to promote to real server JWT
        await _restoreCachedProfile(prefs);
        await syncOrReauthenticate();
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Automatically registers or logs in with stored credentials to obtain a real server JWT
  Future<bool> syncOrReauthenticate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(AppConstants.keySavedEmail) ?? _user?.email;
      final password = prefs.getString(AppConstants.keySavedPassword);

      if (email == null || email.trim().isEmpty) return false;

      // 1. Attempt login with saved credentials
      if (password != null && password.isNotEmpty) {
        try {
          final serverToken = await _apiService.login(email.trim(), password);
          _token = serverToken;
          await prefs.setString(AppConstants.keyToken, serverToken);
          _user = await _apiService.getProfile(serverToken);
          _isOfflineSession = false;
          await _persistUserSafetyCache(_user!);
          _status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        } on ApiException catch (e) {
          // If server returns 401/404, user may not exist on Render database yet
          if ((e.statusCode == 401 || e.statusCode == 404) && _user != null) {
            try {
              await _apiService.register(
                email: email.trim(),
                password: password,
                fullName: _user!.fullName.isNotEmpty ? _user!.fullName : 'Protected User',
                phoneNumber: _user!.phoneNumber.isNotEmpty ? _user!.phoneNumber : '9999999999',
                age: _user!.age,
                emergencyContactName: _user!.emergencyContactName ?? prefs.getString(AppConstants.keyGuardianName),
                emergencyContactPhone: _user!.emergencyContactPhone ?? prefs.getString(AppConstants.keyGuardianPhone),
                emergencyContactRelation: _user!.emergencyContactRelation,
                homeAddress: _user!.homeAddress,
                cityPoliceJurisdiction: _user!.cityPoliceJurisdiction,
                preferredPoliceHelpline: _user!.preferredPoliceHelpline,
                bloodGroup: _user!.bloodGroup,
                medicalNotes: _user!.medicalNotes,
                safeWordPhrase: _user!.safeWordPhrase,
              );

              final serverToken = await _apiService.login(email.trim(), password);
              _token = serverToken;
              await prefs.setString(AppConstants.keyToken, serverToken);
              _user = await _apiService.getProfile(serverToken);
              _isOfflineSession = false;
              await _persistUserSafetyCache(_user!);
              _status = AuthStatus.authenticated;
              notifyListeners();
              return true;
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _restoreCachedProfile(SharedPreferences prefs) async {
    final cachedRaw = prefs.getString(AppConstants.keyUserCache);
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        _user = UserProfile.fromJson(jsonDecode(cachedRaw) as Map<String, dynamic>);
        _isOfflineSession = true;
        _token = prefs.getString(AppConstants.keyToken) ?? 'cached-guardian-session';
        _status = AuthStatus.authenticated;
        return;
      } catch (_) {}
    }

    final safeWord = prefs.getString(AppConstants.keySafeWordPhrase) ?? 'help nexa';
    _user = UserProfile(
      id: 'offline-guardian-session',
      email: prefs.getString(AppConstants.keySavedEmail) ?? '',
      fullName: 'Nexa Protected User',
      phoneNumber: '',
      isActive: true,
      isVerified: true,
      phoneVerified: true,
      createdAt: '',
      emergencyContactName: prefs.getString(AppConstants.keyGuardianName),
      emergencyContactPhone: prefs.getString(AppConstants.keyGuardianPhone),
      preferredPoliceHelpline: prefs.getString(AppConstants.keyPreferredHelpline) ?? '112',
      safeWordPhrase: safeWord,
    );
    _token = 'offline-session-token';
    _isOfflineSession = true;
    _status = AuthStatus.authenticated;
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySavedEmail, email.trim());
    await prefs.setString(AppConstants.keySavedPassword, password);

    try {
      final token = await _apiService.login(email, password);
      _token = token;
      await prefs.setString(AppConstants.keyToken, token);

      _user = await _apiService.getProfile(token);
      _isOfflineSession = false;
      await _persistUserSafetyCache(_user!);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      // Offline fallback: check local profile cache
      final cachedRaw = prefs.getString(AppConstants.keyUserCache);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        try {
          final cached = UserProfile.fromJson(jsonDecode(cachedRaw) as Map<String, dynamic>);
          if (cached.email.toLowerCase().trim() == email.trim().toLowerCase()) {
            _user = cached;
            _token = prefs.getString(AppConstants.keyToken) ?? 'cached-offline-token';
            _isOfflineSession = true;
            _status = AuthStatus.authenticated;
            notifyListeners();
            return true;
          }
        } catch (_) {}
      }

      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    int? age,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? homeAddress,
    String? cityPoliceJurisdiction,
    String? preferredPoliceHelpline,
    String? bloodGroup,
    String? medicalNotes,
    String? safeWordPhrase,
    bool? policeDispatchConsent,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySavedEmail, email.trim());
    await prefs.setString(AppConstants.keySavedPassword, password);

    final safeWord = (safeWordPhrase != null && safeWordPhrase.trim().isNotEmpty)
        ? safeWordPhrase.trim()
        : 'help nexa';

    // 1. Immediately record all guardian and safety telemetry in local device storage
    if (emergencyContactPhone != null && emergencyContactPhone.trim().isNotEmpty) {
      await prefs.setString(AppConstants.keyGuardianPhone, emergencyContactPhone.trim());
    }
    if (emergencyContactName != null && emergencyContactName.trim().isNotEmpty) {
      await prefs.setString(AppConstants.keyGuardianName, emergencyContactName.trim());
    }
    if (preferredPoliceHelpline != null && preferredPoliceHelpline.trim().isNotEmpty) {
      await prefs.setString(AppConstants.keyPreferredHelpline, preferredPoliceHelpline.trim());
    }
    await prefs.setString(AppConstants.keySafeWordPhrase, safeWord);

    // 2. Attempt online registration with Cloud Server
    bool onlineSuccess = false;
    try {
      await _apiService.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        age: age,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        emergencyContactRelation: emergencyContactRelation,
        homeAddress: homeAddress,
        cityPoliceJurisdiction: cityPoliceJurisdiction,
        preferredPoliceHelpline: preferredPoliceHelpline,
        bloodGroup: bloodGroup,
        medicalNotes: medicalNotes,
        safeWordPhrase: safeWord,
        policeDispatchConsent: policeDispatchConsent,
      );

      onlineSuccess = await login(email, password);
    } catch (_) {
      onlineSuccess = false;
    }

    if (onlineSuccess) {
      return true;
    }

    // 3. Fallback: activate local protected profile immediately
    final localProfile = UserProfile(
      id: 'local-protected-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim(),
      isActive: true,
      isVerified: true,
      phoneVerified: true,
      createdAt: DateTime.now().toIso8601String(),
      safeWordPhrase: safeWord,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation,
      homeAddress: homeAddress,
      cityPoliceJurisdiction: cityPoliceJurisdiction,
      preferredPoliceHelpline: preferredPoliceHelpline ?? '112',
      bloodGroup: bloodGroup,
      medicalNotes: medicalNotes,
      age: age,
    );

    _token = 'offline-session-token-${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(AppConstants.keyToken, _token!);
    _user = localProfile;
    _isOfflineSession = true;
    await _persistUserSafetyCache(localProfile);

    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();

    // Trigger background registration sync attempt
    syncOrReauthenticate();

    return true;
  }

  Future<void> refreshProfile() async {
    if (_token == null) return;
    if (_token!.startsWith('offline-')) {
      await syncOrReauthenticate();
      return;
    }
    try {
      _user = await _apiService.getProfile(_token!);
      _isOfflineSession = false;
      await _persistUserSafetyCache(_user!);
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final reauthed = await syncOrReauthenticate();
        if (!reauthed) {
          await logout();
        }
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyUserCache);
    await prefs.remove(AppConstants.keySavedPassword);
    _token = null;
    _user = null;
    _errorMessage = null;
    _isOfflineSession = false;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
