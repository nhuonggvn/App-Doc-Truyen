// lib/views/editor/manga_form_screen.dart
// Màn hình Thêm/Sửa truyện dành cho Editor

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/online_manga.dart';
import '../../services/manga_api_service.dart';

class MangaFormScreen extends StatefulWidget {
  final OnlineManga? manga; // Nếu null là Thêm mới, nếu có là Sửa

  const MangaFormScreen({super.key, this.manga});

  @override
  State<MangaFormScreen> createState() => _MangaFormScreenState();
}

class _MangaFormScreenState extends State<MangaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  
  late TextEditingController _genresController;
  
  String _status = 'Đang tiến hành';
  bool _isVip = false;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.manga?.title ?? '');
    _authorController = TextEditingController(text: widget.manga?.author ?? '');
    _descriptionController = TextEditingController(text: widget.manga?.description ?? '');
    _genresController = TextEditingController(); // TODO: Load genres if available in future
    if (widget.manga != null) {
      _status = widget.manga!.status ?? 'Đang tiến hành';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _genresController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Yêu cầu chọn ảnh nếu là thêm mới
    if (widget.manga == null && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh bìa cho truyện')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      if (widget.manga == null) {
        // TẠO MỚI
        final success = await MangaApiService.createManga(
          title: _titleController.text,
          author: _authorController.text,
          description: _descriptionController.text,
          status: _status,
          coverFile: _imageFile!,
          isVip: _isVip,
          genres: _genresController.text,
        );
        
        if (!success) throw Exception('Không thể tạo truyện lên server');
      } else {
        // CẬP NHẬT (TODO: Thêm API Update sau)
        await Future.delayed(const Duration(seconds: 1));
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.manga == null ? 'Thêm truyện thành công!' : 'Cập nhật thành công!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCoverPreview() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
      );
    }
    if (widget.manga != null && widget.manga!.image != null && widget.manga!.image!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(widget.manga!.image!, fit: BoxFit.cover, width: double.infinity),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(height: 8),
        Text('Nhấn để chọn ảnh bìa', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.manga != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Chỉnh sửa truyện' : 'Thêm truyện mới'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _submit,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  prefixIcon: Icon(Icons.bookmark),
                ),
                items: ['Đang tiến hành', 'Hoàn thành', 'Tạm ngưng'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Là truyện VIP
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Truyện Cao Cấp (VIP)'),
                  ],
                ),
                subtitle: const Text(
                  'Người đọc cần phải mở khoá truyện tính phí.',
                ),
                value: _isVip,
                onChanged: (val) {
                  setState(() {
                    _isVip = val;
                  });
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
