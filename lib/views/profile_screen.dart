// lib/views/profile_screen.dart
// Màn hình hồ sơ cá nhân

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_user.dart';
import '../viewmodels/auth_provider.dart';
import '../viewmodels/story_provider.dart';
import '../viewmodels/theme_provider.dart';
import 'auth_screen.dart';
import 'story_detail_screen.dart';
import 'member/coin_wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _avatarPath;
  String _displayName = 'Người dùng';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false).loadFavorites();
    });
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _avatarPath = prefs.getString('avatar_path');
      _displayName = prefs.getString('display_name') ?? 'Người dùng';
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (_avatarPath != null) {
      await prefs.setString('avatar_path', _avatarPath!);
    }
    await prefs.setString('display_name', _displayName);
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Lưu ảnh vào thư mục app
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/profile');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }
      final newPath = '${avatarDir.path}/avatar.jpg';
      await File(image.path).copy(newPath);

      setState(() {
        _avatarPath = newPath;
      });
      await _saveProfile();
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên hiển thị'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tên của bạn',
            hintText: 'Nhập tên hiển thị',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _displayName = newName;
      });
      await _saveProfile();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final storyProvider = Provider.of<StoryProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ Sơ')),
      body: ListView(
        children: [
          // Header với thông tin user
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              children: [
                // Avatar với nút chỉnh sửa
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage:
                            _avatarPath != null &&
                                File(_avatarPath!).existsSync()
                            ? FileImage(File(_avatarPath!))
                            : null,
                        child:
                            _avatarPath == null ||
                                !File(_avatarPath!).existsSync()
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : null,
                      ),
                      // Nút chỉnh sửa avatar
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF03DAC6), // Xanh ngọc cố định
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Color(0xFF1F1F1F), // Tối cố định
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tên hiển thị với nút chỉnh sửa
                GestureDetector(
                  onTap: _editName,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.currentUser?.email ?? 'Thành viên',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                // Badge hiển thị role
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(
                      authProvider.currentRole,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getRoleColor(
                        authProvider.currentRole,
                      ).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${authProvider.currentUser?.roleIcon ?? "🌐"} ${authProvider.currentUser?.roleLabel ?? "Khách"}',
                    style: TextStyle(
                      color: _getRoleColor(authProvider.currentRole),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Thẻ số xu (chỉ hiện cho Member đã đăng nhập)
          if (authProvider.isAuthenticated)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoinWalletScreen()),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFF44336)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ví Xu của bạn',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${authProvider.coins} xu',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Nạp thêm',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Cài đặt giao diện
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Cài đặt',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Toggle Dark Mode
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Chế độ tối'),
              subtitle: Text(
                themeProvider.isDarkMode ? 'Đang bật' : 'Đang tắt',
              ),
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),

          const SizedBox(height: 16),

          // Danh sách yêu thích
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Truyện yêu thích',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${storyProvider.favorites.length} truyện',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (storyProvider.favorites.isEmpty)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có truyện yêu thích',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...storyProvider.favorites.map(
              (story) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryDetailScreen(story: story),
                      ),
                    );
                  },
                  child: SizedBox(
                    height: 80,
                    child: Row(
                      children: [
                        // Ảnh bìa - vuông đều
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: _buildCoverImage(context, story.coverImage),
                        ),
                        // Thông tin
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  story.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                FutureBuilder<int>(
                                  future: storyProvider.getChapterCount(
                                    story.id!,
                                  ),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data ?? 0;
                                    return Row(
                                      children: [
                                        Icon(
                                          Icons.menu_book,
                                          size: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$count chương',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Nút yêu thích
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => storyProvider.toggleFavorite(story),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Nút đăng xuất
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Lấy màu tương ứng với role
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.amber.shade700;
      case UserRole.editor:
        return Colors.blue;
      case UserRole.member:
        return Colors.green;
      case UserRole.guest:
        return Colors.grey;
    }
  }

  Widget _buildCoverImage(BuildContext context, String? coverImage) {
    if (coverImage != null && coverImage.isNotEmpty) {
      final file = File(coverImage);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    // Placeholder
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book,
          size: 32,
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
