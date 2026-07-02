// lib/views/online_screen.dart
// Màn hình hiển thị truyện online từ API server, tối ưu hiệu năng cuộn và tải ảnh

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/online_manga.dart';
import '../viewmodels/online_manga_provider.dart';
import 'online_manga_detail_screen.dart';
import 'widgets/online_manga_card.dart';

/// Trang hiển thị danh sách truyện lấy từ API online
class OnlineScreen extends StatefulWidget {
  const OnlineScreen({super.key});

  @override
  State<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends State<OnlineScreen> {
  // Controller cho thanh tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  // Controller cuộn để phát hiện khi cần tải thêm (infinite scroll)
  final ScrollController _scrollController = ScrollController();
  // Trạng thái thanh tìm kiếm có đang mở không
  bool _isSearchMode = false;
  // Timer debounce để tránh gọi API quá nhiều khi gõ phím
  Timer? _debounceTimer;

  // Danh sách các bộ lọc loại truyện
  final List<Map<String, String>> _typeFilters = const [
    {'value': 'truyen-moi', 'label': 'Truyện mới'},
    {'value': 'dang-phat-hanh', 'label': 'Đang phát hành'},
    {'value': 'hoan-thanh', 'label': 'Hoàn thành'},
    {'value': 'sap-ra-mat', 'label': 'Sắp ra mắt'},
  ];

  @override
  void initState() {
    super.initState();
    // Tải danh sách truyện khi vào trang lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnlineMangaProvider>(context, listen: false);
      if (provider.mangaList.isEmpty) {
        provider.loadMangas();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Đã xóa _onScroll vì đổi sang phân trang tĩnh

  /// Xử lý tìm kiếm có debounce 300ms.
  /// Đợi người dùng ngừng gõ 300ms rồi mới gọi API,
  /// tránh gọi liên tục mỗi ký tự.
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 300), // chỉnh thời gian debounce tìm kiếm
      () {
        Provider.of<OnlineMangaProvider>(context, listen: false)
            .searchManga(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OnlineMangaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0, // Vô hiệu hóa đổi màu khi lướt lên
        surfaceTintColor: Colors.transparent,
        title: _isSearchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm truyện online...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('Truyện Online'),
        actions: [
          // Nút bật/tắt tìm kiếm
          SizedBox(
            width: 35, // chỉnh kích thước nút tìm kiếm
            height: 35,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 25, // chỉnh kích thước icon tìm kiếm
              icon: Icon(_isSearchMode ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearchMode = !_isSearchMode;
                  if (!_isSearchMode) {
                    _searchController.clear();
                    _debounceTimer?.cancel();
                    provider.clearSearch();
                  }
                });
              },
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          // Nội dung chính nằm dưới
          Positioned.fill(
            child: _isSearchMode && _searchController.text.isNotEmpty
                ? _buildSearchResults(provider)
                : _buildMangaGrid(provider),
          ),
          
          // Thanh bộ lọc nổi lơ lửng trên cùng (Floating)
          if (!_isSearchMode)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: _buildTypeFilterBar(provider),
            ),
        ],
      ),
    );
  }

  /// Xây dựng thanh bộ lọc loại truyện (dạng Floating Dock viên thuốc)
  Widget _buildTypeFilterBar(OnlineMangaProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Bọc bằng ClipRRect để khi cuộn không bị tràn ra ngoài viền bo tròn
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(_typeFilters.length, (index) {
              final filter = _typeFilters[index];
              final isSelected = provider.selectedType == filter['value'];

              return GestureDetector(
                onTap: () => provider.changeType(filter['value']!),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filter['label']!,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Xây dựng lưới truyện (GridView) với các tối ưu hiệu năng
  Widget _buildMangaGrid(OnlineMangaProvider provider) {
    // Trạng thái đang tải lần đầu
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải truyện...'),
          ],
        ),
      );
    }

    // Trạng thái lỗi
    if (provider.errorMessage != null && provider.mangaList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32), // chỉnh khoảng cách nội dung lỗi
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64, // chỉnh kích thước icon lỗi
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => provider.loadMangas(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // Xoá early return cho list.isEmpty để giữ lại cấu trúc cuộn và thanh phân trang

    // Hiển thị lưới truyện với RefreshIndicator và CustomScrollView để đưa phân trang vào cuối danh sách cuộn
    return RefreshIndicator(
      edgeOffset: _isSearchMode ? 0 : 72, // Đẩy con quay loading (pull-to-refresh) xuống dưới thanh Dock
      onRefresh: () => provider.loadMangas(isRefresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        cacheExtent: 9999, // Load trước toàn bộ item của trang hiện tại để mượt hơn
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: _isSearchMode ? 12 : 48, // Chừa vừa đủ 48px 
              left: 12,
              right: 12,
              bottom: 12,
            ),
            sliver: provider.mangaList.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.library_books_outlined,
                            size: 64, // chỉnh kích thước icon danh sách trống
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không có truyện nào',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // chỉnh số cột lưới
                      childAspectRatio: 0.65, // chỉnh tỷ lệ card
                      crossAxisSpacing: 10, // chỉnh khoảng cách ngang giữa card
                      mainAxisSpacing: 10, // chỉnh khoảng cách dọc giữa card
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final manga = provider.mangaList[index];
                        return OnlineMangaCard(
                          key: ValueKey(manga.slug),
                          manga: manga,
                          onTap: () => _openMangaDetail(manga),
                        );
                      },
                      childCount: provider.mangaList.length,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                    ),
                  ),
          ),
          // Thanh phân trang cuộn theo danh sách ở cuối cùng (vẫn hiển thị kể cả khi danh sách trống để có thể chuyển trang về)
          if (!provider.isLoading && provider.totalPages > 1)
            SliverToBoxAdapter(
              child: _buildPaginationBar(provider),
            ),
        ],
      ),
    );
  }

  /// Xây dựng kết quả tìm kiếm
  Widget _buildSearchResults(OnlineMangaProvider provider) {
    // Đang tìm kiếm
    if (provider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // Không có kết quả
    if (provider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64, // chỉnh kích thước icon không tìm thấy
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm với từ khoá khác',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Hiển thị kết quả tìm kiếm dạng danh sách
    return ListView.builder(
      padding: const EdgeInsets.all(12), // chỉnh padding danh sách
      cacheExtent: 9999, // Load trước ảnh để lướt mượt
      // Tắt auto keep alive để giải phóng bộ nhớ
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final manga = provider.searchResults[index];
        return OnlineSearchResultItem(
          key: ValueKey(manga.slug),
          manga: manga,
          onTap: () => _openMangaDetail(manga),
        );
      },
    );
  }

  /// Xây dựng thanh điều hướng phân trang (Pagination) kiểu hiển thị số (1 2 [3] 4 5)
  Widget _buildPaginationBar(OnlineMangaProvider provider) {
    final int currentPage = provider.currentPage;
    final int totalPages = provider.totalPages;

    // Tính toán các trang hiển thị (tối đa 5 trang số + 2 nút nhảy)
    // Để trang hiện tại luôn ở chính giữa (vị trí #4 của tổng 7 nút), ta lùi startPage lại 2 đơn vị
    int startPage = (currentPage - 2).clamp(1, totalPages);
    int endPage = startPage + 4; // Tổng cộng 5 trang

    // Nếu endPage vượt quá tổng số trang, lùi startPage lại để vẫn đủ 5 nút (nếu có thể)
    if (endPage > totalPages) {
      endPage = totalPages;
      startPage = (endPage - 4).clamp(1, totalPages);
    }

    final List<int> displayPages = [];
    for (int i = startPage; i <= endPage; i++) {
      displayPages.add(i);
    }

    // Hàm helper vẽ các nút tròn
    Widget buildPageButton({
      required String label,
      required bool isActive,
      required VoidCallback? onTap,
      IconData? icon,
    }) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38, // Kích thước gọn gàng để vừa 8 nút trên màn hình nhỏ
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 3), // Chỉnh khoảng cách giữa các số
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Theme.of(context).colorScheme.primary // Màu nổi bật cho trang hiện tại
                : (onTap == null 
                    ? Colors.transparent // Nút vô hiệu hóa
                    : Theme.of(context).colorScheme.surfaceContainerHighest), // Màu nền mặc định
            border: onTap == null && !isActive
                ? Border.all(color: Theme.of(context).colorScheme.outlineVariant) // Viền nhạt cho nút disable
                : null,
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? Theme.of(context).colorScheme.onPrimary
                      : (onTap == null 
                          ? Theme.of(context).colorScheme.outline 
                          : Theme.of(context).colorScheme.onSurface),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
        ),
      );
    }

    // Hàm chuyển trang mượt mà
    void changePage(int page) {
      provider.loadMangas(page: page);
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 70), // Thêm bottom padding để cuộn vượt lên thanh Dock
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nút << (Về trang 1)
          buildPageButton(
            label: '<<',
            icon: Icons.keyboard_double_arrow_left,
            isActive: false,
            onTap: currentPage > 1 ? () => changePage(1) : null,
          ),

          // Các nút số trang
          ...displayPages.map((page) => buildPageButton(
                label: page.toString(),
                isActive: page == currentPage,
                onTap: page != currentPage ? () => changePage(page) : null,
              )),

          // Nút >> (Đến trang cuối)
          buildPageButton(
            label: '>>',
            icon: Icons.keyboard_double_arrow_right,
            isActive: false,
            onTap: currentPage < totalPages ? () => changePage(totalPages) : null,
          ),
        ],
      ),
    );
  }

  /// Mở trang chi tiết truyện
  void _openMangaDetail(OnlineManga manga) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineMangaDetailScreen(manga: manga),
      ),
    );
  }
}
