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
          'coins': 0, // Bắt đầu với 0 xu
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

  // ==================== QUẢN LÝ XU (COINS) ====================

  /// Nạp xu cho user (mock VNPay)
  /// [uid] - UID của user
  /// [amount] - Số xu muốn nạp thêm
  static Future<bool> addCoins(String uid, int amount) async {
    try {
      await _db.collection(_usersCollection).doc(uid).update({
        // Dùng FieldValue.increment để tránh race condition
        'coins': FieldValue.increment(amount),
      });
      debugPrint('✅ Firestore: Đã nạp $amount xu cho uid=$uid');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore: Lỗi khi nạp xu: $e');
      return false;
    }
  }

  /// Trừ xu của user khi đọc truyện Premium
  /// [uid] - UID của user
  /// [amount] - Số xu cần trừ (mặc định 1 xu/chapter)
  /// Trả về true nếu trừ xu thành công, false nếu không đủ xu
  static Future<bool> spendCoins(String uid, int amount) async {
    try {
      // Dùng transaction để đảm bảo an toàn khi trừ xu
      return await _db.runTransaction<bool>((transaction) async {
        final docRef = _db.collection(_usersCollection).doc(uid);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          debugPrint('❌ Firestore: Không tìm thấy user uid=$uid để trừ xu');
          return false;
        }

        final currentCoins = (snapshot.data()?['coins'] as int?) ?? 0;

        // Kiểm tra đủ xu không
        if (currentCoins < amount) {
          debugPrint(
            '⚠️ Firestore: Không đủ xu. Hiện có: $currentCoins, cần: $amount',
          );
          return false;
        }

        // Trừ xu
        transaction.update(docRef, {'coins': currentCoins - amount});
        debugPrint(
          '✅ Firestore: Đã trừ $amount xu của uid=$uid. Còn lại: ${currentCoins - amount}',
        );
        return true;
      });
    } catch (e) {
      debugPrint('❌ Firestore: Lỗi khi trừ xu: $e');
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
}
