// lib/services/image_database_service.dart
// Service lưu trữ ảnh và nội dung chương vào Hive database

import 'dart:convert';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class ImageDatabaseService {
  static const String _imageBoxName = 'chapter_images';
  static const String _chapterBoxName = 'chapter_content';
  static Box<Uint8List>? _imageBox;
  static Box<String>? _chapterBox;

  /// Khởi tạo và mở boxes
  static Future<void> init() async {
    if (_imageBox == null || !_imageBox!.isOpen) {
      _imageBox = await Hive.openBox<Uint8List>(_imageBoxName);
    }
    if (_chapterBox == null || !_chapterBox!.isOpen) {
      _chapterBox = await Hive.openBox<String>(_chapterBoxName);
    }
  }

  // ==================== IMAGE METHODS ====================

  /// Lấy ảnh từ database nếu có
  static Uint8List? getImage(String url) {
    return _imageBox?.get(_urlToKey(url));
  }

  /// Kiểm tra ảnh đã có trong database chưa
  static bool hasImage(String url) {
    return _imageBox?.containsKey(_urlToKey(url)) ?? false;
  }

  /// Download và lưu ảnh vào database
  static Future<Uint8List?> downloadAndSaveImage(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      // Kiểm tra nếu đã có trong database
      final cached = getImage(url);
      if (cached != null) {
        return cached;
      }

      // Download ảnh
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Lưu vào database
        await _imageBox?.put(_urlToKey(url), bytes);

        return bytes;
      }
      return null;
    } catch (e) {
      print('Error downloading image: $e');
      return null;
    }
  }

  /// Xóa 1 ảnh
  static Future<void> deleteImage(String url) async {
    await _imageBox?.delete(_urlToKey(url));
  }

  /// Xóa tất cả ảnh
  static Future<void> clearAllImages() async {
    await _imageBox?.clear();
  }

  /// Lấy số lượng ảnh đã lưu
  static int get imageCount => _imageBox?.length ?? 0;

  /// Lấy dung lượng ước tính (bytes)
  static int get estimatedSize {
    int total = 0;
    _imageBox?.values.forEach((bytes) {
      total += bytes.length;
    });
    return total;
  }

  // ==================== CHAPTER CONTENT METHODS ====================

  /// Lưu nội dung chương (JSON) vào database
  static Future<void> saveChapterContent(
    String chapterApiData,
    Map<String, dynamic> content,
  ) async {
    final jsonStr = jsonEncode(content);
    await _chapterBox?.put(_urlToKey(chapterApiData), jsonStr);
  }

  /// Lấy nội dung chương từ database
  static Map<String, dynamic>? getChapterContent(String chapterApiData) {
    final jsonStr = _chapterBox?.get(_urlToKey(chapterApiData));
    if (jsonStr != null) {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    }
    return null;
  }

  /// Kiểm tra chương đã được cache chưa
  static bool hasChapterContent(String chapterApiData) {
    return _chapterBox?.containsKey(_urlToKey(chapterApiData)) ?? false;
  }

  /// Xóa tất cả chapter content
  static Future<void> clearAllChapters() async {
    await _chapterBox?.clear();
  }

  /// Xóa tất cả dữ liệu
  static Future<void> clearAll() async {
    await _imageBox?.clear();
    await _chapterBox?.clear();
  }

  /// Chuyển URL thành key an toàn cho Hive
  static String _urlToKey(String url) {
    // Sử dụng hashCode để tạo key ngắn gọn
    return url.hashCode.toString();
  }
}
