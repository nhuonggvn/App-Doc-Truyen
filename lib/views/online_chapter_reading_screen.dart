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
  final String mangaTitle; // Tên truyện (hiển thị trên AppBar)

  const OnlineChapterReadingScreen({
    super.key,
    required this.chapter,
    required this.mangaTitle,
  });

  @override
  State<OnlineChapterReadingScreen> createState() =>
      _OnlineChapterReadingScreenState();
}

class _OnlineChapterReadingScreenState
    extends State<OnlineChapterReadingScreen> {
  // Ẩn/hiện AppBar khi chạm vào màn hình
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    // Tải ảnh chapter từ API khi mở trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OnlineMangaProvider>(
        context,
        listen: false,
      ).loadChapterImages(widget.chapter.apiId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OnlineMangaProvider>(context);

    return Scaffold(
      // AppBar có thể ẩn/hiện
      appBar: _showAppBar
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên truyện
                  Text(
                    widget.mangaTitle,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Tên chapter
                  Text(
                    widget.chapter.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          : null,
      backgroundColor: Colors.black,
      body: _buildBody(provider),
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

    // Danh sách ảnh cuộn dọc (chạm để ẩn/hiện AppBar)
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAppBar = !_showAppBar;
        });
      },
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return _buildChapterImage(images[index], index, images.length);
        },
      ),
    );
  }

  /// Hiển thị một ảnh chapter
  Widget _buildChapterImage(String imageUrl, int index, int total) {
    return Column(
      children: [
        // Ảnh chapter - chiều rộng full màn hình
        CachedNetworkImage(
          imageUrl: imageUrl,
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
                    'Trang ${index + 1}/$total',
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
                    'Không tải được trang ${index + 1}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Hiển thị số trang cuối cùng
        if (index == total - 1)
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
