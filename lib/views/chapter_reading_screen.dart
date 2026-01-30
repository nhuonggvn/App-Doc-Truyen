// lib/views/chapter_reading_screen.dart
// Màn hình đọc chapter - cuộn ảnh dọc

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story.dart';
import '../models/chapter.dart';
import '../viewmodels/story_provider.dart';

class ChapterReadingScreen extends StatefulWidget {
  final Story story;
  final Chapter chapter;

  const ChapterReadingScreen({
    super.key,
    required this.story,
    required this.chapter,
  });

  @override
  State<ChapterReadingScreen> createState() => _ChapterReadingScreenState();
}

class _ChapterReadingScreenState extends State<ChapterReadingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showControls = true;
  Chapter? _previousChapter;
  Chapter? _nextChapter;

  @override
  void initState() {
    super.initState();
    _loadAdjacentChapters();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Auto-hide controls khi cuộn
    if (_showControls) {
      setState(() {
        _showControls = false;
      });
    }
  }

  Future<void> _loadAdjacentChapters() async {
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    final chapters = storyProvider.currentChapters;

    // Tìm chapter trước và sau
    for (int i = 0; i < chapters.length; i++) {
      if (chapters[i].id == widget.chapter.id) {
        if (i > 0) {
          _previousChapter = chapters[i - 1]; // Chapter sau (số lớn hơn)
        }
        if (i < chapters.length - 1) {
          _nextChapter = chapters[i + 1]; // Chapter trước (số nhỏ hơn)
        }
        break;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.chapter.images;

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
            // Danh sách ảnh cuộn dọc
            if (images.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chương này chưa có ảnh',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  top: _showControls ? 80 : 0,
                  bottom: _showControls ? 120 : 0,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return _buildImageItem(images[index], index);
                },
              ),

            // Top bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showControls ? 0 : -150, // Ẩn cao hơn cho màn hình lớn
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
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.story.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.chapter.displayTitle,
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
              bottom: _showControls ? 0 : -120,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                  top: 16,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Nút Home
                    _buildNavButton(
                      Icons.home,
                      'Trang chủ',
                      () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                    ),

                    // Nút chapter trước
                    _buildNavButton(
                      Icons.chevron_left,
                      'Chap trước',
                      _nextChapter != null
                          ? () => _goToChapter(_nextChapter!)
                          : null,
                    ),

                    // Dropdown chọn chapter
                    _buildChapterSelector(),

                    // Nút chapter sau
                    _buildNavButton(
                      Icons.chevron_right,
                      'Chap sau',
                      _previousChapter != null
                          ? () => _goToChapter(_previousChapter!)
                          : null,
                    ),

                    // Nút scroll to top
                    _buildNavButton(Icons.vertical_align_top, 'Lên đầu', () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(ChapterImage image, int index) {
    final file = File(image.imagePath);

    if (!file.existsSync()) {
      return Container(
        height: 200,
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          color: Colors.grey[900],
          child: const Center(
            child: Icon(Icons.error, color: Colors.red, size: 48),
          ),
        );
      },
    );
  }

  Widget _buildNavButton(IconData icon, String label, VoidCallback? onPressed) {
    final isEnabled = onPressed != null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? Colors.white : Colors.white38,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterSelector() {
    final storyProvider = Provider.of<StoryProvider>(context);
    final chapters = storyProvider.currentChapters;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: widget.chapter.id,
        dropdownColor: Colors.grey[900],
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        items: chapters.map((chapter) {
          return DropdownMenuItem<int>(
            value: chapter.id,
            child: Text(
              'Chương ${chapter.chapterNumber}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        }).toList(),
        onChanged: (chapterId) {
          if (chapterId != null && chapterId != widget.chapter.id) {
            final selectedChapter = chapters.firstWhere(
              (c) => c.id == chapterId,
            );
            _goToChapter(selectedChapter);
          }
        },
      ),
    );
  }

  void _goToChapter(Chapter chapter) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChapterReadingScreen(story: widget.story, chapter: chapter),
      ),
    );
  }
}
