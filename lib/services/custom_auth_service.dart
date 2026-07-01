// lib/services/custom_auth_service.dart
// Dịch vụ xử lý toàn bộ xác thực cục bộ (Offline Auth) qua SharedPreferences
// Giúp ứng dụng hoạt động độc lập không cần kết nối mạng công ty Spro

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

/// Dịch vụ xử lý xác thực offline cục bộ lưu trữ qua SharedPreferences
class CustomAuthService {
  // Danh sách các username hoặc email được cấu hình quyền Admin cục bộ
  static const List<String> adminList = [
    'admin',
    'yuukiasuma12@gmail.com'
    // Bạn có thể thêm email Google hoặc username của bạn vào đây để làm Admin cục bộ
    // Ví dụ: 'huongg.spro@gmail.com',
  ];

  static const String _tokenKey = 'custom_auth_token';
  static const String _usersDbKey = 'otruyen_offline_users_db';
  static const String _googlePhotoKey = 'google_photo_url';

  /// Sinh username hợp lệ từ email Google
  static String _buildGoogleUsername(String email) {
    final localPart = email.split('@').first.toLowerCase();
    final normalized = localPart.replaceAll(RegExp(r'[^a-z0-9._]'), '_');
    final safe = normalized.isEmpty ? 'google_user' : normalized;
    final limited = safe.length > 24 ? safe.substring(0, 24) : safe;
    return 'g_$limited';
  }

  /// Sinh username dự phòng ổn định theo email
  static String _buildGoogleFallbackUsername(String email) {
    final base = _buildGoogleUsername(email);
    final hash = email.hashCode.abs().toString();
    final suffix = hash.length > 6 ? hash.substring(0, 6) : hash;
    return '${base}_$suffix';
  }

