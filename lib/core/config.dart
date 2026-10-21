library;

/// Cấu hình toàn bộ ứng dụng Điểm danh Sinh viên
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244
/// LƯU Ý: Mọi cấu hình Web API (ASP.NET Core) tập trung tại file duy nhất này.

class AppConfig {
  AppConfig._();

  // Thông tin ứng dụng và tác giả
  static const String appName = 'Diem Danh - Vo Anh Tuan';
  static const String appVersion = '1.0.0';
  static const String studentName = 'Võ Anh Tuấn';
  static const String studentId = '238060244';

  // Cấu hình Web API ASP.NET Core
  // Backend đang chạy tại http://localhost:5226 (Swagger: http://localhost:5226/swagger)
  // Dùng adb reverse tcp:5226 tcp:5226 để emulator truy cập backend qua 127.0.0.1
  // (Backend chỉ lắng nghe trên loopback, 10.0.2.2 đi qua mạng ảo nên bị từ chối)
  static const String apiBaseUrl = 'http://127.0.0.1:5226';

  // Thời gian chờ mạng
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Endpoint API theo chuẩn Swagger của backend
  static const String endpointRegister = '/api/auth/register';
  static const String endpointLogin = '/api/auth/login';
  static const String endpointVerifyOtp = '/api/auth/verify-otp';
  static const String endpointVerifyEmail = '/api/auth/verify-email';

  static const String endpointUsers = '/api/users';
  static const String endpointUserRoles = '/api/users/roles';
  static const String endpointCourses = '/api/courses';
  static const String endpointClasses = '/api/classes';
  static const String endpointSessions = '/api/sessions';
  static const String endpointAttendances = '/api/attendances';
  static const String endpointMyAttendance = '/api/attendances/my';
  static const String endpointRegisterDevice = '/api/attendances/register-device';

  static String endpointOpenAttendance(dynamic sessionId) =>
      '/api/sessions/$sessionId/open-attendance';
  static String endpointCloseAttendance(dynamic sessionId) =>
      '/api/sessions/$sessionId/close-attendance';
  static String endpointCurrentQr(dynamic sessionId) =>
      '/api/sessions/$sessionId/current-qr';
  static const String endpointCheckIn = '/api/attendances/check-in';
  static const String endpointAbsenceWarning = '/api/reports/absence-warning';
}
