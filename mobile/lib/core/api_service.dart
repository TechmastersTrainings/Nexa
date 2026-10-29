import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'constants.dart';

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final bool isActive;
  final bool isVerified;
  final bool phoneVerified;
  final String createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.isActive,
    required this.isVerified,
    required this.phoneVerified,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'phone_number': phoneNumber,
    'is_active': isActive,
    'is_verified': isVerified,
    'phone_verified': phoneVerified,
    'created_at': createdAt,
  };
}

class TrustedContact {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String relationship;
  final int priorityOrder;
  final bool isVerified;
  final String createdAt;

  TrustedContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.priorityOrder,
    required this.isVerified,
    required this.createdAt,
  });

  factory TrustedContact.fromJson(Map<String, dynamic> json) {
    return TrustedContact(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      relationship: json['relationship'] as String? ?? 'Family',
      priorityOrder: json['priority_order'] as int? ?? 1,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;

  ApiService({String? customBaseUrl}) 
      : baseUrl = customBaseUrl ?? AppConstants.defaultApiBase;

  Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return data['access_token'] as String;
      } else {
        final detail = data['detail'];
        final msg = detail is String ? detail : 'Invalid email or password.';
        throw ApiException(msg, res.statusCode);
      }
    } on SocketException {
      throw ApiException('Cannot reach Nexa backend server. Verify network connection.');
    } on http.ClientException {
      throw ApiException('Network connection failed.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Login failed: ${e.toString()}');
    }
  }

  Future<UserProfile> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'full_name': fullName.trim(),
          'phone_number': phoneNumber.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        return UserProfile.fromJson(data);
      } else {
        final detail = data['detail'];
        String msg = 'Registration failed.';
        if (detail is String) {
          msg = detail;
        } else if (detail is List) {
          msg = detail.map((e) => e['msg'] ?? '').where((s) => s.isNotEmpty).join(', ');
        }
        throw ApiException(msg, res.statusCode);
      }
    } on SocketException {
      throw ApiException('Cannot reach Nexa backend server. Verify network connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Registration error: ${e.toString()}');
    }
  }

  Future<UserProfile> getProfile(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return UserProfile.fromJson(data);
      } else {
        final detail = data['detail'];
        throw ApiException(detail is String ? detail : 'Failed to retrieve profile.', res.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Profile fetch failed: ${e.toString()}');
    }
  }

  // --- Trusted Contacts ---
  Future<List<TrustedContact>> getContacts(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/contacts'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => TrustedContact.fromJson(e)).toList();
      } else {
        final detail = jsonDecode(res.body)['detail'];
        throw ApiException(detail is String ? detail : 'Failed to fetch contacts.', res.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Contacts retrieval failed: ${e.toString()}');
    }
  }

  Future<TrustedContact> addContact(
    String token, {
    required String name,
    required String phoneNumber,
    required String relationship,
    required int priorityOrder,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/contacts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name.trim(),
          'phone_number': phoneNumber.trim(),
          'relationship': relationship,
          'priority_order': priorityOrder,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        return TrustedContact.fromJson(data);
      } else {
        final detail = data['detail'];
        throw ApiException(detail is String ? detail : 'Failed to add contact.', res.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Add contact failed: ${e.toString()}');
    }
  }

  Future<void> deleteContact(String token, String contactId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/contacts/$contactId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 204) {
        final detail = jsonDecode(res.body)['detail'];
        throw ApiException(detail is String ? detail : 'Failed to delete contact.', res.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Delete contact failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> syncIncidentBatch(String token, List<Map<String, dynamic>> incidents) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/incidents/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'incidents': incidents}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data;
      } else {
        final detail = data['detail'];
        throw ApiException(detail is String ? detail : 'Batch sync failed.', res.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Batch sync error: ${e.toString()}');
    }
  }
}
