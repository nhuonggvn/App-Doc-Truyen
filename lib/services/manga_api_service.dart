// lib/services/manga_api_service.dart
// Service gọi API truyện tranh online từ server

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/online_manga.dart';

/// Service xử lý tất cả các HTTP request tới Manga API
class MangaApiService {
  // URL gốc của API server
  static const String baseUrl = 'http://192.168.3.237:8180/api/v1';

  // Thời gian chờ tối đa cho mỗi request (giây)
  static const Duration _timeout = Duration(seconds: 15);

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

      final response = await http.get(uri).timeout(_timeout);

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

      final response = await http.get(uri).timeout(_timeout);

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

      final response = await http.get(uri).timeout(_timeout);

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

      final response = await http.get(uri).timeout(_timeout);

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

      final response = await http.get(uri).timeout(_timeout);

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

      final response = await http.get(uri).timeout(_timeout);

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
}
