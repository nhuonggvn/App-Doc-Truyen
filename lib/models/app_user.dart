// lib/models/app_user.dart
// Model người dùng - đồng bộ hoàn toàn với Manga App API Backend
// Response từ /auth/login & /auth/me: { id, username, fullname, phone, avatar }
// Role được decode từ JWT payload

import 'dart:convert';

// ─────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────

/// Vai trò người dùng trong hệ thống
enum UserRole {
  /// Khách chưa đăng nhập
  guest,

  /// Thành viên thường
  member,

  /// Thành viên VIP (đã mua gói)
  vip,

  /// Biên tập viên (tạo/sửa truyện, không quản lý user)
  editor,

  /// Quản trị viên (toàn quyền)
  admin,
}

// ─────────────────────────────────────────────────────────
// HELPER FUNCTIONS
// ─────────────────────────────────────────────────────────

/// Chuyển chuỗi role từ JWT/API sang enum
UserRole userRoleFromString(String? role) {
  switch (role?.toLowerCase()) {
    case 'admin':
      return UserRole.admin;
    case 'editor':
      return UserRole.editor;
    case 'vip':
      return UserRole.vip;
    case 'member':
      return UserRole.member;
    default:
      return UserRole.member;
  }
}

/// Chuyển enum sang chuỗi để lưu trữ
String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.editor:
      return 'editor';
    case UserRole.vip:
      return 'vip';
    case UserRole.member:
      return 'member';
    case UserRole.guest:
      return 'guest';
  }
}

/// Decode JWT token không cần verify signature (chỉ để đọc payload phía client)
/// Backend vẫn là nơi verify thật sự khi nhận request
Map<String, dynamic> _decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return {};

    // Base64url decode phần payload (phần thứ 2)
    String payload = parts[1];
    // Thêm padding nếu cần
    while (payload.length % 4 != 0) {
      payload += '=';
    }
    final decoded = utf8.decode(base64Url.decode(payload));
    return json.decode(decoded) as Map<String, dynamic>;
  } catch (e) {
    return {};
  }
}

// ─────────────────────────────────────────────────────────
// MODEL CHÍNH
// ─────────────────────────────────────────────────────────

/// Model đại diện cho người dùng đã xác thực
class AppUser {
  /// ID MongoDB từ Backend (ví dụ: "65d4c9f8a1b2c3d4e5f6g7h8")
  final String id;

  /// Tên đăng nhập (unique)
  final String username;

  /// Họ tên đầy đủ (optional)
  final String? fullname;

  /// Số điện thoại (optional)
  final String? phone;

  /// URL ảnh đại diện từ MinIO/CDN
  final String? avatar;

  /// Vai trò trong hệ thống (decode từ JWT hoặc set thủ công)
  final UserRole role;

  /// JWT Token dùng để xác thực các request tiếp theo
  final String token;

  /// Trạng thái VIP: có gói đang hoạt động hay không
  final bool isVipActive;

  /// Ngày hết hạn VIP (null nếu không có gói)
  final DateTime? vipExpiredAt;

  const AppUser({
    required this.id,
    required this.username,
    this.fullname,
    this.phone,
    this.avatar,
    this.role = UserRole.member,
    required this.token,
    this.isVipActive = false,
    this.vipExpiredAt,
  });

  // ─────────────────────────────────────────────────────────
  // FACTORY CONSTRUCTORS
  // ─────────────────────────────────────────────────────────

  /// Tạo AppUser từ response JSON của /auth/login hoặc /auth/register
  /// Response format: { "data": { "token": "...", "user": { "id", "username", ... } } }
  factory AppUser.fromLoginResponse(Map<String, dynamic> data) {
    final token = data['token'] as String? ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? {};

    // Decode role từ JWT payload
    final jwtPayload = _decodeJwtPayload(token);
    // Lấy role từ user info trước, nếu không có mới decode từ JWT
    final roleStr =
        (userJson['role']?.toString()) ??
        (userJson['Role']?.toString()) ??
        (jwtPayload['role']?.toString()) ??
        (jwtPayload['Role']?.toString());
    final role = userRoleFromString(roleStr);

    return AppUser(
      id: (userJson['id'] ?? userJson['_id'] ?? '').toString(),
      username: userJson['username'] as String? ?? '',
      fullname: userJson['fullname'] as String?,
      phone: userJson['phone'] as String?,
      avatar: userJson['avatar'] as String?,
      role: role,
      token: token,
    );
  }

