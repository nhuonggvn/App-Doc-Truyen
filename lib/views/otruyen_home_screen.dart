// lib/views/otruyen_home_screen.dart
// Màn hình chính hiển thị truyện từ OTruyen API

import 'package:flutter/material.dart';
import '../models/otruyen_models.dart';
import '../services/otruyen_api_service.dart';
import 'otruyen_detail_screen.dart';

class OTruyenHomeScreen extends StatefulWidget {
  const OTruyenHomeScreen({super.key});

  @override
  State<OTruyenHomeScreen> createState() => _OTruyenHomeScreenState();
}

class _OTruyenHomeScreenState extends State<OTruyenHomeScreen>
    with SingleTickerProviderStateMixin {
  final OTruyenApiService _apiService = OTruyenApiService();
  late TabController _tabController;

  // State
  bool _isLoading = true;
  String? _error;
  List<OTruyenStory> _stories = [];
  List<OTruyenCategory> _categories = [];
  String _cdnImageDomain = 'img.otruyenapi.com';
  OTruyenPagination? _pagination;

  // Current state
  final String _currentListType = 'truyen-moi';
  OTruyenCategory? _selectedCategory;
  int _currentPage = 1;

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentPage = 1;
        _isSearching = false;
        _searchKeyword = '';
        _searchController.clear();
      });
      _loadDataForCurrentTab();
    }
  }

  Future<void> _loadInitialData() async {
    await _loadCategories();
    await _loadDataForCurrentTab();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadDataForCurrentTab() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      OTruyenListResponse response;

      if (_isSearching && _searchKeyword.isNotEmpty) {
        response = await _apiService.searchStories(
          _searchKeyword,
          page: _currentPage,
        );
      } else if (_tabController.index == 1 && _selectedCategory != null) {
        response = await _apiService.getStoriesByCategory(
          _selectedCategory!.slug,
          page: _currentPage,
        );
      } else {
        response = await _apiService.getStoryList(
          _currentListType,
          page: _currentPage,
        );
      }

      if (mounted) {
        setState(() {
          _stories = response.items;
          _cdnImageDomain = response.cdnImageDomain;
          _pagination = response.pagination;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchKeyword = keyword;
      _currentPage = 1;
    });
    _loadDataForCurrentTab();
  }

  void _clearSearch() {
    setState(() {
      _isSearching = false;
      _searchKeyword = '';
      _searchController.clear();
      _currentPage = 1;
    });
    _loadDataForCurrentTab();
  }

  void _onCategorySelected(OTruyenCategory category) {
    setState(() {
      _selectedCategory = category;
      _currentPage = 1;
    });
    _loadDataForCurrentTab();
  }

  void _loadNextPage() {
    if (_pagination?.hasNextPage ?? false) {
      setState(() => _currentPage++);
      _loadDataForCurrentTab();
    }
  }

  void _loadPreviousPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
      _loadDataForCurrentTab();
    }
  }

  void _openStoryDetail(OTruyenStory story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OTruyenDetailScreen(storySlug: story.slug, storyName: story.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 25,
        title: const Text('Truyện Online'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mới cập nhật'),
            Tab(text: 'Thể loại'),
            Tab(text: 'Tìm kiếm'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildStoryList(), _buildCategoryTab(), _buildSearchTab()],
      ),
    );
  }

  Widget _buildStoryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Lỗi tải dữ liệu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDataForCurrentTab,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_stories.isEmpty) {
      return const Center(child: Text('Không có truyện nào'));
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Tính số cột dựa trên chiều rộng màn hình
              // Mỗi card có chiều rộng tối thiểu 150px
              final availableWidth = constraints.maxWidth;
              final isWeb = availableWidth > 600;

              // Padding 120px mỗi bên cho web
              final horizontalPadding = isWeb ? 120.0 : 8.0;
              final contentWidth = availableWidth - (horizontalPadding * 2);

              // Tính số cột: tối thiểu 2, tối đa 5
              int crossAxisCount = (contentWidth / 180).floor();
              crossAxisCount = crossAxisCount.clamp(2, 5);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _stories.length,
                  itemBuilder: (context, index) =>
                      _buildStoryCard(_stories[index]),
                ),
              );
            },
          ),
        ),
        _buildPagination(),
      ],
    );
  }

  Widget _buildStoryCard(OTruyenStory story) {
    final thumbUrl = story.getFullThumbUrl(_cdnImageDomain);

    return GestureDetector(
      onTap: () => _openStoryDetail(story),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: thumbUrl.isNotEmpty
                  ? Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 40),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 40),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (story.chaptersLatest != null &&
                        story.chaptersLatest!.isNotEmpty)
                      Text(
                        'Chương ${story.chaptersLatest!.first}',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color.fromARGB(255, 160, 6, 127),
                        ),
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

  Widget _buildCategoryTab() {
    return Column(
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _categories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory?.id == cat.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (_) => _onCategorySelected(cat),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _selectedCategory == null
              ? const Center(child: Text('Chọn thể loại để xem truyện'))
              : _buildStoryList(),
        ),
      ],
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm truyện...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchKeyword.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _onSearch, child: const Text('Tìm')),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isSearching
              ? _buildStoryList()
              : const Center(child: Text('Nhập từ khóa để tìm kiếm')),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    if (_pagination == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? _loadPreviousPage : null,
          ),
          Text('Trang $_currentPage / ${_pagination!.totalPages}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _pagination!.hasNextPage ? _loadNextPage : null,
          ),
        ],
      ),
    );
  }
}
