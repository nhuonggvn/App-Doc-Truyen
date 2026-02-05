// lib/models/otruyen_models.dart
// Models cho OTruyen API responses

/// Thể loại truyện
class OTruyenCategory {
  final String id;
  final String name;
  final String slug;

  OTruyenCategory({required this.id, required this.name, required this.slug});

  factory OTruyenCategory.fromJson(Map<String, dynamic> json) {
    return OTruyenCategory(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

/// Thông tin Truyện từ OTruyen API
class OTruyenStory {
  final String id;
  final String name;
  final String slug;
  final String origin_name;
  final String? status;
  final String? thumb_url;
  final bool? sub_docquyen;
  final List<OTruyenCategory> categories;
  final String? updatedAt;
  final List<String>? chaptersLatest;

  OTruyenStory({
    required this.id,
    required this.name,
    required this.slug,
    this.origin_name = '',
    this.status,
    this.thumb_url,
    this.sub_docquyen,
    this.categories = const [],
    this.updatedAt,
    this.chaptersLatest,
  });

  factory OTruyenStory.fromJson(Map<String, dynamic> json) {
    List<OTruyenCategory> cats = [];
    if (json['category'] != null && json['category'] is List) {
      cats = (json['category'] as List)
          .map((c) => OTruyenCategory.fromJson(c))
          .toList();
    }

    // Parse chaptersLatest - extract chapter_name from objects
    List<String>? latestChaps;
    if (json['chaptersLatest'] != null && json['chaptersLatest'] is List) {
      final chapList = json['chaptersLatest'] as List;
      if (chapList.isNotEmpty) {
        latestChaps = chapList
            .map((c) {
              if (c is Map) {
                return c['chapter_name']?.toString() ?? '';
              }
              return c.toString();
            })
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    return OTruyenStory(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      origin_name: json['origin_name']?.toString() ?? '',
      status: json['status']?.toString(),
      thumb_url: json['thumb_url']?.toString(),
      sub_docquyen: json['sub_docquyen'] as bool?,
      categories: cats,
      updatedAt: json['updatedAt']?.toString(),
      chaptersLatest: latestChaps,
    );
  }

  /// Lấy URL ảnh bìa đầy đủ
  String getFullThumbUrl(String cdnImageDomain) {
    if (thumb_url == null || thumb_url!.isEmpty) return '';
    if (thumb_url!.startsWith('http')) return thumb_url!;
    // CDN domain may already include https://
    final cleanDomain = cdnImageDomain.replaceFirst(RegExp(r'^https?://'), '');
    return 'https://$cleanDomain/uploads/comics/$thumb_url';
  }
}

/// Chi tiết Truyện (bao gồm chapters)
class OTruyenStoryDetail {
  final String id;
  final String name;
  final String slug;
  final String origin_name;
  final String? content; // Mô tả
  final String? status;
  final String? thumb_url;
  final String? author;
  final List<OTruyenCategory> categories;
  final List<OTruyenChapterInfo> chapters;
  final String? updatedAt;

  OTruyenStoryDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.origin_name = '',
    this.content,
    this.status,
    this.thumb_url,
    this.author,
    this.categories = const [],
    this.chapters = const [],
    this.updatedAt,
  });

  factory OTruyenStoryDetail.fromJson(
    Map<String, dynamic> json,
    List<dynamic>? serverData,
  ) {
    List<OTruyenCategory> cats = [];
    if (json['category'] != null && json['category'] is List) {
      cats = (json['category'] as List)
          .map((c) => OTruyenCategory.fromJson(c))
          .toList();
    }

    // Parse chapters từ serverData
    List<OTruyenChapterInfo> chaps = [];
    if (serverData != null && serverData.isNotEmpty) {
      final server = serverData[0];
      if (server['server_data'] != null && server['server_data'] is List) {
        chaps = (server['server_data'] as List)
            .map((c) => OTruyenChapterInfo.fromJson(c))
            .toList();
      }
    }

    // Parse author
    String? authorName;
    if (json['author'] != null) {
      if (json['author'] is List && (json['author'] as List).isNotEmpty) {
        authorName = (json['author'] as List).first?.toString();
      } else if (json['author'] is String) {
        authorName = json['author'];
      }
    }

    return OTruyenStoryDetail(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      origin_name: json['origin_name']?.toString() ?? '',
      content: json['content']?.toString(),
      status: json['status']?.toString(),
      thumb_url: json['thumb_url']?.toString(),
      author: authorName,
      categories: cats,
      chapters: chaps,
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  String getFullThumbUrl(String cdnImageDomain) {
    if (thumb_url == null || thumb_url!.isEmpty) return '';
    if (thumb_url!.startsWith('http')) return thumb_url!;
    // CDN domain may already include https://
    final cleanDomain = cdnImageDomain.replaceFirst(RegExp(r'^https?://'), '');
    return 'https://$cleanDomain/uploads/comics/$thumb_url';
  }
}

/// Thông tin chapter cơ bản
class OTruyenChapterInfo {
  final String filename;
  final String chapterName;
  final String chapterTitle;
  final String chapterApiData;

  OTruyenChapterInfo({
    required this.filename,
    required this.chapterName,
    required this.chapterTitle,
    required this.chapterApiData,
  });

  factory OTruyenChapterInfo.fromJson(Map<String, dynamic> json) {
    return OTruyenChapterInfo(
      filename: json['filename']?.toString() ?? '',
      chapterName: json['chapter_name']?.toString() ?? '',
      chapterTitle: json['chapter_title']?.toString() ?? '',
      chapterApiData: json['chapter_api_data']?.toString() ?? '',
    );
  }

  /// Tên hiển thị
  String get displayName {
    if (chapterTitle.isNotEmpty) {
      return 'Chương $chapterName: $chapterTitle';
    }
    return 'Chương $chapterName';
  }
}

/// Nội dung chapter (các trang ảnh)
class OTruyenChapterContent {
  final String chapterName;
  final String chapterTitle;
  final List<OTruyenPageImage> pages;
  final String chapterPath;

  OTruyenChapterContent({
    required this.chapterName,
    required this.chapterTitle,
    required this.pages,
    required this.chapterPath,
  });

  factory OTruyenChapterContent.fromJson(
    Map<String, dynamic> itemJson,
    String cdnImageDomain,
    String chapterPath,
  ) {
    List<OTruyenPageImage> pageList = [];
    if (itemJson['chapter_image'] != null &&
        itemJson['chapter_image'] is List) {
      pageList = (itemJson['chapter_image'] as List)
          .map(
            (img) =>
                OTruyenPageImage.fromJson(img, cdnImageDomain, chapterPath),
          )
          .toList();
    }

    return OTruyenChapterContent(
      chapterName: itemJson['chapter_name']?.toString() ?? '',
      chapterTitle: itemJson['chapter_title']?.toString() ?? '',
      pages: pageList,
      chapterPath: chapterPath,
    );
  }
}

/// Ảnh trang trong chapter
class OTruyenPageImage {
  final String filename;
  final int page;
  final String imageUrl;

  OTruyenPageImage({
    required this.filename,
    required this.page,
    required this.imageUrl,
  });

  factory OTruyenPageImage.fromJson(
    Map<String, dynamic> json,
    String cdnImageDomain,
    String chapterPath,
  ) {
    final filename = json['image_file']?.toString() ?? '';
    final page = json['image_page'] ?? 0;


    // Tạo full URL với chapter_path
    String imageUrl = '';
    if (filename.isNotEmpty) {
      imageUrl =
          '$cdnImageDomain/$chapterPath/$filename';
    }

    return OTruyenPageImage(
      filename: filename,
      page: page is int ? page : int.tryParse(page.toString()) ?? 0,
      imageUrl: imageUrl,
    );
  }
}

/// Response phân trang
class OTruyenPagination {
  final int totalItems;
  final int totalItemsPerPage;
  final int currentPage;
  final int totalPages;

  OTruyenPagination({
    required this.totalItems,
    required this.totalItemsPerPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory OTruyenPagination.fromJson(Map<String, dynamic> json) {
    final params = json['params'] ?? json;
    final pagination = params['pagination'] ?? {};

    final totalItems = _parseInt(pagination['totalItems']);
    final totalItemsPerPage = _parseInt(pagination['totalItemsPerPage']);
    int totalPages = _parseInt(pagination['totalPages']);

    // Calculate totalPages if not provided but we have totalItems
    if (totalPages == 0 && totalItems > 0 && totalItemsPerPage > 0) {
      totalPages = (totalItems / totalItemsPerPage).ceil();
    }

    return OTruyenPagination(
      totalItems: totalItems,
      totalItemsPerPage: totalItemsPerPage > 0 ? totalItemsPerPage : 24,
      currentPage: _parseInt(pagination['currentPage']),
      totalPages: totalPages,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  bool get hasNextPage => currentPage < totalPages;
}

/// Response danh sách truyện
class OTruyenListResponse {
  final List<OTruyenStory> items;
  final OTruyenPagination pagination;
  final String cdnImageDomain;

  OTruyenListResponse({
    required this.items,
    required this.pagination,
    required this.cdnImageDomain,
  });

  factory OTruyenListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final cdnDomain =
        data['APP_DOMAIN_CDN_IMAGE']?.toString() ?? 'img.otruyenapi.com';

    List<OTruyenStory> storyList = [];
    if (data['items'] != null && data['items'] is List) {
      storyList = (data['items'] as List)
          .map((item) => OTruyenStory.fromJson(item))
          .toList();
    }

    return OTruyenListResponse(
      items: storyList,
      pagination: OTruyenPagination.fromJson(data),
      cdnImageDomain: cdnDomain,
    );
  }
}

/// Response chi tiết truyện
class OTruyenDetailResponse {
  final OTruyenStoryDetail item;
  final String cdnImageDomain;

  OTruyenDetailResponse({required this.item, required this.cdnImageDomain});

  factory OTruyenDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final cdnDomain =
        data['APP_DOMAIN_CDN_IMAGE']?.toString() ?? 'img.otruyenapi.com';
    final itemData = data['item'] ?? {};
    final serverData = data['item']?['chapters'] as List?;

    return OTruyenDetailResponse(
      item: OTruyenStoryDetail.fromJson(itemData, serverData),
      cdnImageDomain: cdnDomain,
    );
  }
}
