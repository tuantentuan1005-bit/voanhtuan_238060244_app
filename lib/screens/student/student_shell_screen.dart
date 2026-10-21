/// Màn hình Dashboard Sinh viên - Hoàn thiện chuẩn mực Bước 5
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244
library;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../data/models/student_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/theme_provider.dart';

class StudentShellScreen extends StatefulWidget {
  const StudentShellScreen({super.key});

  @override
  State<StudentShellScreen> createState() => _StudentShellScreenState();
}

class _StudentShellScreenState extends State<StudentShellScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Điểm Danh Nhanh',
    'Lịch Sử Điểm Danh',
    'Cảnh Báo Vắng Học',
    'Hồ Sơ Sinh Viên',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final studentId = auth.currentUser?.id ?? AppConfig.studentId;
      final sp = context.read<StudentProvider>();
      sp.loadData(studentId);
      sp.checkGpsLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => themeProvider.toggleTheme(!isDark),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          StudentScanTab(),
          StudentHistoryTab(),
          StudentWarningTab(),
          StudentProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Quét QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber_rounded),
            label: 'Cảnh báo',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản Sinh viên?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 1. TAB QUÉT QR ĐIỂM DANH (QR + GPS + FACE)
// ══════════════════════════════════════════════════════════════════

class StudentScanTab extends StatefulWidget {
  const StudentScanTab({super.key});

  @override
  State<StudentScanTab> createState() => _StudentScanTabState();
}

