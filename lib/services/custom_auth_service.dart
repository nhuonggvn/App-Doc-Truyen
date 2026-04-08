// lib/services/custom_auth_service.dart
// Service xử lý toàn bộ xác thực qua Manga App REST API
// Base URL: http://192.168.3.237:8180/api/v1

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class CustomAuthService {
  // ─────────────────────────────────────────────────────────
  // CẤU HÌNH
  // ─────────────────────────────────────────────────────────

  static const String _baseUrl = 'http://192.168.3.237:8180/api/v1';
  static const String _tokenKey = 'custom_auth_token';
  static const Duration _timeout = Duration(seconds: 15);

  // ─────────────────────────────────────────────────────────
  // QUẢN LÝ TOKEN (SharedPreferences)
  // ─────────────────────────────────────────────────────────

  /// Lưu JWT token vào SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Lấy JWT token đã lưu
  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Xóa token khi đăng xuất
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ─────────────────────────────────────────────────────────
  // HTTP HELPER
  // ─────────────────────────────────────────────────────────

  /// Tạo header chuẩn cho REQUEST KHÔNG cần auth
  static Map<String, String> _publicHeaders() {
    return {'Content-Type': 'application/json; charset=utf-8'};
  }

  /// Tạo header chuẩn cho REQUEST CẦN auth (gắn Bearer token)
  static Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// Parse response body an toàn (handle encoding)
  static Map<String, dynamic> _parseBody(http.Response response) {
    return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────────
  // AUTH APIs
  // ─────────────────────────────────────────────────────────

  /// Đăng nhập: POST /auth/login
  /// Trả về AppUser nếu thành công, ném Exception nếu thất bại
  static Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Auth: Đăng nhập với username=$username');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: _publicHeaders(),
            body: json.encode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      final body = _parseBody(response);
      debugPrint('🔐 Auth Login response: ${response.statusCode}');

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final user = AppUser.fromLoginResponse(data);

        // Lưu token để dùng lần sau
        await saveToken(user.token);
        debugPrint(
          '✅ Auth: Đăng nhập thành công - ${user.username} (${user.roleLabel})',
        );
        return user;
      } else {
        final message =
            body['message'] as String? ?? 'Sai tài khoản hoặc mật khẩu';
        throw AuthException(message);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Auth Login lỗi: $e');
      throw AuthException('Không thể kết nối đến máy chủ. Vui lòng thử lại.');
    }
  }

  /// Đăng ký: POST /auth/register
  /// Trả về AppUser nếu thành công
  static Future<AppUser> register({
    required String username,
    required String password,
    String? fullname,
    String? phone,
  }) async {
    try {
      debugPrint('📝 Auth: Đăng ký username=$username');

      final body = <String, dynamic>{
        'username': username.trim(),
        'password': password,
      };
      if (fullname != null && fullname.isNotEmpty)
        body['fullname'] = fullname.trim();
      if (phone != null && phone.isNotEmpty) body['phone'] = phone.trim();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: _publicHeaders(),
            body: json.encode(body),
          )
          .timeout(_timeout);

      final responseBody = _parseBody(response);
      debugPrint('📝 Auth Register response: ${response.statusCode}');

      if (response.statusCode == 201 && responseBody['success'] == true) {
        final data = responseBody['data'] as Map<String, dynamic>;
        final user = AppUser.fromLoginResponse(data);

        await saveToken(user.token);
        debugPrint('✅ Auth: Đăng ký thành công - ${user.username}');
        return user;
      } else {
        final message =
            responseBody['message'] as String? ?? 'Đăng ký thất bại';
        throw AuthException(message);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Auth Register lỗi: $e');
      throw AuthException('Không thể kết nối đến máy chủ. Vui lòng thử lại.');
    }
  }

  /// Lấy thông tin user hiện tại từ token đã lưu: GET /auth/me
  /// Dùng để khôi phục session khi mở lại app
  static Future<AppUser?> getMe() async {
    try {
      final token = await getStoredToken();
      if (token == null || token.isEmpty) {
        debugPrint('🔐 Auth: Không có token đã lưu');
        return null;
      }

      debugPrint('🔐 Auth: Khôi phục session từ token...');
      final response = await http
          .get(Uri.parse('$_baseUrl/auth/me'), headers: _authHeaders(token))
          .timeout(_timeout);

      final body = _parseBody(response);

      if (response.statusCode == 200 && body['success'] == true) {
        final userJson = body['data'] as Map<String, dynamic>;
        final user = AppUser.fromMeResponse(userJson, token);
        debugPrint(
          '✅ Auth: Khôi phục session thành công - ${user.username} (${user.roleLabel})',
        );
        return user;
      } else {
        // Token hết hạn hoặc không hợp lệ
        debugPrint('⚠️ Auth: Token hết hạn hoặc không hợp lệ, xóa token');
        await clearToken();
        return null;
      }
    } catch (e) {
      debugPrint('❌ Auth GetMe lỗi: $e');
      // Không throw exception ở đây - chỉ trả null để app vẫn chạy ở chế độ Guest
      return null;
    }
  }

  /// Đăng xuất: POST /auth/logout + xóa token local
  static Future<void> logout() async {
    try {
      final token = await getStoredToken();
      if (token != null) {
        // Gọi API logout để server invalidate token (nếu BE hỗ trợ)
        await http
            .post(
              Uri.parse('$_baseUrl/auth/logout'),
              headers: _authHeaders(token),
            )
            .timeout(_timeout);
        debugPrint('✅ Auth: Đã logout khỏi server');
      }
    } catch (e) {
      // Dù server lỗi vẫn xóa token local
      debugPrint('⚠️ Auth Logout server lỗi: $e - vẫn xóa token local');
    } finally {
      await clearToken();
    }
  }

  /// Cập nhật thông tin profile: PUT /auth/profile
  static Future<AppUser> updateProfile({
    required String token,
    String? fullname,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullname != null) body['fullname'] = fullname.trim();
      if (phone != null) body['phone'] = phone.trim();

      final response = await http
          .put(
            Uri.parse('$_baseUrl/auth/profile'),
            headers: _authHeaders(token),
            body: json.encode(body),
          )
          .timeout(_timeout);

      final responseBody = _parseBody(response);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final userJson = responseBody['data'] as Map<String, dynamic>;
        return AppUser.fromMeResponse(userJson, token);
      } else {
        final message =
            responseBody['message'] as String? ?? 'Cập nhật thất bại';
        throw AuthException(message);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Lỗi kết nối: $e');
    }
  }

  /// Đổi mật khẩu: PUT /auth/change-password
  static Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/auth/change-password'),
            headers: _authHeaders(token),
            body: json.encode({
              'oldPassword': oldPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(_timeout);

      final body = _parseBody(response);

      if (response.statusCode != 200 || body['success'] != true) {
        final message = body['message'] as String? ?? 'Đổi mật khẩu thất bại';
        throw AuthException(message);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Lỗi kết nối: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────
// CUSTOM EXCEPTION
// ─────────────────────────────────────────────────────────

/// Exception riêng cho lỗi xác thực - dùng message để hiển thị lên UI
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
