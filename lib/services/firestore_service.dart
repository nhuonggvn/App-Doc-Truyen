// lib/services/firestore_service.dart
// Service xử lý tất cả thao tác với Firestore (role, coins, users)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

/// Service trung gian giao tiếp với Firestore Database
class FirestoreService {
  // Instance Firestore singleton
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tên collection lưu thông tin người dùng
  static const String _usersCollection = 'users';

  // ==================== QUẢN LÝ USER ====================

  /// Tạo document user mới trong Firestore khi đăng ký lần đầu
  /// [uid] - UID từ Firebase Auth
  /// [email] - Email của user
  /// [displayName] - Tên hiển thị (tuỳ chọn)
  static Future<void> createUserDocument(
    String uid, {
    required String email,
    String? displayName,
    String? photoUrl,
    UserRole role = UserRole.member,
  }) async {
    try {
      final docRef = _db.collection(_usersCollection).doc(uid);
      final docSnapshot = await docRef.get();

      // Chỉ tạo mới nếu document chưa tồn tại
      if (!docSnapshot.exists) {
        await docRef.set({
          'email': email,
          'displayName': displayName,
          'photoUrl': photoUrl,
          'role': userRoleToString(role), // Mặc định là member
          'isVip': role == UserRole.vip || role == UserRole.admin, // VIP status
          'createdAt': DateTime.now().toIso8601String(),
          'isDisabled': false,
        });
        debugPrint('✅ Firestore: Đã tạo document user mới cho uid=$uid');
      } else {
        debugPrint('ℹ️ Firestore: Document user đã tồn tại cho uid=$uid');
      }
    } catch (e) {
      debugPrint('❌ Firestore: Lỗi khi tạo document user: $e');
      rethrow;
    }
  }

  /// Lấy thông tin user từ Firestore theo UID
  /// Trả về AppUser hoặc null nếu không tìm thấy
  static Future<AppUser?> getUserById(
    String uid, {
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final docSnapshot = await _db.collection(_usersCollection).doc(uid).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        debugPrint('✅ Firestore: Đã lấy thông tin user uid=$uid');
        return AppUser.fromFirestore(
          uid,
          docSnapshot.data()!,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
        );
      }

      debugPrint('⚠️ Firestore: Không tìm thấy document user uid=$uid');
      return null;
    } catch (e) {
      debugPrint('❌ Firestore: Lỗi khi lấy thông tin user: $e');
      return null;
    }
  }

  /// Lắng nghe thay đổi real-time của user (dùng Stream)
  /// Trả về Stream<AppUser?> để cập nhật tự động khi Firestore thay đổi
  static Stream<AppUser?> watchUser(
    String uid, {
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return _db.collection(_usersCollection).doc(uid).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return AppUser.fromFirestore(
          uid,
          snapshot.data()!,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
        );
      }
      return null;
    });
  }

  // ==================== QUẢN LÝ PREMIUM (VIP) ====================

  /// Cập nhật trạng thái VIP của user (chỉ Admin mới được gọi)
  static Future<bool> updateUserVipStatus(String uid, bool isVip) async {
    try {
      await _db.collection(_usersCollection).doc(uid).update({'isVip': isVip});
      debugPrint(
        '✅ Firestore: Đã cập nhật trạng thái VIP của uid=$uid thành $isVip',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Firestore: Lỗi khi cập nhật trạng thái VIP: $e');
      return false;
    }
  }

  // ==================== QUẢN LÝ ROLE (ADMIN) ====================

  /// Cập nhật role của user (chỉ Admin mới được gọi)
  /// [uid] - UID của user cần cập nhật
  /// [newRole] - Role mới
  static Future<bool> updateUserRole(String uid, UserRole newRole) async {
    try {
      await _db.collection(_usersCollection).doc(uid).update({
        'role': userRoleToString(newRole),
      });
      debugPrint(
        '✅ Firestore: Đã cập nhật role của uid=$uid thành ${userRoleToString(newRole)}',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Firestore: Lỗi khi cập nhật role: $e');
      return false;
    }
  }

  /// Khoá/mở khoá tài khoản user (chỉ Admin mới được gọi)
  static Future<bool> toggleUserDisabled(String uid, bool isDisabled) async {
    try {
      await _db.collection(_usersCollection).doc(uid).update({
        'isDisabled': isDisabled,
      });
      final action = isDisabled ? 'khoá' : 'mở khoá';
      debugPrint('✅ Firestore: Đã $action tài khoản uid=$uid');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore: Lỗi khi cập nhật trạng thái tài khoản: $e');
      return false;
    }
  }

  /// Xóa tài khoản người dùng khỏi Firestore (Admin)
  static Future<bool> deleteUser(String uid) async {
    try {
      await _db.collection(_usersCollection).doc(uid).delete();
      debugPrint('✅ Firestore: Đã xóa tài khoản uid=$uid');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore: Lỗi khi xóa tài khoản: $e');
      return false;
    }
  }

  /// Lấy danh sách tất cả users (chỉ Admin mới được gọi)
  /// [limit] - Số lượng user tối đa mỗi lần lấy
  static Future<List<AppUser>> getAllUsers({int limit = 50}) async {
    try {
      final querySnapshot = await _db
          .collection(_usersCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final users = querySnapshot.docs.map((doc) {
        return AppUser.fromFirestore(doc.id, doc.data());
      }).toList();

      debugPrint('✅ Firestore: Đã lấy ${users.length} user');
      return users;
    } catch (e) {
      debugPrint('❌ Firestore: Lỗi khi lấy danh sách user: $e');
      return [];
    }
  }

  // ==================== THỐNG KÊ HỆ THỐNG (ADMIN) ====================

  /// Tên collection lưu truyện (map với tên trong Firestore)
  static const String _storiesCollection = 'stories';

  /// Lấy thống kê tổng quan hệ thống bằng Firestore Aggregation count()
  /// Trả về Map với các key: totalUsers, totalStories
  /// Dùng count() thay vì getDocs để tiết kiệm chi phí đọc Firestore
  static Future<SystemStats> getSystemStats() async {
    try {
      // Chạy song song 2 truy vấn count() để giảm thời gian chờ
      final results = await Future.wait([
        _db.collection(_usersCollection).count().get(),
        _db.collection(_storiesCollection).count().get(),
      ]);

      final totalUsers = results[0].count ?? 0;
      final totalStories = results[1].count ?? 0;

      debugPrint('✅ Firestore Stats: users=$totalUsers, stories=$totalStories');

      return SystemStats(totalUsers: totalUsers, totalStories: totalStories);
    } catch (e) {
      debugPrint('❌ Firestore: Lỗi khi lấy thống kê hệ thống: $e');
      // Trả về giá trị mặc định nếu lỗi (tránh crash app)
      return SystemStats(totalUsers: 0, totalStories: 0);
    }
  }
}

/// Model lưu dữ liệu thống kê hệ thống
class SystemStats {
  final int totalUsers;
  final int totalStories;

  const SystemStats({required this.totalUsers, required this.totalStories});
}
