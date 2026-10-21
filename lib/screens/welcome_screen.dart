import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

/// Màn hình Chào mừng & Chuyển vai trò thử nghiệm cho Bước 1
/// Giúp người chấm bài hoặc tester chạy thử Router, Theme và Secure Storage ngay lập tức
/// Tác giả: Võ Anh Tuấn - 238060244

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hệ Thống Điểm Danh'),
        actions: [
          IconButton(
            tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => themeProvider.toggleTheme(!isDark),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                        : [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.verified_user_rounded,
                        size: 44,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppConfig.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tác giả: ${AppConfig.studentName} - MSSV: ${AppConfig.studentId}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'API: ${AppConfig.apiBaseUrl}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Thông báo trạng thái Bước 1
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bước 1 hoàn tất: Cấu trúc thư mục, Theme Material 3, Config, Dio + Bearer Token, Role Router.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Kiểm thử Điều hướng Phân quyền (Role Router):',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn một vai trò bên dưới để trải nghiệm ngay Shell Dashboard tương ứng (hoặc đăng nhập với tài khoản thực ở Bước 2):',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 16),

              // Nút demo Admin
              _buildRoleTile(
                context,
                title: 'Vào giao diện Quản Trị Viên (Admin)',
                subtitle: 'CRUD Người dùng, Môn học, Lớp học',
                icon: Icons.admin_panel_settings_rounded,
                color: Colors.indigo,
                onTap: () {
                  auth.loginSuccess(
                    token: 'vat_jwt_admin_token_demo',
                    role: UserRole.admin,
                    user: const UserModel(
                      id: 'admin-001',
                      username: 'admin',
                      email: 'admin@university.edu.vn',
                      fullName: 'Võ Anh Tuấn (Admin)',
                      role: UserRole.admin,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Nút demo Giảng viên
              _buildRoleTile(
                context,
                title: 'Vào giao diện Giảng Viên (Lecturer)',
                subtitle: 'Buổi học, QR động 30s, Sổ điểm danh',
                icon: Icons.school_rounded,
                color: Colors.teal,
                onTap: () {
                  auth.loginSuccess(
                    token: 'vat_jwt_lecturer_token_demo',
                    role: UserRole.lecturer,
                    user: const UserModel(
                      id: 'gv-001',
                      username: 'giangvien_tuan',
                      email: 'tuan.va@university.edu.vn',
                      fullName: 'ThS. Võ Anh Tuấn',
                      role: UserRole.lecturer,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Nút demo Sinh viên
              _buildRoleTile(
                context,
                title: 'Vào giao diện Sinh Viên (Student)',
                subtitle: 'Quét QR + GPS + Khuôn mặt, Cảnh báo vắng',
                icon: Icons.person_pin_rounded,
                color: Colors.blue.shade700,
                onTap: () {
                  auth.loginSuccess(
                    token: 'vat_jwt_student_token_demo',
                    role: UserRole.student,
                    user: const UserModel(
                      id: 'sv-238060244',
                      username: '238060244',
                      email: '238060244@student.university.edu.vn',
                      fullName: 'Võ Anh Tuấn',
                      studentCode: '238060244',
                      role: UserRole.student,
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Thông tin cấu hình kỹ thuật
              Center(
                child: Text(
                  'Package: com.voanhtuan.voanhtuan_238060244_app\nFlutter 3.x • Material 3 • Provider • Dio',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
