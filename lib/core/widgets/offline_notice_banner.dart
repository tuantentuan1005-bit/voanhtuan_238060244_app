/// Banner thông báo trạng thái Ngoại Tuyến (Offline Mock Mode)
/// Hiển thị rõ ràng khi máy chủ API không phản hồi và ứng dụng phải dùng dữ liệu mẫu dự phòng
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244
library;

import 'package:flutter/material.dart';
import '../config.dart';

class OfflineNoticeBanner extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const OfflineNoticeBanner({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF422006) // Dark amber
        : const Color(0xFFFEF3C7); // Light amber
    final textColor = isDark
        ? const Color(0xFFFDE68A)
        : const Color(0xFF92400E);
    final borderColor = isDark
        ? const Color(0xFF78350F)
        : const Color(0xFFFCD34D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: textColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CHẾ ĐỘ NGOẠI TUYẾN (DỮ LIỆU MẪU MOCK)',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customMessage ??
                      'Máy chủ API (${AppConfig.apiBaseUrl}) không phản hồi. Đang sử dụng dữ liệu mẫu dự phòng để phục vụ kiểm thử.',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.9),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: borderColor),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'Thử lại',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
