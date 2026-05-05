// lib/viewmodels/auth_provider.dart
// ViewModel quản lý trạng thái xác thực toàn cục
// Sử dụng hoàn toàn CustomAuthService (REST API), không còn Firebase

import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/custom_auth_service.dart';

/// Các trạng thái của quá trình xác thực
enum AuthStatus {
  /// Đang kiểm tra token đã lưu (app vừa mở)
  initializing,

  /// Chưa đăng nhập
  unauthenticated,

  /// Đang xử lý (login/register)
  loading,

  /// Đã đăng nhập thành công
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  // ─────────────────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────────────────

  AuthStatus _status = AuthStatus.initializing;
  AppUser? _currentUser;
  String? _errorMessage;
  int _authOpVersion = 0;

  // ─────────────────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────────────────

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  /// Kiểm tra đã đăng nhập hay chưa
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _currentUser != null;

  /// Vai trò hiện tại (trả về guest nếu chưa đăng nhập)
  UserRole get currentRole => _currentUser?.role ?? UserRole.guest;

  /// Trả về true nếu là Admin
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Trả về true nếu là Editor
  bool get isEditor => _currentUser?.isEditor ?? false;

  /// Kiểm tra có quyền tạo/sửa/xóa Manga không (Admin hoặc Editor)
  bool get canManageManga => _currentUser?.canManageManga ?? false;

  /// Kiểm tra có quyền quản lý Users và Plans không (Admin only)
  bool get canManageUsers => _currentUser?.canManageUsers ?? false;

  /// Kiểm tra có quyền quản lý Plans không (Admin only)
  bool get canManagePlans => _currentUser?.canManagePlans ?? false;

  /// JWT Token hiện tại
  String? get token => _currentUser?.token;

  // ─────────────────────────────────────────────────────────
  // KHỞI TẠO - Khôi phục session từ token đã lưu
  // ─────────────────────────────────────────────────────────

  /// Gọi trong main.dart hoặc initState của App widget
  /// Kiểm tra token cũ, nếu còn hạn thì tự động đăng nhập lại
  Future<void> tryAutoLogin() async {
    final opVersion = ++_authOpVersion;
    _setStatus(AuthStatus.initializing);
    debugPrint('🚀 AuthProvider: Đang khôi phục session...');

    final user = await CustomAuthService.getMe();

    // Nếu có thao tác auth mới hơn (login/logout) thì bỏ qua kết quả cũ.
    if (opVersion != _authOpVersion) {
      debugPrint(
        'ℹ️ AuthProvider: Bỏ qua kết quả tryAutoLogin cũ do có thao tác mới hơn',
      );
      return;
    }

    if (user != null) {
      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
      debugPrint(
        '✅ AuthProvider: Session khôi phục - ${user.username} (${user.roleLabel})',
      );
    } else {
      _setStatus(AuthStatus.unauthenticated);
      debugPrint('ℹ️ AuthProvider: Không có session, vào chế độ Guest');
    }
  }

  // ─────────────────────────────────────────────────────────
  // ĐĂNG NHẬP
  // ─────────────────────────────────────────────────────────

  /// Đăng nhập với username/password
  /// Trả về true nếu thành công, false nếu thất bại
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final opVersion = ++_authOpVersion;
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final user = await CustomAuthService.login(
        username: username,
        password: password,
      );

      if (opVersion != _authOpVersion) {
        debugPrint('ℹ️ AuthProvider: Bỏ qua kết quả login cũ');
        return false;
      }

      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AuthException catch (e) {
      if (opVersion != _authOpVersion) {
        debugPrint('ℹ️ AuthProvider: Bỏ qua lỗi login cũ');
        return false;
      }
      _errorMessage = e.message;
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      if (opVersion != _authOpVersion) {
        debugPrint('ℹ️ AuthProvider: Bỏ qua lỗi login cũ');
        return false;
      }
      _errorMessage = 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// Đăng nhập bằng Google
  Future<bool> loginWithGoogle() async {
    final opVersion = ++_authOpVersion;
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final user = await CustomAuthService.loginWithGoogle();

      if (opVersion != _authOpVersion) {
        debugPrint(
          'ℹ️ AuthProvider: Bỏ qua kết quả login Google cũ (phiên bản khác)',
        );
        return false;
      }

      // ĐẢM BẢO gán user trước khi set status để isAuthenticated getter luôn đúng
      _currentUser = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;

      notifyListeners();
      debugPrint('✅ AuthProvider: Đã đăng nhập Google thành công -> Chuyển UI');
      return true;
    } on AuthException catch (e) {
      if (opVersion != _authOpVersion) {
        debugPrint('ℹ️ AuthProvider: Bỏ qua lỗi login Google cũ');
        return false;
      }
      _errorMessage = e.message;
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      if (opVersion != _authOpVersion) {
        debugPrint('ℹ️ AuthProvider: Bỏ qua lỗi login Google cũ');
        return false;
      }
      _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // ĐĂNG KÝ
  // ─────────────────────────────────────────────────────────

  /// Đăng ký tài khoản mới
  /// Trả về true nếu thành công
  Future<bool> register({
    required String username,
    required String password,
    String? fullname,
    String? phone,
  }) async {
    final opVersion = ++_authOpVersion;
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final user = await CustomAuthService.register(
        username: username,
        password: password,
        fullname: fullname,
        phone: phone,
      );

      if (opVersion != _authOpVersion) {
        debugPrint('ℹ️ AuthProvider: Bỏ qua kết quả register cũ');
        return false;
      }

      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AuthException catch (e) {
      if (opVersion != _authOpVersion) {
        debugPrint('ℹ️ AuthProvider: Bỏ qua lỗi register cũ');
        return false;
      }
      _errorMessage = e.message;
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      if (opVersion != _authOpVersion) {
        debugPrint('ℹ️ AuthProvider: Bỏ qua lỗi register cũ');
        return false;
      }
      _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // ĐĂNG XUẤT
  // ─────────────────────────────────────────────────────────

  Future<void> logout() async {
    final opVersion = ++_authOpVersion;
    debugPrint('🚪 AuthProvider: Đăng xuất...');
    await CustomAuthService.logout();

    if (opVersion != _authOpVersion) {
      debugPrint('ℹ️ AuthProvider: Bỏ qua kết quả logout cũ');
      return;
    }

    _currentUser = null;
    _clearError();
    _setStatus(AuthStatus.unauthenticated);
  }

  // ─────────────────────────────────────────────────────────
  // CẬP NHẬT PROFILE
  // ─────────────────────────────────────────────────────────

  /// Cập nhật thông tin cá nhân
  Future<bool> updateProfile({String? fullname, String? phone}) async {
    if (!isAuthenticated) return false;

    try {
      final updatedUser = await CustomAuthService.updateProfile(
        token: _currentUser!.token,
        fullname: fullname,
        phone: phone,
      );
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Đổi mật khẩu
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!isAuthenticated) return false;

    try {
      await CustomAuthService.changePassword(
        token: _currentUser!.token,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // CẬP NHẬT VIP STATUS (gọi sau khi thanh toán VNPay thành công)
  // ─────────────────────────────────────────────────────────

  /// Cập nhật trạng thái VIP cho user hiện tại
  void updateVipStatus({required bool isActive, DateTime? expiredAt}) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWithVipStatus(
      isVipActive: isActive,
      vipExpiredAt: expiredAt,
    );
    notifyListeners();
    debugPrint('✅ AuthProvider: VIP status cập nhật - isActive=$isActive');
  }

  // ─────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Xóa lỗi thủ công (dùng trong UI để reset trạng thái)
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
