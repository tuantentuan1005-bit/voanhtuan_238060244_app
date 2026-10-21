import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/theme/app_theme.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lecturer_provider.dart';
import 'providers/student_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';

/// ỨNG DỤNG ĐIỂM DANH SINH VIÊN
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244
/// Lớp bài thi: Xây dựng ứng dụng di động

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khóa hướng màn hình dọc để trải nghiệm quét QR và điểm danh tối ưu nhất
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
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
}

class VoAnhTuanApp extends StatelessWidget {
  const VoAnhTuanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AppRoleGate(),
    );
  }
}
