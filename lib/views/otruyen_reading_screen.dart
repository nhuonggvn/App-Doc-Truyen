// lib/views/otruyen_reading_screen.dart
// Màn hình đọc chương truyện từ OTruyen API (hiển thị ảnh)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/otruyen_models.dart';
import '../services/otruyen_api_service.dart';

class OTruyenReadingScreen extends StatefulWidget {
  final String chapterApiData;
  final String chapterName;
  final String storyName;
  final List<OTruyenChapterInfo> chapters;
  final int currentIndex;

  const OTruyenReadingScreen({
    super.key,
    required this.chapterApiData,
    required this.chapterName,
    required this.storyName,
    required this.chapters,
    required this.currentIndex,
  });

  @override
  State<OTruyenReadingScreen> createState() => _OTruyenReadingScreenState();
}

class _OTruyenReadingScreenState extends State<OTruyenReadingScreen> {
  final OTruyenApiService _apiService = OTruyenApiService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _error;
  OTruyenChapterContent? _chapterContent;
  late int _currentIndex;
  late String _currentChapterApiData;
  late String _currentChapterName;

  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _currentChapterApiData = widget.chapterApiData;
    _currentChapterName = widget.chapterName;
    _loadChapter();

    // Ẩn system UI khi đọc truyện
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Khôi phục system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadChapter() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final content = await _apiService.getChapterContent(
        _currentChapterApiData,
      );
      if (mounted) {
        setState(() {
          _chapterContent = content;
          _isLoading = false;
        });
        // Scroll về đầu khi load chapter mới
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
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

  bool get _hasPrevious => _currentIndex < widget.chapters.length - 1;
  bool get _hasNext => _currentIndex > 0;

  void _goToPrevious() {
    if (!_hasPrevious) return;
    _currentIndex++;
    final chapter = widget.chapters[_currentIndex];
    _currentChapterApiData = chapter.chapterApiData;
    _currentChapterName = chapter.displayName;
    _loadChapter();
  }

  void _goToNext() {
    if (!_hasNext) return;
    _currentIndex--;
    final chapter = widget.chapters[_currentIndex];
    _currentChapterApiData = chapter.chapterApiData;
    _currentChapterName = chapter.displayName;
    _loadChapter();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _showChapterList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Danh sách chương',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.chapters.length,
                itemBuilder: (context, index) {
                  final chapter = widget.chapters[index];
                  final isCurrentChapter = index == _currentIndex;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrentChapter
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: isCurrentChapter ? Colors.white : null,
                      child: Text(
                        chapter.chapterName,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    title: Text(
                      chapter.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isCurrentChapter
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isCurrentChapter
                        ? const Icon(Icons.play_arrow, color: Colors.green)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentIndex = index;
                        _currentChapterApiData = chapter.chapterApiData;
                        _currentChapterName = chapter.displayName;
                      });
                      _loadChapter();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Nội dung chương
          GestureDetector(
            onTap: _toggleControls,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _error != null
                ? _buildError()
                : _buildContent(),
          ),

          // Controls overlay
          if (_showControls) ...[
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.storyName,
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          _currentChapterName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.list),
                        onPressed: _showChapterList,
                        tooltip: 'Danh sách chương',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _hasPrevious ? _goToPrevious : null,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Chương trước'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        if (_chapterContent != null)
                          Text(
                            '${_chapterContent!.pages.length} trang',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ElevatedButton.icon(
                          onPressed: _hasNext ? _goToNext : null,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Chương sau'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Lỗi tải chương',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChapter,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final pages = _chapterContent?.pages ?? [];

    if (pages.isEmpty) {
      return const Center(
        child: Text('Không có nội dung', style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        return Image.network(
          page.imageUrl,
          fit: BoxFit.fitWidth,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey[900],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: 200,
            color: Colors.grey[900],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.white54),
                  SizedBox(height: 8),
                  Text(
                    'Không tải được ảnh',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
