// lib/views/admin/user_management_screen.dart
// Màn hình quản lý tài khoản người dùng - dành riêng cho Admin

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../viewmodels/auth_provider.dart';
import '../widgets/transaction_feedback.dart';

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
  // Danh sách user sau khi lọc
  List<AppUser> _filteredUsers = [];
  // Thông báo lỗi khi tải
  String? _errorMessage;
  // Biến tìm kiếm
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tải danh sách user khi vào trang
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Lọc danh sách theo email/tên
  void _filterUsers(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((u) {
          final emailMatches = (u.email ?? '').toLowerCase().contains(
            query.toLowerCase(),
          );
          final nameMatches = u.name.toLowerCase().contains(
            query.toLowerCase(),
          );
          return emailMatches || nameMatches;
        }).toList();
      }
    });
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
        _filterUsers(_searchController.text);
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

  /// Hiện BottomSheet chỉnh sửa thông tin user (Role + Coins)
  Future<void> _showEditUserBottomSheet(AppUser user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    UserRole selectedRole = user.role;
    bool isVip = user.role == UserRole.vip;

    final bool? isSaved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chỉnh sửa: ${user.name}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email ?? 'Không có email',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // Thay đổi Role
                const Text(
                  'Quyền hạn hệ thống',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      items: UserRole.values
                          .where((r) => r != UserRole.guest)
                          .map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Row(
                                children: [
                                  Text(
                                    _getRoleIcon(role),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getRoleLabel(role),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setBottomSheetState(() => selectedRole = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Thay đổi VIP Status
                const Text(
                  'Hội viên Premium',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Kích hoạt gói VIP'),
                  subtitle: const Text(
                    'Người dùng có thể đọc mọi truyện không QC',
                  ),
                  value: isVip,
                  onChanged: (val) {
                    setBottomSheetState(() => isVip = val);
                  },
                ),
                const SizedBox(height: 32),

                // Nút hành động
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Lưu thay đổi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Hủy bỏ',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );

    if (isSaved != true || !mounted) return;

    // Tiến hành lưu dữ liệu
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Gọi API cập nhật
    bool roleSuccess = true;
    if (selectedRole != user.role) {
      roleSuccess = await authProvider.updateUserRole(user.uid, selectedRole);
    } else if (isVip != (user.role == UserRole.vip)) {
      // Nếu chỉ thay đổi VIP qua switch chứ không qua dropdown
      roleSuccess = await authProvider.updateUserRole(
        user.uid,
        isVip ? UserRole.vip : UserRole.member,
      );
    }

    if (!mounted) return;
    Navigator.pop(context); // Đóng loading

    if (roleSuccess) {
      TransactionFeedback.show(
        context,
        title: 'Cập nhật thành công',
        message: 'Đã lưu thay đổi cho người dùng ${user.name}',
      );
      await _loadUsers();
    } else {
      TransactionFeedback.show(
        context,
        title: 'Lỗi cập nhật',
        message: 'Không thể lưu thay đổi. Vui lòng thử lại.',
        isSuccess: false,
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

    if (success) {
      TransactionFeedback.show(
        context,
        title: 'Thành công',
        message: 'Đã $action tài khoản ${user.name}',
      );
      await _loadUsers();
    } else {
      TransactionFeedback.show(
        context,
        title: 'Thất bại',
        message: 'Không thể thực hiện thao tác này.',
        isSuccess: false,
      );
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá tài khoản'),
        content: Text(
          'Bạn có chắc chắn muốn xoá tài khoản "${user.name}" không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá luôn'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await FirestoreService.deleteUser(user.uid);
      if (mounted) {
        if (success) {
          TransactionFeedback.show(
            context,
            title: 'Thành công',
            message: 'Đã xoá tài khoản ${user.name}',
          );
          await _loadUsers();
        } else {
          TransactionFeedback.show(
            context,
            title: 'Lỗi',
            message: 'Không thể xoá tài khoản này',
            isSuccess: false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tài khoản'),
        centerTitle: true,
        actions: [
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

    if (_filteredUsers.isEmpty) {
      return Column(
        children: [
          _buildSearchBar(),
          const Expanded(
            child: Center(child: Text('Không tìm thấy người dùng nào.')),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                return _buildUserCard(_filteredUsers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm tên hoặc email...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF3F51B5)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterUsers('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: _filterUsers,
        ),
      ),
    );
  }

  /// Card hiển thị thông tin một user (Mới - Hiện đại hơn)
  Widget _buildUserCard(AppUser user) {
    final roleColor = _getRoleColor(user.role);
    final isVip = user.isVip;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => _showEditUserBottomSheet(user),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar modern
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: roleColor.withValues(alpha: 0.15),
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (isVip)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: Text('👑', style: TextStyle(fontSize: 16)),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Thông tin chính
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isDisabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Bị khoá',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? 'No email',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_getRoleIcon(user.role)} ${_getRoleLabel(user.role)}',
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Premium Badge (New)
                        if (isVip)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '👑 PREMIUM',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions icon
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Hiển thị menu nhanh
                  _showUserQuickActions(user);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserQuickActions(AppUser user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Chỉnh sửa chi tiết'),
            onTap: () {
              Navigator.pop(context);
              _showEditUserBottomSheet(user);
            },
          ),
          ListTile(
            leading: Icon(
              user.isDisabled ? Icons.lock_open : Icons.block,
              color: user.isDisabled ? Colors.green : Colors.red,
            ),
            title: Text(
              user.isDisabled ? 'Mở khoá tài khoản' : 'Khoá tài khoản',
              style: TextStyle(
                color: user.isDisabled ? Colors.green : Colors.red,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _toggleUserAccount(user);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Xoá tài khoản',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
          ),
          const SizedBox(height: 32),
        ],
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
      case UserRole.vip:
        return 'Thành viên VIP';
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
      case UserRole.vip:
        return '👑';
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
      case UserRole.vip:
        return Colors.orangeAccent;
      case UserRole.member:
        return Colors.green;
      case UserRole.guest:
        return Colors.grey;
    }
  }
}
