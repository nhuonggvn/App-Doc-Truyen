// lib/views/widgets/online_manga_card.dart
// Widget hiển thị thẻ truyện trong lưới trang Online, tách riêng để tối ưu rebuild

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/online_manga.dart';

/// Widget hiển thị thẻ truyện trong GridView trang Online.
/// Tách riêng thành StatelessWidget để Flutter tối ưu rebuild khi cuộn.
class OnlineMangaCard extends StatelessWidget {
  // Dữ liệu truyện cần hiển thị
  final OnlineManga manga;
  // Callback khi nhấn vào thẻ
  final VoidCallback onTap;

  const OnlineMangaCard({
    super.key,
    required this.manga,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16), // chỉnh bo góc hiệu ứng nhấn
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vùng ảnh bìa - ôm trọn hình ảnh
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // chỉnh bo góc card
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Ảnh từ URL với cache và kích thước tối ưu
                  _OnlineMangaNetworkImage(imageUrl: manga.image),

                  // Badge trạng thái
                  if (manga.status != null)
                    Positioned(
                      top: 8, // chỉnh vị trí badge từ trên
                      left: 8, // chỉnh vị trí badge từ trái
                      child: _StatusBadge(status: manga.status!),
                    ),
                ],
              ),
            ),
          ),

          // Tên truyện và số chương - nằm ngoài box ảnh
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 4), // chỉnh khoảng cách thông tin
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manga.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // chỉnh cỡ chữ tên truyện
                  ),
                ),
                const SizedBox(height: 4), // chỉnh khoảng cách giữa tên và số chương
                _ChapterCountRow(chapters: manga.chapters),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị ảnh truyện online với cache và kích thước tối ưu.
/// Sử dụng memCacheWidth/memCacheHeight để decode ảnh nhỏ hơn, giảm RAM.
class _OnlineMangaNetworkImage extends StatelessWidget {
  // Đường dẫn URL của ảnh
  final String? imageUrl;

  const _OnlineMangaNetworkImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const _ImagePlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      // Giới hạn kích thước ảnh trong bộ nhớ cache để giảm RAM
      memCacheWidth: 300, // chỉnh kích thước cache ảnh theo chiều rộng
      memCacheHeight: 420, // chỉnh kích thước cache ảnh theo chiều cao
      // Dùng placeholder tĩnh thay vì CircularProgressIndicator quay liên tục
      placeholder: (context, url) => const _ImageShimmerPlaceholder(),
      errorWidget: (context, url, error) => const _ImagePlaceholder(),
      // Hiệu ứng mờ dần khi ảnh tải xong
      fadeInDuration: const Duration(milliseconds: 200), // chỉnh thời gian hiệu ứng mờ dần
      fadeOutDuration: const Duration(milliseconds: 100), // chỉnh thời gian hiệu ứng mất đi
    );
  }
}

/// Placeholder shimmer tĩnh khi ảnh đang tải.
/// Dùng màu gradient thay vì spinner để tránh tốn CPU khi cuộn nhanh.
class _ImageShimmerPlaceholder extends StatelessWidget {
  const _ImageShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainerHigh,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32, // chỉnh kích thước icon placeholder
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

/// Placeholder khi không có ảnh hoặc ảnh lỗi
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book,
          size: 40, // chỉnh kích thước icon lỗi ảnh
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// Badge hiển thị trạng thái truyện (Hoàn thành, Đang hoạt động, ...)
class _StatusBadge extends StatelessWidget {
  // Nội dung trạng thái
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8, // chỉnh khoảng cách ngang badge
        vertical: 3, // chỉnh khoảng cách dọc badge
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(6), // chỉnh bo góc badge
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10, // chỉnh cỡ chữ trạng thái
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Lấy màu tương ứng với trạng thái truyện
  Color _getStatusColor(String status) {
    if (status.contains('Hoàn thành') || status.contains('COMPLETED')) {
      return Colors.green;
    } else if (status.contains('Đang') || status.contains('ONGOING')) {
      return const Color.fromARGB(255, 0, 140, 255);
    }
    return Colors.orange;
  }
}

/// Widget hiển thị số chương của truyện
class _ChapterCountRow extends StatelessWidget {
  // Số lượng chương
  final int chapters;

  const _ChapterCountRow({required this.chapters});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.menu_book,
          size: 12, // chỉnh kích thước icon số chương
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 4), // chỉnh khoảng cách icon và text
        Expanded(
          child: Text(
            '$chapters chương',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 11, // chỉnh cỡ chữ số chương
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget hiển thị một truyện trong kết quả tìm kiếm.
/// Tách riêng để tối ưu rebuild khi cuộn danh sách tìm kiếm.
class OnlineSearchResultItem extends StatelessWidget {
  // Dữ liệu truyện
  final OnlineManga manga;
  // Callback khi nhấn
  final VoidCallback onTap;

  const OnlineSearchResultItem({
    super.key,
    required this.manga,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // chỉnh khoảng cách item
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa
            SizedBox(
              width: 90, // chỉnh chiều rộng ảnh bìa kết quả
              height: 120, // chỉnh chiều cao ảnh bìa kết quả
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // chỉnh bo góc ảnh
                ),
                child: _OnlineMangaNetworkImage(imageUrl: manga.image),
              ),
            ),

            // Thông tin truyện
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4), // chỉnh khoảng cách thông tin
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      manga.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15, // chỉnh cỡ chữ tên truyện
                      ),
                    ),
                    const SizedBox(height: 8), // chỉnh khoảng cách
                    // Số chương
                    _ChapterCountRow(chapters: manga.chapters),
                    const SizedBox(height: 12), // chỉnh khoảng cách
                    if (manga.status != null)
                      _SearchStatusBadge(status: manga.status!),
                  ],
                ),
              ),
            ),

            // Icon điều hướng
            Padding(
              padding: const EdgeInsets.only(top: 12), // chỉnh vị trí icon
              child: Icon(
                Icons.chevron_right,
                size: 20, // chỉnh kích thước icon
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge trạng thái cho kết quả tìm kiếm (có viền)
class _SearchStatusBadge extends StatelessWidget {
  // Nội dung trạng thái
  final String status;

  const _SearchStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8, // chỉnh khoảng cách ngang badge
        vertical: 3, // chỉnh khoảng cách dọc badge
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6), // chỉnh bo góc badge
        border: Border.all(
          color: statusColor,
          width: 1,
        ),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: statusColor,
          fontSize: 10, // chỉnh cỡ chữ trạng thái
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Lấy màu tương ứng với trạng thái truyện
  Color _getStatusColor(String status) {
    if (status.contains('Hoàn thành') || status.contains('COMPLETED')) {
      return Colors.green;
    } else if (status.contains('Đang') || status.contains('ONGOING')) {
      return const Color.fromARGB(255, 0, 140, 255);
    }
    return Colors.orange;
  }
}
