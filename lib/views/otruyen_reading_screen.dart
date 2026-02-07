// lib/views/otruyen_reading_screen.dart
// Màn hình đọc chương truyện từ OTruyen API (hiển thị ảnh)

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/otruyen_models.dart';
import '../services/otruyen_api_service.dart';
import '../services/image_database_service.dart';

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
      // Kiểm tra cache trước
      final cachedData = ImageDatabaseService.getChapterContent(
        _currentChapterApiData,
      );
      if (cachedData != null) {
        // Load từ cache
        final content = _parseChapterFromCache(cachedData);
        if (mounted) {
          setState(() {
            _chapterContent = content;
            _isLoading = false;
          });
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        }
        return;
      }

      // Không có cache, fetch từ API
      final content = await _apiService.getChapterContent(
        _currentChapterApiData,
      );

      // Lưu vào cache cho offline
      _saveChapterToCache(_currentChapterApiData, content);

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

  /// Lưu chapter content vào database
  void _saveChapterToCache(
    String chapterApiData,
    OTruyenChapterContent content,
  ) {
    final data = {
      'chapterName': content.chapterName,
      'chapterTitle': content.chapterTitle,
      'chapterPath': content.chapterPath,
      'pages': content.pages
          .map(
            (p) => {
              'filename': p.filename,
              'page': p.page,
              'imageUrl': p.imageUrl,
            },
          )
          .toList(),
    };
    ImageDatabaseService.saveChapterContent(chapterApiData, data);
  }

  /// Parse chapter content từ cache
  OTruyenChapterContent _parseChapterFromCache(Map<String, dynamic> data) {
    final pages = (data['pages'] as List)
        .map(
          (p) => OTruyenPageImage(
            filename: p['filename'] ?? '',
            page: p['page'] ?? 0,
            imageUrl: p['imageUrl'] ?? '',
          ),
        )
        .toList();

    return OTruyenChapterContent(
      chapterName: data['chapterName'] ?? '',
      chapterTitle: data['chapterTitle'] ?? '',
      chapterPath: data['chapterPath'] ?? '',
      pages: pages,
    );
  }

  // "Về trước" = quay lại chapter trước = lower index
  // "Tiếp theo" = chuyển sang chapter sau = higher index
  // chuyển hết trên này qua tiếng việt
  bool get _hasPrevious => _currentIndex > 0;
  bool get _hasNext => _currentIndex < widget.chapters.length - 1;

  void _goToPrevious() {
    // Go to previous chapter (e.g., from chapter 5 to chapter 4)
    if (!_hasPrevious) return;
    _currentIndex--;
    final chapter = widget.chapters[_currentIndex];
    _currentChapterApiData = chapter.chapterApiData;
    _currentChapterName = chapter.displayName;
    _loadChapter();
  }

  void _goToNext() {
    // Go to next chapter (e.g., from chapter 4 to chapter 5)
    if (!_hasNext) return;
    _currentIndex++;
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
                  ),
                ),
              ),
            ),

            // Bottom navigation bar
            Positioned(
              bottom: 0,
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
                    // Nút Home (chỉ icon) - bên trái
                    _buildIconOnlyButton(
                      Icons.home,
                      () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                    ),

                    // Nút chapter trước (chỉ icon)
                    _buildIconOnlyButton(
                      Icons.chevron_left,
                      _hasPrevious ? _goToPrevious : null,
                    ),

                    // Dropdown chọn chapter
                    Flexible(flex: 2, child: _buildChapterSelector()),

                    // Nút chapter sau (chỉ icon)
                    _buildIconOnlyButton(
                      Icons.chevron_right,
                      _hasNext ? _goToNext : null,
                    ),

                    // Nút yêu thích (disabled cho truyện online) - bên phải
                    _buildIconOnlyButton(
                      Icons.favorite_border,
                      null, // Disabled cho truyện online
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Floating scroll to top button
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              },
              child: Container(
                width: 40,
                height: 40,
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
        return _DatabaseImage(imageUrl: page.imageUrl, fit: BoxFit.fitWidth);
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

  Widget _buildChapterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: _currentIndex,
        dropdownColor: Colors.grey[900],
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
        items: widget.chapters.asMap().entries.map((entry) {
          final index = entry.key;
          final chapter = entry.value;
          return DropdownMenuItem<int>(
            value: index,
            child: Text(
              'Chương ${chapter.chapterName}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        }).toList(),
        onChanged: (index) {
          if (index != null && index != _currentIndex) {
            final chapter = widget.chapters[index];
            setState(() {
              _currentIndex = index;
              _currentChapterApiData = chapter.chapterApiData;
              _currentChapterName = chapter.displayName;
            });
            _loadChapter();
          }
        },
      ),
    );
  }
}

/// Widget hiển thị ảnh từ database (Hive)
/// Load từ database nếu có, otherwise download và lưu
class _DatabaseImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;

  const _DatabaseImage({required this.imageUrl, this.fit = BoxFit.fitWidth});

  @override
  State<_DatabaseImage> createState() => _DatabaseImageState();
}

class _DatabaseImageState extends State<_DatabaseImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_DatabaseImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // Kiểm tra trong database trước
    final cachedBytes = ImageDatabaseService.getImage(widget.imageUrl);
    if (cachedBytes != null) {
      setState(() {
        _imageBytes = cachedBytes;
        _isLoading = false;
      });
      return;
    }

    // Download và lưu vào database
    final bytes = await ImageDatabaseService.downloadAndSaveImage(
      widget.imageUrl,
    );
    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _isLoading = false;
        _hasError = bytes == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_hasError || _imageBytes == null) {
      return Container(
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
      );
    }

    return Image.memory(
      _imageBytes!,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 200,
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.white54),
        ),
      ),
    );
  }
}
