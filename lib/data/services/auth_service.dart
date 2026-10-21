library;

import '../../core/config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/auth_models.dart';

/// Dịch vụ gọi API xác thực (Đăng ký, Đăng nhập, Xác thực OTP)
/// Kết nối trực tiếp Web API ASP.NET Core
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244

class AuthService {
  final ApiClient _client = ApiClient();

  /// Đăng ký tài khoản mới: POST /api/auth/register
  Future<ApiResponse<dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? studentCode,
    String? phoneNumber,
  }) async {
    final payload = {
      // Backend ASP.NET Core YeuCauDangKy
      'hoTen': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'tenDangNhap': username.trim(),
      'matKhau': password,
      if (studentCode != null && studentCode.isNotEmpty) 'maSoSinhVien': studentCode.trim(),
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'soDienThoai': phoneNumber.trim(),

      // Aliases
      'username': username.trim(),
      'fullName': fullName.trim(),
      'password': password,
      'role': role.rawValue,
      if (studentCode != null && studentCode.isNotEmpty) 'studentCode': studentCode.trim(),
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber.trim(),
    };

    return await _client.post(
      AppConfig.endpointRegister,
      data: payload,
    );
  }

  /// Xác thực email sau khi đăng ký: POST /api/auth/verify-email
  Future<ApiResponse<dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final payload = {
      'email': email.trim().toLowerCase(),
      'maOtp': otp.trim(),
    };

    return await _client.post(
      AppConfig.endpointVerifyEmail,
      data: payload,
    );
  }

  /// Đăng nhập tài khoản: POST /api/auth/login
  /// Trả về thông tin yêu cầu OTP hoặc token tạm thời
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String username,
    required String password,
  }) async {
    final payload = {
      // Backend ASP.NET Core YeuCauDangNhap
      'tenDangNhap': username.trim(),
      'matKhau': password,

      // Aliases
      'username': username.trim(),
      'password': password,
    };

    return await _client.post<Map<String, dynamic>>(
      AppConfig.endpointLogin,
      data: payload,
      fromData: (data) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        return {'raw': data};
      },
    );
  }

  /// Xác thực mã OTP: POST /api/auth/verify-otp
  /// Trả về JWT Access Token + vai trò (Admin, GiangVien, SinhVien) + User Profile
  Future<ApiResponse<AuthTokenData>> verifyOtp({
    required String username,
    required String otp,
    String? email,
    String? tempToken,
  }) async {
    final payload = {
      // Backend ASP.NET Core YeuCauXacThucOtp
      'email': (email != null && email.isNotEmpty ? email : username).trim().toLowerCase(),
      'maOtp': otp.trim(),

      // Aliases
      'username': username.trim(),
      'otp': otp.trim(),
      if (tempToken != null && tempToken.isNotEmpty) 'tempToken': tempToken,
    };

    return await _client.post<AuthTokenData>(
      AppConfig.endpointVerifyOtp,
      data: payload,
      fromData: (data) {
        if (data is Map<String, dynamic>) {
          return AuthTokenData.fromJson(data);
        }
        throw Exception('Dữ liệu xác thực không hợp lệ');
      },
    );
  }
}
