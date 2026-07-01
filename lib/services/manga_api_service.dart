// lib/services/manga_api_service.dart
// Dịch vụ gọi API truyện tranh online từ server OTruyen và lưu trữ dữ liệu cục bộ

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/online_manga.dart';

/// Dịch vụ xử lý tất cả các HTTP request tới Manga API của OTruyen
class MangaApiService {
  // Đường dẫn gốc của API OTruyen
  static const String baseUrl = 'https://otruyenapi.com/v1/api';

  // Thời gian chờ tối đa cho mỗi request (giây)
  static const Duration _timeout = Duration(seconds: 15);

  // Khóa lưu trữ danh sách yêu thích trong SharedPreferences
  static const String _favoritesPrefKey = 'otruyen_favorites_local';

  // Khóa lưu trữ lịch sử đọc trong SharedPreferences
  static const String _progressPrefKey = 'otruyen_progress_local';

  /// Ghép đường dẫn ảnh đầy đủ từ CDN của OTruyen
  static String _getFullThumbUrl(String thumbUrl, String cdnDomain) {
    if (thumbUrl.isEmpty) return '';
    if (thumbUrl.startsWith('http')) return thumbUrl;
    final cleanDomain = cdnDomain.replaceFirst(RegExp(r'^https?://'), '');
    return 'https://$cleanDomain/uploads/comics/$thumbUrl';
  }

  /// Trích xuất thông tin tác giả từ dữ liệu trả về của API
  static String _parseAuthor(dynamic authorData) {
    if (authorData == null) return 'Đang cập nhật';
    if (authorData is List && authorData.isNotEmpty) {
      return authorData.first?.toString() ?? 'Đang cập nhật';
    }
    if (authorData is String) {
      return authorData;
    }
    return 'Đang cập nhật';
  }

  /// Tính số lượng chương dựa trên chương mới nhất được cập nhật
  static int _parseChaptersCount(dynamic chaptersLatest) {
    if (chaptersLatest != null && chaptersLatest is List && chaptersLatest.isNotEmpty) {
      final firstChap = chaptersLatest.first;
      if (firstChap is Map) {
        final chapName = firstChap['chapter_name']?.toString() ?? '0';
        final match = RegExp(r'(\d+)').firstMatch(chapName);
        if (match != null) {
          return int.tryParse(match.group(1)!) ?? 0;
        }
        return int.tryParse(chapName) ?? 0;
      }
    }
    return 0;
  }

  /// Chuyển đổi dữ liệu JSON từ API thành đối tượng OnlineManga
  static OnlineManga _parseManga(Map<String, dynamic> item, String cdnDomain) {
    final thumbUrl = item['thumb_url']?.toString() ?? '';
    final fullThumbUrl = _getFullThumbUrl(thumbUrl, cdnDomain);
    final authorName = _parseAuthor(item['author']);
    final chaptersCount = _parseChaptersCount(item['chaptersLatest']);

    return OnlineManga(
      id: item['_id']?.toString() ?? '',
      slug: item['slug']?.toString() ?? '',
      title: item['name']?.toString() ?? 'Không có tiêu đề',
      image: fullThumbUrl,
      status: item['status']?.toString() ?? 'Đang cập nhật',
      author: authorName,
      description: item['content']?.toString() ?? '',
      updatedAt: item['updatedAt'] != null
          ? DateTime.tryParse(item['updatedAt'].toString())
          : null,
      chapters: chaptersCount,
    );
  }

  /// Phân tích thông tin phân trang từ API OTruyen
  static Map<String, dynamic> _parsePagination(Map<String, dynamic> data) {
    final params = data['params'] ?? {};
    final paginationData = params['pagination'] ?? {};
    
    final int totalItems = int.tryParse(paginationData['totalItems']?.toString() ?? '0') ?? 0;
    final int totalItemsPerPage = int.tryParse(paginationData['totalItemsPerPage']?.toString() ?? '24') ?? 24;
    final int currentPage = int.tryParse(paginationData['currentPage']?.toString() ?? '1') ?? 1;
    
    return {
      'totalItems': totalItems,
      'itemsPerPage': totalItemsPerPage,
      'currentPage': currentPage,
    };
  }

