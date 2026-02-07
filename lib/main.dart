// lib/main.dart
// Điểm vào chính của ứng dụng

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

import 'viewmodels/auth_provider.dart';
import 'viewmodels/story_provider.dart';
import 'viewmodels/theme_provider.dart';
import 'views/auth_screen.dart';
import 'views/main_navigation.dart';
import 'services/image_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load biến môi trường từ .env
  await dotenv.load(fileName: ".env");

  // Khởi tạo Firebase với options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo Hive cho database ảnh
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
        // Provider xác thực
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Provider truyện
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        // Provider giao diện
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Ứng Dụng Đọc Truyện',
            debugShowCheckedModeBanner: false,
            // Sử dụng theme và darkTheme cố định, chỉ đổi themeMode
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode:
                themeProvider.themeMode, // Chỉ đổi mode, không rebuild theme
            // Builder để full screen background trên desktop/web
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1A1A2E),
                            const Color(0xFF16213E),
                            const Color(0xFF0F3460),
                          ]
                        : [
                            const Color.fromARGB(255, 74, 107, 255),
                            const Color.fromARGB(255, 111, 63, 158),
                            const Color.fromARGB(255, 236, 61, 255),
                          ],
                  ),
                ),
                child: child,
              );
            },
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // Điều hướng dựa trên trạng thái đăng nhập
                if (authProvider.isAuthenticated) {
                  return const MainNavigation();
                }
                return const AuthScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
