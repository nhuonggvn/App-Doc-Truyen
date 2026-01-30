// lib/views/my_stories_screen.dart
// Màn hình quản lý truyện của tôi

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/story_provider.dart';
import 'widgets/story_card.dart';
import 'story_form_screen.dart';
import 'story_detail_screen.dart';

class MyStoriesScreen extends StatefulWidget {
  const MyStoriesScreen({super.key});

  @override
  State<MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends State<MyStoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false).loadStories();
    });
  }

  Future<bool> _showDeleteConfirmation(story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa truyện'),
        content: Text(
          'Bạn có chắc muốn xóa "${story.title}"?\n\nTất cả chương và ảnh trong truyện cũng sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final success = await storyProvider.deleteStory(story.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã xóa truyện' : 'Không thể xóa truyện'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    final stories = storyProvider.stories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Truyện Của Tôi'),
        actions: [
          if (stories.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${stories.length} truyện',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
      body: storyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : stories.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () => storyProvider.loadStories(),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return Dismissible(
                    key: Key('story_${story.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _showDeleteConfirmation(story),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FutureBuilder<int>(
                        future: storyProvider.getChapterCount(story.id!),
                        builder: (context, snapshot) {
                          return StoryCard(
                            story: story,
                            chapterCount: snapshot.data ?? 0,
                            showActions: true,
                            onTap: () => _openStoryDetail(story),
                            onFavoriteToggle: () =>
                                storyProvider.toggleFavorite(story),
                            onEdit: () => _editStory(story),
                            onDelete: () => _showDeleteConfirmation(story),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StoryFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm truyện'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_add,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa có truyện nào',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút bên dưới để thêm truyện mới',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StoryFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm truyện đầu tiên'),
          ),
        ],
      ),
    );
  }

  void _openStoryDetail(story) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoryDetailScreen(story: story)),
    );
  }

  void _editStory(story) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoryFormScreen(story: story)),
    );
  }
}
