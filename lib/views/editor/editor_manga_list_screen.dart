// lib/views/editor/editor_manga_list_screen.dart
// Màn hình danh sách truyện do Editor quản lý

import 'package:flutter/material.dart';
import '../../models/online_manga.dart';
import '../../services/manga_api_service.dart';
import 'manga_form_screen.dart';
import 'chapter_form_screen.dart';

class EditorMangaListScreen extends StatefulWidget {
  const EditorMangaListScreen({super.key});

  @override
  State<EditorMangaListScreen> createState() => _EditorMangaListScreenState();
}

class _EditorMangaListScreenState extends State<EditorMangaListScreen> {
  bool _isLoading = true;
  List<OnlineManga> _mangas = [];

  @override
  void initState() {
    super.initState();
    _fetchMangas();
  }

  Future<void> _fetchMangas() async {
    setState(() => _isLoading = true);
    try {
      final results = await MangaApiService.getEditorMangas();
      setState(() {
        _mangas = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Truyện Của Tôi'),
        actions: [
          SizedBox(
            width: 35, // chỉnh kích thước nút load lại
            height: 35,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 25,
              onPressed: _fetchMangas,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mangas.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mangas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final manga = _mangas[index];
                    return _buildMangaCard(manga);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MangaFormScreen()),
          );
          if (result == true) _fetchMangas();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa đăng truyện nào',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MangaFormScreen()),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Đăng truyện ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildMangaCard(OnlineManga manga) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Ảnh bìa
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.network(
                manga.image ?? '',
                width: 100,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            
            // Thông tin
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      manga.author ?? 'Chưa cập nhật tác giả',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 13),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Nút Sửa
                        IconButton.filledTonal(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MangaFormScreen(manga: manga)),
                            );
                            if (result == true) _fetchMangas();
                          },
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        // Nút Thêm Chương
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChapterFormScreen(initialManga: manga),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Chương'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
