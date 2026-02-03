// lib/viewmodels/theme_provider.dart
// Provider quản lý chế độ giao diện Tối/Sáng - Tối ưu hiệu năng

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';

  bool _isDarkMode = false;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Getter
  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  // Trả về ThemeMode thay vì ThemeData để tối ưu
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  // Tải theme từ SharedPreferences
  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool(_themeKey) ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  // Chuyển đổi theme - không cần await để UI mượt hơn
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    // Lưu async không chờ
    _prefs?.setBool(_themeKey, _isDarkMode);
  }

  // Đặt theme cụ thể
  void setDarkMode(bool value) {
    if (_isDarkMode == value) return; // Không làm gì nếu không đổi
    _isDarkMode = value;
    notifyListeners();
    _prefs?.setBool(_themeKey, _isDarkMode);
  }

  // Light Theme - định nghĩa static để không phải tạo lạio
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  // Dark Theme - Điều chỉnh sáng hơn để dễ đọc
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFBB86FC),
      onPrimary: Color(0xFF1F1F1F),
      primaryContainer: Color(0xFF4A3B6B),
      onPrimaryContainer: Color(0xFFE8DEF8),
      secondary: Color(0xFF03DAC6),
      onSecondary: Color(0xFF1F1F1F),
      secondaryContainer: Color(0xFF1E4E4A),
      onSecondaryContainer: Color(0xFFA7F3EE),
      tertiary: Color(0xFFFFB74D),
      onTertiary: Color(0xFF1F1F1F),
      tertiaryContainer: Color(0xFF5D4037),
      onTertiaryContainer: Color(0xFFFFE0B2),
      error: Color(0xFFCF6679),
      onError: Color(0xFF1F1F1F),
      surface: Color(0xFF2D2D2D), // Nền sáng hơn (trước: 0xFF121212)
      onSurface: Color(0xFFEEEEEE), // Text sáng hơn
      surfaceContainerHighest: Color(0xFF3D3D3D),
      onSurfaceVariant: Color(0xFFCACACA), // Text phụ sáng hơn
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF2D2D2D),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: const Color(0xFF3A3A3A), // Card sáng hơn
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF3A3A3A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFF252525), // Nền scaffold sáng hơn
  );
}
