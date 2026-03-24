// lib/views/online_manga_detail_screen.dart
// Màn hình chi tiết truyện online - hiển thị thông tin và danh sách chapters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/online_manga.dart';
import '../viewmodels/online_manga_provider.dart';
import 'online_chapter_reading_screen.dart';

/// Trang chi tiết một truyện online, hiển thị mô tả và danh sách chapter
class OnlineMangaDetailScreen extends StatefulWidget {
  final OnlineManga manga; // Thông tin truyện cơ bản từ danh sách

  const OnlineMangaDetailScreen({super.key, required this.manga});

  @override
  State<OnlineMangaDetailScreen> createState() =>
      _OnlineMangaDetailScreenState();
}

class _OnlineMangaDetailScreenState extends State<OnlineMangaDetailScreen> {
  // Trạng thái mở rộng mô tả
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    // Tải chi tiết truyện từ API khi mở trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OnlineMangaProvider>(
        context,
        listen: false,
      ).loadMangaDetail(widget.manga.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OnlineMangaProvider>(context);
    final detail = provider.currentDetail;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar với ảnh bìa
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(background: _buildCoverImage()),
          ),

          // Nội dung chi tiết
          if (provider.isLoadingDetail)
            // Đang tải chi tiết
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải thông tin truyện...'),
                  ],
                ),
              ),
            )
          else if (provider.errorMessage != null && detail == null)
            // Lỗi khi tải
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(provider.errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            provider.loadMangaDetail(widget.manga.slug),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (detail != null)
            // Hiển thị thông tin chi tiết
            ..._buildDetailContent(detail),
        ],
      ),
    );
  }

  /// Xây dựng ảnh bìa cho SliverAppBar
  Widget _buildCoverImage() {
    final imageUrl = widget.manga.image;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh bìa từ URL
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => _buildPlaceholderCover(),
          ),
          // Gradient phủ dưới để dễ đọc chữ
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _buildPlaceholderCover();
  }

  /// Placeholder khi không có ảnh bìa
  Widget _buildPlaceholderCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book,
          size: 80,
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Xây dựng nội dung chi tiết truyện (list of slivers)
  List<Widget> _buildDetailContent(OnlineMangaDetail detail) {
    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin cơ bản
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề truyện
                  Text(
                    detail.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tác giả
                  if (detail.author != null && detail.author!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            detail.author!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Trạng thái và số chapter
                  Row(
                    children: [
                      if (detail.status != null)
                        _buildInfoChip(
                          Icons.bookmark,
                          detail.status!,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.menu_book,
                        '${detail.chapters.length} chương',
                        Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Thể loại
                  if (detail.categories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: detail.categories.map((cat) {
                        return Chip(
                          label: Text(
                            cat.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            // Mô tả truyện
            if (detail.description != null && detail.description!.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề section
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Giới thiệu',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Nội dung mô tả
                    Text(
                      detail.description!,
                      maxLines: _isDescriptionExpanded ? null : 3,
                      overflow: _isDescriptionExpanded
                          ? null
                          : TextOverflow.ellipsis,
                    ),
                    // Nút mở rộng/thu gọn
                    if (detail.description!.length > 100)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Text(
                          _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm',
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Nút đọc từ đầu
            if (detail.chapters.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openChapter(
                      detail.chapters.last, // Chapter đầu tiên (cuối list)
                      detail.title,
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Đọc từ đầu'),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Header danh sách chapter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.list,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Danh sách chương (${detail.chapters.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),

      // Danh sách chapters
      if (detail.chapters.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Chưa có chương nào.')),
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final chapter = detail.chapters[index];
            return _buildChapterTile(chapter, index, detail.title);
          }, childCount: detail.chapters.length),
        ),

      // Padding bottom
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  /// Chip hiển thị thông tin (trạng thái, số chương, ...)
  Widget _buildInfoChip(IconData icon, String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Tile hiển thị một chapter trong danh sách
  Widget _buildChapterTile(
    OnlineChapter chapter,
    int index,
    String mangaTitle,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(chapter.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openChapter(chapter, mangaTitle),
      ),
    );
  }

  /// Mở trang đọc chapter
  void _openChapter(OnlineChapter chapter, String mangaTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineChapterReadingScreen(
          chapter: chapter,
          mangaTitle: mangaTitle,
        ),
      ),
    );
  }
}
