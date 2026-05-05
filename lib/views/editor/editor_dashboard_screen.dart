// lib/views/editor/editor_dashboard_screen.dart
// Màn hình quản lý nội dung - dành cho Editor và Admin

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'manga_form_screen.dart';
import 'chapter_form_screen.dart';
import 'editor_manga_list_screen.dart';
import '../../viewmodels/auth_provider.dart';

/// Màn hình Dashboard quản lý nội dung cho Editor
class EditorDashboardScreen extends StatelessWidget {
  const EditorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Nội Dung'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ thông tin Editor
            _buildEditorInfoCard(context, user),

            const SizedBox(height: 24),

            // Tiêu đề
            Text(
              'Công cụ biên tập',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Lưới Chức năng
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                // Thêm truyện mới
                _buildMenuCard(
                  context,
                  icon: Icons.add_circle_outline,
                  label: 'Thêm\nTruyện mới',
                  color: const Color(0xFF1565C0),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MangaFormScreen()),
                  ),
                ),

                // Quản lý truyện đã đăng
                _buildMenuCard(
                  context,
                  icon: Icons.edit_outlined,
                  label: 'Truyện\ncủa tôi',
                  color: const Color(0xFF00897B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditorMangaListScreen()),
                  ),
                ),

                // Thêm chương mới
                _buildMenuCard(
                  context,
                  icon: Icons.playlist_add,
                  label: 'Thêm\nChương mới',
                  color: const Color(0xFFE64A19),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChapterFormScreen()),
                  ),
                ),

                // Quản lý bình luận
                _buildMenuCard(
                  context,
                  icon: Icons.comment_outlined,
                  label: 'Quản lý\nBình luận',
                  color: const Color(0xFF7B1FA2),
                  onTap: () => _showComingSoon(context, 'Quản lý bình luận'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Thông báo quyền hạn
            _buildPermissionInfo(context, authProvider.isAdmin),
          ],
        ),
      ),
    );
  }

  /// Thẻ thông tin Editor đang đăng nhập
  Widget _buildEditorInfoCard(BuildContext context, appUser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: const Icon(Icons.edit_note, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appUser?.displayName ?? 'Editor',
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
                    color: Colors.lightBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '✏️ Biên tập viên',
                    style: TextStyle(
                      color: Colors.white,
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

  /// Hộp thông tin về quyền hạn của Editor
  Widget _buildPermissionInfo(BuildContext context, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Quyền hạn của bạn',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('✅ Thêm và chỉnh sửa truyện'),
          const Text('✅ Thêm chương mới'),
          const Text('✅ Quản lý bình luận'),
          if (isAdmin) ...[
            const Text('✅ Quản lý toàn bộ tài khoản users'),
            const Text('✅ Cấu hình hệ thống'),
          ] else ...[
            const Text('❌ Không thể quản lý tài khoản users'),
            const Text('❌ Không thể xóa truyện của Editor khác'),
          ],
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
