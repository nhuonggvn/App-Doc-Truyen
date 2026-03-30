// lib/viewmodels/auth_provider.dart
// Provider quản lý xác thực và phân quyền (Firebase Auth + Firestore + Google)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';

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

  /// Kiểm tra có phải member (đã đăng nhập, không kể role) không
  bool get isMember => isAuthenticated;

  /// Số xu hiện tại của user
  int get coins => _currentUser?.coins ?? 0;

  /// Kiểm tra có xu để đọc truyện không
  bool get hasCoins => coins > 0;

  // ==================== KHỞI TẠO ====================

  AuthProvider() {
    // Lắng nghe thay đổi trạng thái đăng nhập từ Firebase Auth
    _firebaseAuth.authStateChanges().listen((User? firebaseUser) async {
      // Huỷ stream cũ nếu có
      await _userStreamSubscription?.cancel();

      if (firebaseUser == null) {
        // Người dùng đã đăng xuất
        _currentUser = null;
        notifyListeners();
        debugPrint('ℹ️ Auth: Người dùng chưa đăng nhập (Guest)');
        return;
      }

      // Đăng nhập thành công - lắng nghe Firestore real-time để tự cập nhật xuất/vào role và coin
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
              '♻️ Auth: Cập nhật user từ Firestore - role=${appUser?.role}, coins=${appUser?.coins}',
            );
          });
    });
  }

  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    super.dispose();
  }

  // ==================== ĐĂNG NHẬP EMAIL ====================

  /// Đăng nhập bằng email và mật khẩu
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Kiểm tra tài khoản có bị khoá trong Firestore không
      if (credential.user != null) {
        final user = await FirestoreService.getUserById(credential.user!.uid);
        if (user != null && user.isDisabled) {
          // Tài khoản bị khoá - đăng xuất ngay
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
        '✅ Auth: Đăng nhập email thành công - ${credential.user?.email}',
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _translateFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }

  // ==================== ĐĂNG KÝ EMAIL ====================

  /// Đăng ký tài khoản mới bằng email
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
        // Cập nhật tên hiển thị nếu có
        if (displayName != null && displayName.isNotEmpty) {
          await credential.user!.updateDisplayName(displayName);
        }

        // Tạo document Firestore với role mặc định là member
        await FirestoreService.createUserDocument(
          credential.user!.uid,
          email: email.trim(),
          displayName: displayName,
          role: UserRole.member,
        );
      }

      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Auth: Đăng ký thành công - $email');
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _translateFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi khi đăng ký. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }

  // ==================== ĐĂNG NHẬP GOOGLE ====================

  /// Đăng nhập bằng tài khoản Google (dành cho Member)
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Mở Google Sign-In Dialog
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();

      if (googleAccount == null) {
        // Người dùng bấm Cancel
        _isLoading = false;
        notifyListeners();
        debugPrint('ℹ️ Auth: Người dùng huỷ đăng nhập Google');
        return false;
      }

      // Lấy credentials từ Google
      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập vào Firebase bằng credentials Google
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        // Tạo document Firestore nếu lần đầu đăng nhập
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
      debugPrint(
        '✅ Auth: Đăng nhập Google thành công - ${userCredential.user?.email}',
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _translateFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đăng nhập Google thất bại. Vui lòng thử lại.';
      notifyListeners();
      debugPrint('❌ Auth: Lỗi đăng nhập Google: $e');
      return false;
    }
  }

  // ==================== ĐĂNG XUẤT ====================

  /// Đăng xuất khỏi hệ thống (cả Firebase và Google)
  Future<void> logout() async {
    try {
      // Đăng xuất Google nếu đang dùng
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
      _currentUser = null;
      debugPrint('✅ Auth: Đã đăng xuất thành công');
    } catch (e) {
      debugPrint('❌ Auth: Lỗi khi đăng xuất: $e');
    }
    notifyListeners();
  }

  // ==================== QUẢN LÝ XU ====================

  /// Nạp xu giả lập (Mock VNPay)
  /// [packageIndex] - Chỉ số gói nạp (0 = 10 xu, 1 = 50 xu, 2 = 120 xu)
  Future<bool> purchaseCoins(int coinAmount) async {
    if (_currentUser == null) {
      _errorMessage = 'Vui lòng đăng nhập để nạp xu.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    // Giả lập delay thanh toán VNPay (3 giây)
    await Future.delayed(const Duration(seconds: 3));

    final success = await FirestoreService.addCoins(
      _currentUser!.uid,
      coinAmount,
    );

    _isLoading = false;

    if (!success) {
      _errorMessage = 'Nạp xu thất bại. Vui lòng thử lại.';
    }

    notifyListeners();
    return success;
  }

  /// Trừ xu để đọc truyện Premium (1 xu/chapter)
  Future<bool> spendCoinsForChapter() async {
    if (_currentUser == null) return false;
    if (!hasCoins) {
      debugPrint('⚠️ Auth: User không đủ xu để đọc');
      return false;
    }

    return await FirestoreService.spendCoins(_currentUser!.uid, 1);
  }

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
