// lib/views/online_screen.dart
// Màn hình hiển thị truyện online từ API server

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/online_manga.dart';
import '../viewmodels/online_manga_provider.dart';
import 'online_manga_detail_screen.dart';

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
    super.dispose();
  }

  /// Xử lý sự kiện cuộn - tải thêm khi gần cuối danh sách
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Gần cuối danh sách, tải thêm truyện
      Provider.of<OnlineMangaProvider>(context, listen: false).loadMore();
    }
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
                onChanged: (value) {
                  // Tìm kiếm khi người dùng nhập
                  provider.searchManga(value);
                },
              )
            : const Text('Truyện Online'),
        actions: [
          // Nút bật/tắt tìm kiếm
          IconButton(
            icon: Icon(_isSearchMode ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchMode = !_isSearchMode;
                if (!_isSearchMode) {
                  _searchController.clear();
                  provider.clearSearch();
                }
              });
            },
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
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _typeFilters.length,
        itemBuilder: (context, index) {
          final filter = _typeFilters[index];
          final isSelected = provider.selectedType == filter['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
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

  /// Xây dựng lưới truyện (GridView)
  Widget _buildMangaGrid(OnlineMangaProvider provider) {
    // Trạng thái đang tải lần đầu
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
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
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
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
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        // +1 cho indicator tải thêm ở cuối
        itemCount: provider.mangaList.length + (provider.hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          // Item cuối cùng là indicator tải thêm
          if (index == provider.mangaList.length) {
            return _buildLoadMoreIndicator(provider);
          }

          final manga = provider.mangaList[index];
          return _buildMangaCard(manga);
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
          children: [
            Icon(
              Icons.search_off,
              size: 64,
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
      padding: const EdgeInsets.all(12),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final manga = provider.searchResults[index];
        return _buildSearchResultItem(manga);
      },
    );
  }

  /// Card hiển thị một truyện trong lưới
  Widget _buildMangaCard(OnlineManga manga) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openMangaDetail(manga),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa truyện
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Ảnh từ URL
                  _buildNetworkImage(manga.image),

                  // Gradient overlay ở dưới
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Badge trạng thái
                  if (manga.status != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(manga.status!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          manga.status!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Tên truyện và số chương
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tên truyện - chỉ hiển thị 1 dòng, nếu dài thì thêm "..."
                    Flexible(
                      child: Text(
                        manga.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Số chương
                    Flexible(
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${manga.chapterCount} chương',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item hiển thị một truyện trong kết quả tìm kiếm
  Widget _buildSearchResultItem(OnlineManga manga) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openMangaDetail(manga),
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              // Ảnh bìa
              SizedBox(width: 85, child: _buildNetworkImage(manga.image)),

              // Thông tin truyện
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          manga.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Số chương
                      Flexible(
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${manga.chapterCount} chương',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (manga.status != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(manga.status!),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            manga.status!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Mũi tên
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Indicator hiển thị khi đang tải thêm truyện
  Widget _buildLoadMoreIndicator(OnlineMangaProvider provider) {
    if (provider.isLoadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// Hiển thị ảnh từ URL với cache và placeholder
  Widget _buildNetworkImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildImagePlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => _buildImagePlaceholder(),
    );
  }

  /// Placeholder khi không có ảnh hoặc ảnh lỗi
  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book,
          size: 40,
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// Lấy màu tương ứng với trạng thái truyện
  Color _getStatusColor(String status) {
    if (status.contains('Hoàn thành') || status.contains('COMPLETED')) {
      return Colors.green;
    } else if (status.contains('Đang') || status.contains('ONGOING')) {
      return const Color.fromARGB(255, 0, 140, 255);
    }
    return Colors.orange;
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
