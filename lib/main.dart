// lib/main.dart
// Điểm vào chính của ứng dụng

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

import 'viewmodels/auth_provider.dart';
import 'viewmodels/story_provider.dart';
import 'viewmodels/theme_provider.dart';
import 'views/auth_screen.dart';
import 'views/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load biến môi trường từ .env
  await dotenv.load(fileName: ".env");

  // Khởi tạo Firebase với options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
