// lib/views/reading_history_screen.dart
// Màn hình lịch sử đọc truyện

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/story_provider.dart';
import '../models/reading_history.dart';
import 'chapter_reading_screen.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto refresh khi tab được chọn
  }

  void _loadHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false).loadReadingHistory();
    });
  }

  // Gọi mỗi khi màn hình được focus (quay lại từ màn hình khác)
  @override
  void didPopNext() {
    super.didPopNext();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Đọc'),
        actions: [
          // Nút refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadHistory,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Xóa tất cả lịch sử',
            onPressed: _confirmClearHistory,
          ),
        ],
      ),
      body: Consumer<StoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Luôn cho phép pull-to-refresh, kể cả khi rỗng
          return RefreshIndicator(
            onRefresh: () => provider.loadReadingHistory(),
            child: provider.readingHistory.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(provider.readingHistory),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 80,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có lịch sử đọc',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Các truyện bạn đọc sẽ hiển thị ở đây',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kéo xuống để làm mới',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<ReadingHistory> history) {
    // Nhóm theo ngày
    final grouped = _groupByDate(history);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header ngày
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Danh sách items
            ...entry.value.map((item) => _buildHistoryItem(item)),
          ],
        );
      },
    );
  }

  Map<String, List<ReadingHistory>> _groupByDate(List<ReadingHistory> history) {
    final Map<String, List<ReadingHistory>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var item in history) {
      final itemDate = DateTime(
        item.readAt.year,
        item.readAt.month,
        item.readAt.day,
      );
      String key;

      if (itemDate == today) {
        key = 'Hôm nay';
      } else if (itemDate == yesterday) {
        key = 'Hôm qua';
      } else {
        key = DateFormat('dd/MM/yyyy').format(item.readAt);
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    return grouped;
  }

  Widget _buildHistoryItem(ReadingHistory item) {
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _openChapter(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ảnh bìa
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildCoverImage(item.storyCoverImage),
              ),
              const SizedBox(width: 12),
              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.storyTitle ?? 'Không rõ tên',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Chương ${item.chapterNumber}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeFormat.format(item.readAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Mũi tên
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(String? coverPath) {
    if (coverPath != null && coverPath.isNotEmpty) {
      final file = File(coverPath);
      if (file.existsSync()) {
        return Image.file(file, width: 60, height: 80, fit: BoxFit.cover);
      }
    }

    return Container(
      width: 60,
      height: 80,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.book, color: Theme.of(context).colorScheme.outline),
    );
  }

  Future<void> _openChapter(ReadingHistory item) async {
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);

    try {
      // Load story và chapters
      await storyProvider.loadStories();
      final story = storyProvider.stories.firstWhere(
        (s) => s.id == item.storyId,
      );

      await storyProvider.loadChapters(item.storyId);
      final chapter = storyProvider.currentChapters.firstWhere(
        (c) => c.id == item.chapterId,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChapterReadingScreen(story: story, chapter: chapter),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không tìm thấy chương')));
      }
    }
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch sử'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử đọc?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<StoryProvider>(
                context,
                listen: false,
              );
              final success = await provider.clearAllReadingHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Đã xóa lịch sử' : 'Không thể xóa'),
                  ),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
