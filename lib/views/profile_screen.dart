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
import '../viewmodels/online_manga_provider.dart';
import '../services/manga_api_service.dart';
import 'auth_screen.dart';
import 'online_manga_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  String? _avatarPath;
  String _displayName = 'Người dùng';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false).loadFavorites();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Khi người dùng quay lại từ trình duyệt thanh toán VNPay
      // Reload lại thông tin user từ server (để cập nhật role Premium)
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        authProvider.tryAutoLogin(); // Sẽ gọi API lấy lại profile mới
      }
    }
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
    final onlineMangaProvider = Provider.of<OnlineMangaProvider>(context);
    final isManager = authProvider.currentUser?.isStaff ?? false;

    return Scaffold(
      // Không hardcode màu nền - tự lấy từ Theme (trắng sáng / đen tối)
      appBar: AppBar(
        title: const Text('Hồ Sơ'),
        centerTitle: true,
        // Không hardcode: tự lấy theo AppBarTheme
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
      ),

      body: ListView(
        children: [
          // Header với thông tin user (Premium Look)
          _buildUserInfoHeader(context, authProvider),

          const SizedBox(height: 12),

          // Action cho Manager (Admin/Editor)
          if (isManager) _buildManagerPanel(context, authProvider),

          // Subscription Banner (Thay thế Upgrade VIP cũ)
          if (!isManager &&
              authProvider.isAuthenticated &&
              !authProvider.currentUser!.isVip)
            _buildSubscriptionBanner(context),

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
                  '${onlineMangaProvider.favorites.length} truyện',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (onlineMangaProvider.favorites.isEmpty)
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
            ...onlineMangaProvider.favorites.map(
              (manga) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OnlineMangaDetailScreen(manga: manga),
                      ),
                    );
                  },
                  child: SizedBox(
                    height: 80,
                    child: Row(
                      children: [
                        // Ảnh bìa
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CachedNetworkImage(
                            imageUrl: manga.image ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[300]),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.image_not_supported),
                          ),
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
                                  manga.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.cloud_done_outlined,
                                      size: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Lưu trên Cloud',
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
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Nút yêu thích
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () =>
                              onlineMangaProvider.toggleFavorite(manga),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildManagerPanel(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUẢN TRỊ TRUYỆN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.dashboard_customize_rounded,
            title: 'Bảng điều khiển Editor',
            subtitle: 'Quản lý kho truyện và chương',
            onTap: () {
              // Điều hướng đến dashboard editor sau này
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang chuyển đến Bảng điều khiển...'),
                ),
              );
            },
            color: const Color(0xFF1A1A2E),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? Theme.of(context).primaryColor).withValues(
              alpha: 0.1,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color ?? Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  // ==================== NEW UI HELPERS ====================

  Widget _buildUserInfoHeader(BuildContext context, AuthProvider authProvider) {
    final appUser = authProvider.currentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      // Dùng đúng màu nền scaffold -> hòa cùng nền, không phân chia
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Avatar với logic đa nguồn (Local file -> Google photo -> Icon)
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white10,
                    backgroundImage:
                        _avatarPath != null && File(_avatarPath!).existsSync()
                        ? FileImage(File(_avatarPath!))
                        : (appUser?.avatar != null
                              ? NetworkImage(appUser!.avatar!)
                              : null),
                    child:
                        (_avatarPath == null ||
                                !File(_avatarPath!).existsSync()) &&
                            appUser?.avatar == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF03DAC6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Name with Edit - Chữ trắng trên nền primary
          GestureDetector(
            onTap: _editName,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayName,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit,
                  size: 18,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Email - Luôn hiển thị nếu đã đăng nhập
          if (authProvider.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                authProvider.currentUser?.username ?? 'Chưa xác thực',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),

          // Giao diện Badge loại tài khoản
          if (authProvider.isAuthenticated)
            Builder(
              builder: (context) {
                final role = authProvider.currentRole;
                final bool isSpecialRole =
                    role == UserRole.admin ||
                    role == UserRole.editor ||
                    role == UserRole.vip;

                if (isSpecialRole) {
                  // Hiển thị Badge phát sáng cho Admin, Editor, VIP
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: role == UserRole.admin
                            ? [const Color(0xFFFF4E50), const Color(0xFFF9D423)]
                            : role == UserRole.editor
                            ? [const Color(0xFF00C6FF), const Color(0xFF0072FF)]
                            : [
                                const Color(0xFFFFD700),
                                const Color(0xFFFFA500),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${authProvider.currentUser?.roleIcon} ${authProvider.currentUser?.roleLabel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Member bình thường - Dùng màu theme thay vì hardcode
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '👤 Thành viên',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
              },
            ),

          // Nút số dư xu nạp tiền - ĐÃ LOẠI BỎ THEO YÊU CẦU
        ],
      ),
    );
  }

  Widget _buildSubscriptionBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF4A4A8E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gói Hội Viên Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Đọc mọi truyện không giới hạn',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showUpgradeVipDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A1A2E),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'TÌM HIỂU THÊM',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeVipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: MangaApiService.getPlans(),
          builder: (context, snapshot) {
            final plans = snapshot.data ?? [];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.workspace_premium, color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Text('Chọn Gói Hội Viên'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: isLoading
                    ? const Center(
                        heightFactor: 3,
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                    : plans.isEmpty
                    ? const Text('Hiện tại không có gói VIP nào được mở bán.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: plans.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              plan['name'] ?? 'Gói VIP',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${plan['durationDays']} ngày - ${plan['description'] ?? ''}',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () =>
                                  _handleSubscribePlan(context, plan['_id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('${plan['price']} đ'),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Để sau',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSubscribePlan(BuildContext context, String planId) async {
    // Đóng dialog danh sách gói
    Navigator.pop(context);

    // Hiển thị loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    final urlString = await MangaApiService.createPaymentUrl(planId);

    // Đóng loading
    if (context.mounted) Navigator.pop(context);

    if (urlString != null && urlString.isNotEmpty) {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể mở liên kết thanh toán VNPay'),
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lỗi thao tác hoặc chưa đăng nhập. Không thể tạo liên kết VNPay.',
            ),
          ),
        );
      }
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
