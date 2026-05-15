// lib/views/online_chapter_reading_screen.dart
// Màn hình đọc chapter truyện online - hiển thị ảnh từ API

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/online_manga.dart';
import '../viewmodels/online_manga_provider.dart';

/// Trang đọc nội dung chapter online - hiển thị danh sách ảnh cuộn dọc
class OnlineChapterReadingScreen extends StatefulWidget {
  final OnlineChapter chapter; // Thông tin chapter cần đọc
  final OnlineManga manga; // Thông tin truyện để lưu lịch sử đọc

  const OnlineChapterReadingScreen({
    super.key,
    required this.chapter,
    required this.manga,
  });

  @override
  State<OnlineChapterReadingScreen> createState() =>
      _OnlineChapterReadingScreenState();
}

class _OnlineChapterReadingScreenState extends State<OnlineChapterReadingScreen> {
  // Ẩn/hiện AppBar khi chạm vào màn hình
  bool _showControls = true;
  final ScrollController _scrollController = ScrollController();
  
  // Chapter số lớn hơn (mới hơn) - hiển thị khi bấm mũi tên PHẢI
  OnlineChapter? _newerChapter;
  // Chapter số nhỏ hơn (cũ hơn) - hiển thị khi bấm mũi tên TRÁI
  OnlineChapter? _olderChapter;

