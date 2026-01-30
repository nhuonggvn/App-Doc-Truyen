// lib/models/chapter.dart
// Model class cho chapter - chứa danh sách ảnh

class Chapter {
  final int? id;
  final int storyId;
  final int chapterNumber;
  final String? title;
  final DateTime createdAt;
  final List<ChapterImage> images; // Danh sách ảnh trong chapter

  Chapter({
    this.id,
    required this.storyId,
    required this.chapterNumber,
    this.title,
    DateTime? createdAt,
    this.images = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  // Chuyển đổi Chapter thành Map (không bao gồm images)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'story_id': storyId,
      'chapter_number': chapterNumber,
      'title': title,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Tạo Chapter từ Map
  factory Chapter.fromMap(
    Map<String, dynamic> map, {
    List<ChapterImage>? images,
  }) {
    return Chapter(
      id: map['id'] as int?,
      storyId: map['story_id'] as int,
      chapterNumber: map['chapter_number'] as int,
      title: map['title'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      images: images ?? [],
    );
  }

  // Tạo bản sao với thay đổi
  Chapter copyWith({
    int? id,
    int? storyId,
    int? chapterNumber,
    String? title,
    DateTime? createdAt,
    List<ChapterImage>? images,
  }) {
    return Chapter(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
    );
  }

  // Tiêu đề hiển thị
  String get displayTitle => title ?? 'Chương $chapterNumber';

  @override
  String toString() {
    return 'Chapter(id: $id, storyId: $storyId, chapterNumber: $chapterNumber)';
  }
}

// Model cho ảnh trong chapter
class ChapterImage {
  final int? id;
  final int chapterId;
  final String imagePath;
  final int orderIndex;

  ChapterImage({
    this.id,
    required this.chapterId,
    required this.imagePath,
    required this.orderIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'image_path': imagePath,
      'order_index': orderIndex,
    };
  }

  factory ChapterImage.fromMap(Map<String, dynamic> map) {
    return ChapterImage(
      id: map['id'] as int?,
      chapterId: map['chapter_id'] as int,
      imagePath: map['image_path'] as String,
      orderIndex: map['order_index'] as int,
    );
  }

  ChapterImage copyWith({
    int? id,
    int? chapterId,
    String? imagePath,
    int? orderIndex,
  }) {
    return ChapterImage(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      imagePath: imagePath ?? this.imagePath,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
