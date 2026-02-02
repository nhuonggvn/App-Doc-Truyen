// lib/views/story_form_screen.dart
// Màn hình thêm/sửa truyện với upload ảnh bìa và quản lý chapters

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/story.dart';
import '../models/chapter.dart';
import '../viewmodels/story_provider.dart';
import 'chapter_edit_screen.dart';

class StoryFormScreen extends StatefulWidget {
  final Story? story; // null = thêm mới, có giá trị = chỉnh sửa

  const StoryFormScreen({super.key, this.story});

  @override
  State<StoryFormScreen> createState() => _StoryFormScreenState();
}

class _StoryFormScreenState extends State<StoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _genresController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _coverImageFile;
  String? _existingCoverPath;
  String _selectedStatus = 'Đang cập nhật';
  bool _isLoading = false;
  List<Chapter> _chapters = [];

  bool get isEditing => widget.story != null;

  final List<String> _statusOptions = [
    'Đang cập nhật',
    'Hoàn thành',
    'Tạm dừng',
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.story!.title;
      _authorController.text = widget.story!.author;
      _descriptionController.text = widget.story!.description ?? '';
      _genresController.text = widget.story!.genres.join(', ');
      _selectedStatus = widget.story!.status;
      _existingCoverPath = widget.story!.coverImage;

      // Tải danh sách chapters
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadChapters();
      });
    }
  }

  Future<void> _loadChapters() async {
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    await storyProvider.loadChapters(widget.story!.id!);
    setState(() {
      _chapters = storyProvider.currentChapters;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _genresController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    _coverImageFile = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    _coverImageFile = File(image.path);
                  });
                }
              },
            ),
            if (_coverImageFile != null || _existingCoverPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Xóa ảnh bìa',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _coverImageFile = null;
                    _existingCoverPath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteChapterConfirmation(Chapter chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('Xóa chương'),
        content: Text(
          'Bạn có chắc muốn xóa "${chapter.displayTitle}"?\n\n'
          'Tất cả ${chapter.images.length} ảnh trong chương này cũng sẽ bị xóa. '
          'Hành động này không thể hoàn tác!',
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
      final success = await storyProvider.deleteChapter(
        chapter.id!,
        widget.story!.id!,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa chương thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadChapters(); // Refresh danh sách
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                storyProvider.errorMessage ?? 'Không thể xóa chương',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveStory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);

      // Parse genres
      final genresText = _genresController.text.trim();
      final genres = genresText.isEmpty
          ? <String>[]
          : genresText
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

      final story = Story(
        id: widget.story?.id,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        coverImage: _existingCoverPath,
        genres: genres,
        status: _selectedStatus,
        viewsCount: widget.story?.viewsCount ?? 0,
        isFavorite: widget.story?.isFavorite ?? false,
        createdAt: widget.story?.createdAt,
      );

      bool success;
      if (isEditing) {
        success = await storyProvider.updateStory(
          story,
          newCoverImageFile: _coverImageFile,
        );
      } else {
        success = await storyProvider.addStory(
          story,
          coverImageFile: _coverImageFile,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing ? 'Đã cập nhật truyện!' : 'Đã thêm truyện mới!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(storyProvider.errorMessage ?? 'Có lỗi xảy ra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa truyện' : 'Thêm truyện mới'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveStory,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Lưu'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh bìa
              Text(
                'Ảnh bìa',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _buildCoverPreview(),
                ),
              ),
              const SizedBox(height: 24),

              // Tiêu đề
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề truyện *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tác giả
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Tác giả *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tác giả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Thể loại
              TextFormField(
                controller: _genresController,
                decoration: const InputDecoration(
                  labelText: 'Thể loại',
                  hintText: 'Action, Fantasy, Romance...',
                  prefixIcon: Icon(Icons.category),
                  helperText: 'Phân cách bằng dấu phẩy',
                ),
              ),
              const SizedBox(height: 16),

              // Trạng thái
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  prefixIcon: Icon(Icons.bookmark),
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Mô tả
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Mô tả / Giới thiệu',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description),
                  ),
                ),
              ),

              // Phần quản lý chapters (chỉ hiện khi đang edit)
              if (isEditing) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // Header quản lý chapters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.library_books,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quản lý chương',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_chapters.length} chương',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Danh sách chapters
                if (_chapters.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có chương nào',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._chapters.map((chapter) => _buildChapterItem(chapter)),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterItem(Chapter chapter) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            // Avatar số chương
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${chapter.chapterNumber}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Thông tin chương
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${chapter.images.length} ảnh',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    dateFormat.format(chapter.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Nút sửa
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              onPressed: () => _editChapter(chapter),
              tooltip: 'Sửa chương',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),

            // Nút xóa
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 22),
              onPressed: () => _showDeleteChapterConfirmation(chapter),
              tooltip: 'Xóa chương',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    );
  }

  void _editChapter(Chapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChapterEditScreen(story: widget.story!, chapter: chapter),
      ),
    ).then((_) => _loadChapters()); // Refresh sau khi edit
  }

  Widget _buildCoverPreview() {
    // Ưu tiên hiển thị ảnh mới chọn
    if (_coverImageFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_coverImageFile!, fit: BoxFit.cover),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Nhấn để thay đổi',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }

    // Hiển thị ảnh cũ nếu đang edit
    if (_existingCoverPath != null) {
      final file = File(_existingCoverPath!);
      if (file.existsSync()) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(file, fit: BoxFit.cover),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Nhấn để thay đổi',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        );
      }
    }

    // Placeholder
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          'Nhấn để chọn ảnh bìa',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
