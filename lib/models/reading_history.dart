// lib/models/reading_history.dart
// Model lưu lịch sử đọc truyện

class ReadingHistory {
  final int? id;
  final int storyId;
  final int chapterId;
  final DateTime readAt;

  // Thông tin bổ sung (join từ bảng khác)
  final String? storyTitle;
  final String? storyCoverImage;
  final int? chapterNumber;
  final String? chapterTitle;

  ReadingHistory({
    this.id,
    required this.storyId,
    required this.chapterId,
    required this.readAt,
    this.storyTitle,
    this.storyCoverImage,
    this.chapterNumber,
    this.chapterTitle,
  });

  // Chuyển đổi từ Map (database)
  factory ReadingHistory.fromMap(Map<String, dynamic> map) {
    return ReadingHistory(
      id: map['id'],
      storyId: map['story_id'],
      chapterId: map['chapter_id'],
      readAt: DateTime.parse(map['read_at']),
      storyTitle: map['story_title'],
      storyCoverImage: map['cover_image'],
      chapterNumber: map['chapter_number'],
      chapterTitle: map['chapter_title'],
    );
  }

  // Chuyển đổi sang Map (database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'story_id': storyId,
      'chapter_id': chapterId,
      'read_at': readAt.toIso8601String(),
    };
  }
}
