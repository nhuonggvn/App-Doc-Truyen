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

    // Lắng nghe sự kiện cuộn để tải thêm truyện
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Xử lý sự kiện cuộn - tải thêm khi gần cuối danh sách.
  /// Tăng threshold lên 500 pixel để bắt đầu tải trước khi đến cuối,
  /// tạo cảm giác mượt hơn cho người dùng.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      // Gần cuối danh sách, tải thêm truyện
      Provider.of<OnlineMangaProvider>(context, listen: false).loadMore();
    }
  }

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

      body: Column(
        children: [
          // Thanh bộ lọc loại truyện (chỉ hiện khi không tìm kiếm)
          if (!_isSearchMode) _buildTypeFilterBar(provider),

          // Nội dung chính
          Expanded(
            child: _isSearchMode && _searchController.text.isNotEmpty
                ? _buildSearchResults(provider)
                : _buildMangaGrid(provider),
          ),
        ],
      ),
    );
  }

  /// Xây dựng thanh bộ lọc loại truyện (horizontal scroll)
  Widget _buildTypeFilterBar(OnlineMangaProvider provider) {
    return SizedBox(
      height: 50, // chỉnh chiều cao thanh bộ lọc
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // chỉnh padding thanh lọc
        itemCount: _typeFilters.length,
        itemBuilder: (context, index) {
          final filter = _typeFilters[index];
          final isSelected = provider.selectedType == filter['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8), // chỉnh khoảng cách giữa các chip
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (_) {
                // Chuyển bộ lọc
                provider.changeType(filter['value']!);
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
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

    // Danh sách trống
    if (provider.mangaList.isEmpty) {
      return Center(
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
      );
    }

    // Hiển thị lưới truyện với RefreshIndicator để kéo xuống làm mới
    return RefreshIndicator(
      onRefresh: () => provider.loadMangas(),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12), // chỉnh padding lưới truyện
        // Tắt auto keep alive để giải phóng bộ nhớ cho item ngoài màn hình
        addAutomaticKeepAlives: false,
        // Bật repaint boundaries để tối ưu vẽ lại từng item
        addRepaintBoundaries: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // chỉnh số cột lưới
          childAspectRatio: 0.65, // chỉnh tỷ lệ card
          crossAxisSpacing: 10, // chỉnh khoảng cách ngang giữa card
          mainAxisSpacing: 10, // chỉnh khoảng cách dọc giữa card
        ),
        // +1 cho indicator tải thêm ở cuối
        itemCount: provider.mangaList.length + (provider.hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          // Item cuối cùng là indicator tải thêm
          if (index == provider.mangaList.length) {
            return _buildLoadMoreIndicator(provider);
          }

          final manga = provider.mangaList[index];
          return OnlineMangaCard(
            key: ValueKey(manga.slug),
            manga: manga,
            onTap: () => _openMangaDetail(manga),
          );
        },
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

  /// Indicator hiển thị khi đang tải thêm truyện
  Widget _buildLoadMoreIndicator(OnlineMangaProvider provider) {
    if (provider.isLoadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16), // chỉnh khoảng cách indicator
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return const SizedBox.shrink();
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
