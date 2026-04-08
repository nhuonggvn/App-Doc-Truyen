// lib/viewmodels/admin_provider.dart
// Provider quản lý dữ liệu thống kê hệ thống cho Admin Dashboard

import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';

/// Provider quản lý trạng thái thống kê hệ thống dành cho Admin
class AdminProvider with ChangeNotifier {
  // ==================== STATE ====================

  /// Tổng số người dùng đã đăng ký (lấy từ Firestore count())
  int _totalUsers = 0;

  /// Tổng số truyện trong hệ thống (lấy từ Firestore count())
  int _totalStories = 0;

  /// Đang tải dữ liệu thống kê hay không
  bool _isLoadingStats = false;

  /// Thông báo lỗi nếu có
  String? _statsError;

  // ==================== GETTERS ====================

  int get totalUsers => _totalUsers;
  int get totalStories => _totalStories;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  // ==================== METHODS ====================

  /// Tải thống kê hệ thống từ Firestore (gọi khi Admin mở Dashboard)
  Future<void> loadSystemStats() async {
    // Tránh tải lại nếu đang trong quá trình tải
    if (_isLoadingStats) return;

    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      final stats = await FirestoreService.getSystemStats();

      _totalUsers = stats.totalUsers;
      _totalStories = stats.totalStories;
      _statsError = null;

      debugPrint(
        '✅ AdminProvider: Đã tải thống kê - users=$_totalUsers, stories=$_totalStories',
      );
    } catch (e) {
      _statsError = 'Không thể tải thống kê. Vui lòng thử lại.';
      debugPrint('❌ AdminProvider: Lỗi khi tải thống kê: $e');
    }

    _isLoadingStats = false;
    notifyListeners();
  }

  /// Làm mới thống kê (force reload bỏ qua cache)
  Future<void> refreshStats() async {
    _isLoadingStats = false; // Reset để cho phép tải lại
    await loadSystemStats();
  }
}
