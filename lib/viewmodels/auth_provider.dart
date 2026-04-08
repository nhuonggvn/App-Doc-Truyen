// lib/viewmodels/auth_provider.dart
// Provider quản lý xác thực và phân quyền (Firebase Auth + Firestore + Google)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';
import '../services/custom_auth_service.dart';

/// Provider quản lý toàn bộ trạng thái xác thực và phân quyền
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Thông tin user hiện tại (null nếu chưa đăng nhập)
  AppUser? _currentUser;

  // Trạng thái loading và lỗi
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscription để huỷ khi dispose
  StreamSubscription<AppUser?>? _userStreamSubscription;

  // ==================== GETTERS ====================

  /// User hiện tại (null = Guest)
  AppUser? get currentUser => _currentUser;

  /// Kiểm tra đã đăng nhập chưa
  bool get isAuthenticated => _currentUser != null;

  /// Kiểm tra user có phải cấp Quản lý (Admin/Editor) không
  bool get isManager => _currentUser?.authSource == AuthSource.custom;

  /// Token JWT (nếu có - chỉ dành cho Manager)
  String? get managerToken => _currentUser?.token;

  /// Kiểm tra đang loading không
  bool get isLoading => _isLoading;

  /// Thông báo lỗi
  String? get errorMessage => _errorMessage;

  /// Lấy role hiện tại (guest nếu chưa đăng nhập)
  UserRole get currentRole => _currentUser?.role ?? UserRole.guest;

  /// Kiểm tra có phải admin không
  bool get isAdmin => currentRole == UserRole.admin;

  /// Kiểm tra có phải editor (editor + admin) không
  bool get isEditor =>
      currentRole == UserRole.editor || currentRole == UserRole.admin;

  /// Kiểm tra có phải member (đã đăng nhập qua Firebase) không
  bool get isMember =>
      isAuthenticated && _currentUser?.authSource == AuthSource.firebase;

  /// Số xu hiện tại của user
  int get coins => _currentUser?.coins ?? 0;

  /// Kiểm tra có xu để đọc truyện không
  bool get hasCoins => coins > 0;

  // ==================== KHỞI TẠO ====================

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    // 1. Kiểm tra xem có token Admin cũ không (Persistence cho Manager)
    final savedToken = await CustomAuthService.getToken();
    if (savedToken != null) {
      final managerData = await CustomAuthService.getMe();
      if (managerData != null) {
        _currentUser = AppUser.fromCustomApi(managerData, savedToken);
        notifyListeners();
        debugPrint('✅ Auth: Khôi phục session Manager thành công (Custom BE)');
        return; // Ưu tiên session Manager
      }
    }

    // 2. Lắng nghe thay đổi trạng thái đăng nhập từ Firebase Auth (Cho Member)
    _firebaseAuth.authStateChanges().listen((User? firebaseUser) async {
      // Nếu đang có session Manager thì không ghi đè bởi Firebase Guest state
      if (isManager) return;

      // Huỷ stream cũ nếu có
      await _userStreamSubscription?.cancel();

      if (firebaseUser == null) {
        _currentUser = null;
        notifyListeners();
        debugPrint('ℹ️ Auth: Firebase - Người dùng chưa đăng nhập (Guest)');
        return;
      }

      // Đăng nhập Firebase thành công - lắng nghe Firestore real-time
      _userStreamSubscription =
          FirestoreService.watchUser(
            firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
          ).listen((appUser) {
            _currentUser = appUser;
            notifyListeners();
            debugPrint(
              '♻️ Auth: Member cập từ Firestore - role=${appUser?.role}',
            );
          });
    });
  }

  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    super.dispose();
  }

  // ==================== ĐĂNG NHẬP MANAGER (ADMIN/EDITOR) ====================

  /// Đăng nhập Admin/Editor qua Custom BE API
  Future<bool> loginAsManager(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await CustomAuthService.loginManager(email, password);

      if (result != null) {
        final userData = result['user'] as Map<String, dynamic>;
        final token = result['token'] as String;

        // Tạo AppUser từ API data
        _currentUser = AppUser.fromCustomApi(userData, token);

        // Nếu đang login Firebase, hãy logout Firebase để tránh nhầm lẫn
        if (_firebaseAuth.currentUser != null) {
          await _firebaseAuth.signOut();
        }

        _isLoading = false;
        notifyListeners();
        debugPrint('✅ Auth: Login Manager thành công (Custom BE)');
        return true;
      } else {
        _errorMessage = 'Đăng nhập thất bại. Kiểm tra lại email/mật khẩu.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối tới máy chủ quản trị.';
      debugPrint('❌ Auth Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
  // ==================== ĐĂNG NHẬP MEMBER (FIREBASE) ====================

  /// Đăng nhập bằng email và mật khẩu qua Firebase
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final user = await FirestoreService.getUserById(credential.user!.uid);
        if (user != null && user.isDisabled) {
          await _firebaseAuth.signOut();
          _errorMessage =
              'Tài khoản của bạn đã bị khoá. Liên hệ quản trị viên.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _isLoading = false;
      notifyListeners();
      debugPrint(
        '✅ Auth: Đăng nhập Member thành công - ${credential.user?.email}',
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _translateFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không mong muốn.';
      notifyListeners();
      return false;
    }
  }

  /// Đăng ký tài khoản mới qua Firebase
  Future<bool> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        if (displayName != null && displayName.isNotEmpty) {
          await credential.user!.updateDisplayName(displayName);
        }

        await FirestoreService.createUserDocument(
          credential.user!.uid,
          email: email.trim(),
          displayName: displayName,
          role: UserRole.member,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _translateFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi khi đăng ký.';
      notifyListeners();
      return false;
    }
  }

  /// Đăng nhập bằng tài khoản Google (dành cho Member)
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        await FirestoreService.createUserDocument(
          userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
          role: UserRole.member,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _translateFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đăng nhập Google thất bại.';
      notifyListeners();
      return false;
    }
  }

  // ==================== ĐĂNG XUẤT ====================

  /// Đăng xuất khỏi hệ thống (cả Firebase và Custom BE)
  Future<void> logout() async {
    try {
      if (isManager) {
        // Đăng xuất Manager (Custom BE)
        await CustomAuthService.clearToken();
        debugPrint('✅ Auth: Đã xóa token Admin');
      } else {
        // Đăng xuất Member (Firebase/Google)
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
        await _firebaseAuth.signOut();
      }

      await _userStreamSubscription?.cancel();
      _currentUser = null;
      debugPrint('✅ Auth: Đã đăng xuất thành công');
    } catch (e) {
      debugPrint('❌ Auth: Lỗi khi đăng xuất: $e');
    }
    notifyListeners();
  }

  // ==================== QUẢN LÝ SUBSCRIPTION ====================
  // Logic cũ về Xu và VNPay đã bị xóa.
  // Các tính năng Subscription sẽ được tích hợp ở Phase tiếp theo.

  // ==================== TIỆN ÍCH ADMIN ====================

  /// Cập nhật role của user khác (chỉ Admin mới được gọi)
  Future<bool> updateUserRole(String uid, UserRole newRole) async {
    if (!isAdmin) {
      _errorMessage = 'Bạn không có quyền thực hiện hành động này.';
      notifyListeners();
      return false;
    }
    return await FirestoreService.updateUserRole(uid, newRole);
  }

  /// Khoá/mở khoá tài khoản (chỉ Admin)
  Future<bool> toggleUserAccount(String uid, bool disable) async {
    if (!isAdmin) {
      _errorMessage = 'Bạn không có quyền thực hiện hành động này.';
      notifyListeners();
      return false;
    }
    return await FirestoreService.toggleUserDisabled(uid, disable);
  }

  /// Cập nhật trạng thái VIP của user (chỉ Admin)
  Future<bool> updateUserVipStatus(String uid, bool isVip) async {
    if (!isAdmin) {
      _errorMessage = 'Bạn không có quyền thực hiện hành động này.';
      notifyListeners();
      return false;
    }
    return await FirestoreService.updateUserVipStatus(uid, isVip);
  }

  // ==================== XÓA LỖI ====================

  /// Xoá thông báo lỗi
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== PRIVATE HELPERS ====================

  /// Dịch mã lỗi Firebase thành tiếng Việt
  String _translateFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Vui lòng đăng nhập.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Cần ít nhất 6 ký tự.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu liên tiếp. Vui lòng thử lại sau.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Kiểm tra internet và thử lại.';
      case 'account-exists-with-different-credential':
        return 'Email này đã đăng ký với phương thức khác.';
      default:
        return 'Đã xảy ra lỗi: $code';
    }
  }
}
