// lib/models/online_manga.dart
// Model cho truyện tranh online - lấy dữ liệu từ API server

/// Model đại diện cho một truyện trong danh sách (MangaItem từ API)
class OnlineManga {
  final String id;
  final String slug;
  final String title;
  final String? image; // URL ảnh bìa từ server
  final String? status; // Trạng thái: Đang tiến hành, Hoàn thành, ...
  final DateTime? updatedAt; // Thời gian cập nhật gần nhất
  final int chapterCount; // Số lượng chương

  OnlineManga({
    required this.id,
    required this.slug,
    required this.title,
    this.image,
    this.status,
    this.updatedAt,
    this.chapterCount = 0,
  });

  /// Tạo OnlineManga từ JSON trả về bởi API
  factory OnlineManga.fromJson(Map<String, dynamic> json) {
    // Lấy số chương từ API nếu có, nếu không thì đếm từ chapters list
    int chaptersCount = 0;
    if (json['chapterCount'] != null) {
      chaptersCount = int.tryParse(json['chapterCount'].toString()) ?? 0;
    } else if (json['chapters'] != null && json['chapters'] is List) {
      chaptersCount = (json['chapters'] as List).length;
    }

    return OnlineManga(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Không có tiêu đề',
      image: json['image']?.toString(),
      status: json['status']?.toString(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      chapterCount: chaptersCount,
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