  /// Giải mã JWT payload cục bộ để đọc thông tin (role, username)
  static Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};

      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Sinh token giả lập JWT chứa payload được mã hóa Base64
  static String _generateFakeToken(String username, String role) {
    final payloadMap = {
      'role': role,
      'username': username,
      'exp': DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch ~/ 1000,
    };
    final payloadJson = json.encode(payloadMap);
    final payloadBase64 = base64Url.encode(utf8.encode(payloadJson)).replaceAll('=', '');
    return 'fakeheader.$payloadBase64.fakesignature';
  }

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

  /// Đọc cơ sở dữ liệu user offline từ SharedPreferences
  static Future<Map<String, dynamic>> _getUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersDbKey);
      if (usersJson == null) {
        final defaultDb = {
          'admin': {
            'id': 'user_admin',
            'username': 'admin',
            'password': '123',
            'fullname': 'Spro Admin',
            'phone': '0123456789',
            'role': 'admin',
            'avatar': null,
            'isVipActive': true,
            'vipExpiredAt': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          },
          'member': {
            'id': 'user_member',
            'username': 'member',
            'password': '123',
            'fullname': 'Spro Member',
            'phone': '0987654321',
            'role': 'member',
            'avatar': null,
            'isVipActive': false,
            'vipExpiredAt': null,
          }
        };
        await prefs.setString(_usersDbKey, json.encode(defaultDb));
        return defaultDb;
      }
      return json.decode(usersJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Lỗi đọc db user offline: $e');
      return {};
    }
  }

  /// Ghi cơ sở dữ liệu user offline vào SharedPreferences
  static Future<void> _saveUsers(Map<String, dynamic> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usersDbKey, json.encode(users));
    } catch (e) {
      debugPrint('❌ Lỗi ghi db user offline: $e');
    }
  }

  /// Chuyển đổi dữ liệu thô thành đối tượng AppUser
  static AppUser _buildAppUser(Map<String, dynamic> userData, String token) {
    return AppUser(
      id: userData['id']?.toString() ?? userData['username']?.toString() ?? '',
      username: userData['username']?.toString() ?? '',
      fullname: userData['fullname']?.toString(),
      phone: userData['phone']?.toString(),
      avatar: userData['avatar']?.toString(),
      role: userRoleFromString(userData['role']?.toString()),
      token: token,
      isVipActive: userData['isVipActive'] == true,
      vipExpiredAt: userData['vipExpiredAt'] != null
          ? DateTime.tryParse(userData['vipExpiredAt'].toString())
          : null,
    );
  }

  /// Đăng nhập cục bộ (Offline)
  static Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    debugPrint('🔑 Auth offline: Đăng nhập với username=$cleanUsername');

    final users = await _getUsers();
    if (!users.containsKey(cleanUsername)) {
      throw const AuthException('Tài khoản không tồn tại trên thiết bị');
    }

    final userData = users[cleanUsername] as Map<String, dynamic>;
    if (userData['password'] != password) {
      throw const AuthException('Sai tài khoản hoặc mật khẩu');
    }

    final token = _generateFakeToken(cleanUsername, userData['role']?.toString() ?? 'member');
    await saveToken(token);
    
    debugPrint('✅ Auth offline: Đăng nhập thành công - $cleanUsername');
    return _buildAppUser(userData, token);
  }

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

  /// Đăng nhập bằng Google (Google Auth thật)
  static Future<AppUser> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Đã hủy đăng nhập Google.');
      }
      return _handleGoogleUser(googleUser);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Lỗi đăng nhập Google: $e');
    }
  }

  /// Xử lý logic đăng nhập/đăng ký tài khoản Google sau khi lấy thông tin thành công
  static Future<AppUser> _handleGoogleUser(GoogleSignInAccount googleUser) async {
    final email = googleUser.email;
    final displayName = googleUser.displayName ?? 'Google User';
    final googlePhotoUrl = googleUser.photoUrl;
    
    final password = 'G_${email}_Spro_123!';
    final primaryUsername = _buildGoogleUsername(email);
    final fallbackUsername = _buildGoogleFallbackUsername(email);

    final role = _determineGoogleUserRole(email, primaryUsername, fallbackUsername);

    try {
      final user = await _loginOfflineForGoogle(username: primaryUsername, password: password, role: role);
      await saveGooglePhotoUrl(googlePhotoUrl);
      return user;
    } on AuthException {
      final user = await _registerGoogleOffline(primaryUsername, fallbackUsername, password, displayName, role);
      await saveGooglePhotoUrl(googlePhotoUrl);
      return user;
    }
  }

  /// Xác định vai trò của tài khoản Google dựa trên adminList
  static String _determineGoogleUserRole(String email, String primary, String fallback) {
    if (adminList.contains(email) || adminList.contains(primary) || adminList.contains(fallback)) {
      return 'admin';
    }
    return 'member';
  }

  /// Đăng ký tài khoản Google mới offline (có thử tên phụ nếu trùng)
  static Future<AppUser> _registerGoogleOffline(
    String primary,
    String fallback,
    String password,
    String displayName,
    String role,
  ) async {
    try {
      return await _registerOfflineForGoogle(
        username: primary,
        password: password,
        fullname: displayName,
        role: role,
      );
    } on AuthException {
      return await _registerOfflineForGoogle(
        username: fallback,
        password: password,
        fullname: displayName,
        role: role,
      );
    }
  }

  /// Đăng nhập offline chuyên dùng cho tài khoản Google (cập nhật role nếu đổi cấu hình)
  static Future<AppUser> _loginOfflineForGoogle({
    required String username,
    required String password,
    required String role,
  }) async {
    final users = await _getUsers();
    if (!users.containsKey(username)) {
      throw const AuthException('Tài khoản không tồn tại');
    }

    final userData = users[username] as Map<String, dynamic>;
    if (userData['password'] != password) {
      throw const AuthException('Sai mật khẩu');
    }

    userData['role'] = role;
    users[username] = userData;
    await _saveUsers(users);

    final token = _generateFakeToken(username, role);
    await saveToken(token);
    return _buildAppUser(userData, token);
  }

  /// Đăng ký offline chuyên dùng cho tài khoản Google
  static Future<AppUser> _registerOfflineForGoogle({
    required String username,
    required String password,
    String? fullname,
    required String role,
  }) async {
    final users = await _getUsers();
    if (users.containsKey(username)) {
      throw const AuthException('Tài khoản đã tồn tại');
    }

    final newUser = {
      'id': 'user_${username}_${DateTime.now().millisecondsSinceEpoch}',
      'username': username,
      'password': password,
      'fullname': fullname ?? username,
      'phone': null,
      'role': role,
      'avatar': null,
      'isVipActive': role == 'admin',
      'vipExpiredAt': role == 'admin' ? DateTime.now().add(const Duration(days: 365)).toIso8601String() : null,
    };

    users[username] = newUser;
    await _saveUsers(users);

    final token = _generateFakeToken(username, role);
    await saveToken(token);
    return _buildAppUser(newUser, token);
  }

  /// Đăng ký tài khoản cục bộ (Offline)
  static Future<AppUser> register({
    required String username,
    required String password,
    String? fullname,
    String? phone,
  }) async {
    final cleanUsername = username.trim();
    debugPrint('📝 Auth offline: Đăng ký username=$cleanUsername');

    final users = await _getUsers();
    if (users.containsKey(cleanUsername)) {
      throw const AuthException('Tài khoản đã tồn tại trên thiết bị');
    }

    final role = adminList.contains(cleanUsername) ? 'admin' : 'member';

    final newUser = {
      'id': 'user_${cleanUsername}_${DateTime.now().millisecondsSinceEpoch}',
      'username': cleanUsername,
      'password': password,
      'fullname': fullname?.trim() ?? cleanUsername,
      'phone': phone?.trim(),
      'role': role,
      'avatar': null,
      'isVipActive': role == 'admin',
      'vipExpiredAt': role == 'admin' ? DateTime.now().add(const Duration(days: 365)).toIso8601String() : null,
    };

    users[cleanUsername] = newUser;
    await _saveUsers(users);

    final token = _generateFakeToken(cleanUsername, role);
    await saveToken(token);

    debugPrint('✅ Auth offline: Đăng ký thành công - $cleanUsername');
    return _buildAppUser(newUser, token);
  }

  /// Lấy thông tin user hiện tại từ token đã lưu (Khôi phục session offline)
  static Future<AppUser?> getMe() async {
    try {
      final token = await getStoredToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final payload = _decodeJwtPayload(token);
      final username = payload['username']?.toString();
      if (username == null || username.isEmpty) {
        await clearToken();
        return null;
      }

      final users = await _getUsers();
      if (!users.containsKey(username)) {
        await clearToken();
        return null;
      }

      final userData = users[username] as Map<String, dynamic>;
      debugPrint('✅ Auth offline: Khôi phục session thành công cho $username');
      return _buildAppUser(userData, token);
    } catch (e) {
      debugPrint('❌ Auth offline khôi phục session lỗi: $e');
      return null;
    }
  }

  /// Đăng xuất offline
  static Future<void> logout() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {
    } finally {
      await clearToken();
      await clearGooglePhotoUrl();
      debugPrint('✅ Auth offline: Đăng xuất thành công');
    }
  }

  /// Cập nhật thông tin profile cục bộ
  static Future<AppUser> updateProfile({
    required String token,
    String? fullname,
    String? phone,
  }) async {
    final payload = _decodeJwtPayload(token);
    final username = payload['username']?.toString();
    if (username == null || username.isEmpty) {
      throw const AuthException('Phiên đăng nhập không hợp lệ');
    }

    final users = await _getUsers();
    if (!users.containsKey(username)) {
      throw const AuthException('Tài khoản không tồn tại');
    }

    final userData = users[username] as Map<String, dynamic>;
    if (fullname != null) userData['fullname'] = fullname.trim();
    if (phone != null) userData['phone'] = phone.trim();

    users[username] = userData;
    await _saveUsers(users);

    debugPrint('✅ Auth offline: Cập nhật profile thành công cho $username');
    return _buildAppUser(userData, token);
  }

  /// Đổi mật khẩu cục bộ
  static Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final payload = _decodeJwtPayload(token);
    final username = payload['username']?.toString();
    if (username == null || username.isEmpty) {
      throw const AuthException('Phiên đăng nhập không hợp lệ');
    }

    final users = await _getUsers();
    if (!users.containsKey(username)) {
      throw const AuthException('Tài khoản không tồn tại');
    }

    final userData = users[username] as Map<String, dynamic>;
    if (userData['password'] != oldPassword) {
      throw const AuthException('Mật khẩu cũ không chính xác');
    }

    userData['password'] = newPassword;
    users[username] = userData;
    await _saveUsers(users);
    
    debugPrint('✅ Auth offline: Đổi mật khẩu thành công cho $username');
  }
}

/// Exception riêng cho lỗi xác thực cục bộ
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
