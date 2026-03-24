// lib/views/main_navigation.dart
// Điều hướng chính với Bottom Navigation Bar (5 tab)

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_stories_screen.dart';
import 'reading_history_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Danh sách 5 màn hình: Trang chủ, Online, Truyện của tôi, Lịch sử, Hồ sơ
  final List<Widget> _screens = const [
    HomeScreen(),
    MyStoriesScreen(),
    ReadingHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          // Tab 1: Trang chủ (truyện local)
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          // Tab 2: Truyện của tôi
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Truyện của tôi',
          ),
          // Tab 3: Lịch sử đọc
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          // Tab 4: Hồ sơ cá nhân
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
