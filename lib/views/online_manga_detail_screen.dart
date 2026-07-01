// lib/views/online_manga_detail_screen.dart
// Màn hình chi tiết truyện online - hiển thị thông tin và danh sách chapters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/online_manga.dart';
import '../viewmodels/online_manga_provider.dart';
import '../viewmodels/auth_provider.dart';
import 'online_chapter_reading_screen.dart';
import 'member/ad_reward_dialog.dart';

/// Trang chi tiết một truyện online, hiển thị mô tả và danh sách chapter
class OnlineMangaDetailScreen extends StatefulWidget {
  final OnlineManga manga; // Thông tin truyện cơ bản từ danh sách

  const OnlineMangaDetailScreen({super.key, required this.manga});

  @override
  State<OnlineMangaDetailScreen> createState() =>
      _OnlineMangaDetailScreenState();
}

class _OnlineMangaDetailScreenState extends State<OnlineMangaDetailScreen> {
  // Trạng thái mở rộng mô tả
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    // Tải chi tiết truyện từ API khi mở trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OnlineMangaProvider>(
        context,
        listen: false,
      ).loadMangaDetail(widget.manga.slug);
    });
  }

  int _getDisplayChaptersCount(List<OnlineChapter> chapters) {
    if (chapters.isEmpty) return 0;
    int maxChapter = 0;
    for (final ch in chapters) {
      final match = RegExp(r'(\d+)').firstMatch(ch.name);
      if (match != null) {
        final val = int.tryParse(match.group(1)!) ?? 0;
        if (val > maxChapter) {
          maxChapter = val;
        }
      }
    }
    return maxChapter > 0 ? maxChapter : chapters.length;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OnlineMangaProvider>(context);
    final detail = provider.currentDetail;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(background: _buildCoverImage()),
            actions: [
              Consumer<OnlineMangaProvider>(
                builder: (context, mangaProvider, child) {
                  final isFav = mangaProvider.isFavorite(widget.manga.slug);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      final authProvider = context.read<AuthProvider>();
                      if (!authProvider.isAuthenticated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vui lòng đăng nhập để thêm vào yêu thích',
                            ),
                          ),
                        );
                        return;
                      }
                      mangaProvider.toggleFavorite(widget.manga);
                    },
                  );
                },
              ),
            ],
          ),

          // Nội dung chi tiết
          if (provider.isLoadingDetail)
            // Đang tải chi tiết
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải thông tin truyện...'),
                  ],
                ),
              ),
            )
          else if (provider.errorMessage != null && detail == null)
            // Lỗi khi tải
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(provider.errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            provider.loadMangaDetail(widget.manga.slug),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (detail != null)
            // Hiển thị thông tin chi tiết
            ..._buildDetailContent(detail),
        ],
      ),
    );
  }

  /// Xây dựng ảnh bìa cho SliverAppBar
  Widget _buildCoverImage() {
    final imageUrl = widget.manga.image;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh bìa từ URL
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => _buildPlaceholderCover(),
          ),
          // Gradient phủ dưới để dễ đọc chữ
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

    return _buildPlaceholderCover();
  }

  /// Placeholder khi không có ảnh bìa
  Widget _buildPlaceholderCover() {
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

  /// Xây dựng nội dung chi tiết truyện (list of slivers)
  List<Widget> _buildDetailContent(OnlineMangaDetail detail) {
    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin cơ bản
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề truyện
                  Text(
                    detail.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tác giả
                  if (detail.author != null && detail.author!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            detail.author!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Trạng thái và số chapter
                  Row(
                    children: [
                      if (detail.status != null)
                        _buildInfoChip(
                          Icons.bookmark,
                          detail.status!,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.menu_book,
                        '${_getDisplayChaptersCount(detail.chapters)} chương',
                        Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Thể loại
                  if (detail.categories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: detail.categories.map((cat) {
                        return Chip(
                          label: Text(
                            cat.name,
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

            // Mô tả truyện
            if (detail.description != null && detail.description!.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề section
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
                    // Nội dung mô tả
                    Text(
                      detail.description!,
                      maxLines: _isDescriptionExpanded ? null : 3,
                      overflow: _isDescriptionExpanded
                          ? null
                          : TextOverflow.ellipsis,
                    ),
                    // Nút mở rộng/thu gọn
                    if (detail.description!.length > 100)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
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

            // Nút đọc từ đầu & đọc tiếp
            if (detail.chapters.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openChapter(
                          detail.chapters.first, // API tăng dần: first = chapter nhỏ nhất (tập đầu tiên)
                          detail.title,
                          true,
                        ),
                        icon: const Icon(Icons.menu_book),
                        label: const Text('Đọc từ đầu'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openChapter(
                          detail.chapters.last, // API tăng dần: last = chapter lớn nhất (tập mới nhất)
                          detail.title,
                          false,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Đọc tiếp'),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Header danh sách chapter
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
                    'Danh sách chương (${_getDisplayChaptersCount(detail.chapters)})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Danh sách chapters nằm trong một box có chiều cao cố định giống StoryDetailScreen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: detail.chapters.isEmpty
                  ? Center(
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
                          ],
                        ),
                      ),
                    )
                  : Container(
                      height: 400, // Chiều cao cố định
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: detail.chapters.length,
                        itemBuilder: (context, index) {
                          // Đảo ngược thứ tự: newest chapter (largest) at top
                          final reversedIndex = detail.chapters.length - 1 - index;
                          final chapter = detail.chapters[reversedIndex];
                          // 5 chương cũ nhất (oldest) là miễn phí -> trong view ngược, là 5 đầu tiên
                          final isFree = reversedIndex < 5;
                          return _buildChapterTile(
                            chapter,
                            reversedIndex,
                            detail.title,
                            detail.chapters.length,
                            isFree,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),

      // Padding bottom
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  /// Chip hiển thị thông tin (trạng thái, số chương, ...)
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

  /// Tile hiển thị một chapter trong danh sách
  Widget _buildChapterTile(
    OnlineChapter chapter,
    int index,
    String mangaTitle,
    int totalChapters,
    bool isFree,
  ) {
    // Trích xuất số từ tên chương (vd: "Chương 100" -> "100")
    String displayNum = '';
    final match = RegExp(r'(\d+)').firstMatch(chapter.name);
    if (match != null) {
      displayNum = match.group(0)!;
    } else {
      // Nếu không tìm thấy số, dùng index + 1 (vì index lúc này là reversedIndex)
      displayNum = '${index + 1}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isFree
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.amber.shade100,
          child: isFree
              ? Text(
                  displayNum,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: displayNum.length > 3 ? 10 : 12,
                  ),
                )
              : const Icon(
                  Icons.workspace_premium,
                  color: Colors.amber,
                  size: 18,
                ),
        ),
        title: Text(chapter.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openChapter(chapter, mangaTitle, isFree),
      ),
    );
  }

  /// Mở trang đọc chapter (Premium & Subscriptions)
  Future<void> _openChapter(
    OnlineChapter chapter,
    String mangaTitle,
    bool isFree,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Quản trị viên & Biên tập viên: Quyền tối thượng
    if (authProvider.isAdmin || authProvider.isEditor) {
      _navigateToReadingScreen(chapter, widget.manga);
      return;
    }

    // 2. Hội viên Premium: Đọc mọi thứ
    if (authProvider.isAuthenticated && authProvider.currentUser!.isVip) {
      _navigateToReadingScreen(chapter, widget.manga);
      return;
    }

    // 3. Chapter Free: Luôn phải xem quảng cáo
    if (isFree) {
      final adResult = await AdRewardDialog.show(context);
      if (adResult == AdRewardResult.rewarded && mounted) {
        _navigateToReadingScreen(chapter, widget.manga);
      }
      return;
    }

    // 4. Chapter Premium: Yêu cầu đăng ký
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text(
              'Chương Premium 👑',
              style: TextStyle(color: Colors.amber, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Chương này chỉ dành cho Hội viên Premium. Hãy đăng ký ngay để đọc không giới hạn và loại bỏ quảng cáo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Chuyển sang màn hình Profile hoặc nạp Premium
            },
            child: const Text('Tìm hiểu Premium'),
          ),
        ],
      ),
    );
  }

  // Điều hướng thực sự tới màn hình đọc
  void _navigateToReadingScreen(OnlineChapter chapter, OnlineManga manga) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OnlineChapterReadingScreen(chapter: chapter, manga: manga),
      ),
    );
  }
}