  @override
  void initState() {
    super.initState();
    // Tải ảnh chapter từ API khi mở trang
    // Update Reading Progress on Cloud
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OnlineMangaProvider>();

      // Tải hình ảnh
      provider.loadChapterImages(widget.chapter.apiId);

      // Cập nhật lịch sử đọc
      provider.updateReadingProgress(
        mangaSlug: widget.manga.slug,
        chapterApiId: widget.chapter.apiId,
        mangaTitle: widget.manga.title,
        mangaImage: widget.manga.image,
        chapterName: widget.chapter.name,
        pageIndex: 0,
      );
      
      _loadAdjacentChapters(provider);
    });
    
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_showControls) {
      setState(() {
        _showControls = false;
      });
    }
  }

  void _loadAdjacentChapters(OnlineMangaProvider provider) {
    final detail = provider.currentDetail;
    if (detail == null) return;
    
    final chapters = detail.chapters;
    for (int i = 0; i < chapters.length; i++) {
      if (chapters[i].apiId == widget.chapter.apiId) {
        // API xếp theo thứ tự TĂNG DẦN (index 0 = chapter nhỏ nhất/cũ nhất).
        // → chapters[i - 1] = số NHỎ hơn (cũ hơn) → mũi tên TRÁI
        // → chapters[i + 1] = số LỚN hơn (mới hơn) → mũi tên PHẢI
        if (i > 0) {
          _olderChapter = chapters[i - 1]; // số nhỏ hơn - mũi tên TRÁI
        }
        if (i < chapters.length - 1) {
          _newerChapter = chapters[i + 1]; // số lớn hơn - mũi tên PHẢI
        }
        break;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OnlineMangaProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // Nội dung chính (ảnh truyện)
            _buildBody(provider),

            // Top bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showControls ? -50 : -150,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                    stops: const [0.2, 0.5, 0.9, 1.0],
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.manga.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.chapter.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            // Bottom navigation bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showControls ? 0 : -140,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  top: 24,
                  left: 8,
                  right: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black,
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 0.8, 1.0],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Nút Home (chỉ icon)
                    _buildIconOnlyButton(
                      Icons.home,
                      () => Navigator.popUntil(context, (route) => route.isFirst),
                    ),

                    // Nút chapter nhỏ hơn (cũ hơn) - mũi tên TRÁI
                    _buildIconOnlyButton(
                      Icons.chevron_left,
                      _olderChapter != null
                          ? () => _goToChapter(_olderChapter!)
                          : null,
                    ),

                    // Dropdown chọn chapter
                    Flexible(flex: 2, child: _buildChapterSelector(provider)),

                    // Nút chapter lớn hơn (mới hơn) - mũi tên PHẢI
                    _buildIconOnlyButton(
                      Icons.chevron_right,
                      _newerChapter != null
                          ? () => _goToChapter(_newerChapter!)
                          : null,
                    ),

                    // Nút yêu thích
                    _buildIconOnlyButton(
                      provider.isFavorite(widget.manga.slug) ? Icons.favorite : Icons.favorite_border,
                      () {
                         provider.toggleFavorite(widget.manga);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Floating scroll to top button
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 100,
              child: GestureDetector(
                onTap: () {
                  _scrollController.jumpTo(0);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xây dựng nội dung chính
  Widget _buildBody(OnlineMangaProvider provider) {
    // Đang tải ảnh
    if (provider.isLoadingChapter) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Đang tải chapter...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    // Lỗi khi tải
    if (provider.errorMessage != null && provider.currentChapterData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    provider.loadChapterImages(widget.chapter.apiId),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // Hiển thị ảnh chapter
    final chapterData = provider.currentChapterData;
    if (chapterData == null) {
      return const Center(
        child: Text(
          'Không có dữ liệu chapter.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final images = chapterData['images'] as List<String>? ?? [];

    if (images.isEmpty) {
      return const Center(
        child: Text(
          'Chapter này chưa có ảnh.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Danh sách ảnh cuộn dọc
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      cacheExtent: 9999, // Tải trước ảnh (khoảng 3-4 màn hình) để lướt mượt
      itemCount: images.length,
      itemBuilder: (context, index) {
        return _KeepAliveImage(
          imageUrl: images[index], 
          index: index, 
          total: images.length,
        );
      },
    );
  }

  Widget _buildIconOnlyButton(IconData icon, VoidCallback? onPressed) {
    final isEnabled = onPressed != null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.white38,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildChapterSelector(OnlineMangaProvider provider) {
    final detail = provider.currentDetail;
    if (detail == null || detail.chapters.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: widget.chapter.apiId,
        dropdownColor: Colors.grey[900],
        underline: const SizedBox(),
        isDense: true,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
        items: detail.chapters.reversed.map((chapter) {
          return DropdownMenuItem<String>(
            value: chapter.apiId,
            child: Text(
              chapter.name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (chapterId) {
          if (chapterId != null && chapterId != widget.chapter.apiId) {
            final selectedChapter = detail.chapters.firstWhere(
              (c) => c.apiId == chapterId,
            );
            _goToChapter(selectedChapter);
          }
        },
      ),
    );
  }

  void _goToChapter(OnlineChapter chapter) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OnlineChapterReadingScreen(manga: widget.manga, chapter: chapter),
      ),
    );
  }
}

/// Widget bọc ảnh để giữ lại trong bộ nhớ (không bị load lại khi cuộn)
class _KeepAliveImage extends StatefulWidget {
  final String imageUrl;
  final int index;
  final int total;

  const _KeepAliveImage({
    required this.imageUrl,
    required this.index,
    required this.total,
  });

  @override
  State<_KeepAliveImage> createState() => _KeepAliveImageState();
}

class _KeepAliveImageState extends State<_KeepAliveImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Quan trọng: Yêu cầu Flutter giữ widget này

  @override
  Widget build(BuildContext context) {
    super.build(context); // Bắt buộc gọi super

    return Column(
      children: [
        // Ảnh chapter - chiều rộng full màn hình
        CachedNetworkImage(
          imageUrl: widget.imageUrl,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          placeholder: (context, url) => Container(
            height: 300,
            color: Colors.grey[900],
            child: Center(
              child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trang ${widget.index + 1}/${widget.total}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[900],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không tải được trang ${widget.index + 1}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Hiển thị số trang cuối cùng
        if (widget.index == widget.total - 1)
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.black,
            child: const Center(
              child: Text(
                '— Hết chapter —',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
