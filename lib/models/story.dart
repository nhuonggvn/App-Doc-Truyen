// lib/models/story.dart
// Model class cho truyện tranh - hỗ trợ ảnh bìa và thể loại

class Story {
  final int? id;
  final String title;
  final String author;
  final String? description;
  final String? coverImage; // Đường dẫn ảnh bìa
  final List<String> genres; // Thể loại
  final String status; // Trạng thái: Đang cập nhật, Hoàn thành
  final int viewsCount;
  final bool isFavorite;
  final DateTime createdAt;

  Story({
    this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverImage,
    this.genres = const [],
    this.status = 'Đang cập nhật',
    this.viewsCount = 0,
    this.isFavorite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Chuyển đổi Story thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'cover_image': coverImage,
      'genres': genres.join(','), // Lưu dạng string phân cách bởi dấu phẩy
      'status': status,
      'views_count': viewsCount,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Tạo Story từ Map lấy từ SQLite
  factory Story.fromMap(Map<String, dynamic> map) {
    final genresStr = map['genres'] as String? ?? '';
    return Story(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String,
      description: map['description'] as String?,
      coverImage: map['cover_image'] as String?,
      genres: genresStr.isEmpty ? [] : genresStr.split(','),
      status: map['status'] as String? ?? 'Đang cập nhật',
      viewsCount: map['views_count'] as int? ?? 0,
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Tạo bản sao với một số thuộc tính thay đổi
  Story copyWith({
    int? id,
    String? title,
    String? author,
    String? description,
    String? coverImage,
    List<String>? genres,
    String? status,
    int? viewsCount,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      genres: genres ?? this.genres,
      status: status ?? this.status,
      viewsCount: viewsCount ?? this.viewsCount,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Story(id: $id, title: $title, author: $author)';
  }
}
