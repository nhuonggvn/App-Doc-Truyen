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
        // App bar với ảnh bìa
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              story.name,
              style: const TextStyle(
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (thumbUrl.isNotEmpty)
                  Image.network(
                    thumbUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.book,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  )
                else
                  Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.book,
                      size: 80,
                      color: Colors.white54,
                    ),
                  ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(179)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Thông tin truyện
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tác giả
                if (story.author != null && story.author!.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Tác giả: ${story.author}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),

                // Trạng thái
                if (story.status != null && story.status!.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        story.status == 'completed'
                            ? Icons.check_circle
                            : Icons.update,
                        size: 18,
                        color: story.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        story.status == 'completed'
                            ? 'Hoàn thành'
                            : 'Đang cập nhật',
                        style: TextStyle(
                          fontSize: 14,
                          color: story.status == 'completed'
                              ? Colors.green
                              : Colors.orange,
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
                  const Text(
                    'Nội dung',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stripHtml(story.content!),
                    style: const TextStyle(height: 1.5),
                  ),
                ],
                const SizedBox(height: 24),

                // Danh sách chương
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Danh sách chương (${story.chapters.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (story.chapters.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 20),
                        // Chỉnh đỡ bị lỗi overflow
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        label: const Text('Đọc từ đầu'),
                        onPressed: () => _openChapter(story.chapters.first, 0),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Container danh sách chương với scroll riêng
                if (story.chapters.isEmpty)
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: const Text('Chưa có chương nào'),
                  )
                else
                  Container(
                    height: 400, // Chiều cao cố định
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: story.chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = story.chapters[index];
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
                          onTap: () => _openChapter(chapter, index),
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
