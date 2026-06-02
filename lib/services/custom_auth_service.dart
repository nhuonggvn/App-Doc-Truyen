// lib/services/custom_auth_service.dart
// Service xử lý toàn bộ xác thực qua Manga App REST API
// Base URL: http://192.168.3.237:8180/api/v1

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

class CustomAuthService {
  // ─────────────────────────────────────────────────────────
  // CẤU HÌNH
  // ─────────────────────────────────────────────────────────

  static const String _baseUrl = 'http://192.168.3.237:8180/api/v1';
  static const String _tokenKey = 'custom_auth_token';
  static const Duration _timeout = Duration(seconds: 15);

  /// Chuẩn hóa username từ email Google để phù hợp validate backend.
  /// Chỉ giữ chữ thường, số, dấu chấm và gạch dưới.
  static String _buildGoogleUsername(String email) {
    final localPart = email.split('@').first.toLowerCase();
    final normalized = localPart.replaceAll(RegExp(r'[^a-z0-9._]'), '_');
    final safe = normalized.isEmpty ? 'google_user' : normalized;
    final limited = safe.length > 24 ? safe.substring(0, 24) : safe;
    return 'g_$limited';
  }

  /// Sinh username dự phòng ổn định theo email để giảm xung đột trùng tên.
  static String _buildGoogleFallbackUsername(String email) {
    final base = _buildGoogleUsername(email);
    final hash = email.hashCode.abs().toString();
    final suffix = hash.length > 6 ? hash.substring(0, 6) : hash;
    return '${base}_$suffix';
  }

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
      debugPrint(' Auth: Đăng nhập với username=$username');

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
      debugPrint(' Auth Login response: ${response.statusCode}');

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final user = AppUser.fromLoginResponse(data);

        // Lưu token để dùng lần sau
        await saveToken(user.token);
        debugPrint(
          'Auth: Đăng nhập thành công - ${user.username} (${user.roleLabel})',
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
      debugPrint(' Auth Login lỗi: $e');
      throw AuthException('Không thể kết nối đến máy chủ. Vui lòng thử lại.');
    }
  }

  // Key SharedPreferences để lưu ảnh Google
  static const String _googlePhotoKey = 'google_photo_url';

  /// Lưu Google photo URL vào SharedPreferences
  static Future<void> saveGooglePhotoUrl(String? photoUrl) async {
    final prefs = await SharedPreferences.getInstance();
    if (photoUrl != null && photoUrl.isNotEmpty) {
      await prefs.setString(_googlePhotoKey, photoUrl);
    } else {
      await prefs.remove(_googlePhotoKey);
    }
  }

  /// Lấy Google photo URL đã lưu
  static Future<String?> getGooglePhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_googlePhotoKey);
  }

  /// Xóa Google photo URL khi đăng xuất
  static Future<void> clearGooglePhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_googlePhotoKey);
  }

  /// Đăng nhập bằng Google
  /// (Mô phỏng: Dùng email Google làm username và tự sinh password)
  static Future<AppUser> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Đã hủy đăng nhập Google.');
      }

      final email = googleUser.email;
      final displayName = googleUser.displayName ?? 'Google User';
      // Lưu ảnh Google ngay tại đây để dùng sau
      final googlePhotoUrl = googleUser.photoUrl;
      final password = 'G_${email}_Spro_123!';
      final primaryUsername = _buildGoogleUsername(email);
      final fallbackUsername = _buildGoogleFallbackUsername(email);

      // Hàm nội bộ: đăng nhập + lưu ảnh Google
      Future<AppUser> loginAndSavePhoto(String username) async {
        final user = await login(username: username, password: password);
        // Lưu ảnh Google vào SharedPreferences để ProfileScreen dùng
        await saveGooglePhotoUrl(googlePhotoUrl);
        return user;
      }

      // Ưu tiên email trước nếu login bình thường
      final loginCandidates = <String>[email, primaryUsername];
      for (final username in loginCandidates) {
        try {
          debugPrint(' Auth: Thử đăng nhập Google với username=$username');
          return await loginAndSavePhoto(username);
        } on AuthException {
          // Bỏ qua để thử candidate tiếp theo.
        }
      }

      // Nếu chưa có tài khoản thì tạo mới.
      debugPrint(' Auth: Chưa có tài khoản Google, tiến hành đăng ký mới...');
      AppUser newUser;
      try {
        newUser = await register(
          username: primaryUsername,
          password: password,
          fullname: displayName,
        );
      } on AuthException {
        // Có thể trùng username, thử username dự phòng.
        debugPrint(
          ' Auth: Username Google chính bị trùng, thử username dự phòng...',
        );
        newUser = await register(
          username: fallbackUsername,
          password: password,
          fullname: displayName,
        );
      }
      // Lưu ảnh Google sau khi đăng ký thành công
      await saveGooglePhotoUrl(googlePhotoUrl);
      return newUser;
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('Auth Google lỗi: $e');
      throw AuthException('Lỗi đăng nhập Google: $e');
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
      debugPrint(' Auth: Đăng ký username=$username');

      final body = <String, dynamic>{
        'username': username.trim(),
        'password': password,
      };
      if (fullname != null && fullname.isNotEmpty) {
        body['fullname'] = fullname.trim();
      }
      if (phone != null && phone.isNotEmpty) body['phone'] = phone.trim();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: _publicHeaders(),
            body: json.encode(body),
          )
          .timeout(_timeout);

      final responseBody = _parseBody(response);
      debugPrint(' Auth Register response: ${response.statusCode}');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseBody['success'] == true) {
        final data = responseBody['data'] as Map<String, dynamic>;
        final user = AppUser.fromLoginResponse(data);

        await saveToken(user.token);
        debugPrint(' Auth: Đăng ký thành công - ${user.username}');
        return user;
      } else {
        final message =
            responseBody['message'] as String? ?? 'Đăng ký thất bại';
        throw AuthException(message);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint(' Auth Register lỗi: $e');
      throw AuthException('Không thể kết nối đến máy chủ. Vui lòng thử lại.');
    }
  }

  /// Lấy thông tin user hiện tại từ token đã lưu: GET /auth/me
  /// Dùng để khôi phục session khi mở lại app
  static Future<AppUser?> getMe() async {
    try {
      final token = await getStoredToken();
      if (token == null || token.isEmpty) {
        debugPrint(' Auth: Không có token đã lưu');
        return null;
      }

      debugPrint(' Auth: Khôi phục session từ token...');
      final response = await http
          .get(Uri.parse('$_baseUrl/auth/me'), headers: _authHeaders(token))
          .timeout(_timeout);

      final body = _parseBody(response);

      if (response.statusCode == 200 && body['success'] == true) {
        final userJson = body['data'] as Map<String, dynamic>;
        final user = AppUser.fromMeResponse(userJson, token);
        debugPrint(
          ' Auth: Khôi phục session thành công - ${user.username} (${user.roleLabel})',
        );
        return user;
      } else {
        // Token hết hạn hoặc không hợp lệ
        debugPrint(' Auth: Token hết hạn hoặc không hợp lệ, xóa token');
        await clearToken();
        return null;
      }
    } catch (e) {
      debugPrint(' Auth GetMe lỗi: $e');
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

      // Đăng xuất khỏi Google nếu đang dùng
      try {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (_) {}
    } catch (e) {
      // Dù server lỗi vẫn xóa token local
      debugPrint('⚠️ Auth Logout server lỗi: $e - vẫn xóa token local');
    } finally {
      // Xóa JWT token và ảnh Google
      await clearToken();
      await clearGooglePhotoUrl();
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