  /// Tạo AppUser từ response JSON của /auth/me
  /// Cần truyền token đang dùng vào để giữ lại
  factory AppUser.fromMeResponse(
    Map<String, dynamic> userJson,
    String currentToken,
  ) {
    // Decode role từ JWT
    final jwtPayload = _decodeJwtPayload(currentToken);
    // Lấy role từ userJson trước, nếu không có mới decode từ JWT
    final roleStr =
        (userJson['role']?.toString()) ??
        (userJson['Role']?.toString()) ??
        (jwtPayload['role']?.toString()) ??
        (jwtPayload['Role']?.toString());
    final role = userRoleFromString(roleStr);

    return AppUser(
      id: (userJson['id'] ?? userJson['_id'] ?? '').toString(),
      username: userJson['username'] as String? ?? '',
      fullname: userJson['fullname'] as String?,
      phone: userJson['phone'] as String?,
      avatar: userJson['avatar'] as String?,
      role: role,
      token: currentToken,
    );
  }

  /// Tạo bản sao với VIP status được cập nhật
  AppUser copyWithVipStatus({
    required bool isVipActive,
    DateTime? vipExpiredAt,
  }) {
    return AppUser(
      id: id,
      username: username,
      fullname: fullname,
      phone: phone,
      avatar: avatar,
      role: isVipActive ? UserRole.vip : role,
      token: token,
      isVipActive: isVipActive,
      vipExpiredAt: vipExpiredAt,
    );
  }

  /// Tạo bản sao với token mới (sau khi refresh)
  AppUser copyWithToken(String newToken) {
    final jwtPayload = _decodeJwtPayload(newToken);
    final roleStr =
        (jwtPayload['role']?.toString()) ?? (jwtPayload['Role']?.toString());
    final newRole = userRoleFromString(roleStr ?? userRoleToString(role));

    return AppUser(
      id: id,
      username: username,
      fullname: fullname,
      phone: phone,
      avatar: avatar,
      role: newRole,
      token: newToken,
      isVipActive: isVipActive,
      vipExpiredAt: vipExpiredAt,
    );
  }

  // ─────────────────────────────────────────────────────────
  // THUỘC TÍNH TIỆN ÍCH
  // ─────────────────────────────────────────────────────────

  /// Kiểm tra có phải Admin không
  bool get isAdmin => role == UserRole.admin;

  /// Kiểm tra có phải Editor hoặc Admin không (dùng chung nhóm "Staff")
  bool get isStaff => role == UserRole.editor || role == UserRole.admin;

  /// Kiểm tra Editor (chỉ đúng với editor, không phải admin)
  bool get isEditor => role == UserRole.editor;

  /// Kiểm tra có quyền tạo/sửa/xóa Manga không
  /// Editor và Admin đều được phép
  bool get canManageManga => isStaff;

  /// Kiểm tra xem user có phải là VIP (mua gói, hoặc là Admin/Editor)
  bool get isVip => role == UserRole.vip || isVipActive || isStaff;

  /// Kiểm tra có quyền quản lý Plans, Users không (chỉ Admin)
  bool get canManageUsers => isAdmin;

  /// Kiểm tra có quyền quản lý Plans không (chỉ Admin)
  bool get canManagePlans => isAdmin;

  /// Tên hiển thị: ưu tiên fullname, fallback về username
  String get displayName => fullname?.isNotEmpty == true ? fullname! : username;

  /// Icon vai trò để hiển thị Badge
  String get roleIcon {
    switch (role) {
      case UserRole.admin:
        return '👑';
      case UserRole.editor:
        return '✏️';
      case UserRole.vip:
        return '⭐';
      case UserRole.member:
        return '👤';
      case UserRole.guest:
        return '🌐';
    }
  }

  /// Nhãn vai trò tiếng Việt
  String get roleLabel {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.editor:
        return 'Biên tập viên';
      case UserRole.vip:
        return 'Thành viên VIP';
      case UserRole.member:
        return 'Thành viên';
      case UserRole.guest:
        return 'Khách';
    }
  }

  @override
  String toString() {
    return 'AppUser(id: $id, username: $username, role: ${userRoleToString(role)})';
  }
}
