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
  bool get isAuthenticated => _status == AuthStatus.authenticated && _token != null;

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

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        try {
          _user = await _apiService.getProfile(savedToken);
          _isOfflineSession = false;
          await _persistUserSafetyCache(_user!);
          _status = AuthStatus.authenticated;
        } on ApiException catch (e) {
          if (e.statusCode == 401 || e.statusCode == 403) {
            await prefs.remove(AppConstants.keyToken);
            _token = null;
            _user = null;
            _status = AuthStatus.unauthenticated;
          } else {
            // Isolated dead-zone or temporary server error: keep user authenticated using cached profile
            await _restoreCachedProfile(prefs);
          }
        } catch (_) {
          // Zero-internet isolated area: keep protected session active from local cache
          await _restoreCachedProfile(prefs);
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<void> _restoreCachedProfile(SharedPreferences prefs) async {
    final cachedRaw = prefs.getString(AppConstants.keyUserCache);
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        _user = UserProfile.fromJson(jsonDecode(cachedRaw) as Map<String, dynamic>);
        _isOfflineSession = true;
        _status = AuthStatus.authenticated;
        return;
      } catch (_) {}
    }
    // Even without cached JSON, if token exists, preserve emergency access so SOS remains usable
    _user = UserProfile(
      id: 'offline-guardian-session',
      email: '',
      fullName: 'Nexa Protected User',
      phoneNumber: '',
      isActive: true,
      isVerified: true,
      phoneVerified: true,
      createdAt: '',
      emergencyContactName: prefs.getString(AppConstants.keyGuardianName),
      emergencyContactPhone: prefs.getString(AppConstants.keyGuardianPhone),
      preferredPoliceHelpline: prefs.getString(AppConstants.keyPreferredHelpline) ?? '112',
      safeWordPhrase: prefs.getString(AppConstants.keySafeWordPhrase),
    );
    _isOfflineSession = true;
    _status = AuthStatus.authenticated;
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _apiService.login(email, password);
      _token = token;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyToken, token);

      _user = await _apiService.getProfile(token);
      _isOfflineSession = false;
      await _persistUserSafetyCache(_user!);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
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

    try {
      final prefs = await SharedPreferences.getInstance();
      if (emergencyContactPhone != null && emergencyContactPhone.trim().isNotEmpty) {
        await prefs.setString(AppConstants.keyGuardianPhone, emergencyContactPhone.trim());
      }
      if (emergencyContactName != null && emergencyContactName.trim().isNotEmpty) {
        await prefs.setString(AppConstants.keyGuardianName, emergencyContactName.trim());
      }
      if (preferredPoliceHelpline != null && preferredPoliceHelpline.trim().isNotEmpty) {
        await prefs.setString(AppConstants.keyPreferredHelpline, preferredPoliceHelpline.trim());
      }
      if (safeWordPhrase != null && safeWordPhrase.trim().isNotEmpty) {
        await prefs.setString(AppConstants.keySafeWordPhrase, safeWordPhrase.trim());
      }

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
        safeWordPhrase: safeWordPhrase,
        policeDispatchConsent: policeDispatchConsent,
      );

      // Auto login upon successful registration
      return await login(email, password);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (_token == null) return;
    try {
      _user = await _apiService.getProfile(_token!);
      _isOfflineSession = false;
      await _persistUserSafetyCache(_user!);
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
      }
    } catch (_) {
      // Preserve offline cellular session silently
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyUserCache);
    _token = null;
    _user = null;
    _errorMessage = null;
    _isOfflineSession = false;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
