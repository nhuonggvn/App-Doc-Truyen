// lib/services/custom_auth_service.dart
// Service xử lý xác thực qua Custom BE API dành riêng cho Admin/Editor

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CustomAuthService {
  // Thay đổi IP này tương ứng với máy chủ của bạn
  static const String baseUrl = 'http://192.168.3.237:8180/api/v1';

  static const String _tokenKey = 'admin_jwt_token';

  /// Đăng nhập Admin/Editor qua REST API
  /// Trả về Map chứa 'user' (Map) và 'token' (String) hoặc null nếu thất bại
  static Future<Map<String, dynamic>?> loginManager(
    String email,
    String password,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/login-manager');
      debugPrint('🔐 CustomAuth: Đang đăng nhập Manager - $uri');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];
          final token = data['token']?.toString();

          if (token != null) {
            await saveToken(token);
            debugPrint('✅ CustomAuth: Đăng nhập thành công, đã lưu token.');
            return {'user': data['user'], 'token': token};
          }
        }
      }

      debugPrint(
        '❌ CustomAuth: Đăng nhập thất bại - Status: ${response.statusCode}',
      );
      return null;
    } catch (e) {
      debugPrint('❌ CustomAuth: Lỗi kết nối API: $e');
      return null;
    }
  }

  /// Lấy thông tin Manager từ Token hiện tại (Dùng để khôi phục session)
  static Future<Map<String, dynamic>?> getMe() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final uri = Uri.parse('$baseUrl/auth/me');
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return jsonData['data'] as Map<String, dynamic>;
        }
      }

      // Nếu token hết hạn hoặc lỗi, xoá sạch
      if (response.statusCode == 401) {
        await clearToken();
      }
      return null;
    } catch (e) {
      debugPrint('❌ CustomAuth: Lỗi khi lấy profile: $e');
      return null;
    }
  }

  /// Lưu JWT Token vào Local Storage
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Lấy JWT Token từ Local Storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Xoá token khi đăng xuất
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
