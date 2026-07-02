// lib/viewmodels/online_manga_provider.dart
// Provider quản lý state cho trang truyện Online (từ API)

import 'package:flutter/foundation.dart';
import '../models/online_manga.dart';
import '../services/manga_api_service.dart';

/// Provider quản lý trạng thái dữ liệu truyện online
class OnlineMangaProvider with ChangeNotifier {
  // Danh sách truyện hiện tại
  List<OnlineManga> _mangaList = [];
  // Kết quả tìm kiếm
  List<OnlineManga> _searchResults = [];
  // Chi tiết truyện đang xem
  OnlineMangaDetail? _currentDetail;
  // Dữ liệu chapter đang đọc (tên, ảnh)
  Map<String, dynamic>? _currentChapterData;
  // Danh sách thể loại
  List<OnlineCategory> _categories = [];

  // ==================== CLOUD SYNC ====================
  // Danh sách truyện yêu thích từ Cloud
  List<OnlineManga> _favorites = [];
  Set<String> _favoriteSlugs = {}; // Lưu slug để check nhanh

  // Danh sách lịch sử đọc từ Cloud
  List<Map<String, dynamic>> _readingProgress = [];

  // Trạng thái loading
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingDetail = false;
  bool _isLoadingChapter = false;
  bool _isSearching = false;

  // Thông tin phân trang
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Bộ lọc hiện tại
  String _selectedType = 'truyen-moi';

  // Thông báo lỗi
  String? _errorMessage;

  // ==================== GETTERS ====================

  List<OnlineManga> get mangaList => _mangaList;
  List<OnlineManga> get searchResults => _searchResults;
  OnlineMangaDetail? get currentDetail => _currentDetail;
  Map<String, dynamic>? get currentChapterData => _currentChapterData;
  List<OnlineCategory> get categories => _categories;

  List<OnlineManga> get favorites => _favorites;
  List<Map<String, dynamic>> get readingProgress => _readingProgress;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoadingChapter => _isLoadingChapter;
  bool get isSearching => _isSearching;

  int get currentPage => _currentPage;
  bool get hasMorePages => _hasMorePages;
  String get selectedType => _selectedType;
  String? get errorMessage => _errorMessage;

  // Cache danh sách truyện (key: "type-page", value: danh sách truyện)
  final Map<String, List<OnlineManga>> _pageCache = {};

  // Số truyện hiển thị trên mỗi trang (gộp từ 2 trang API)
  static const int _displayPageSize = 42;

  // ==================== DANH SÁCH TRUYỆN ====================

