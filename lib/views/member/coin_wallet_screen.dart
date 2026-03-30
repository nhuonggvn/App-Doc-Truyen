// lib/views/member/coin_wallet_screen.dart
// Màn hình Ví xu - Hiển thị số xu và các gói nạp tiền giả lập

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';

/// Gói nạp xu giả lập
class _CoinPackage {
  final String name;
  final int coins;
  final String price;
  final String bonus;
  final Color color;
  final IconData icon;

  const _CoinPackage({
    required this.name,
    required this.coins,
    required this.price,
    required this.bonus,
    required this.color,
    required this.icon,
  });
}

/// Màn hình ví xu và nạp tiền giả lập cho Member
class CoinWalletScreen extends StatefulWidget {
  const CoinWalletScreen({super.key});

  @override
  State<CoinWalletScreen> createState() => _CoinWalletScreenState();
}

class _CoinWalletScreenState extends State<CoinWalletScreen> {
  // Danh sách các gói nạp xu giả lập
  final List<_CoinPackage> _packages = const [
    _CoinPackage(
      name: 'Gói Khởi Đầu',
      coins: 10,
      price: '5.000đ',
      bonus: '',
      color: Color(0xFF4CAF50),
      icon: Icons.monetization_on_outlined,
    ),
    _CoinPackage(
      name: 'Gói Phổ Thông',
      coins: 50,
      price: '20.000đ',
      bonus: '+5 xu tặng kèm',
      color: Color(0xFF2196F3),
      icon: Icons.stars_outlined,
    ),
    _CoinPackage(
      name: 'Gói Cao Cấp',
      coins: 120,
      price: '40.000đ',
      bonus: '+20 xu tặng kèm',
      color: Color(0xFFFF9800),
      icon: Icons.workspace_premium_outlined,
    ),
    _CoinPackage(
      name: 'Gói VIP',
      coins: 300,
      price: '80.000đ',
      bonus: '+80 xu tặng kèm',
      color: Color(0xFF9C27B0),
      icon: Icons.diamond_outlined,
    ),
  ];

  /// Xử lý khi bấm nút nạp xu - hiện dialog xác nhận + mock payment
  Future<void> _onPurchase(_CoinPackage package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nạp xu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(package.icon, size: 48, color: package.color),
            const SizedBox(height: 12),
            Text(
              'Bạn sẽ nạp ${package.coins} xu\nvới giá ${package.price}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (package.bonus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '🎁 ${package.bonus}',
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚡ Đây là giao dịch giả lập (Mock VNPay)\nSẽ mất 3 giây để xử lý',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận nạp'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Hiện dialog loading giả lập thanh toán
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Đang xử lý thanh toán\n(Mock VNPay)...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Gọi hàm nạp xu từ AuthProvider (đã có delay 3 giây bên trong)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.purchaseCoins(package.coins);

    // Đóng dialog loading
    if (mounted) Navigator.pop(context);

    if (!mounted) return;

    // Thông báo kết quả
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Nạp ${package.coins} xu thành công!'
              : '❌ Nạp xu thất bại. Vui lòng thử lại.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ví Xu'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ hiển thị số xu hiện tại
            _buildCoinBalanceCard(authProvider.coins),

            const SizedBox(height: 24),

            // Tiêu đề phần nạp xu
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Chọn gói nạp xu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lưới các gói nạp xu
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio:
                    1.05, // Giảm tỉ lệ để Box cao chiều dọc hơn, tránh tràn chữ
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                return _buildPackageCard(_packages[index]);
              },
            ),

            const SizedBox(height: 24),

            // Hướng dẫn sử dụng xu
            _buildHowToUseBox(),
          ],
        ),
      ),
    );
  }

  /// Thẻ hiển thị số xu hiện tại của user
  Widget _buildCoinBalanceCard(int coins) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF44336)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.monetization_on, size: 48, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            '$coins',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'XU HIỆN CÓ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1 xu = Đọc 1 chapter VIP',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  /// Card một gói nạp xu
  Widget _buildPackageCard(_CoinPackage package) {
    return InkWell(
      onTap: () => _onPurchase(package),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: package.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: package.color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(package.icon, size: 36, color: package.color),
            const SizedBox(height: 8),
            Text(
              '${package.coins} xu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: package.color,
              ),
            ),
            if (package.bonus.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                package.bonus,
                style: const TextStyle(fontSize: 10, color: Colors.green),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              package.price,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hộp thông tin hướng dẫn sử dụng xu
  Widget _buildHowToUseBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Cách sử dụng xu',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('• 1 xu = Mở khoá đọc 1 chapter VIP không quảng cáo'),
          const Text('• Xu không có thời hạn sử dụng'),
          const Text('• Xem quảng cáo miễn phí → đọc 1 chapter (có giới hạn)'),
          const Text('• Thành viên có xu → không hiện quảng cáo khi đọc'),
        ],
      ),
    );
  }
}
