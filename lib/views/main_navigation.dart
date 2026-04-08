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

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

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
      body: IndexedStack(
        index: _currentIndex,
        children: navItems.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
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
          label: 'Quản lý truyện',
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
          label: 'Quản lý truyện',
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
