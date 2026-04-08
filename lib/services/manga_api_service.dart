// lib/services/manga_api_service.dart
// Service gọi API truyện tranh online từ server

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/online_manga.dart';
import 'custom_auth_service.dart';

/// Service xử lý tất cả các HTTP request tới Manga API
class MangaApiService {
  // URL gốc của API server
  static const String baseUrl = 'http://192.168.3.237:8180/api/v1';

  // Thời gian chờ tối đa cho mỗi request (giây)
  static const Duration _timeout = Duration(seconds: 15);

  /// Header mặc định kèm Token nếu có
  static Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await CustomAuthService.getStoredToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Lấy danh sách truyện (Trang chủ Online)
  /// [type] - Loại danh sách: truyen-moi, sap-ra-mat, dang-phat-hanh, hoan-thanh
  /// [page] - Số trang (bắt đầu từ 1)
  /// [pageSize] - Số lượng truyện mỗi trang (tuỳ chọn)
  /// Trả về Map chứa danh sách manga và thông tin phân trang
  static Future<Map<String, dynamic>> getMangas({
    String type = 'truyen-moi',
    int page = 1,
    int? pageSize,
  }) async {
    try {
      // Xây dựng URL với query parameters
      final queryParams = <String, String>{
        'type': type,
        'page': page.toString(),
      };
      if (pageSize != null) {
        queryParams['pageSize'] = pageSize.toString();
      }

      final uri = Uri.parse(
        '$baseUrl/manga',
      ).replace(queryParameters: queryParams);
      debugPrint('🌐 Đang gọi API: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];

          // Parse danh sách manga
          final mangaList =
              (data['manga'] as List?)
                  ?.map(
                    (item) =>
                        OnlineManga.fromJson(item as Map<String, dynamic>),
                  )
                  .toList() ??
              [];

          // Parse thông tin phân trang
          final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

          debugPrint('✅ Đã tải ${mangaList.length} truyện (trang $page)');

          return {'manga': mangaList, 'pagination': pagination};
        }
      }

      debugPrint('❌ API trả về lỗi: ${response.statusCode}');
      return {'manga': <OnlineManga>[], 'pagination': {}};
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi API danh sách truyện: $e');
      rethrow;
    }
  }

  /// Lấy chi tiết thông tin truyện theo slug
  /// [slug] - Slug của truyện (vd: "dao-hai-tac")
  /// Trả về OnlineMangaDetail hoặc null nếu không tìm thấy
  static Future<OnlineMangaDetail?> getMangaDetail(String slug) async {
    try {
      final uri = Uri.parse('$baseUrl/manga/$slug');
      debugPrint('🌐 Đang gọi API chi tiết: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final detail = OnlineMangaDetail.fromJson(
            jsonData['data'] as Map<String, dynamic>,
          );
          debugPrint('✅ Đã tải chi tiết truyện: ${detail.title}');
          return detail;
        }
      }

      debugPrint('❌ Không tìm thấy truyện với slug: $slug');
      return null;
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi API chi tiết truyện: $e');
      rethrow;
    }
  }

  /// Lấy nội dung ảnh của một chapter
  /// [chapterId] - ID chapter (vd: "chapter-100")
  /// Trả về Map chứa tên chapter, tên truyện, và danh sách URL ảnh
  static Future<Map<String, dynamic>?> getChapterImages(
    String chapterId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/manga/chapter/$chapterId');
      debugPrint('🌐 Đang gọi API chapter: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'] as Map<String, dynamic>;

          // Lấy danh sách ảnh từ response
          final images =
              (data['images'] as List?)
                  ?.map((img) => img.toString())
                  .toList() ??
              [];

          debugPrint('✅ Đã tải ${images.length} ảnh chapter');

          return {
            'chapter_name': data['chapter_name']?.toString() ?? '',
            'comic_name': data['comic_name']?.toString() ?? '',
            'images': images,
          };
        }
      }

      debugPrint('❌ Không tải được chapter: $chapterId');
      return null;
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi API chapter: $e');
      rethrow;
    }
  }

  /// Tìm kiếm truyện tranh theo từ khoá
  /// [query] - Từ khoá tìm kiếm
  /// Trả về danh sách truyện tìm thấy
  static Future<List<OnlineManga>> searchManga(String query) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/manga/search',
      ).replace(queryParameters: {'query': query});
      debugPrint('🌐 Đang tìm kiếm: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final results = (jsonData['data'] as List)
              .map((item) => OnlineManga.fromJson(item as Map<String, dynamic>))
              .toList();

          debugPrint('✅ Tìm thấy ${results.length} kết quả cho "$query"');
          return results;
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ Lỗi khi tìm kiếm truyện: $e');
      rethrow;
    }
  }

  /// Lấy danh sách tất cả thể loại truyện
  /// Trả về danh sách OnlineCategory
  static Future<List<OnlineCategory>> getCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/manga/categories');
      debugPrint('🌐 Đang gọi API thể loại: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final categories = (jsonData['data'] as List)
              .map(
                (item) => OnlineCategory.fromJson(item as Map<String, dynamic>),
              )
              .toList();

          debugPrint('✅ Đã tải ${categories.length} thể loại');
          return categories;
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi API thể loại: $e');
      rethrow;
    }
  }

  /// Lấy danh sách truyện theo thể loại
  /// [categorySlug] - Slug của thể loại (vd: "action")
  /// [page] - Số trang
  /// Trả về Map chứa danh sách manga và thông tin phân trang
  static Future<Map<String, dynamic>> getMangaByCategory(
    String categorySlug, {
    int page = 1,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, String>{'page': page.toString()};
      if (pageSize != null) {
        queryParams['pageSize'] = pageSize.toString();
      }

      final uri = Uri.parse(
        '$baseUrl/manga/category/$categorySlug',
      ).replace(queryParameters: queryParams);
      debugPrint('🌐 Đang gọi API thể loại $categorySlug: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];

          final mangaList =
              (data['manga'] as List?)
                  ?.map(
                    (item) =>
                        OnlineManga.fromJson(item as Map<String, dynamic>),
                  )
                  .toList() ??
              [];

          final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

          debugPrint(
            '✅ Đã tải ${mangaList.length} truyện thể loại $categorySlug',
          );

          return {'manga': mangaList, 'pagination': pagination};
        }
      }

      return {'manga': <OnlineManga>[], 'pagination': {}};
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi API truyện theo thể loại: $e');
      rethrow;
    }
  }

  // ==================== FAVORITES API ====================

  /// Lấy danh sách truyện yêu thích từ Server
  static Future<List<OnlineManga>> getFavorites({int page = 1}) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/favorites',
      ).replace(queryParameters: {'page': page.toString()});
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final items = jsonData['data']['items'] as List?;
          return items
                  ?.map((item) => OnlineManga.fromJson(item['manga']))
                  .toList() ??
              [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ Manga API Lỗi tải danh sách yêu thích: $e');
      return [];
    }
  }

  /// Thêm truyện yêu thích lên Server
  static Future<bool> addFavorite({
    required String mangaSlug,
    String? mangaTitle,
    String? mangaImage,
  }) async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return false;

      final body = json.encode({
        'mangaSlug': mangaSlug,
        'mangaTitle': mangaTitle ?? '',
        'mangaImage': mangaImage ?? '',
      });

      final response = await http
          .post(Uri.parse('$baseUrl/favorites'), headers: headers, body: body)
          .timeout(_timeout);

      final jsonData = json.decode(response.body);
      return response.statusCode == 201 ||
          (response.statusCode == 200 && jsonData['success'] == true);
    } catch (e) {
      debugPrint('❌ Manga API Lỗi thêm yêu thích: $e');
      return false;
    }
  }

  /// Xóa truyện yêu thích khỏi Server
  static Future<bool> removeFavorite(String mangaSlug) async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return false;

      final uri = Uri.parse('$baseUrl/favorites/$mangaSlug');
      final response = await http
          .delete(uri, headers: headers)
          .timeout(_timeout);

      final jsonData = json.decode(response.body);
      return response.statusCode == 200 && jsonData['success'] == true;
    } catch (e) {
      debugPrint('❌ Manga API Lỗi xóa yêu thích: $e');
      return false;
    }
  }

  // ==================== READING PROGRESS API ====================

  /// Lấy danh sách lịch sử đọc từ Server
  static Future<List<Map<String, dynamic>>> getReadingProgress() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/progress'), headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ Manga API Lỗi tải lịch sử đọc: $e');
      return [];
    }
  }

  /// Cập nhật tiến độ đọc lên Server
  static Future<bool> updateReadingProgress({
    required String mangaSlug,
    required String chapterApiId,
    String? mangaTitle,
    String? mangaImage,
    String? chapterName,
    int pageIndex = 0,
  }) async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization'))
        return false; // Guest không lưu lịch sử Cloud

      final body = json.encode({
        'mangaSlug': mangaSlug,
        'chapterApiId': chapterApiId,
        'mangaTitle': mangaTitle ?? '',
        'mangaImage': mangaImage ?? '',
        'chapterName': chapterName ?? '',
        'pageIndex': pageIndex,
      });

      final response = await http
          .put(Uri.parse('$baseUrl/progress'), headers: headers, body: body)
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Manga API Cập nhật tiến độ lỗi: $e');
      return false;
    }
  }

  // ==================== PAYMENT & PLANS ====================

  /// Lấy danh sách các gói cước đang bán
  static Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/plans'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ Manga API lỗi tải danh sách Plans: $e');
      return [];
    }
  }

  /// Gọi API tạo payment URL VNPay
  static Future<String?> createPaymentUrl(String planId) async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return null;

      final body = json.encode({'planId': planId});

      final response = await http
          .post(
            Uri.parse('$baseUrl/payment/create-url'),
            headers: headers,
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['paymentUrl'] != null) {
          return jsonData['paymentUrl'].toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Manga API lỗi tạo payment URL: $e');
      return null;
    }
  }
}
