// lib/models/online_manga.dart
// Model cho truyện tranh online - lấy dữ liệu từ API server

import 'package:flutter/foundation.dart';

/// Model đại diện cho một truyện trong danh sách (MangaItem từ API)
class OnlineManga {
  final String id;
  final String slug;
  final String title;
  final String? image; // URL ảnh bìa từ server
  final String? status; // Trạng thái: Đang tiến hành, Hoàn thành, ...
  final String? author; // Tác giả
  final String? description; // Mô tả
  final DateTime? updatedAt; // Thời gian cập nhật gần nhất
  final int chapters; // Số lượng chương

  OnlineManga({
    required this.id,
    required this.slug,
    required this.title,
    this.image,
    this.status,
    this.author,
    this.description,
    this.updatedAt,
    this.chapters = 0,
  });

  /// Tạo OnlineManga từ JSON trả về bởi API
  factory OnlineManga.fromJson(Map<String, dynamic> json) {
    // Lấy số chương từ API nếu có
    int chapters = 0;

    // Danh sách các phím có khả năng chứa số lượng chương từ các API khác nhau
    final possibleCountKeys = [
      'chapterCount', 'chaptersCount', 'chapters_count', 'chapter_count',
      'countChapters', 'count_chapters', 'totalChapters', 'total_chapters',
      'chapter_total', 'total_chapter', 'numChapters', 'num_chapters',
      'chapters_num', 'chaptersNum', 'count_chapter', 'countChapter',
      'total', 'count'
    ];

    for (final key in possibleCountKeys) {
      if (json[key] != null) {
        final val = int.tryParse(json[key].toString());
        if (val != null && val > 0) {
          chapters = val;
          break;
        }
      }
    }

    // Kiểm tra trong các object lồng nhau thường gặp: stats, meta
    if (chapters == 0) {
      for (final parentKey in ['stats', 'meta', 'statistics']) {
        if (json[parentKey] is Map) {
          final subMap = json[parentKey] as Map<String, dynamic>;
          for (final key in possibleCountKeys) {
            if (subMap[key] != null) {
              final val = int.tryParse(subMap[key].toString());
              if (val != null && val > 0) {
                chapters = val;
                break;
              }
            }
          }
        }
        if (chapters > 0) break;
      }
    }

    // Nếu vẫn bằng 0, kiểm tra phím 'chapters' (có thể là List, Map hoặc Number)
    if (chapters == 0 && json['chapters'] != null) {
      final chaptersJson = json['chapters'];
      if (chaptersJson is List) {
        chapters = chaptersJson.length;
      } else if (chaptersJson is Map) {
        final chaptersMap = json['chapters'] as Map<String, dynamic>;
        chapters = int.tryParse((chaptersMap['total'] ??
                    chaptersMap['count'] ??
                    chaptersMap['total_chapters'] ??
                    chaptersMap['length'] ??
                    '0')
                .toString()) ??
            0;
      } else {
        // Trường hợp chapters là một con số trực tiếp
        chapters = int.tryParse(chaptersJson.toString()) ?? 0;
      }
    }

    // Cuối cùng, nếu vẫn bằng 0, thử lấy từ phím 'last_chapter' (vd: "Chapter 165")
    if (chapters == 0 && json['last_chapter'] != null) {
      final lastChapter = json['last_chapter'].toString();
      final match = RegExp(r'(\d+)').firstMatch(lastChapter);
      if (match != null) {
        chapters = int.parse(match.group(1)!);
      }
    }
    
    // Debug log để kiểm tra dữ liệu từ API
    debugPrint(
      '📖 OnlineManga.fromJson - title: ${json['title']}, chapters: $chapters, keys: ${json.keys.toList()}',
    );

    return OnlineManga(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Không có tiêu đề',
      image: json['image']?.toString(),
      status: json['status']?.toString(),
      author: json['author']?.toString(),
      description: json['description']?.toString(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      chapters: chapters,
    );
  }

  @override
  String toString() {
    return 'OnlineManga(id: $id, title: $title, slug: $slug)';
  }
}

/// Model đại diện cho chi tiết truyện (MangaDetail từ API)
class OnlineMangaDetail {
  final String id;
  final String title;
  final String? description; // Mô tả truyện
  final String? author; // Tác giả
  final String? image; // URL ảnh bìa
  final String? status; // Trạng thái
  final List<OnlineChapter> chapters; // Danh sách chapters
  final List<OnlineCategory> categories; // Danh sách thể loại

  OnlineMangaDetail({
    required this.id,
    required this.title,
    this.description,
    this.author,
    this.image,
    this.status,
    this.chapters = const [],
    this.categories = const [],
  });

  /// Tạo OnlineMangaDetail từ JSON trả về bởi API
  factory OnlineMangaDetail.fromJson(Map<String, dynamic> json) {
    // Parse danh sách chapters
    List<OnlineChapter> chaptersList = [];
    if (json['chapters'] != null && json['chapters'] is List) {
      chaptersList = (json['chapters'] as List)
          .map((ch) => OnlineChapter.fromJson(ch as Map<String, dynamic>))
          .toList();
    }

    // Parse danh sách thể loại
    List<OnlineCategory> categoriesList = [];
    if (json['categories'] != null && json['categories'] is List) {
      categoriesList = (json['categories'] as List)
          .map((cat) => OnlineCategory.fromJson(cat as Map<String, dynamic>))
          .toList();
    }

    return OnlineMangaDetail(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Không có tiêu đề',
      description: json['description']?.toString(),
      author: json['author']?.toString(),
      image: json['image']?.toString(),
      status: json['status']?.toString(),
      chapters: chaptersList,
      categories: categoriesList,
    );
  }

  @override
  String toString() {
    return 'OnlineMangaDetail(id: $id, title: $title, chapters: ${chapters.length})';
  }
}

/// Model đại diện cho một chapter
class OnlineChapter {
  final String apiId; // ID dùng để gọi API lấy nội dung chapter
  final String name; // Tên chapter (vd: "Chapter 100")

  OnlineChapter({required this.apiId, required this.name});

  /// Tạo OnlineChapter từ JSON
  factory OnlineChapter.fromJson(Map<String, dynamic> json) {
    return OnlineChapter(
      apiId: json['api_id']?.toString() ?? json['apiId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Không có tên',
    );
  }

  @override
  String toString() {
    return 'OnlineChapter(apiId: $apiId, name: $name)';
  }
}

/// Model đại diện cho thể loại truyện
class OnlineCategory {
  final String id;
  final String slug; // Slug dùng để lọc truyện theo thể loại
  final String name; // Tên thể loại hiển thị

  OnlineCategory({required this.id, required this.slug, required this.name});

  /// Tạo OnlineCategory từ JSON
  factory OnlineCategory.fromJson(Map<String, dynamic> json) {
    return OnlineCategory(
      id: json['_id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'OnlineCategory(slug: $slug, name: $name)';
  }
}
