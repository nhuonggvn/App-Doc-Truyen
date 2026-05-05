// lib/views/admin/admin_dashboard_screen.dart
// Màn hình bảng điều khiển quản trị - chỉ Admin mới truy cập được

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/admin_provider.dart';
import 'user_management_screen.dart';

/// Màn hình Dashboard dành riêng cho Admin
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Tải thống kê hệ thống ngay khi Dashboard được mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadSystemStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Trị Hệ Thống'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới thống kê',
            onPressed: () {
              Provider.of<AdminProvider>(context, listen: false).refreshStats();
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với thông tin Admin (Modern Header)
            _buildModernHeader(context, user),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phần thống kê hệ thống (Quick Stats)
                  _buildSectionTitle(context, 'Thống kê hệ thống'),
                  const SizedBox(height: 12),
                  Consumer<AdminProvider>(
                    builder: (context, admin, _) {
                      return _buildPremiumStats(context, admin);
                    },
                  ),

                  const SizedBox(height: 32),

                  // Phần chức năng quản trị (Admin Tools)
                  _buildSectionTitle(context, 'Công cụ quản trị'),
                  const SizedBox(height: 16),

                  // Chức năng chính: Quản lý người dùng
                  _buildMainActionCard(
                    context,
                    title: 'Quản lý Tài khoản',
                    subtitle: 'Phân quyền, nạp xu, khoá/mở khoá người dùng',
                    icon: Icons.manage_accounts,
                    color: const Color(0xFF3F51B5),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserManagementScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Các chức năng phụ dạng Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      _buildSecondaryActionCard(
                        context,
                        icon: Icons.settings_suggest_outlined,
                        label: 'Cấu hình\nHệ thống',
                        color: const Color(0xFF009688),
                        onTap: () =>
                            _showComingSoon(context, 'Cấu hình hệ thống'),
                      ),
                      _buildSecondaryActionCard(
                        context,
                        icon: Icons.workspace_premium_outlined,
                        label: 'Gói nạp\nVIP',
                        color: const Color(0xFF9C27B0),
                        onTap: () =>
                            _showComingSoon(context, 'Quản lý gói VIP'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Theme.of(context).textTheme.titleMedium?.color,
      ),
    );
  }

  /// Header hiện đại tích hợp thông tin Admin
  Widget _buildModernHeader(BuildContext context, appUser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar Admin
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white10,
                  backgroundImage: appUser?.avatar != null
                      ? NetworkImage(appUser!.avatar!)
                      : null,
                  child: appUser?.avatar == null
                      ? Icon(
                          Icons.person,
                          size: 35,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 20),
              // Thông tin Admin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appUser?.displayName ?? 'Quản trị viên',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Badge Admin sáng rực
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4E50), Color(0xFFF9D423)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('👑', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 4),
                          Text(
                            'QUẢN TRỊ VIÊN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Thống kê dạng thẻ Premium
  Widget _buildPremiumStats(BuildContext context, AdminProvider admin) {
    return Row(
      children: [
        // Thẻ Tổng Users
        Expanded(
          child: _buildGlassStatCard(
            context,
            label: 'Người dùng',
            value: admin.isLoadingStats ? null : admin.totalUsers.toString(),
            icon: Icons.people_rounded,
            color: const Color(0xFF42A5F5),
          ),
        ),
        const SizedBox(width: 12),
        // Thẻ Tổng Truyện
        Expanded(
          child: _buildGlassStatCard(
            context,
            label: 'Truyện tranh',
            value: admin.isLoadingStats ? null : admin.totalStories.toString(),
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFF66BB6A),
          ),
        ),
        const SizedBox(width: 12),
        // Thẻ Doanh thu
        Expanded(
          child: _buildGlassStatCard(
            context,
            label: 'Doanh thu',
            value: 'N/A',
            icon: Icons.monetization_on_rounded,
            color: const Color(0xFFFFA726),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassStatCard(
    BuildContext context, {
    required String label,
    required String? value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          if (value == null)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Card chức năng chính (Full width)
  Widget _buildMainActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card chức năng phụ (Grid)
  Widget _buildSecondaryActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
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
