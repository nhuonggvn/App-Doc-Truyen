// lib/views/otruyen_detail_screen.dart
// Màn hình chi tiết truyện từ OTruyen API

import 'package:flutter/material.dart';
import '../models/otruyen_models.dart';
import '../services/otruyen_api_service.dart';
import 'otruyen_reading_screen.dart';

class OTruyenDetailScreen extends StatefulWidget {
  final String storySlug;
  final String storyName;

  const OTruyenDetailScreen({
    super.key,
    required this.storySlug,
    required this.storyName,
  });

  @override
  State<OTruyenDetailScreen> createState() => _OTruyenDetailScreenState();
}

class _OTruyenDetailScreenState extends State<OTruyenDetailScreen> {
  final OTruyenApiService _apiService = OTruyenApiService();

  bool _isLoading = true;
  String? _error;
  OTruyenStoryDetail? _storyDetail;
  String _cdnImageDomain = 'img.otruyenapi.com';

  @override
  void initState() {
    super.initState();
    _loadStoryDetail();
  }

  Future<void> _loadStoryDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getStoryDetail(widget.storySlug);
      if (mounted) {
        setState(() {
          _storyDetail = response.item;
          _cdnImageDomain = response.cdnImageDomain;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openChapter(OTruyenChapterInfo chapter, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTruyenReadingScreen(
          chapterApiData: chapter.chapterApiData,
          chapterName: chapter.displayName,
          storyName: widget.storyName,
          chapters: _storyDetail!.chapters,
          currentIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(title: Text(widget.storyName), pinned: true),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text('Lỗi tải dữ liệu'),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadStoryDetail,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final story = _storyDetail!;
    final thumbUrl = story.getFullThumbUrl(_cdnImageDomain);

    return CustomScrollView(
      slivers: [
        // App bar đơn giản
        SliverAppBar(
          pinned: true,
          expandedHeight: 280,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Ảnh bìa hoặc gradient placeholder
                if (thumbUrl.isNotEmpty)
                  Image.network(
                    thumbUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
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
                      child: Icon(
                        Icons.menu_book,
                        size: 80,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withAlpha(128),
                      ),
                    ),
                  )
                else
                  Container(
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
                    child: Icon(
                      Icons.menu_book,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withAlpha(128),
                    ),
                  ),
                // Gradient overlay phía dưới
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(120)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Thông tin truyện bên dưới
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên truyện
                Text(
                  story.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Tác giả
                if (story.author != null && story.author!.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        story.author!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // Trạng thái + Số chương
                Row(
                  children: [
                    if (story.status != null && story.status!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (story.status == 'completed'
                                      ? Colors.green
                                      : Colors.orange)
                                  .withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: story.status == 'completed'
                                ? Colors.green
                                : Colors.orange,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              story.status == 'completed'
                                  ? Icons.check_circle
                                  : Icons.update,
                              size: 14,
                              color: story.status == 'completed'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              story.status == 'completed'
                                  ? 'Hoàn thành'
                                  : 'Đang cập nhật',
                              style: TextStyle(
                                fontSize: 12,
                                color: story.status == 'completed'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withAlpha(80),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${story.chapters.length} chương',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Thể loại
                if (story.categories.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: story.categories
                        .map(
                          (cat) => Chip(
                            label: Text(
                              cat.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 16),

                // Mô tả
                if (story.content != null && story.content!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withAlpha(80),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Text(
                          _stripHtml(story.content!),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Nút đọc từ đầu
                if (story.chapters.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Đọc từ đầu'),
                          onPressed: () =>
                              _openChapter(story.chapters.first, 0),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Danh sách chương
                Row(
                  children: [
                    Icon(
                      Icons.list,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Danh sách chương (${story.chapters.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Container danh sách chương
                if (story.chapters.isEmpty)
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: const Text('Chưa có chương nào'),
                  )
                else
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: story.chapters.length,
                      itemBuilder: (context, index) {
                        final reversedIndex = story.chapters.length - 1 - index;
                        final chapter = story.chapters[reversedIndex];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            radius: 16,
                            child: Text(
                              chapter.chapterName,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),

                          title: Text(
                            chapter.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          dense: true,
                          onTap: () => _openChapter(chapter, reversedIndex),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}
