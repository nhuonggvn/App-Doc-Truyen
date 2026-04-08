// lib/views/reading_history_screen.dart
// Màn hình lịch sử đọc truyện (đồng bộ Cloud qua REST API)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../viewmodels/online_manga_provider.dart';
import '../models/online_manga.dart';
import 'online_manga_detail_screen.dart';

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

  void _loadHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<OnlineMangaProvider>(
          context,
          listen: false,
        ).loadReadingProgress();
      }
    });
  }

  // Gọi mỗi khi màn hình được focus
  @override
  void didPopNext() {
    super.didPopNext();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Sử Đọc')),
      body: Consumer<OnlineMangaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadReadingProgress(),
            child: provider.readingProgress.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(provider.readingProgress),
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
                'Lịch sử đọc sẽ được tự động đồng bộ lên Cloud',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> history) {
    // Nhóm theo ngày từ trường 'updatedAt'
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

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> history,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var item in history) {
      DateTime? t;
      if (item['updatedAt'] != null) {
        try {
          t = DateTime.parse(item['updatedAt']).toLocal();
        } catch (_) {}
      }
      if (t == null) continue;

      final itemDate = DateTime(t.year, t.month, t.day);
      String key;

      if (itemDate.year == today.year &&
          itemDate.month == today.month &&
          itemDate.day == today.day) {
        key = 'Hôm nay';
      } else if (itemDate.year == yesterday.year &&
          itemDate.month == yesterday.month &&
          itemDate.day == yesterday.day) {
        key = 'Hôm qua';
      } else {
        key = DateFormat('dd/MM/yyyy').format(t);
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    return grouped;
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final title = item['mangaTitle'] ?? 'Không rõ tên';
    final chapterName = item['chapterName'] ?? 'Không rõ chương';
    final imageUrl = item['mangaImage'];

    DateTime? t;
    if (item['updatedAt'] != null) {
      try {
        t = DateTime.parse(item['updatedAt']).toLocal();
      } catch (_) {}
    }
    final timeStr = t != null ? DateFormat('HH:mm').format(t) : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          // Bạn có thể mở đọc luôn chương đó nếu có API,
          // Hiện tại điều hướng tới truyện để user chọn.
          final slug = item['mangaSlug'];
          if (slug != null) {
            final manga = OnlineManga(
              id: slug, // History API không trả về id, dùng slug tạm
              slug: slug,
              title: title,
              image: imageUrl != null ? imageUrl.toString() : null,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OnlineMangaDetailScreen(manga: manga),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ảnh bìa
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 80,
                  child: imageUrl != null && imageUrl.toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[300]),
                          errorWidget: (context, url, err) =>
                              Icon(Icons.image_not_supported),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.book),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                            chapterName,
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
                    Text(timeStr, style: Theme.of(context).textTheme.bodySmall),
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
}
