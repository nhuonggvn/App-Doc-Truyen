// lib/views/story_detail_screen.dart
// Màn hình chi tiết truyện với danh sách chapters

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story.dart';
import '../models/chapter.dart';
import '../models/comment.dart';
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
  final TextEditingController _commentController = TextEditingController();
  String _userName = 'Người dùng';
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StoryProvider>(context, listen: false);
      provider.loadChapters(widget.story.id!);
      provider.loadComments(widget.story.id!);
      provider.loadReadChapterIds(widget.story.id!);
      provider.incrementViews(widget.story.id!);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('display_name') ?? 'Người dùng';
      _userAvatar = prefs.getString('avatar_path');
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final provider = Provider.of<StoryProvider>(context, listen: false);
    await provider.addComment(
      widget.story.id!,
      _userName,
      _commentController.text.trim(),
      avatarPath: _userAvatar,
    );
    _commentController.clear();
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

          // Danh sách chapters trong container scroll riêng
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: chapters.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có chương nào',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                    )
                  : Container(
                      height: 400, // Chiều cao cố định
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = chapters[index];
                          return _buildChapterTile(chapter, index);
                        },
                      ),
                    ),
            ),
          ),

          // Section bình luận
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bình luận (${storyProvider.currentComments.length})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Form nhập bình luận
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            _userAvatar != null &&
                                File(_userAvatar!).existsSync()
                            ? FileImage(File(_userAvatar!))
                            : null,
                        child:
                            _userAvatar == null ||
                                !File(_userAvatar!).existsSync()
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Viết bình luận...',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _addComment,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: 1,
                          onSubmitted: (_) => _addComment(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Danh sách bình luận
          if (storyProvider.currentComments.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!'),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final comment = storyProvider.currentComments[index];
                return _buildCommentTile(comment);
              }, childCount: storyProvider.currentComments.length),
            ),

          // Padding bottom
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  comment.avatarPath != null &&
                      File(comment.avatarPath!).existsSync()
                  ? FileImage(File(comment.avatarPath!))
                  : null,
              child:
                  comment.avatarPath == null ||
                      !File(comment.avatarPath!).existsSync()
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(comment.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.content),
                ],
              ),
            ),
          ],
        ),
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
    final storyProvider = Provider.of<StoryProvider>(context);
    final isRead = storyProvider.isChapterRead(chapter.id!);

    // Màu vàng cho chương đã đọc
    final readColor = const Color(0xFFFFB300); // Amber/vàng đậm

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRead
              ? readColor.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${chapter.chapterNumber}',
            style: TextStyle(
              color: isRead ? readColor : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          chapter.displayTitle,
          style: TextStyle(
            color: isRead ? readColor : null,
            fontWeight: isRead ? FontWeight.w600 : null,
          ),
        ),
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
            Icon(Icons.chevron_right, color: isRead ? readColor : null),
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
