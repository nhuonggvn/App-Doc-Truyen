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

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoadingChapter => _isLoadingChapter;
  bool get isSearching => _isSearching;

  int get currentPage => _currentPage;
  bool get hasMorePages => _hasMorePages;
  String get selectedType => _selectedType;
  String? get errorMessage => _errorMessage;

  // ==================== DANH SÁCH TRUYỆN ====================

  /// Tải danh sách truyện từ API (trang đầu tiên)
  Future<void> loadMangas({String? type}) async {
    // Cập nhật bộ lọc nếu có
    if (type != null) {
      _selectedType = type;
    }

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _hasMorePages = true;
    notifyListeners();

    try {
      final result = await MangaApiService.getMangas(
        type: _selectedType,
        page: 1,
      );

      _mangaList = result['manga'] as List<OnlineManga>;

      // Kiểm tra còn trang tiếp theo không
      final pagination = result['pagination'] as Map<String, dynamic>;
      final totalItems = pagination['totalItems'] as int? ?? 0;
      final itemsPerPage = pagination['itemsPerPage'] as int? ?? 24;
      _hasMorePages = _mangaList.length < totalItems && itemsPerPage > 0;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách truyện. Kiểm tra kết nối mạng.';
      debugPrint('❌ Lỗi loadMangas: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tải thêm truyện (trang tiếp theo - infinite scroll)
  Future<void> loadMore() async {
    // Không tải thêm nếu đang loading hoặc hết trang
    if (_isLoadingMore || !_hasMorePages) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;

      final result = await MangaApiService.getMangas(
        type: _selectedType,
        page: _currentPage,
      );

      final newMangas = result['manga'] as List<OnlineManga>;

      if (newMangas.isEmpty) {
        // Hết truyện, không tải thêm nữa
        _hasMorePages = false;
      } else {
        _mangaList.addAll(newMangas);
      }
    } catch (e) {
      // Lỗi khi tải thêm, giảm trang về để thử lại sau
      _currentPage--;
      debugPrint('❌ Lỗi loadMore: $e');
    }

    _isLoadingMore = false;
    notifyListeners();
  }

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

  // ==================== TIỆN ÍCH ====================

  /// Xoá thông báo lỗi
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
