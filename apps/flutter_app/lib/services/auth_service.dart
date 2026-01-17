import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'device_service.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DeviceService _deviceService = DeviceService();
  static const String _tokenKey = 'auth_token';

  /// Get the stored JWT or register with the server if not found
  Future<String?> getOrRegister(String baseUrl) async {
    // Try to get existing token from secure storage
    String? token = await _storage.read(key: _tokenKey);
    if (token != null) {
      debugPrint('✅ Using stored auth token');
      return token;
    }

    // No token found, register with server
    debugPrint('🚀 No auth token found, registering device...');
    try {
      final deviceId = await _deviceService.getDeviceId();
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['token'];

        if (token != null) {
          await _storage.write(key: _tokenKey, value: token);
          debugPrint('✅ Successfully registered and stored token');
          return token;
        }
      } else {
        debugPrint(
            '❌ Failed to register: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error during registration: $e');
    }

    return null;
  }

  /// Get the stored JWT token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Clear the stored JWT token
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }
}
