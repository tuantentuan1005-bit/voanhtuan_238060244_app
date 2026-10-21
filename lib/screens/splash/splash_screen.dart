import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_shell_screen.dart';
import '../auth/login_screen.dart';
import '../lecturer/lecturer_shell_screen.dart';
import '../student/student_shell_screen.dart';

/// Màn hình Khởi động và Bộ định tuyến vai trò (Role-based App Gate)
/// Tác giả: Võ Anh Tuấn - 238060244

class AppRoleGate extends StatelessWidget {
  const AppRoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Nếu đang đọc dữ liệu phiên từ Secure Storage
    if (auth.status == AuthStatus.uninitialized) {
      return const SplashScreen();
    }

    // Nếu đã đăng nhập thành công có token -> Chuyển vào đúng Dashboard
    if (auth.isAuthenticated) {
      switch (auth.currentRole) {
        case UserRole.admin:
          return const AdminShellScreen();
        case UserRole.lecturer:
          return const LecturerShellScreen();
        case UserRole.student:
        default:
          return const StudentShellScreen();
      }
    }

    // Chưa đăng nhập: Màn hình Đăng nhập (Username + Password -> OTP)
    return const LoginScreen();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.how_to_reg_rounded,
                size: 64,
                color: Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hệ Thống Điểm Danh Thông Minh',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const Spacer(),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SV: ${AppConfig.studentName} • MSSV: ${AppConfig.studentId}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
