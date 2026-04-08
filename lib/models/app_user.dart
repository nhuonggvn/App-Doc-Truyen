// lib/models/app_user.dart
// Model đại diện cho người dùng trong hệ thống phân quyền (Refactored for Auth Split)

/// Enum định nghĩa các nguồn xác thực của hệ thống
enum AuthSource {
  /// Xác thực qua Firebase (cho Member/VIP)
  firebase,

  /// Xác thực qua Custom BE API (cho Admin/Editor)
  custom,
}

/// Enum định nghĩa 4 vai trò trong hệ thống
enum UserRole {
  /// Người dùng chưa đăng nhập
  guest,

  /// Thành viên thường (đăng nhập bằng Firebase)
  member,

  /// Thành viên VIP (trả phí - quản lý qua Firebase)
  vip,

  /// Biên tập viên (quản lý qua Custom BE)
  editor,

  /// Quản trị viên (quản lý qua Custom BE)
  admin,
}

/// Chuyển chuỗi thành UserRole
UserRole userRoleFromString(String? role) {
  switch (role) {
    case 'admin':
      return UserRole.admin;
    case 'vip':
      return UserRole.vip;
    case 'editor':
      return UserRole.editor;
    case 'member':
      return UserRole.member;
    default:
      return UserRole.member;
  }
}

/// Chuyển UserRole thành chuỗi
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

/// Model người dùng đầy đủ
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final AuthSource authSource;
  final String? token; // JWT dành cho Admin/Editor
  final int coins; // Sẽ deprecate ở Phase 2
  final DateTime createdAt;
  final bool isDisabled;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.member,
    this.authSource = AuthSource.firebase,
    this.token,
    this.coins = 0,
    DateTime? createdAt,
    this.isDisabled = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // ==================== THUỘC TÍNH TIỆN ÍCH ====================

  bool get isAdmin => role == UserRole.admin;
  bool get isEditor => role == UserRole.editor || role == UserRole.admin;
  bool get isVip => role == UserRole.vip || isAdmin || isEditor;
  bool get isMember => role == UserRole.member || role == UserRole.vip;

  /// Kiểm tra xem user có phải là cấp Quản lý (Admin/Editor) từ Custom BE không
  bool get isManager => authSource == AuthSource.custom;

  String get name => displayName ?? email?.split('@').first ?? 'Người dùng';

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

  String get roleIcon {
    switch (role) {
      case UserRole.admin:
        return '👑';
      case UserRole.editor:
        return '✏️';
      case UserRole.vip:
        return '👑';
      case UserRole.member:
        return '👤';
      case UserRole.guest:
        return '🌐';
    }
  }

  // ==================== PARSE / SERIALIZE ====================

  /// Tạo Member từ Firestore (Firebase Auth)
  factory AppUser.fromFirestore(
    String uid,
    Map<String, dynamic> data, {
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? data['email']?.toString(),
      displayName: displayName ?? data['displayName']?.toString(),
      photoUrl: photoUrl ?? data['photoUrl']?.toString(),
      role: userRoleFromString(data['role']?.toString()),
      authSource: AuthSource.firebase,
      coins: (data['coins'] as int?) ?? 0,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isDisabled: (data['isDisabled'] as bool?) ?? false,
    );
  }

  /// Tạo Manager (Admin/Editor) từ Custom BE API
  factory AppUser.fromCustomApi(Map<String, dynamic> data, String token) {
    return AppUser(
      uid: data['id']?.toString() ?? '',
      email: data['email']?.toString(),
      displayName: data['name']?.toString(),
      photoUrl: data['avatar']?.toString(),
      role: userRoleFromString(data['role']?.toString()),
      authSource: AuthSource.custom,
      token: token,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': userRoleToString(role),
      'coins': coins,
      'createdAt': createdAt.toIso8601String(),
      'isDisabled': isDisabled,
    };
  }

  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    AuthSource? authSource,
    String? token,
    int? coins,
    bool? isDisabled,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      authSource: authSource ?? this.authSource,
      token: token ?? this.token,
      coins: coins ?? this.coins,
      createdAt: createdAt,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}
