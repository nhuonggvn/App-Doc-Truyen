// lib/views/widgets/story_card.dart
// Card widget hiển thị truyện với ảnh bìa

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/story.dart';

class StoryCard extends StatelessWidget {
  final Story story;
  final int chapterCount;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const StoryCard({
    super.key,
    required this.story,
    this.chapterCount = 0,
    this.onTap,
    this.onFavoriteToggle,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa - Thu gọn trong Box riêng
            SizedBox(
              width: 100,
              height: 115,
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildCoverImage(context),
              ),
            ),

            // Thông tin - Để trên nền trong suốt
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          if (story.isVip)
                            const WidgetSpan(
                              child: Padding(
                                padding: EdgeInsets.only(right: 4.0),
                                child: Icon(
                                  Icons.workspace_premium,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              ),
                            ),
                          TextSpan(
                            text: story.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Tác giả
                    Text(
                      story.author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Thể loại
                    if (story.genres.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: story.genres.take(2).map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),

                    // Stats & Status
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatNumber(story.viewsCount),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.menu_book,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$chapterCount chương',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions Area
            if (showActions)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: Icon(
                        Icons.edit_note,
                        color: Theme.of(context).colorScheme.primary,
                        size: 26,
                      ),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(height: 12),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              )
            else
              // Nút Yêu thích mặc định cho người dùng
              IconButton(
                icon: Icon(
                  story.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: story.isFavorite
                      ? Colors.red
                      : Theme.of(context).colorScheme.outline,
                  size: 22,
                ),
                onPressed: onFavoriteToggle,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    if (story.coverImage != null && story.coverImage!.isNotEmpty) {
      final file = File(story.coverImage!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
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
          size: 40,
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return Colors.green;
      case 'Tạm dừng':
        return const Color.fromARGB(255, 255, 17, 0);
      default:
        return const Color.fromARGB(255, 0, 140, 255);
    }
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

// Grid card cho hiển thị dạng lưới
class StoryGridCard extends StatelessWidget {
  final Story story;
  final int chapterCount;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const StoryGridCard({
    super.key,
    required this.story,
    this.chapterCount = 0,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Box ảnh bìa - Ôm trọn hình ảnh
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverImage(context),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          story.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: story.isFavorite ? Colors.red : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(story.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        story.status,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Thông tin nội dung - Để ở ngoài box trắng
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      if (story.isVip)
                        const WidgetSpan(
                          child: Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Icon(
                              Icons.workspace_premium,
                              color: Colors.orange,
                              size: 16,
                            ),
                          ),
                        ),
                      TextSpan(
                        text: story.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Số chương
                Row(
                  children: [
                    Icon(
                      Icons.menu_book,
                      size: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$chapterCount chương',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    if (story.coverImage != null && story.coverImage!.isNotEmpty) {
      final file = File(story.coverImage!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

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
          size: 40,
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return Colors.green;
      case 'Tạm dừng':
        return const Color.fromARGB(255, 255, 17, 0);
      default:
        return const Color.fromARGB(255, 0, 140, 255);
    }
  }
}
