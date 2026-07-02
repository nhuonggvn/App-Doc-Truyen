// lib/views/main_navigation.dart
// Điều hướng chính - render Tab theo Role (Admin/Editor/Member/Guest)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../viewmodels/auth_provider.dart';
import 'home_screen.dart';
import 'online_screen.dart';
import 'my_stories_screen.dart';
import 'reading_history_screen.dart';
import 'profile_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import '../viewmodels/online_manga_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final onlineMangaProvider = context.read<OnlineMangaProvider>();
        final authProvider = context.read<AuthProvider>();
        if (authProvider.isAuthenticated) {
          onlineMangaProvider.loadFavorites();
          onlineMangaProvider.loadReadingProgress();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi role để tự cập nhật navigation
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.currentRole;

    // Xây dựng danh sách tab theo role
    final List<_NavItem> navItems = _buildNavItems(role);

    // Đảm bảo currentIndex không vượt quá số tab
    if (_currentIndex >= navItems.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      extendBody: true, // Quan trọng: Cho phép danh sách cuộn trượt xuống dưới nền của thanh Dock
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: navItems.map((item) => item.screen).toList(),
          ),
          // Hiệu ứng mờ dần (Gradient fade) ở đáy màn hình
          // Thanh Dock: bottom margin = 8, height = 56 => nửa thanh = 36px từ đáy
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 45, // Nằm gọn dưới thanh Dock
            child: IgnorePointer( // Không chặn thao tác cuộn của người dùng
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0), // Trong suốt ở trên
                      Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7), // Mờ dần tại nửa thanh bar
                      Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95), // Gần đặc ở đáy
                    ],
                    stops: const [0.0, 0.6, 1.0], // 0.6 * 90 = 54px từ trên = 36px từ đáy (nửa thanh bar)
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
          height: 56, // Chiều cao tối giản
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(32), // Bo tròn dạng viên thuốc (Pill shape)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = _currentIndex == index;

              return InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(32),
                child: Padding(
                  padding: const EdgeInsets.all(10.0), //
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack, // Hiệu ứng nảy nhẹ
                    transform: Matrix4.identity()..scale(isSelected ? 1.15 : 1.0),
                    transformAlignment: Alignment.center,
                    child: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      size: 26,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary // Bắt màu chủ đạo
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Xây dựng danh sách Navigation Item theo vai trò người dùng
  List<_NavItem> _buildNavItems(UserRole role) {
    // Tab cơ bản cho tất cả mọi người (kể cả Guest)
    final baseItems = [
      _NavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Trang chủ',
        screen: const HomeScreen(),
      ),
      _NavItem(
        icon: Icons.cloud_outlined,
        selectedIcon: Icons.cloud,
        label: 'Online',
        screen: const OnlineScreen(),
      ),
      _NavItem(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: 'Lịch sử',
        screen: const ReadingHistoryScreen(),
      ),
      _NavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Hồ sơ',
        screen: const ProfileScreen(),
      ),
    ];

    // Tab bổ sung cho Editor
    if (role == UserRole.editor) {
      return [
        baseItems[0], // Trang chủ
        baseItems[1], // Online
        _NavItem(
          icon: Icons.edit_note_outlined,
          selectedIcon: Icons.edit_note,
          label: 'Editor',
          screen: const MyStoriesScreen(),
        ),
        baseItems[2], // Lịch sử
        baseItems[3], // Hồ sơ
      ];
    }

    // Tab bổ sung cho Admin (có thêm tab Quản trị & Quản lý truyện)
    if (role == UserRole.admin) {
      return [
        baseItems[0], // Trang chủ
        baseItems[1], // Online
        _NavItem(
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          label: 'Quản trị',
          screen: const AdminDashboardScreen(),
        ),
        _NavItem(
          icon: Icons.edit_note_outlined,
          selectedIcon: Icons.edit_note,
          label: 'Editor',
          screen: const MyStoriesScreen(),
        ),
        baseItems[3], // Hồ sơ
      ];
    }

    // Member, VIP, Guest: chỉ có tab cơ bản
    return baseItems;
  }
}

/// Dữ liệu một tab Navigation
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.screen,
  });
}
