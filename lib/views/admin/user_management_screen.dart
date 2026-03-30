// lib/views/admin/user_management_screen.dart
// Màn hình quản lý tài khoản người dùng - dành riêng cho Admin

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../viewmodels/auth_provider.dart';

/// Màn hình quản lý danh sách user (Admin only)
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Trạng thái loading danh sách
  bool _isLoading = true;
  // Danh sách tất cả users
  List<AppUser> _users = [];
  // Thông báo lỗi khi tải
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Tải danh sách user khi vào trang
    _loadUsers();
  }

  /// Tải danh sách toàn bộ users từ Firestore
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await FirestoreService.getAllUsers(limit: 100);
      setState(() {
        _users = users;
        _isLoading = false;
      });
      debugPrint('✅ UserManagement: Đã tải ${users.length} user');
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách người dùng: $e';
        _isLoading = false;
      });
      debugPrint('❌ UserManagement: Lỗi tải user: $e');
    }
  }

  /// Hiện dialog đổi role của user
  Future<void> _showChangeRoleDialog(AppUser user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    UserRole selectedRole = user.role;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Phân quyền: ${user.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Email: ${user.email ?? "N/A"}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // Chọn role mới
                ...UserRole.values.where((r) => r != UserRole.guest).map((
                  role,
                ) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<UserRole>(
                      value: role,
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setDialogState(() => selectedRole = value!);
                      },
                    ),
                    title: Text('${_getRoleIcon(role)} ${_getRoleLabel(role)}'),
                    onTap: () {
                      setDialogState(() => selectedRole = role);
                    },
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Huỷ'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lưu thay đổi'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;

    // Cập nhật role lên Firestore
    final success = await authProvider.updateUserRole(user.uid, selectedRole);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Đã cập nhật quyền ${_getRoleLabel(selectedRole)} cho ${user.name}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Tải lại danh sách để hiện thị thay đổi
      await _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Cập nhật quyền thất bại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Khoá / Mở khoá tài khoản user
  Future<void> _toggleUserAccount(AppUser user) async {
    final action = user.isDisabled ? 'mở khoá' : 'khoá';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận $action tài khoản'),
        content: Text(
          'Bạn có chắc muốn $action tài khoản của "${user.name}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: user.isDisabled ? Colors.green : Colors.red,
            ),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.toggleUserAccount(
      user.uid,
      !user.isDisabled,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Đã $action tài khoản ${user.name}'
              : '❌ Thao tác thất bại.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tài khoản'),
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        actions: [
          // Nút làm mới danh sách
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Xây dựng nội dung chính
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải danh sách người dùng...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Text('Chưa có người dùng nào trong hệ thống.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          return _buildUserTile(_users[index]);
        },
      ),
    );
  }

  /// Tile hiển thị thông tin một user
  Widget _buildUserTile(AppUser user) {
    final roleColor = _getRoleColor(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        // Avatar với chữ cái đầu
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.2),
          child: Text(
            user.name.substring(0, 1).toUpperCase(),
            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
          ),
        ),

        // Tên và email
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Badge trạng thái khoá
            if (user.isDisabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Bị khoá',
                  style: TextStyle(fontSize: 10, color: Colors.red),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email ?? 'Không có email',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                // Badge role
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${_getRoleIcon(user.role)} ${_getRoleLabel(user.role)}',
                    style: TextStyle(fontSize: 11, color: roleColor),
                  ),
                ),
                const SizedBox(width: 8),
                // Số xu
                Text(
                  '🪙 ${user.coins} xu',
                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ],
            ),
          ],
        ),

        // Menu hành động
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'role') {
              _showChangeRoleDialog(user);
            } else if (action == 'toggle') {
              _toggleUserAccount(user);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'role',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined),
                  SizedBox(width: 8),
                  Text('Đổi quyền'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    user.isDisabled ? Icons.lock_open : Icons.block,
                    color: user.isDisabled ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.isDisabled ? 'Mở khoá' : 'Khoá tài khoản',
                    style: TextStyle(
                      color: user.isDisabled ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  // ==================== HELPER ====================

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.editor:
        return 'Biên tập viên';
      case UserRole.member:
        return 'Thành viên';
      case UserRole.guest:
        return 'Khách';
    }
  }

  String _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '👤';
      case UserRole.editor:
        return '✏️';
      case UserRole.member:
        return '👥';
      case UserRole.guest:
        return '🌐';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.amber;
      case UserRole.editor:
        return Colors.blue;
      case UserRole.member:
        return Colors.green;
      case UserRole.guest:
        return Colors.grey;
    }
  }
}