  /// Lấy danh sách truyện (Trang chủ Online)
  /// [type] - Loại danh sách: truyen-moi, sap-ra-mat, dang-phat-hanh, hoan-thanh
  /// [page] - Số trang (bắt đầu từ 1)
  /// [pageSize] - Số lượng truyện mỗi trang (để giữ đúng chữ ký hàm)
  static Future<Map<String, dynamic>> getMangas({
    String type = 'truyen-moi',
    int page = 1,
    int? pageSize,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/danh-sach/$type?page=$page');
      debugPrint('🌐 Đang gọi API OTruyen: $uri');

      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return {'manga': <OnlineManga>[], 'pagination': <String, dynamic>{}};
      }

      final jsonData = json.decode(response.body);
      if (jsonData['status'] != 'success' || jsonData['data'] == null) {
        return {'manga': <OnlineManga>[], 'pagination': <String, dynamic>{}};
      }

      final data = jsonData['data'];
      final cdnDomain = data['APP_DOMAIN_CDN_IMAGE']?.toString() ?? 'img.otruyenapi.com';
      final items = data['items'] as List? ?? [];
      
      final mangaList = items.map((item) => _parseManga(item as Map<String, dynamic>, cdnDomain)).toList();
      final pagination = _parsePagination(data);

      debugPrint('✅ Đã tải ${mangaList.length} truyện (trang $page)');
      return {'manga': mangaList, 'pagination': pagination};
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi API danh sách truyện: $e');
      return {'manga': <OnlineManga>[], 'pagination': <String, dynamic>{}};
    }
  }

  /// Phân tích danh sách thể loại từ dữ liệu thô
  static List<OnlineCategory> _parseCategoriesList(dynamic categoryData) {
    if (categoryData == null || categoryData is! List) return [];
    return categoryData.map((cat) {
      return OnlineCategory(
        id: cat['_id']?.toString() ?? '',
        slug: cat['slug']?.toString() ?? '',
        name: cat['name']?.toString() ?? '',
      );
    }).toList();
  }

  /// Trích xuất số từ văn bản
  static double _extractNum(String text) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
    return match != null ? (double.tryParse(match.group(1)!) ?? 0.0) : 0.0;
  }

  /// Sắp xếp danh sách chương theo thứ tự tăng dần của chương
  static void _sortChapters(List<OnlineChapter> chapters) {
    chapters.sort((a, b) {
      final aNum = _extractNum(a.name);
      final bNum = _extractNum(b.name);
      return aNum.compareTo(bNum);
    });
  }

  /// Gộp các chương của một server vào danh sách chung, loại bỏ trùng lặp
  static void _mergeServerChapters(
    List<dynamic> serverData,
    List<OnlineChapter> allChapters,
    Set<String> addedChapterNames,
  ) {
    for (final ch in serverData) {
      if (ch is Map) {
        final chName = ch['chapter_name']?.toString() ?? '';
        if (chName.isNotEmpty && !addedChapterNames.contains(chName)) {
          addedChapterNames.add(chName);
          final chTitle = ch['chapter_title']?.toString() ?? '';
          final displayName = chTitle.isNotEmpty ? 'Chương $chName: $chTitle' : 'Chương $chName';
          
          allChapters.add(OnlineChapter(
            apiId: ch['chapter_api_data']?.toString() ?? '',
            name: displayName,
          ));
        }
      }
    }
  }

  /// Phân tích danh sách chương truyện từ dữ liệu thô (gộp tất cả các server)
  static List<OnlineChapter> _parseChaptersList(dynamic chaptersData) {
    if (chaptersData == null || chaptersData is! List || chaptersData.isEmpty) return [];
    
    final List<OnlineChapter> allChapters = [];
    final Set<String> addedChapterNames = {};

    for (final server in chaptersData) {
      if (server is Map && server['server_data'] is List) {
        _mergeServerChapters(server['server_data'] as List, allChapters, addedChapterNames);
      }
    }

    _sortChapters(allChapters);
    return allChapters;
  }

  /// Xây dựng đối tượng chi tiết truyện tranh OnlineDetail
  static OnlineMangaDetail _buildMangaDetail(Map<String, dynamic> item, String cdnDomain) {
    final thumbUrl = item['thumb_url']?.toString() ?? '';
    final fullThumbUrl = _getFullThumbUrl(thumbUrl, cdnDomain);
    final authorName = _parseAuthor(item['author']);
    final categoriesList = _parseCategoriesList(item['category']);
    final chaptersList = _parseChaptersList(item['chapters']);

    return OnlineMangaDetail(
      id: item['_id']?.toString() ?? '',
      title: item['name']?.toString() ?? 'Không có tiêu đề',
      description: item['content']?.toString() ?? 'Không có mô tả',
      author: authorName,
      image: fullThumbUrl,
      status: item['status']?.toString() ?? 'Đang cập nhật',
      categories: categoriesList,
      chapters: chaptersList,
    );
  }

  /// Lấy chi tiết thông tin truyện theo slug
  static Future<OnlineMangaDetail?> getMangaDetail(String slug) async {
    try {
      final uri = Uri.parse('$baseUrl/truyen-tranh/$slug');
      debugPrint('🌐 Đang gọi API chi tiết OTruyen: $uri');

      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final jsonData = json.decode(response.body);
      if (jsonData['status'] != 'success' || jsonData['data'] == null) return null;

      final data = jsonData['data'];
      final item = data['item'] ?? {};
      final cdnDomain = data['APP_DOMAIN_CDN_IMAGE']?.toString() ?? 'img.otruyenapi.com';

      return _buildMangaDetail(item, cdnDomain);
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi API chi tiết truyện: $e');
      return null;
    }
  }

  /// Tạo cấu trúc danh sách ảnh của chapter từ dữ liệu thô
  static Map<String, dynamic> _buildChapterImagesData(Map<String, dynamic> item, String cdnDomain) {
    final chapterPath = item['chapter_path']?.toString() ?? '';
    var cleanDomain = cdnDomain.trim();
    if (!cleanDomain.startsWith('http://') && !cleanDomain.startsWith('https://')) {
      cleanDomain = 'https://$cleanDomain';
    }

    final chapterImages = item['chapter_image'] as List? ?? [];
    final images = chapterImages.map((img) {
      final file = img['image_file']?.toString() ?? '';
      return '$cleanDomain/$chapterPath/$file';
    }).toList();

    final chName = item['chapter_name']?.toString() ?? '';
    final chTitle = item['chapter_title']?.toString() ?? '';
    final displayName = chTitle.isNotEmpty ? 'Chương $chName: $chTitle' : 'Chương $chName';

    return {
      'chapter_name': displayName,
      'comic_name': item['comic_name']?.toString() ?? '',
      'images': images,
    };
  }

  /// Lấy nội dung ảnh của một chapter
  /// [chapterId] - ID chapter (Ở đây chính là URL chapter_api_data đầy đủ)
  static Future<Map<String, dynamic>?> getChapterImages(String chapterId) async {
    try {
      final uri = Uri.parse(chapterId);
      debugPrint('🌐 Đang gọi API chapter OTruyen: $uri');

      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final jsonData = json.decode(response.body);
      if (jsonData['status'] != 'success' || jsonData['data'] == null) return null;

      final data = jsonData['data'] as Map<String, dynamic>;
      final item = data['item'] as Map<String, dynamic>? ?? {};
      final cdnDomain = data['domain_cdn']?.toString() ?? 'sv1.otruyencdn.com';

      return _buildChapterImagesData(item, cdnDomain);
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi API chapter: $e');
      return null;
    }
  }

  /// Tìm kiếm truyện tranh theo từ khoá
  static Future<List<OnlineManga>> searchManga(String query) async {
    try {
      final encodedKeyword = Uri.encodeComponent(query);
      final uri = Uri.parse('$baseUrl/tim-kiem?keyword=$encodedKeyword&page=1');
      debugPrint('🌐 Đang tìm kiếm OTruyen: $uri');

      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final jsonData = json.decode(response.body);
      if (jsonData['status'] != 'success' || jsonData['data'] == null) return [];

      final data = jsonData['data'];
      final cdnDomain = data['APP_DOMAIN_CDN_IMAGE']?.toString() ?? 'img.otruyenapi.com';
      final items = data['items'] as List? ?? [];

      return items.map((item) => _parseManga(item as Map<String, dynamic>, cdnDomain)).toList();
    } catch (e) {
      debugPrint('❌ Lỗi khi tìm kiếm truyện: $e');
      return [];
    }
  }

  /// Lấy danh sách tất cả thể loại truyện
  static Future<List<OnlineCategory>> getCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/the-loai');
      debugPrint('🌐 Đang gọi API thể loại OTruyen: $uri');

      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final jsonData = json.decode(response.body);
      if (jsonData['status'] != 'success' || jsonData['data'] == null) return [];

      final items = jsonData['data']['items'] as List? ?? [];
      return items.map((item) {
        return OnlineCategory(
          id: item['_id']?.toString() ?? '',
          slug: item['slug']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi API thể loại: $e');
      return [];
    }
  }

  /// Lấy danh sách truyện theo thể loại
  static Future<Map<String, dynamic>> getMangaByCategory(
    String categorySlug, {
    int page = 1,
    int? pageSize,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/the-loai/$categorySlug?page=$page');
      debugPrint('🌐 Đang gọi API truyện theo thể loại OTruyen: $uri');

      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return {'manga': <OnlineManga>[], 'pagination': <String, dynamic>{}};
      }

      final jsonData = json.decode(response.body);
      if (jsonData['status'] != 'success' || jsonData['data'] == null) {
        return {'manga': <OnlineManga>[], 'pagination': <String, dynamic>{}};
      }

      final data = jsonData['data'];
      final cdnDomain = data['APP_DOMAIN_CDN_IMAGE']?.toString() ?? 'img.otruyenapi.com';
      final items = data['items'] as List? ?? [];

      final mangaList = items.map((item) => _parseManga(item as Map<String, dynamic>, cdnDomain)).toList();
      final pagination = _parsePagination(data);

      return {'manga': mangaList, 'pagination': pagination};
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi API truyện theo thể loại: $e');
      return {'manga': <OnlineManga>[], 'pagination': <String, dynamic>{}};
    }
  }

  // ==================== LOCAL FAVORITES (OFFLINE) ====================

  /// Lấy danh sách truyện yêu thích từ bộ nhớ cục bộ
  static Future<List<OnlineManga>> getFavorites({int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesPrefKey);
      if (favoritesJson == null) {
        return [];
      }

      final List<dynamic> decodedList = json.decode(favoritesJson);
      return decodedList.map((item) => OnlineManga.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ Lỗi đọc danh sách yêu thích cục bộ: $e');
      return [];
    }
  }

  /// Thêm truyện yêu thích vào bộ nhớ cục bộ
  static Future<bool> addFavorite({
    required String mangaSlug,
    String? mangaTitle,
    String? mangaImage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();
      
      if (favorites.any((e) => e.slug == mangaSlug)) {
        return true;
      }

      final newFav = OnlineManga(
        id: mangaSlug,
        slug: mangaSlug,
        title: mangaTitle ?? 'Không có tiêu đề',
        image: mangaImage,
        status: 'Đang cập nhật',
        author: 'Đang cập nhật',
        description: '',
        updatedAt: DateTime.now(),
        chapters: 0,
      );

      favorites.insert(0, newFav);

      final encoded = json.encode(favorites.map((e) => {
        'id': e.id,
        'slug': e.slug,
        'title': e.title,
        'image': e.image,
        'status': e.status,
        'author': e.author,
        'description': e.description,
        'updatedAt': e.updatedAt?.toIso8601String(),
        'chapters': e.chapters,
      }).toList());

      await prefs.setString(_favoritesPrefKey, encoded);
      return true;
    } catch (e) {
      debugPrint('❌ Lỗi thêm yêu thích cục bộ: $e');
      return false;
    }
  }

  /// Xóa truyện yêu thích khỏi bộ nhớ cục bộ
  static Future<bool> removeFavorite(String mangaSlug) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();
      
      favorites.removeWhere((e) => e.slug == mangaSlug);

      final encoded = json.encode(favorites.map((e) => {
        'id': e.id,
        'slug': e.slug,
        'title': e.title,
        'image': e.image,
        'status': e.status,
        'author': e.author,
        'description': e.description,
        'updatedAt': e.updatedAt?.toIso8601String(),
        'chapters': e.chapters,
      }).toList());

      await prefs.setString(_favoritesPrefKey, encoded);
      return true;
    } catch (e) {
      debugPrint('❌ Lỗi xóa yêu thích cục bộ: $e');
      return false;
    }
  }

  // ==================== LOCAL READING PROGRESS (OFFLINE) ====================

  /// Lấy danh sách lịch sử đọc từ bộ nhớ cục bộ
  static Future<List<Map<String, dynamic>>> getReadingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressPrefKey);
      if (progressJson == null) {
        return [];
      }

      final List<dynamic> decodedList = json.decode(progressJson);
      return List<Map<String, dynamic>>.from(decodedList);
    } catch (e) {
      debugPrint('❌ Lỗi đọc tiến độ đọc cục bộ: $e');
      return [];
    }
  }

  /// Cập nhật tiến độ đọc cục bộ
  static Future<bool> updateReadingProgress({
    required String mangaSlug,
    required String chapterApiId,
    String? mangaTitle,
    String? mangaImage,
    String? chapterName,
    int pageIndex = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressList = await getReadingProgress();

      final index = progressList.indexWhere((e) => e['mangaSlug'] == mangaSlug);

      final progressData = {
        'mangaSlug': mangaSlug,
        'chapterApiId': chapterApiId,
        'mangaTitle': mangaTitle ?? '',
        'mangaImage': mangaImage ?? '',
        'chapterName': chapterName ?? '',
        'pageIndex': pageIndex,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (index >= 0) {
        progressList.removeAt(index);
      }
      progressList.insert(0, progressData);

      await prefs.setString(_progressPrefKey, json.encode(progressList));
      return true;
    } catch (e) {
      debugPrint('❌ Lỗi cập nhật tiến độ đọc cục bộ: $e');
      return false;
    }
  }

  // ==================== PAYMENT & PLANS (OFFLINE mock) ====================

  /// Lấy danh sách các gói cước đang bán (trả về danh sách giả lập)
  static Future<List<Map<String, dynamic>>> getPlans() async {
    return [
      {
        'id': 'plan_free',
        'name': 'Gói Miễn Phí',
        'price': 0,
        'description': 'Đọc tất cả các truyện miễn phí từ OTruyen',
        'durationDays': 30,
      },
      {
        'id': 'plan_vip_local',
        'name': 'Gói VIP Vô Hạn',
        'price': 0,
        'description': 'Gói VIP giả lập offline dành cho lập trình viên',
        'durationDays': 9999,
      }
    ];
  }

  /// Gọi API tạo payment URL (trả về null vì offline)
  static Future<String?> createPaymentUrl(String planId) async {
    return null;
  }

  // ============= EDITOR APIs (GIAI ĐOẠN 2 - OFFLINE mock) =============

  /// Lấy danh sách truyện do chính Editor/Admin này quản lý (offline)
  static Future<List<OnlineManga>> getEditorMangas() async {
    return [];
  }

  /// Tạo truyện mới (offline)
  static Future<bool> createManga({
    required String title,
    String? author,
    String? description,
    required String status,
    required File coverFile,
    bool? isVip,
    String? genres,
  }) async {
    debugPrint('⚠️ Tạo truyện offline không được hỗ trợ');
    return false;
  }

  /// Tạo chương mới (offline)
  static Future<bool> createChapter({
    required String mangaSlug,
    required String chapterNum,
    String? title,
    required List<File> imageFiles,
  }) async {
    debugPrint('⚠️ Tạo chương offline không được hỗ trợ');
    return false;
  }
}
