// lib/models/app_user.dart
// Model đại diện cho người dùng trong hệ thống phân quyền

/// Enum định nghĩa 4 vai trò trong hệ thống
enum UserRole {
  /// Người dùng chưa đăng nhập
  guest,

  /// Thành viên thường (đăng nhập bằng email hoặc Google)
  member,

  /// Biên tập viên (có quyền thêm/sửa/xóa truyện)
  editor,

  /// Quản trị viên (toàn quyền hệ thống)
  admin,
}

/// Chuyển chuỗi từ Firestore thành UserRole
UserRole userRoleFromString(String? role) {
  switch (role) {
    case 'admin':
      return UserRole.admin;
    case 'editor':
      return UserRole.editor;
    case 'member':
      return UserRole.member;
    default:
      // Mặc định là member nếu đã đăng nhập mà không có role
      return UserRole.member;
  }
}

/// Chuyển UserRole thành chuỗi để lưu vào Firestore
String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.editor:
      return 'editor';
    case UserRole.member:
      return 'member';
    case UserRole.guest:
      return 'guest';
  }
}

/// Model người dùng đầy đủ (kết hợp Firebase Auth + Firestore)
class AppUser {
  /// UID từ Firebase Auth
  final String uid;

  /// Email đăng nhập
  final String? email;

  /// Tên hiển thị
  final String? displayName;

  /// URL ảnh đại diện
  final String? photoUrl;

  /// Vai trò trong hệ thống
  final UserRole role;

  /// Số xu hiện tại (dùng để đọc truyện Premium)
  final int coins;

  /// Thời điểm tạo tài khoản
  final DateTime createdAt;

  /// Tài khoản có bị khoá không
  final bool isDisabled;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.member,
    this.coins = 0,
    DateTime? createdAt,
    this.isDisabled = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // ==================== THUỘC TÍNH TIỆN ÍCH ====================

  /// Kiểm tra có phải Admin không
  bool get isAdmin => role == UserRole.admin;

  /// Kiểm tra có phải Editor không
  bool get isEditor => role == UserRole.editor || role == UserRole.admin;

  /// Kiểm tra có phải Member (đã đăng nhập, không phải guest) không
  bool get isMember => role != UserRole.guest;

  /// Kiểm tra có xu để đọc truyện Premium không
  bool get hasCoins => coins > 0;

  /// Lấy tên hiển thị (ưu tiên displayName, fallback về email)
  String get name {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!.split('@').first;
    }
    return 'Người dùng';
  }

  /// Lấy nhãn vai trò bằng tiếng Việt
  String get roleLabel {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.editor:
        return 'Biên tập viên';
      case UserRole.member:
        return 'Thành viên';
      case UserRole.guest:
        return 'Khách';
    }
  }

  /// Lấy icon tương ứng với vai trò
  String get roleIcon {
    switch (role) {
      case UserRole.admin:
        return '👑';
      case UserRole.editor:
        return '✏️';
      case UserRole.member:
        return '👤';
      case UserRole.guest:
        return '🌐';
    }
  }

  // ==================== PARSE / SERIALIZE ====================

  /// Tạo AppUser từ document Firestore
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
      coins: (data['coins'] as int?) ?? 0,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isDisabled: (data['isDisabled'] as bool?) ?? false,
    );
  }

  /// Chuyển AppUser thành Map để lưu vào Firestore
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

  /// Tạo bản sao với một số thuộc tính thay đổi
  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    int? coins,
    bool? isDisabled,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      coins: coins ?? this.coins,
      createdAt: createdAt,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, role: ${userRoleToString(role)}, coins: $coins)';
  }
}
