/// Màn hình Dashboard Giảng viên - Hoàn thiện chuẩn mực Bước 4
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/models/lecturer_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lecturer_provider.dart';
import '../../providers/theme_provider.dart';

class LecturerShellScreen extends StatefulWidget {
  const LecturerShellScreen({super.key});

  @override
  State<LecturerShellScreen> createState() => _LecturerShellScreenState();
}

class _LecturerShellScreenState extends State<LecturerShellScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Lịch Buổi Học',
    'Phát Mã QR Điểm Danh',
    'Sổ Điểm Danh',
    'Hồ Sơ Giảng Viên',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final lecId = auth.currentUser?.id ?? 'demo_lecturer';
      context.read<LecturerProvider>().loadSessions(lecId);
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
          LecturerSessionsTab(),
          LecturerQrTab(),
          LecturerAttendanceTab(),
          LecturerProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          if (_currentIndex == 1 && idx != 1) {
            context.read<LecturerProvider>().stopQr();
          }
          setState(() => _currentIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Buổi học',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_2_rounded),
            label: 'Mã QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg_rounded),
            label: 'Điểm danh',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSessionDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tạo buổi học'),
            )
          : null,
    );
  }

  void _showAddSessionDialog(BuildContext context) {
    final classCtrl = TextEditingController(text: 'CNTT_K22_C');
    final dateCtrl = TextEditingController(text: '23/10/2026');
    final startCtrl = TextEditingController(text: '07:30');
    final endCtrl = TextEditingController(text: '10:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo Buổi Học Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: classCtrl,
                decoration: const InputDecoration(labelText: 'Tên lớp học / Mã lớp'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Ngày học (DD/MM/YYYY)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(labelText: 'Bắt đầu (HH:mm)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(labelText: 'Kết thúc (HH:mm)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LecturerProvider>().createSession(
                    classId: classCtrl.text.trim(),
                    date: dateCtrl.text.trim(),
                    startTime: startCtrl.text.trim(),
                    endTime: endCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã tạo buổi học mới thành công')),
              );
            },
            child: const Text('Tạo buổi'),
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
        content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản Giảng viên?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LecturerProvider>().stopQr();
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
// 1. TAB BUỔI HỌC (SESSIONS)
// ══════════════════════════════════════════════════════════════════

class LecturerSessionsTab extends StatelessWidget {
  const LecturerSessionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LecturerProvider>();
    final sessions = lp.filteredSessions;

    return Column(
      children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Tất cả'),
                selected: lp.sessionFilter == 'all',
                onSelected: (_) => lp.setSessionFilter('all'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Đang mở'),
                selected: lp.sessionFilter == 'open',
                onSelected: (_) => lp.setSessionFilter('open'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Sắp học'),
                selected: lp.sessionFilter == 'scheduled',
                onSelected: (_) => lp.setSessionFilter('scheduled'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Đã kết thúc'),
                selected: lp.sessionFilter == 'closed',
                onSelected: (_) => lp.setSessionFilter('closed'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Danh sách buổi học
        Expanded(
          child: sessions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Không có buổi học nào trong bộ lọc'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => lp.loadSessions('demo_lecturer'),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: sessions.length,
                    itemBuilder: (ctx, i) => _SessionCardItem(session: sessions[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SessionCardItem extends StatelessWidget {
  final SessionItem session;
  const _SessionCardItem({required this.session});

  @override
  Widget build(BuildContext context) {
    final lp = context.read<LecturerProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    Color statusColor;
    IconData statusIcon;
    switch (session.status) {
      case 'open':
        statusColor = Colors.green;
        statusIcon = Icons.lock_open_rounded;
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusIcon = Icons.lock_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
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
                      Text(
                        session.className,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${session.courseCode} • ${session.courseName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        session.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14),
                const SizedBox(width: 4),
                Text(session.date, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
                const Icon(Icons.access_time_outlined, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${session.startTime} – ${session.endTime}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            if (session.totalStudents > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: session.attendanceRate / 100,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    session.attendanceRate >= 80
                        ? Colors.green
                        : session.attendanceRate >= 50
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _statBadge('✅ ${session.presentCount}', Colors.green),
                  const SizedBox(width: 6),
                  _statBadge('⏰ ${session.lateCount}', Colors.orange),
                  const SizedBox(width: 6),
                  _statBadge('❌ ${session.absentCount}', Colors.red),
                  const Spacer(),
                  Text(
                    '${session.attendanceRate.toStringAsFixed(0)}% có mặt',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (session.status == 'open') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openQrModal(context, session),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                      label: const Text('Phát QR', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => lp.toggleSession(session.id, 'closed'),
                      icon: const Icon(Icons.lock_rounded, size: 16),
                      label: const Text('Đóng ca', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else if (session.status == 'scheduled') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => lp.toggleSession(session.id, 'open'),
                      icon: const Icon(Icons.lock_open_rounded, size: 16),
                      label: const Text('Mở ca', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openAttendanceModal(context, session),
                    icon: const Icon(Icons.how_to_reg_outlined, size: 16),
                    label: const Text('Sổ ĐD', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );

  void _openQrModal(BuildContext context, SessionItem session) {
    final lp = context.read<LecturerProvider>();
    lp.startQr(session.id, 'demo_lecturer');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: lp,
        child: _QrBottomSheetWidget(session: session),
      ),
    ).then((_) => lp.stopQr());
  }

  void _openAttendanceModal(BuildContext context, SessionItem session) {
    final lp = context.read<LecturerProvider>();
    lp.loadAttendance(session);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: lp,
        child: _AttendanceBottomSheetWidget(session: session),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 2. TAB PHÁT MÃ QR ĐỘNG (30s)
// ══════════════════════════════════════════════════════════════════

class LecturerQrTab extends StatelessWidget {
  const LecturerQrTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LecturerProvider>();
    final openSessions = lp.sessions.where((s) => s.status == 'open').toList();

    if (lp.currentQr == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn ca học đang mở để phát mã QR điểm danh:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (openSessions.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Chưa có buổi học nào đang mở điểm danh.\nHãy vào tab "Buổi học" và bấm "Mở ca học".',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: openSessions.length,
                  itemBuilder: (ctx, i) {
                    final s = openSessions[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.15),
                          child: const Icon(Icons.qr_code_2_rounded, color: Colors.green),
                        ),
                        title: Text(s.className, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${s.courseName} • ${s.startTime}–${s.endTime}'),
                        trailing: ElevatedButton.icon(
                          onPressed: () => lp.startQr(s.id, 'demo_lecturer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Bật QR'),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    }

    final qr = lp.currentQr!;
    final colorScheme = Theme.of(context).colorScheme;
    final double progress = lp.qrSecondsLeft / 30;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Mã QR Điểm Danh Động',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Sinh viên quét mã này để điểm danh tự động',
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: lp.currentQrString ?? qr.toQrString(),
              version: QrVersions.auto,
              size: 230,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6.5,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    progress > 0.35 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${lp.qrSecondsLeft}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'giây',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Mã QR tự động làm mới sau mỗi 30 giây bảo mật cao', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('Mã ca học (Session ID)'),
                  subtitle: Text(qr.sessionId),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded),
                  title: const Text('Chữ ký bảo mật (Signature)'),
                  subtitle: Text(qr.signature),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    tooltip: 'Sao chép chuỗi QR',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: qr.toQrString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép chuỗi QR điểm danh')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => lp.stopQr(),
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Dừng phát QR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 3. TAB SỔ ĐIỂM DANH (ATTENDANCE)
// ══════════════════════════════════════════════════════════════════

class LecturerAttendanceTab extends StatelessWidget {
  const LecturerAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LecturerProvider>();
    final sessions = lp.sessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            'Chọn ca học để xem và điều chỉnh điểm danh sinh viên:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sessions.length,
            itemBuilder: (ctx, i) {
              final s = sessions[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: s.status == 'open'
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    child: Icon(
                      s.status == 'open' ? Icons.lock_open_rounded : Icons.how_to_reg_rounded,
                      color: s.status == 'open' ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Text(s.className, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${s.date} • ${s.startTime}–${s.endTime}\nCó mặt: ${s.presentCount} | Muộn: ${s.lateCount} | Vắng: ${s.absentCount}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    lp.loadAttendance(s);
                    showModalBottomSheet(
                      context: ctx,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => ChangeNotifierProvider.value(
                        value: lp,
                        child: _AttendanceBottomSheetWidget(session: s),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 4. TAB HỒ SƠ GIẢNG VIÊN (PROFILE)
// ══════════════════════════════════════════════════════════════════

class LecturerProfileTab extends StatelessWidget {
  const LecturerProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lp = context.watch<LecturerProvider>();

    final total = lp.sessions.length;
    final open = lp.sessions.where((s) => s.status == 'open').length;
    final closed = lp.sessions.where((s) => s.status == 'closed').length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.teal.withValues(alpha: 0.15),
                child: Text(
                  (auth.currentUser?.fullName ?? 'GV').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                auth.currentUser?.fullName ?? 'ThS. Võ Anh Tuấn',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Giảng Viên • Khoa CNTT',
                  style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 13),
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
                title: const Text('Email'),
                subtitle: Text(auth.currentUser?.email ?? 'tuan.va@university.edu.vn'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Tên đăng nhập'),
                subtitle: Text(auth.currentUser?.username ?? 'gv_tuan'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.school_outlined),
                title: Text('Khoa / Bộ môn'),
                subtitle: Text('Công Nghệ Thông Tin'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.verified_outlined),
                title: Text('Đồ án'),
                subtitle: Text('MSSV: 238060244 - Võ Anh Tuấn'),
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
                const Text('Thống kê giảng dạy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statBox('$total', 'Tổng ca học', Icons.calendar_month_rounded, Colors.indigo),
                    const SizedBox(width: 8),
                    _statBox('$open', 'Đang mở', Icons.lock_open_rounded, Colors.green),
                    const SizedBox(width: 8),
                    _statBox('$closed', 'Đã kết thúc', Icons.lock_rounded, Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            context.read<LecturerProvider>().stopQr();
            context.read<AuthProvider>().logout();
          },
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

  Widget _statBox(String value, String label, IconData icon, Color color) {
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
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// BOTTOM SHEET WIDGETS
// ══════════════════════════════════════════════════════════════════

class _QrBottomSheetWidget extends StatelessWidget {
  final SessionItem session;
  const _QrBottomSheetWidget({required this.session});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LecturerProvider>();
    final qr = lp.currentQr;
    final progress = lp.qrSecondsLeft / 30;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'QR Điểm Danh – ${session.className}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text('${session.date}  •  ${session.startTime}–${session.endTime}'),
            const SizedBox(height: 20),
            if (qr == null)
              const CircularProgressIndicator()
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                  ],
                ),
                child: QrImageView(
                  data: lp.currentQrString ?? qr.toQrString(),
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation(progress > 0.35 ? Colors.green : Colors.orange),
                    ),
                  ),
                  Text('${lp.qrSecondsLeft}s', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Mã tự làm mới mỗi 30 giây'),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Đóng'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceBottomSheetWidget extends StatelessWidget {
  final SessionItem session;
  const _AttendanceBottomSheetWidget({required this.session});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LecturerProvider>();
    final records = lp.attendanceRecords;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sổ ĐD – ${session.className}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${session.date}  ${session.startTime}–${session.endTime}'),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: records.isEmpty
                ? const Center(child: Text('Chưa có dữ liệu điểm danh'))
                : ListView.builder(
                    controller: ctrl,
                    padding: const EdgeInsets.all(8),
                    itemCount: records.length,
                    itemBuilder: (_, i) {
                      final r = records[i];
                      Color statusColor;
                      IconData statusIcon;
                      switch (r.status) {
                        case 'present':
                          statusColor = Colors.green;
                          statusIcon = Icons.check_circle_rounded;
                          break;
                        case 'late':
                          statusColor = Colors.orange;
                          statusIcon = Icons.access_time_filled_rounded;
                          break;
                        default:
                          statusColor = Colors.red;
                          statusIcon = Icons.cancel_rounded;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.12),
                            child: Icon(statusIcon, color: statusColor),
                          ),
                          title: Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('MSSV: ${r.studentCode}${r.method != null ? " • ${r.method}" : ""}${r.timestamp != null ? " ${r.timestamp}" : ""}'),
                          trailing: PopupMenuButton<String>(
                            initialValue: r.status,
                            tooltip: 'Thay đổi trạng thái',
                            onSelected: (newStatus) => lp.updateRecord(r.studentId, newStatus, null),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'present',
                                child: Row(children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Có mặt'),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'late',
                                child: Row(children: [
                                  Icon(Icons.access_time_filled_rounded, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Đi muộn'),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'absent',
                                child: Row(children: [
                                  Icon(Icons.cancel_rounded, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Vắng mặt'),
                                ]),
                              ),
                            ],
                            child: Chip(
                              avatar: Icon(statusIcon, size: 16, color: statusColor),
                              label: Text(r.statusLabel, style: TextStyle(color: statusColor, fontSize: 12)),
                              backgroundColor: statusColor.withValues(alpha: 0.1),
                              side: BorderSide.none,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