  /// Tải danh sách truyện từ API theo trang.
  /// Gộp 2 trang API (mỗi trang 24 truyện) thành 1 trang hiển thị 42 truyện.
  Future<void> loadMangas({String? type, int? page, bool isRefresh = false}) async {
    // Cập nhật bộ lọc và reset trang nếu đổi loại
    if (type != null && _selectedType != type) {
      _selectedType = type;
      _currentPage = 1;
      _pageCache.clear();
    } else if (page != null) {
      _currentPage = page;
    } else if (type != null && _selectedType == type) {
      // Đang bấm lại cùng một filter, refresh về trang 1
      _currentPage = 1;
      _pageCache.clear();
    }

    final cacheKey = '$_selectedType-$_currentPage';

    if (isRefresh) {
      _pageCache.remove(cacheKey);
    }

    // Trả về kết quả từ Cache ngay lập tức nếu có
    if (_pageCache.containsKey(cacheKey)) {
      _mangaList = _pageCache[cacheKey]!;
      _isLoading = false;
      notifyListeners();
    } else {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // Ánh xạ trang hiển thị sang trang API: Trang 1 = API(1,2), Trang 2 = API(3,4), ...
      final apiPage1 = (_currentPage - 1) * 2 + 1;
      final apiPage2 = apiPage1 + 1;

      // Gọi song song 2 trang API cùng lúc để tăng tốc
      final results = await Future.wait([
        MangaApiService.getMangas(type: _selectedType, page: apiPage1),
        MangaApiService.getMangas(type: _selectedType, page: apiPage2),
      ]);

      // Gộp 2 danh sách lại
      final list1 = results[0]['manga'] as List<OnlineManga>;
      final list2 = results[1]['manga'] as List<OnlineManga>;
      final combined = [...list1, ...list2];

      // Cắt xuống tối đa 42 truyện
      _mangaList = combined.length > _displayPageSize
          ? combined.sublist(0, _displayPageSize)
          : combined;
      _pageCache[cacheKey] = _mangaList;

      // Tính toán phân trang dựa trên kết quả trang API đầu tiên
      final pagination = results[0]['pagination'] as Map<String, dynamic>;
      final totalItems = pagination['totalItems'] as int? ?? 0;

      if (totalItems > 0) {
        // Tổng số trang hiển thị = tổng trang API chia 2
        _hasMorePages = (apiPage2 * 24) < totalItems;
      } else {
        _hasMorePages = list2.isNotEmpty;
      }

      // Tải trước trang tiếp theo ở dưới nền
      if (_hasMorePages) {
        _prefetchPage(_currentPage + 1);
      }
    } catch (e) {
      if (!_pageCache.containsKey(cacheKey)) {
        _errorMessage = 'Không thể tải danh sách truyện. Kiểm tra kết nối mạng.';
      }
      debugPrint('❌ Lỗi loadMangas: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tải trước dữ liệu trang để chuyển trang tức thì
  Future<void> _prefetchPage(int page) async {
    final cacheKey = '$_selectedType-$page';
    if (_pageCache.containsKey(cacheKey)) return;

    try {
      final apiPage1 = (page - 1) * 2 + 1;
      final apiPage2 = apiPage1 + 1;

      final results = await Future.wait([
        MangaApiService.getMangas(type: _selectedType, page: apiPage1),
        MangaApiService.getMangas(type: _selectedType, page: apiPage2),
      ]);

      final list1 = results[0]['manga'] as List<OnlineManga>;
      final list2 = results[1]['manga'] as List<OnlineManga>;
      final combined = [...list1, ...list2];

      final prefetchList = combined.length > _displayPageSize
          ? combined.sublist(0, _displayPageSize)
          : combined;

      if (prefetchList.isNotEmpty) {
        _pageCache[cacheKey] = prefetchList;
        debugPrint('⚡️ Đã tải trước trang $page (${prefetchList.length} truyện)');
      }
    } catch (e) {
      // Bỏ qua lỗi prefetch vì chạy ngầm
    }
  }

  // Đã xóa hàm loadMore vì chuyển sang phân trang tĩnh (Pagination) thay vì Infinite Scroll

  /// Thay đổi loại danh sách (filter)
  Future<void> changeType(String type) async {
    if (_selectedType == type) return; // Không cần tải lại nếu cùng loại
    await loadMangas(type: type);
  }

  // ==================== TÌM KIẾM ====================

  /// Tìm kiếm truyện theo từ khoá
  Future<void> searchManga(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await MangaApiService.searchManga(query);
    } catch (e) {
      _errorMessage = 'Không thể tìm kiếm. Kiểm tra kết nối mạng.';
      debugPrint('❌ Lỗi searchManga: $e');
    }

    _isSearching = false;
    notifyListeners();
  }

  /// Xoá kết quả tìm kiếm
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // ==================== CHI TIẾT TRUYỆN ====================

  /// Tải chi tiết truyện theo slug
  Future<void> loadMangaDetail(String slug) async {
    _isLoadingDetail = true;
    _currentDetail = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDetail = await MangaApiService.getMangaDetail(slug);
      if (_currentDetail == null) {
        _errorMessage = 'Không tìm thấy truyện.';
      }
    } catch (e) {
      _errorMessage = 'Không thể tải chi tiết truyện. Kiểm tra kết nối mạng.';
      debugPrint('❌ Lỗi loadMangaDetail: $e');
    }

    _isLoadingDetail = false;
    notifyListeners();
  }

  // ==================== ĐỌC CHAPTER ====================

  /// Tải nội dung ảnh của chapter
  Future<void> loadChapterImages(String chapterId) async {
    _isLoadingChapter = true;
    _currentChapterData = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentChapterData = await MangaApiService.getChapterImages(chapterId);
      if (_currentChapterData == null) {
        _errorMessage = 'Không tải được nội dung chapter.';
      }
    } catch (e) {
      _errorMessage = 'Không thể tải chapter. Kiểm tra kết nối mạng.';
      debugPrint('❌ Lỗi loadChapterImages: $e');
    }

    _isLoadingChapter = false;
    notifyListeners();
  }

