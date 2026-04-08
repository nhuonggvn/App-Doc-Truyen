// lib/viewmodels/admin_provider.dart
// Provider thống kê hệ thống - Tạm thời stubbed, sẽ tích hợp REST API ở Giai đoạn 2

import 'package:flutter/foundation.dart';

/// Provider quản lý trạng thái thống kê hệ thống dành cho Admin
class AdminProvider with ChangeNotifier {
  int _totalUsers = 0;
  int _totalStories = 0;
  bool _isLoadingStats = false;
  String? _statsError;

  int get totalUsers => _totalUsers;
  int get totalStories => _totalStories;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  /// TODO Giai đoạn 2: Tích hợp API Backend để lấy thống kê thật
  Future<void> loadSystemStats() async {
    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();

    // Tạm thời giả lập - sẽ gọi API thật
    await Future.delayed(const Duration(milliseconds: 300));
    _totalUsers = 0;
    _totalStories = 0;
    _isLoadingStats = false;
    debugPrint('ℹ️ AdminProvider: Stub - sẽ tích hợp API thật ở Giai đoạn 2');
    notifyListeners();
  }

  Future<void> refreshStats() async {
    _isLoadingStats = false;
    await loadSystemStats();
  }
}
