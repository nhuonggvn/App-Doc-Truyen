// lib/main.dart
// Điểm vào chính của ứng dụng - đã loại bỏ Firebase

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'viewmodels/auth_provider.dart';
import 'viewmodels/story_provider.dart';
import 'viewmodels/theme_provider.dart';
import 'viewmodels/online_manga_provider.dart';
import 'viewmodels/admin_provider.dart';
import 'views/auth_screen.dart';
import 'views/main_navigation.dart';
import 'services/image_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Hive cho database ảnh local
  await Hive.initFlutter();
  await ImageDatabaseService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider xác thực (REST API - không còn Firebase)
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthProvider();
            // Tự động khôi phục session từ token đã lưu
            auth.tryAutoLogin();
            return auth;
          },
        ),
        // Provider truyện local SQLite
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        // Provider truyện online (API)
        ChangeNotifierProvider(create: (_) => OnlineMangaProvider()),
        // Provider giao diện
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Provider thống kê hệ thống (Admin)
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Manga App',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // Đang khởi tạo: load token từ storage
                if (authProvider.status == AuthStatus.initializing) {
                  return const _SplashScreen();
                }

                // Đã đăng nhập -> vào app chính
                if (authProvider.isAuthenticated) {
                  return const MainNavigation();
                }

                // Chưa đăng nhập -> màn hình Auth
                return const AuthScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Splash Screen khi app đang kiểm tra token
// ─────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Manga App',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
