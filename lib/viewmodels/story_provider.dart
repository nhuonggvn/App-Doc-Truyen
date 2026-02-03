// lib/viewmodels/story_provider.dart
// Provider quản lý truyện và chapters với SQLite

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/story.dart';
import '../models/chapter.dart';
import '../models/comment.dart';
import '../models/reading_history.dart';
import '../services/database_helper.dart';

class StoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Story> _stories = [];
  List<Story> _favorites = [];
  List<Story> _searchResults = [];
  List<Chapter> _currentChapters = [];
  List<ReadingHistory> _readingHistory = [];
  Set<int> _readChapterIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Story> get stories => _stories;
  List<Story> get favorites => _favorites;
  List<Story> get searchResults => _searchResults;
  List<Chapter> get currentChapters => _currentChapters;
  List<ReadingHistory> get readingHistory => _readingHistory;
  Set<int> get readChapterIds => _readChapterIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== STORY OPERATIONS ====================

  // Tải tất cả truyện từ database
  Future<void> loadStories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _stories = await _dbHelper.getStories();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách truyện.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Tải danh sách yêu thích
  Future<void> loadFavorites() async {
    try {
      _favorites = await _dbHelper.getFavorites();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách yêu thích.';
      notifyListeners();
    }
  }

  // Thêm truyện mới
  Future<bool> addStory(Story story, {File? coverImageFile}) async {
    try {
      String? savedCoverPath;

      // Lưu ảnh bìa nếu có
      if (coverImageFile != null) {
        savedCoverPath = await saveImageToLocal(coverImageFile, 'covers');
      }

      final storyWithCover = story.copyWith(coverImage: savedCoverPath);
      final id = await _dbHelper.insertStory(storyWithCover);
      final newStory = storyWithCover.copyWith(id: id);
      _stories.insert(0, newStory);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể thêm truyện.';
      notifyListeners();
      return false;
    }
  }

  // Cập nhật truyện
  Future<bool> updateStory(Story story, {File? newCoverImageFile}) async {
    try {
      String? coverPath = story.coverImage;

      // Lưu ảnh bìa mới nếu có
      if (newCoverImageFile != null) {
        coverPath = await saveImageToLocal(newCoverImageFile, 'covers');
      }

      final updatedStory = story.copyWith(coverImage: coverPath);
      await _dbHelper.updateStory(updatedStory);

      final index = _stories.indexWhere((s) => s.id == story.id);
      if (index != -1) {
        _stories[index] = updatedStory;
      }

      // Cập nhật trong favorites
      final favIndex = _favorites.indexWhere((s) => s.id == story.id);
      if (favIndex != -1) {
        _favorites[favIndex] = updatedStory;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật truyện.';
      notifyListeners();
      return false;
    }
  }

  // Xóa truyện
  Future<bool> deleteStory(int id) async {
    try {
      await _dbHelper.deleteStory(id);
      _stories.removeWhere((story) => story.id == id);
      _favorites.removeWhere((story) => story.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa truyện.';
      notifyListeners();
      return false;
    }
  }

  // Toggle yêu thích
  Future<void> toggleFavorite(Story story) async {
    try {
      final newFavoriteStatus = !story.isFavorite;
      await _dbHelper.toggleFavorite(story.id!, newFavoriteStatus);

      final index = _stories.indexWhere((s) => s.id == story.id);
      if (index != -1) {
        _stories[index] = story.copyWith(isFavorite: newFavoriteStatus);
      }

      if (newFavoriteStatus) {
        _favorites.add(story.copyWith(isFavorite: true));
      } else {
        _favorites.removeWhere((s) => s.id == story.id);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể cập nhật yêu thích.';
      notifyListeners();
    }
  }

  // Tìm kiếm truyện
  Future<void> searchStories(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _searchResults = await _dbHelper.searchStories(query);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tìm kiếm.';
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  Story? getStoryById(int id) {
    try {
      return _stories.firstWhere((story) => story.id == id);
    } catch (e) {
      return null;
    }
  }

  // Tăng lượt xem
  Future<void> incrementViews(int storyId) async {
    try {
      await _dbHelper.incrementViewsCount(storyId);
      final index = _stories.indexWhere((s) => s.id == storyId);
      if (index != -1) {
        _stories[index] = _stories[index].copyWith(
          viewsCount: _stories[index].viewsCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      // Silent fail
    }
  }

  // ==================== CHAPTER OPERATIONS ====================

  // Tải chapters của truyện
  Future<void> loadChapters(int storyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentChapters = await _dbHelper.getChaptersByStoryId(storyId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách chương.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Thêm chapter mới với ảnh
  Future<bool> addChapter(
    int storyId,
    String? title,
    List<File> imageFiles,
  ) async {
    try {
      // Lấy số chapter tiếp theo
      final chapterNumber = await _dbHelper.getNextChapterNumber(storyId);

      // Tạo chapter
      final chapter = Chapter(
        storyId: storyId,
        chapterNumber: chapterNumber,
        title: title,
      );

      final chapterId = await _dbHelper.insertChapter(chapter);

      // Lưu ảnh và thêm vào database
      List<ChapterImage> chapterImages = [];
      for (int i = 0; i < imageFiles.length; i++) {
        final savedPath = await saveImageToLocal(
          imageFiles[i],
          'chapters/$storyId/$chapterId',
        );
        chapterImages.add(
          ChapterImage(
            chapterId: chapterId,
            imagePath: savedPath,
            orderIndex: i,
          ),
        );
      }

      await _dbHelper.insertChapterImages(chapterImages);

      // Refresh danh sách chapters
      await loadChapters(storyId);

      return true;
    } catch (e) {
      _errorMessage = 'Không thể thêm chương.';
      notifyListeners();
      return false;
    }
  }

  // Lấy chapter theo ID
  Future<Chapter?> getChapterById(int chapterId) async {
    try {
      return await _dbHelper.getChapterById(chapterId);
    } catch (e) {
      return null;
    }
  }

  // Xóa chapter
  Future<bool> deleteChapter(int chapterId, int storyId) async {
    try {
      await _dbHelper.deleteChapter(chapterId);
      await loadChapters(storyId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa chương.';
      notifyListeners();
      return false;
    }
  }

  // Lấy số chapters
  Future<int> getChapterCount(int storyId) async {
    return await _dbHelper.getChapterCount(storyId);
  }

  // ==================== HELPER METHODS ====================

  // Lưu ảnh vào local storage (public để các screen khác gọi được)
  Future<String> saveImageToLocal(File imageFile, String subFolder) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/story_images/$subFolder');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imageFile.path)}';
    final savedFile = await imageFile.copy('${imagesDir.path}/$fileName');

    return savedFile.path;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== COMMENTS OPERATIONS ====================

  List<Comment> _currentComments = [];

  List<Comment> get currentComments => _currentComments;

  // Tải comments của truyện
  Future<void> loadComments(int storyId) async {
    try {
      _currentComments = await _dbHelper.getCommentsByStoryId(storyId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải bình luận.';
      notifyListeners();
    }
  }

  // Thêm bình luận mới
  Future<bool> addComment(
    int storyId,
    String username,
    String content, {
    String? avatarPath,
  }) async {
    try {
      final comment = Comment(
        storyId: storyId,
        username: username,
        avatarPath: avatarPath,
        content: content,
        createdAt: DateTime.now(),
      );
      await _dbHelper.insertComment(comment);
      await loadComments(storyId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể thêm bình luận.';
      notifyListeners();
      return false;
    }
  }

  // Xóa bình luận
  Future<bool> deleteComment(int commentId, int storyId) async {
    try {
      await _dbHelper.deleteComment(commentId);
      await loadComments(storyId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa bình luận.';
      notifyListeners();
      return false;
    }
  }

  // ==================== READING HISTORY ====================

  // Đánh dấu chương đã đọc
  Future<void> markChapterAsRead(int storyId, int chapterId) async {
    try {
      await _dbHelper.markChapterAsRead(storyId, chapterId);
      _readChapterIds.add(chapterId);
      // Tự động cập nhật danh sách lịch sử đọc (không hiện loading)
      await _silentLoadReadingHistory();
    } catch (e) {
      debugPrint('Error marking chapter as read: $e');
    }
  }

  // Load danh sách chapter đã đọc của 1 truyện
  Future<void> loadReadChapterIds(int storyId) async {
    try {
      _readChapterIds = await _dbHelper.getReadChapterIds(storyId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading read chapters: $e');
    }
  }

  // Kiểm tra chương đã đọc chưa
  bool isChapterRead(int chapterId) {
    return _readChapterIds.contains(chapterId);
  }

  // Load lịch sử đọc (hiện loading indicator)
  Future<void> loadReadingHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _readingHistory = await _dbHelper.getReadingHistory();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Không thể tải lịch sử đọc.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load lịch sử đọc ngầm (không hiện loading, giống như favorite)
  Future<void> _silentLoadReadingHistory() async {
    try {
      _readingHistory = await _dbHelper.getReadingHistory();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error silent loading reading history: $e');
    }
  }

  // Xóa lịch sử đọc của 1 truyện
  Future<bool> deleteReadingHistoryByStory(int storyId) async {
    try {
      await _dbHelper.deleteReadingHistoryByStory(storyId);
      await loadReadingHistory();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Xóa toàn bộ lịch sử đọc
  Future<bool> clearAllReadingHistory() async {
    try {
      await _dbHelper.clearAllReadingHistory();
      _readingHistory.clear();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
