// lib/views/admin/admin_dashboard_screen.dart
// Màn hình bảng điều khiển quản trị - chỉ Admin mới truy cập được

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import 'user_management_screen.dart';

/// Màn hình Dashboard dành riêng cho Admin
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Trị Hệ Thống'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ thông tin Admin
            _buildAdminInfoCard(context, user),

            const SizedBox(height: 24),

            // Tiêu đề menu
            Text(
              'Chức năng quản trị',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Lưới menu chức năng
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                // Quản lý tài khoản
                _buildMenuCard(
                  context,
                  icon: Icons.manage_accounts,
                  label: 'Quản lý\nTài khoản',
                  color: const Color(0xFF3F51B5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserManagementScreen(),
                    ),
                  ),
                ),

                // Cấu hình nội dung (placeholder)
                _buildMenuCard(
                  context,
                  icon: Icons.settings_outlined,
                  label: 'Cấu hình\nHệ thống',
                  color: const Color(0xFF009688),
                  onTap: () => _showComingSoon(context, 'Cấu hình hệ thống'),
                ),

                // Thống kê (placeholder)
                _buildMenuCard(
                  context,
                  icon: Icons.bar_chart_outlined,
                  label: 'Thống kê\n& Báo cáo',
                  color: const Color(0xFFFF5722),
                  onTap: () => _showComingSoon(context, 'Thống kê & Báo cáo'),
                ),

                // Quản lý gói VIP (placeholder)
                _buildMenuCard(
                  context,
                  icon: Icons.workspace_premium_outlined,
                  label: 'Gói nạp\nVIP',
                  color: const Color(0xFF9C27B0),
                  onTap: () => _showComingSoon(context, 'Quản lý gói VIP'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Phần thống kê nhanh
            Text(
              'Tổng quan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildQuickStats(context),
          ],
        ),
      ),
    );
  }

  /// Thẻ thông tin Admin đang đăng nhập
  Widget _buildAdminInfoCard(BuildContext context, appUser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: const Icon(
              Icons.admin_panel_settings,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          // Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appUser?.name ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    '👤 Quản trị viên',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card menu chức năng
  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thống kê nhanh (placeholder - sau sẽ kết nối Firestore)
  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            label: 'Tổng Users',
            value: '---',
            icon: Icons.people_outline,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            context,
            label: 'Tổng Truyện',
            value: '---',
            icon: Icons.menu_book_outlined,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            context,
            label: 'Doanh thu',
            value: '---',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  /// Một ô thống kê
  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Hiện thông báo tính năng đang phát triển
  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚧 $featureName - Đang phát triển'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
