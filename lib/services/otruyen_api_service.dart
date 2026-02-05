// lib/services/otruyen_api_service.dart
// Service để gọi OTruyen API

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/otruyen_models.dart';

class OTruyenApiService {
  static final OTruyenApiService _instance = OTruyenApiService._internal();
  factory OTruyenApiService() => _instance;
  OTruyenApiService._internal();

  static const String baseUrl = 'https://otruyenapi.com/v1/api';

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Lấy trang chủ
  Future<OTruyenListResponse> getHome() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/home'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return OTruyenListResponse.fromJson(json);
      } else {
        throw Exception('Failed to load home: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching home: $e');
    }
  }

  /// Lấy danh sách truyện theo loại
  /// type: 'truyen-moi', 'dang-phat-hanh', 'hoan-thanh'
  Future<OTruyenListResponse> getStoryList(String type, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/danh-sach/$type?page=$page'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return OTruyenListResponse.fromJson(json);
      } else {
        throw Exception('Failed to load list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching list: $e');
    }
  }

  /// Lấy danh sách thể loại
  Future<List<OTruyenCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/the-loai'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] ?? {};
        final items = data['items'] as List? ?? [];
        return items.map((c) => OTruyenCategory.fromJson(c)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  /// Lấy truyện theo thể loại
  Future<OTruyenListResponse> getStoriesByCategory(
    String slug, {
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/the-loai/$slug?page=$page'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return OTruyenListResponse.fromJson(json);
      } else {
        throw Exception(
          'Failed to load category stories: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching category stories: $e');
    }
  }

  /// Lấy chi tiết truyện
  Future<OTruyenDetailResponse> getStoryDetail(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/truyen-tranh/$slug'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return OTruyenDetailResponse.fromJson(json);
      } else {
        throw Exception('Failed to load story detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching story detail: $e');
    }
  }

  /// Tìm kiếm truyện
  Future<OTruyenListResponse> searchStories(
    String keyword, {
    int page = 1,
  }) async {
    try {
      final encodedKeyword = Uri.encodeComponent(keyword);
      final response = await http.get(
        Uri.parse('$baseUrl/tim-kiem?keyword=$encodedKeyword&page=$page'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return OTruyenListResponse.fromJson(json);
      } else {
        throw Exception('Failed to search: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching: $e');
    }
  }

  /// Lấy nội dung chapter
  Future<OTruyenChapterContent> getChapterContent(String chapterApiData) async {
    try {
      final response = await http.get(
        Uri.parse(chapterApiData),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] ?? {};
        final cdnDomain =
            data['domain_cdn']?.toString() ?? 'sv1.otruyencdn.com';
        final item = data['item'] ?? {};
        final chapterPath = item['chapter_path']?.toString() ?? '';

        return OTruyenChapterContent.fromJson(item, cdnDomain, chapterPath);
      } else {
        throw Exception('Failed to load chapter: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching chapter: $e');
    }
  }
}