  // ==================== THỂ LOẠI ====================

  /// Tải danh sách thể loại
  Future<void> loadCategories() async {
    try {
      _categories = await MangaApiService.getCategories();
    } catch (e) {
      debugPrint('❌ Lỗi loadCategories: $e');
    }
    notifyListeners();
  }

  // ==================== CLOUD SYNC (FAVORITES & PROGRESS) ====================

  /// Tải danh sách yêu thích từ Cloud
  Future<void> loadFavorites() async {
    try {
      _favorites = await MangaApiService.getFavorites();
      _favoriteSlugs = _favorites.map((e) => e.slug).toSet();
      notifyListeners();
      debugPrint('✅ OnlineMangaProvider: tải \${_favorites.length} Favorites');
    } catch (e) {
      debugPrint('❌ OnlineMangaProvider lỗi loadFavorites: $e');
    }
  }

  /// Kiểm tra xem truyện đã có trong danh sách yêu thích chưa
  bool isFavorite(String slug) {
    return _favoriteSlugs.contains(slug);
  }

  /// Thêm hoặc xóa khỏi danh sách yêu thích (Toggle)
  Future<bool> toggleFavorite(OnlineManga manga) async {
    final slug = manga.slug;
    final isFav = isFavorite(slug);

    // Optimistic UI updates
    if (isFav) {
      _favoriteSlugs.remove(slug);
      _favorites.removeWhere((e) => e.slug == slug);
    } else {
      _favoriteSlugs.add(slug);
      _favorites.insert(0, manga);
    }
    notifyListeners();

    try {
      bool success;
      if (isFav) {
        success = await MangaApiService.removeFavorite(slug);
      } else {
        success = await MangaApiService.addFavorite(
          mangaSlug: slug,
          mangaTitle: manga.title,
          mangaImage: manga.image,
        );
      }

      if (!success) {
        // Rollback nếu API lỗi
        if (isFav) {
          _favoriteSlugs.add(slug);
          _favorites.insert(0, manga);
        } else {
          _favoriteSlugs.remove(slug);
          _favorites.removeWhere((e) => e.slug == slug);
        }
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      // Rollback
      if (isFav) {
        _favoriteSlugs.add(slug);
        _favorites.insert(0, manga);
      } else {
        _favoriteSlugs.remove(slug);
        _favorites.removeWhere((e) => e.slug == slug);
      }
      notifyListeners();
      return false;
    }
  }

  /// Tải lịch sử đọc từ Cloud
  Future<void> loadReadingProgress() async {
    try {
      _readingProgress = await MangaApiService.getReadingProgress();
      notifyListeners();
      debugPrint(
        '✅ OnlineMangaProvider: tải \${_readingProgress.length} ReadingProgress',
      );
    } catch (e) {
      debugPrint('❌ OnlineMangaProvider lỗi loadReadingProgress: $e');
    }
  }

  /// Cập nhật tiến độ đọc lên Cloud
  Future<void> updateReadingProgress({
    required String mangaSlug,
    required String chapterApiId,
    String? mangaTitle,
    String? mangaImage,
    String? chapterName,
    int pageIndex = 0,
  }) async {
    try {
      final success = await MangaApiService.updateReadingProgress(
        mangaSlug: mangaSlug,
        chapterApiId: chapterApiId,
        mangaTitle: mangaTitle,
        mangaImage: mangaImage,
        chapterName: chapterName,
        pageIndex: pageIndex,
      );

      if (success) {
        // Cập nhật local list nếu thành công
        final index = _readingProgress.indexWhere(
          (e) => e['mangaSlug'] == mangaSlug,
        );
        final newProgress = {
          'mangaSlug': mangaSlug,
          'mangaTitle': mangaTitle,
          'mangaImage': mangaImage,
          'chapterApiId': chapterApiId,
          'chapterName': chapterName,
          'pageIndex': pageIndex,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        if (index >= 0) {
          _readingProgress[index] = newProgress;
        } else {
          _readingProgress.insert(0, newProgress);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ OnlineMangaProvider lỗi updateReadingProgress: $e');
    }
  }

  // ==================== TIỆN ÍCH ====================

  /// Xoá thông báo lỗi
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
