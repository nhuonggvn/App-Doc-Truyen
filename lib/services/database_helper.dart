// lib/services/database_helper.dart
// Singleton class để quản lý cơ sở dữ liệu SQLite
// Hỗ trợ truyện tranh với chapters và images

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/story.dart';
import '../models/chapter.dart';
import '../models/comment.dart';
import '../models/reading_history.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Singleton pattern
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // Lấy instance của database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Khởi tạo database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'stories_database_v4.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Upgrade database khi thay đổi version
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          story_id INTEGER NOT NULL,
          username TEXT NOT NULL,
          avatar_path TEXT,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reading_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          story_id INTEGER NOT NULL,
          chapter_id INTEGER NOT NULL,
          read_at TEXT NOT NULL,
          FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE,
          FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE,
          UNIQUE(story_id, chapter_id)
        )
      ''');
    }
  }

  // Tạo các bảng
  Future<void> _onCreate(Database db, int version) async {
    // Bảng stories
    await db.execute('''
      CREATE TABLE stories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        description TEXT,
        cover_image TEXT,
        genres TEXT,
        status TEXT DEFAULT 'Đang cập nhật',
        views_count INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Bảng chapters
    await db.execute('''
      CREATE TABLE chapters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        story_id INTEGER NOT NULL,
        chapter_number INTEGER NOT NULL,
        title TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE
      )
    ''');

    // Bảng chapter_images
    await db.execute('''
      CREATE TABLE chapter_images(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE
      )
    ''');

    // Bảng comments
    await db.execute('''
      CREATE TABLE comments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        story_id INTEGER NOT NULL,
        username TEXT NOT NULL,
        avatar_path TEXT,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE
      )
    ''');

    // Bảng reading_history
    await db.execute('''
      CREATE TABLE reading_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        story_id INTEGER NOT NULL,
        chapter_id INTEGER NOT NULL,
        read_at TEXT NOT NULL,
        FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE,
        FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE,
        UNIQUE(story_id, chapter_id)
      )
    ''');

    // Thêm dữ liệu mẫu
    await _insertSampleData(db);
  }

  // Thêm dữ liệu mẫu
  Future<void> _insertSampleData(Database db) async {
    // Thêm truyện mẫu
    await db.insert('stories', {
      'title': 'Solo Leveling',
      'author': 'Chugong',
      'description':
          'Sung Jin-Woo là một thợ săn hạng E yếu nhất. Sau khi suýt chết trong một dungeon đặc biệt, anh ta nhận được sức mạnh đặc biệt để "lên cấp" không giới hạn.',
      'cover_image': null,
      'genres': 'Action,Fantasy,Adventure',
      'status': 'Hoàn thành',
      'views_count': 1000000,
      'is_favorite': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('stories', {
      'title': 'Võ Luyện Đỉnh Phong',
      'author': 'Mạc Mặc',
      'description':
          'Dương Khai, một thiếu niên nghèo khó tu luyện võ đạo, từng bước trở thành cường giả tối thượng trong thế giới võ học đầy rẫy những thế lực mạnh mẽ.',
      'cover_image': null,
      'genres': 'Action,Martial Arts,Fantasy',
      'status': 'Đang cập nhật',
      'views_count': 847859,
      'is_favorite': 0,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    });

    await db.insert('stories', {
      'title': 'One Piece',
      'author': 'Eiichiro Oda',
      'description':
          'Hành trình của Luffy Mũ Rơm và băng hải tặc của anh ta trong việc tìm kiếm kho báu One Piece để trở thành Vua Hải Tặc.',
      'cover_image': null,
      'genres': 'Adventure,Comedy,Action',
      'status': 'Đang cập nhật',
      'views_count': 5000000,
      'is_favorite': 1,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
    });
  }

  // ==================== STORY OPERATIONS ====================

  // CREATE - Thêm truyện mới
  Future<int> insertStory(Story story) async {
    final db = await database;
    return await db.insert('stories', story.toMap());
  }

  // READ - Lấy tất cả truyện
  Future<List<Story>> getStories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stories',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Story.fromMap(maps[i]));
  }

  // READ - Lấy truyện theo ID
  Future<Story?> getStoryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Story.fromMap(maps.first);
    }
    return null;
  }

  // UPDATE - Cập nhật truyện
  Future<int> updateStory(Story story) async {
    final db = await database;
    return await db.update(
      'stories',
      story.toMap(),
      where: 'id = ?',
      whereArgs: [story.id],
    );
  }

  // DELETE - Xóa truyện
  Future<int> deleteStory(int id) async {
    final db = await database;
    // Xóa chapters và images liên quan (CASCADE)
    return await db.delete('stories', where: 'id = ?', whereArgs: [id]);
  }

  // Toggle yêu thích
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'stories',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Lấy danh sách yêu thích
  Future<List<Story>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stories',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Story.fromMap(maps[i]));
  }

  // Tìm kiếm truyện
  Future<List<Story>> searchStories(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stories',
      where: 'title LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Story.fromMap(maps[i]));
  }

  // Tăng lượt xem
  Future<void> incrementViewsCount(int storyId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE stories SET views_count = views_count + 1 WHERE id = ?',
      [storyId],
    );
  }

  // ==================== CHAPTER OPERATIONS ====================

  // Thêm chapter mới
  Future<int> insertChapter(Chapter chapter) async {
    final db = await database;
    return await db.insert('chapters', chapter.toMap());
  }

  // Lấy tất cả chapters của một truyện
  Future<List<Chapter>> getChaptersByStoryId(int storyId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      where: 'story_id = ?',
      whereArgs: [storyId],
      orderBy: 'chapter_number DESC',
    );

    List<Chapter> chapters = [];
    for (var map in maps) {
      final images = await getChapterImages(map['id'] as int);
      chapters.add(Chapter.fromMap(map, images: images));
    }
    return chapters;
  }

  // Lấy chapter theo ID
  Future<Chapter?> getChapterById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final images = await getChapterImages(id);
      return Chapter.fromMap(maps.first, images: images);
    }
    return null;
  }

  // Lấy số chapter tiếp theo
  Future<int> getNextChapterNumber(int storyId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(chapter_number) as max_num FROM chapters WHERE story_id = ?',
      [storyId],
    );
    final maxNum = result.first['max_num'] as int?;
    return (maxNum ?? 0) + 1;
  }

  // Đếm số chapters
  Future<int> getChapterCount(int storyId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM chapters WHERE story_id = ?',
      [storyId],
    );
    return result.first['count'] as int? ?? 0;
  }

  // Xóa chapter
  Future<int> deleteChapter(int id) async {
    final db = await database;
    return await db.delete('chapters', where: 'id = ?', whereArgs: [id]);
  }

  // Cập nhật chapter
  Future<int> updateChapter(Chapter chapter) async {
    final db = await database;
    return await db.update(
      'chapters',
      chapter.toMap(),
      where: 'id = ?',
      whereArgs: [chapter.id],
    );
  }

  // ==================== CHAPTER IMAGE OPERATIONS ====================

  // Thêm ảnh vào chapter
  Future<int> insertChapterImage(ChapterImage image) async {
    final db = await database;
    return await db.insert('chapter_images', image.toMap());
  }

  // Thêm nhiều ảnh vào chapter
  Future<void> insertChapterImages(List<ChapterImage> images) async {
    final db = await database;
    final batch = db.batch();
    for (var image in images) {
      batch.insert('chapter_images', image.toMap());
    }
    await batch.commit(noResult: true);
  }

  // Lấy tất cả ảnh của chapter
  Future<List<ChapterImage>> getChapterImages(int chapterId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapter_images',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      orderBy: 'order_index ASC',
    );
    return List.generate(maps.length, (i) => ChapterImage.fromMap(maps[i]));
  }

  // Xóa tất cả ảnh của chapter
  Future<int> deleteChapterImages(int chapterId) async {
    final db = await database;
    return await db.delete(
      'chapter_images',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
  }

  // Xóa 1 ảnh theo ID
  Future<int> deleteChapterImage(int imageId) async {
    final db = await database;
    return await db.delete(
      'chapter_images',
      where: 'id = ?',
      whereArgs: [imageId],
    );
  }

  // ==================== COMMENTS ====================

  // Thêm bình luận mới
  Future<int> insertComment(Comment comment) async {
    final db = await database;
    return await db.insert('comments', {
      'story_id': comment.storyId,
      'username': comment.username,
      'avatar_path': comment.avatarPath,
      'content': comment.content,
      'created_at': comment.createdAt.toIso8601String(),
    });
  }

  // Lấy tất cả bình luận của truyện
  Future<List<Comment>> getCommentsByStoryId(int storyId) async {
    final db = await database;
    final maps = await db.query(
      'comments',
      where: 'story_id = ?',
      whereArgs: [storyId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Comment.fromMap(maps[i]));
  }

  // Xóa bình luận
  Future<int> deleteComment(int commentId) async {
    final db = await database;
    return await db.delete('comments', where: 'id = ?', whereArgs: [commentId]);
  }

  // ==================== READING HISTORY ====================

  // Đánh dấu chương đã đọc
  Future<void> markChapterAsRead(int storyId, int chapterId) async {
    final db = await database;
    await db.insert('reading_history', {
      'story_id': storyId,
      'chapter_id': chapterId,
      'read_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Lấy danh sách chapter_id đã đọc của 1 truyện
  Future<Set<int>> getReadChapterIds(int storyId) async {
    final db = await database;
    final maps = await db.query(
      'reading_history',
      columns: ['chapter_id'],
      where: 'story_id = ?',
      whereArgs: [storyId],
    );
    return maps.map((m) => m['chapter_id'] as int).toSet();
  }

  // Lấy lịch sử đọc (kèm thông tin truyện và chương)
  Future<List<ReadingHistory>> getReadingHistory({int limit = 50}) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT rh.*, s.title as story_title, s.cover_image, c.chapter_number, c.title as chapter_title
      FROM reading_history rh
      JOIN stories s ON rh.story_id = s.id
      JOIN chapters c ON rh.chapter_id = c.id
      ORDER BY rh.read_at DESC
      LIMIT ?
    ''',
      [limit],
    );
    return List.generate(maps.length, (i) => ReadingHistory.fromMap(maps[i]));
  }

  // Xóa lịch sử đọc của 1 truyện
  Future<int> deleteReadingHistoryByStory(int storyId) async {
    final db = await database;
    return await db.delete(
      'reading_history',
      where: 'story_id = ?',
      whereArgs: [storyId],
    );
  }

  // Xóa toàn bộ lịch sử đọc
  Future<int> clearAllReadingHistory() async {
    final db = await database;
    return await db.delete('reading_history');
  }

  // Đóng database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
