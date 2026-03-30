// lib/views/member/ad_reward_dialog.dart
// Dialog quảng cáo giả lập - xem 3 giây để mở khoá 1 chapter

import 'dart:async';
import 'package:flutter/material.dart';

/// Kết quả sau khi xem quảng cáo
enum AdRewardResult {
  /// Đã xem xong quảng cáo, được mở khoá chapter
  rewarded,

  /// Người dùng bỏ qua / đóng sớm
  skipped,
}

/// Dialog giả lập quảng cáo video - đếm ngược 5 giây trước khi nhận phần thưởng
class AdRewardDialog extends StatefulWidget {
  const AdRewardDialog({super.key});

  @override
  State<AdRewardDialog> createState() => _AdRewardDialogState();

  /// Hiện dialog và trả về kết quả
  static Future<AdRewardResult> show(BuildContext context) async {
    final result = await showDialog<AdRewardResult>(
      context: context,
      barrierDismissible: false, // Không cho phép đóng khi đang xem
      builder: (context) => const AdRewardDialog(),
    );
    return result ?? AdRewardResult.skipped;
  }
}

class _AdRewardDialogState extends State<AdRewardDialog>
    with SingleTickerProviderStateMixin {
  // Số giây đếm ngược (5 giây giả lập)
  static const int _adDurationSeconds = 5;
  int _secondsRemaining = _adDurationSeconds;
  bool _adCompleted = false;
  Timer? _timer;

  // Animation controller cho progress bar
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Khởi tạo animation progress bar mượt mà
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _adDurationSeconds),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    // Bắt đầu đếm ngược và animation
    _animationController.forward();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Bắt đầu đếm ngược giây
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          // Quảng cáo đã xem xong
          timer.cancel();
          _adCompleted = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Chặn nút Back khi đang xem quảng cáo
      canPop: _adCompleted,
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Phần quảng cáo giả lập
                _buildAdContent(),

                // Phần điều hướng
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Nội dung quảng cáo giả lập (banner màu sắc với mock content)
  Widget _buildAdContent() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      child: Stack(
        children: [
          // Badge "QUẢNG CÁO" ở góc trên trái
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'QUẢNG CÁO',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          // Nội dung quảng cáo giả lập ở giữa
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  size: 64,
                  color: Colors.white54,
                ),
                const SizedBox(height: 8),
                const Text(
                  'TruyenHay Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đọc không giới hạn - Không quảng cáo',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),

          // Đếm ngược ở góc trên phải
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _adCompleted ? Colors.green : Colors.white54,
                  width: 2,
                ),
              ),
              child: Center(
                child: _adCompleted
                    ? const Icon(Icons.check, color: Colors.green, size: 20)
                    : Text(
                        '$_secondsRemaining',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Progress bar và nút hành động
  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress bar đếm ngược
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressAnimation.value,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: _adCompleted ? Colors.green : Colors.orange,
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Thông báo trạng thái
          Text(
            _adCompleted
                ? '✅ Xem xong! Nhận phần thưởng ngay'
                : 'Đang xem quảng cáo... còn $_secondsRemaining giây',
            style: TextStyle(
              fontSize: 13,
              color: _adCompleted ? Colors.green : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Nút hành động
          Row(
            children: [
              // Nút bỏ qua (chỉ hiện khi đang xem, trước khi xong)
              if (!_adCompleted)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, AdRewardResult.skipped);
                    },
                    child: const Text('Bỏ qua'),
                  ),
                ),

              // Nút nhận phần thưởng (chỉ hiện khi đã xem xong)
              if (_adCompleted)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context, AdRewardResult.rewarded);
                    },
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Nhận & Đọc chapter'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
