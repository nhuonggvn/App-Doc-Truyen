// lib/views/chapter_edit_screen.dart
// Màn hình chỉnh sửa chapter - thêm/xóa ảnh

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/story.dart';
import '../models/chapter.dart';
import '../viewmodels/story_provider.dart';
import '../services/database_helper.dart';

class ChapterEditScreen extends StatefulWidget {
  final Story story;
  final Chapter chapter;

  const ChapterEditScreen({
    super.key,
    required this.story,
    required this.chapter,
  });

  @override
  State<ChapterEditScreen> createState() => _ChapterEditScreenState();
}

class _ChapterEditScreenState extends State<ChapterEditScreen> {
  final _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<ChapterImage> _existingImages = [];
  List<File> _newImages = [];
  List<int> _imagesToDelete = []; // IDs của ảnh cần xóa
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.chapter.title ?? '';
    _existingImages = List.from(widget.chapter.images);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImages.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      final image = _existingImages.removeAt(index);
      if (image.id != null) {
        _imagesToDelete.add(image.id!);
      }
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    // Kiểm tra còn ít nhất 1 ảnh
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chương phải có ít nhất 1 ảnh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Cập nhật tiêu đề chapter
      final updatedChapter = widget.chapter.copyWith(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
      );
      await _dbHelper.updateChapter(updatedChapter);

      // 2. Xóa các ảnh đã đánh dấu
      for (final imageId in _imagesToDelete) {
        await _dbHelper.deleteChapterImage(imageId);
      }

      // 3. Thêm ảnh mới nếu có
      if (_newImages.isNotEmpty) {
        final storyProvider = Provider.of<StoryProvider>(
          context,
          listen: false,
        );
        // Tính order index tiếp theo
        int nextOrder = _existingImages.isNotEmpty
            ? _existingImages
                      .map((e) => e.orderIndex)
                      .reduce((a, b) => a > b ? a : b) +
                  1
            : 0;

        for (final file in _newImages) {
          // Lưu ảnh vào local storage
          final savedPath = await storyProvider.saveImageToLocal(
            file,
            'chapters/${widget.story.id}/${widget.chapter.id}',
          );

          final chapterImage = ChapterImage(
            chapterId: widget.chapter.id!,
            imagePath: savedPath,
            orderIndex: nextOrder++,
          );
          await _dbHelper.insertChapterImage(chapterImage);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật chương!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sửa ${widget.chapter.displayTitle}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.story.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveChanges,
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
      body: Column(
        children: [
          // Tiêu đề chapter
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề chương (tùy chọn)',
                hintText: 'Ví dụ: Khởi đầu mới',
                prefixIcon: Icon(Icons.title),
              ),
            ),
          ),

          // Nút thêm ảnh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Thêm ảnh mới'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Thông tin số ảnh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.image,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ảnh hiện có: ${_existingImages.length} | Ảnh mới: ${_newImages.length}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Danh sách ảnh
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Ảnh hiện có
                if (_existingImages.isNotEmpty) ...[
                  Text(
                    'Ảnh hiện có',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._existingImages.asMap().entries.map((entry) {
                    return _buildExistingImageCard(entry.key, entry.value);
                  }),
                  const SizedBox(height: 16),
                ],

                // Ảnh mới
                if (_newImages.isNotEmpty) ...[
                  Text(
                    'Ảnh mới thêm',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._newImages.asMap().entries.map((entry) {
                    return _buildNewImageCard(entry.key, entry.value);
                  }),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingImageCard(int index, ChapterImage image) {
    final file = File(image.imagePath);
    final exists = file.existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Số thứ tự
          Container(
            width: 40,
            height: 60,
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          // Preview ảnh
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: exists
                ? Image.file(file, width: 80, height: 60, fit: BoxFit.cover)
                : Container(
                    width: 80,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
          ),

          const SizedBox(width: 12),

          // Tên file
          Expanded(
            child: Text(
              image.imagePath.split(Platform.pathSeparator).last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          // Nút xóa
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _removeExistingImage(index),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageCard(int index, File file) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.green.withValues(alpha: 0.1),
      child: Row(
        children: [
          // Badge NEW
          Container(
            width: 40,
            height: 60,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'MỚI',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),

          // Preview ảnh
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, width: 80, height: 60, fit: BoxFit.cover),
          ),

          const SizedBox(width: 12),

          // Tên file
          Expanded(
            child: Text(
              file.path.split(Platform.pathSeparator).last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          // Nút xóa
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _removeNewImage(index),
          ),
        ],
      ),
    );
  }
}