class _StudentScanTabState extends State<StudentScanTab> {
  MobileScannerController? _scannerController;
  bool _isScannerPaused = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScannerPaused) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() => _isScannerPaused = true);
        _handleQrScanned(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _handleQrScanned(String rawQr) async {
    final sp = context.read<StudentProvider>();
    final auth = context.read<AuthProvider>();
    final studentId = auth.currentUser?.id ?? AppConfig.studentId;

    final result = await sp.performCheckIn(
      studentId: studentId,
      qrPayload: rawQr,
    );

    if (!mounted) return;

    if (result.success) {
      _showSuccessDialog(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red.shade600,
        ),
      );
      setState(() => _isScannerPaused = false);
    }
  }

  void _showSuccessDialog(CheckInResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const CircleAvatar(
          radius: 32,
          backgroundColor: Colors.green,
          child: Icon(Icons.check, size: 40, color: Colors.white),
        ),
        title: const Text('Điểm Danh Thành Công!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow('Môn học:', result.courseName ?? 'Lập trình thiết bị di động'),
            const SizedBox(height: 6),
            _dialogRow('Lớp:', result.className ?? 'CNTT_K22_A'),
            const SizedBox(height: 6),
            _dialogRow('Thời gian:', result.checkInTime ?? '07:01'),
            const SizedBox(height: 6),
            _dialogRow('Định vị GPS:', '${result.distanceMeters?.toStringAsFixed(1) ?? '14.5'}m (Tại phòng học)'),
            const SizedBox(height: 6),
            _dialogRow('Khuôn mặt:', result.faceVerified ? 'Đã xác thực ✅' : 'Bỏ qua'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bản ghi đã được lưu vào hệ thống chuyên cần',
                      style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isScannerPaused = false);
            },
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );

  void _showManualInputDialog() {
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập Mã QR Điểm Danh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập hoặc dán mã QR Token do Giảng viên phát trên màn hình:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Mã QR Token',
                hintText: 'Nhập hoặc dán mã tại đây...',
                prefixIcon: Icon(Icons.qr_code_2),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = textCtrl.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                _handleQrScanned(code);
              }
            },
            child: const Text('Xác nhận điểm danh'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudentProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. Thẻ trạng thái Xác thực Đa Yếu Tố ─────────────
          Card(
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Xác Thực Đa Yếu Tố (MFA)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  // Yếu tố 1: GPS
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: sp.isLocationVerified
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      child: Icon(
                        sp.isLocationVerified ? Icons.location_on : Icons.location_searching,
                        color: sp.isLocationVerified ? Colors.green : Colors.orange,
                        size: 18,
                      ),
                    ),
                    title: const Text('Định vị GPS tại phòng học', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(sp.locationStatusText),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Đo lại vị trí GPS',
                      onPressed: () => sp.checkGpsLocation(),
                    ),
                  ),

                  // Yếu tố 2: Khuôn mặt
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: sp.isFaceDetected
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      child: Icon(
                        sp.isFaceDetected ? Icons.face : Icons.face_retouching_natural,
                        color: sp.isFaceDetected ? Colors.green : Colors.grey,
                        size: 18,
                      ),
                    ),
                    title: const Text('Nhận diện khuôn mặt sinh viên', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(sp.faceStatusText),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () => sp.simulateFaceDetection(),
                      child: const Text('Quét mặt', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ─── 2. Camera Quét QR Code ───────────────────────────
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),

                // Scanner target overlay
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                // Torch & Switch controls
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: Colors.black45),
                        icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                        onPressed: () {
                          _scannerController?.toggleTorch();
                          setState(() => _isTorchOn = !_isTorchOn);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: Colors.black45),
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                        onPressed: () => _scannerController?.switchCamera(),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Căn chỉnh mã QR buổi học vào giữa khung hình',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── 3. Nút hành động bổ trợ ──────────────────────────
          ElevatedButton.icon(
            onPressed: () => _showManualInputDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.keyboard_alt_outlined),
            label: const Text(
              'Nhập mã QR điểm danh thủ công (Dành cho máy ảo)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () {
              setState(() => _isScannerPaused = false);
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Quét lại mã bằng Camera'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 2. TAB LỊCH SỬ ĐIỂM DANH (HISTORY)
// ══════════════════════════════════════════════════════════════════

class StudentHistoryTab extends StatelessWidget {
  const StudentHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudentProvider>();
    final history = sp.filteredHistory;

    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: Text('Tất cả (${sp.history.length})'),
                selected: sp.historyFilter == 'all',
                onSelected: (_) => sp.setHistoryFilter('all'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Có mặt (${sp.history.where((h) => h.status == 'present').length})'),
                selected: sp.historyFilter == 'present',
                onSelected: (_) => sp.setHistoryFilter('present'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Đi muộn (${sp.history.where((h) => h.status == 'late').length})'),
                selected: sp.historyFilter == 'late',
                onSelected: (_) => sp.setHistoryFilter('late'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Vắng mặt (${sp.history.where((h) => h.status == 'absent').length})'),
                selected: sp.historyFilter == 'absent',
                onSelected: (_) => sp.setHistoryFilter('absent'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Danh sách lịch sử
        Expanded(
          child: history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_toggle_off, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Không tìm thấy bản ghi điểm danh nào'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: history.length,
                  itemBuilder: (ctx, i) => _HistoryCardItem(item: history[i]),
                ),
        ),
      ],
    );
  }
}

class _HistoryCardItem extends StatelessWidget {
  final AttendanceHistoryItem item;
  const _HistoryCardItem({required this.item});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (item.status) {
      case 'present':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'late':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_rounded;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.courseName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.courseCode} • ${item.className}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        item.statusLabel,
                        style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(item.date, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.schedule, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(item.time, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.room_outlined, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.room,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _tagBadge('Phương thức: ${item.methodLabel}', Colors.blue),
                if (item.distanceMeters != null)
                  _tagBadge('GPS: ${item.distanceMeters!.toStringAsFixed(1)}m', Colors.teal),
                if (item.faceVerified)
                  _tagBadge('Face OK ✅', Colors.indigo),
                if (item.note != null)
                  _tagBadge(item.note!, Colors.blueGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════
// 3. TAB CẢNH BÁO VẮNG HỌC (WARNINGS)
// ══════════════════════════════════════════════════════════════════

class StudentWarningTab extends StatelessWidget {
  const StudentWarningTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudentProvider>();
    final summaries = sp.summaries;
    final atRiskList = sp.atRiskCourses;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Banner cảnh báo nguy cơ ──────────────────────────
        if (atRiskList.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade300, width: 1.2),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CẢNH BÁO NGUY CƠ CẤM THI!',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bạn có ${atRiskList.length} môn học đã vượt ngưỡng vắng 20%. Hãy liên hệ Giảng viên hoặc Phòng đào tạo để được hướng dẫn!',
                        style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300, width: 1.2),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chuyên cần đạt chuẩn',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Tất cả các môn học đều nằm trong ngưỡng an toàn (< 20% vắng)',
                        style: TextStyle(color: Colors.black87, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        Text(
          'Thống Kê Tỷ Lệ Vắng Theo Môn Học',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        ...summaries.map((s) => _CourseSummaryCard(summary: s)),
      ],
    );
  }
}

class _CourseSummaryCard extends StatelessWidget {
  final CourseAttendanceSummary summary;
  const _CourseSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    Color progressColor;
    String statusTitle;
    if (summary.isAtRisk) {
      progressColor = Colors.red;
      statusTitle = 'NGUY CƠ CẤM THI';
    } else if (summary.absenceRate >= 10.0) {
      progressColor = Colors.orange;
      statusTitle = 'CẦN CHÚ Ý';
    } else {
      progressColor = Colors.green;
      statusTitle = 'AN TOÀN';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('Mã HP: ${summary.courseCode}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusTitle,
                    style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: summary.absenceRate / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(progressColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${summary.absenceRate.toStringAsFixed(1)}% vắng',
                  style: TextStyle(fontWeight: FontWeight.bold, color: progressColor, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Metrics row
            Row(
              children: [
                _metricCol('Tổng số buổi', '${summary.totalSessions}'),
                _metricCol('Có mặt', '${summary.presentCount}', color: Colors.green),
                _metricCol('Đi muộn', '${summary.lateCount}', color: Colors.orange),
                _metricCol('Đã vắng', '${summary.absentCount}', color: Colors.red),
                _metricCol('Còn được vắng', '${summary.remainingAllowedAbsence} buổi', color: Colors.indigo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCol(String title, String val, {Color? color}) => Expanded(
        child: Column(
          children: [
            Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════════
// 4. TAB HỒ SƠ SINH VIÊN (PROFILE)
// ══════════════════════════════════════════════════════════════════

class StudentProfileTab extends StatelessWidget {
  const StudentProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sp = context.watch<StudentProvider>();

    final totalSessions = sp.summaries.fold<int>(0, (sum, e) => sum + e.totalSessions);
    final totalAttended = sp.summaries.fold<int>(0, (sum, e) => sum + e.presentCount + e.lateCount);
    final overallRate = totalSessions == 0 ? 100.0 : (totalAttended / totalSessions) * 100;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.blue.withValues(alpha: 0.15),
                child: const Text(
                  'T',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                auth.currentUser?.fullName ?? AppConfig.studentName,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MSSV: ${auth.currentUser?.studentCode ?? AppConfig.studentId} • Lớp CNTT_K22_A',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email sinh viên'),
                subtitle: Text(auth.currentUser?.email ?? '238060244@student.university.edu.vn'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Mã số sinh viên (MSSV)'),
                subtitle: Text(auth.currentUser?.studentCode ?? AppConfig.studentId),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.school_outlined),
                title: Text('Khoa / Chuyên ngành'),
                subtitle: Text('Khoa Công Nghệ Thông Tin'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.verified_outlined),
                title: Text('Hệ Thống'),
                subtitle: Text('Ứng Dụng Điểm Danh Thông Minh - Võ Anh Tuấn'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng quan chuyên cần học kỳ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _profileStatBox('$totalSessions', 'Tổng buổi học', Icons.calendar_month, Colors.indigo),
                    const SizedBox(width: 8),
                    _profileStatBox('$totalAttended', 'Đã tham gia', Icons.check_circle_outline, Colors.green),
                    const SizedBox(width: 8),
                    _profileStatBox('${overallRate.toStringAsFixed(0)}%', 'Tỉ lệ có mặt', Icons.percent, Colors.teal),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: () => context.read<AuthProvider>().logout(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 46),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất'),
        ),
      ],
    );
  }

  Widget _profileStatBox(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
