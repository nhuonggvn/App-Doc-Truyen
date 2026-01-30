// lib/views/story_detail_screen.dart
// Màn hình chi tiết truyện với danh sách chapters

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/story.dart';
import '../models/chapter.dart';
import '../viewmodels/story_provider.dart';
import 'chapter_reading_screen.dart';
import 'chapter_form_screen.dart';

class StoryDetailScreen extends StatefulWidget {
  final Story story;

  const StoryDetailScreen({super.key, required this.story});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    // Tải danh sách chapters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(
        context,
        listen: false,
      ).loadChapters(widget.story.id!);
      Provider.of<StoryProvider>(
        context,
        listen: false,
      ).incrementViews(widget.story.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    final currentStory =
        storyProvider.getStoryById(widget.story.id!) ?? widget.story;
    final chapters = storyProvider.currentChapters;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar với ảnh bìa
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildCoverImage(currentStory),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  currentStory.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: currentStory.isFavorite ? Colors.red : null,
                ),
                onPressed: () => storyProvider.toggleFavorite(currentStory),
              ),
            ],
          ),

          // Nội dung
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin truyện
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề
                      Text(
                        currentStory.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Tác giả
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentStory.author,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Trạng thái
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.bookmark,
                            currentStory.status,
                            Theme.of(context).colorScheme.secondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.visibility,
                            _formatNumber(currentStory.viewsCount),
                            Theme.of(context).colorScheme.tertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.menu_book,
                            '${chapters.length} chương',
                            Theme.of(context).colorScheme.primaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Thể loại
                      if (currentStory.genres.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: currentStory.genres.map((genre) {
                            return Chip(
                              label: Text(
                                genre,
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

                // Mô tả
                if (currentStory.description != null &&
                    currentStory.description!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
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
                          currentStory.description!,
                          maxLines: _isDescriptionExpanded ? null : 3,
                          overflow: _isDescriptionExpanded
                              ? null
                              : TextOverflow.ellipsis,
                        ),
                        if (currentStory.description!.length > 100)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isDescriptionExpanded =
                                    !_isDescriptionExpanded;
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

                // Buttons hành động
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: chapters.isNotEmpty
                              ? () => _readFromFirstChapter(chapters)
                              : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Đọc từ đầu'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _addNewChapter(),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm chương'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Danh sách chapters
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
                        'Danh sách chương',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Danh sách chapters
          if (chapters.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.library_books_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có chương nào',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _addNewChapter(),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm chương đầu tiên'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final chapter = chapters[index];
                return _buildChapterTile(chapter, index);
              }, childCount: chapters.length),
            ),

          // Padding bottom
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildCoverImage(Story story) {
    if (story.coverImage != null && story.coverImage!.isNotEmpty) {
      final file = File(story.coverImage!);
      if (file.existsSync()) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.cover),
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
    }

    // Placeholder
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

  Widget _buildChapterTile(Chapter chapter, int index) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${chapter.chapterNumber}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(chapter.displayTitle),
        subtitle: Text(
          dateFormat.format(chapter.createdAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${chapter.images.length} ảnh',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _openChapter(chapter),
      ),
    );
  }

  void _readFromFirstChapter(List<Chapter> chapters) {
    // Tìm chapter có số nhỏ nhất
    final firstChapter = chapters.reduce(
      (a, b) => a.chapterNumber < b.chapterNumber ? a : b,
    );
    _openChapter(firstChapter);
  }

  void _openChapter(Chapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChapterReadingScreen(story: widget.story, chapter: chapter),
      ),
    );
  }

  void _addNewChapter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterFormScreen(story: widget.story),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
