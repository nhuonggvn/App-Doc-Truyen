// lib/views/editor/chapter_form_screen.dart
// Màn hình Thêm chương mới dành cho Editor

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/online_manga.dart';
import '../../services/manga_api_service.dart';

class ChapterFormScreen extends StatefulWidget {
  final OnlineManga? initialManga; // Nếu mở từ trang chi tiết truyện

  const ChapterFormScreen({super.key, this.initialManga});

  @override
  State<ChapterFormScreen> createState() => _ChapterFormScreenState();
}

class _ChapterFormScreenState extends State<ChapterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  late TextEditingController _mangaSearchController;
  late TextEditingController _chapterNumController;
  late TextEditingController _chapterTitleController;
  
  final List<File> _imageFiles = [];
  bool _isLoading = false;
  OnlineManga? _selectedManga;

  @override
  void initState() {
    super.initState();
    _selectedManga = widget.initialManga;
    _mangaSearchController = TextEditingController(text: _selectedManga?.title ?? '');
    _chapterNumController = TextEditingController();
    _chapterTitleController = TextEditingController();
  }

  @override
  void dispose() {
    _mangaSearchController.dispose();
    _chapterNumController.dispose();
    _chapterTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_selectedManga == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn bộ truyện')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh nội dung chương')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final success = await MangaApiService.createChapter(
        mangaSlug: _selectedManga!.slug,
        chapterNum: _chapterNumController.text,
        title: _chapterTitleController.text,
        imageFiles: _imageFiles,
      );
      
      if (!success) throw Exception('Không thể upload chương lên server');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng chương mới thành công!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Chương Mới'),
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _submit,
              icon: const Icon(Icons.cloud_upload_rounded),
            )
        ],
      ),
      body: _isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang upload dữ liệu...'),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chọn truyện
                  TextFormField(
                    controller: _mangaSearchController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Chọn bộ truyện *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.library_books_outlined),
                      suffixIcon: Icon(Icons.search_rounded),
                    ),
                    onTap: () {
                      // TODO: Show Search/Select Manga Dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng tìm truyện sẽ sớm cập nhật')),
                      );
                    },
                    validator: (v) => (_selectedManga == null) ? 'Vui lòng chọn truyện' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _chapterNumController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Số chương *',
                            border: OutlineInputBorder(),
                            hintText: 'VD: 1',
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? '!' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _chapterTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Tên chương (tùy chọn)',
                            border: OutlineInputBorder(),
                            hintText: 'VD: Sự khởi đầu',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Phần chọn ảnh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nội dung chương (Ảnh)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Thêm ảnh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Danh sách ảnh đã chọn (Dạng Grid)
                  if (_imageFiles.isEmpty)
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant, 
                          style: BorderStyle.solid
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.collections_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 40),
                          const SizedBox(height: 8),
                          Text('Chưa có ảnh nào được chọn', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _imageFiles.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.7,
                      ),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _imageFiles[index],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('ĐĂNG CHƯƠNG TRUYỆN'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
