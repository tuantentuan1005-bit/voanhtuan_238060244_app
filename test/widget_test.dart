import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voanhtuan_238060244_app/core/config.dart';
import 'package:voanhtuan_238060244_app/main.dart';
import 'package:voanhtuan_238060244_app/providers/admin_provider.dart';
import 'package:voanhtuan_238060244_app/providers/auth_provider.dart';
import 'package:voanhtuan_238060244_app/providers/lecturer_provider.dart';
import 'package:voanhtuan_238060244_app/providers/student_provider.dart';
import 'package:voanhtuan_238060244_app/providers/theme_provider.dart';
import 'package:voanhtuan_238060244_app/screens/lecturer/lecturer_shell_screen.dart';
import 'package:voanhtuan_238060244_app/screens/student/student_shell_screen.dart';

void main() {
  testWidgets('Kiểm tra khởi động ứng dụng VoAnhTuanApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
          ChangeNotifierProvider(create: (_) => LecturerProvider()),
          ChangeNotifierProvider(create: (_) => StudentProvider()),
        ],
        child: const VoAnhTuanApp(),
      ),
    );

    // Kiểm tra tên ứng dụng hiển thị
    expect(find.text(AppConfig.appName), findsWidgets);
  });

  testWidgets('Kiểm tra giao diện LecturerShellScreen và danh sách buổi học', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
          ChangeNotifierProvider(create: (_) => LecturerProvider()),
          ChangeNotifierProvider(create: (_) => StudentProvider()),
        ],
        child: const MaterialApp(
          home: LecturerShellScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Kiểm tra tiêu đề và các tab
    expect(find.text('Lịch Buổi Học'), findsWidgets);
    expect(find.byType(LecturerShellScreen), findsOneWidget);
  });

  testWidgets('Kiểm tra giao diện StudentShellScreen và xác thực đa yếu tố', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
          ChangeNotifierProvider(create: (_) => LecturerProvider()),
          ChangeNotifierProvider(create: (_) => StudentProvider()),
        ],
        child: const MaterialApp(
          home: StudentShellScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Kiểm tra tiêu đề sinh viên và các thành phần MFA
    expect(find.text('Điểm Danh Nhanh'), findsWidgets);
    expect(find.text('Xác Thực Đa Yếu Tố (MFA)'), findsWidgets);
    expect(find.text('Định vị GPS tại phòng học'), findsWidgets);
    expect(find.text('Nhận diện khuôn mặt sinh viên'), findsWidgets);
  });
}
