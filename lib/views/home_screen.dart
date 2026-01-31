// lib/views/home_screen.dart
// Màn hình trang chủ với danh sách truyện tranh

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/story_provider.dart';
import 'widgets/story_card.dart';
import 'story_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false).loadStories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    final stories = _isSearching && _searchController.text.isNotEmpty
        ? storyProvider.searchResults
        : storyProvider.stories;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm truyện...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  storyProvider.searchStories(value);
                },
              )
            : const Text('Truyện Tranh'),
        actions: [
          // Toggle search
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  storyProvider.clearSearch();
                }
              });
            },
          ),
          // Toggle view mode
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => storyProvider.loadStories(),
        child: storyProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : stories.isEmpty
            ? _buildEmptyState()
            : _isGridView
            ? _buildGridView(stories, storyProvider)
            : _buildListView(stories, storyProvider),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.menu_book,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'Không tìm thấy truyện' : 'Chưa có truyện nào',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching
                ? 'Thử tìm kiếm với từ khóa khác'
                : 'Thêm truyện mới để bắt đầu',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List stories, StoryProvider storyProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];
        return FutureBuilder<int>(
          future: storyProvider.getChapterCount(story.id!),
          builder: (context, snapshot) {
            return StoryGridCard(
              story: story,
              chapterCount: snapshot.data ?? 0,
              onTap: () => _openStoryDetail(story),
              onFavoriteToggle: () => storyProvider.toggleFavorite(story),
            );
          },
        );
      },
    );
  }

  // danh sách truyện
  Widget _buildListView(List stories, StoryProvider storyProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FutureBuilder<int>(
            future: storyProvider.getChapterCount(story.id!),
            builder: (context, snapshot) {
              return StoryCard(
                story: story,
                chapterCount: snapshot.data ?? 0,
                onTap: () => _openStoryDetail(story),
                onFavoriteToggle: () => storyProvider.toggleFavorite(story),
              );
            },
          ),
        );
      },
    );
  }

  void _openStoryDetail(story) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoryDetailScreen(story: story)),
    );
  }
}
