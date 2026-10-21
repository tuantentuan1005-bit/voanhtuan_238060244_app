library;

import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_vault.dart';
import '../data/models/auth_models.dart';
import '../data/services/auth_service.dart';

enum AuthStatus {
  uninitialized,
  authenticating,
  authenticated,
  unauthenticated,
}

/// Provider quản lý trạng thái xác thực và phân quyền (Role Router)
/// Hỗ trợ luồng Đăng ký -> Đăng nhập -> Xác thực OTP
/// Tác giả: Võ Anh Tuấn - 238060244

class AuthProvider extends ChangeNotifier {
  final SecureVault _vault = SecureVault();
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.uninitialized;
  String? _token;
  UserModel? _currentUser;
  UserRole _currentRole = UserRole.unknown;
  String? _errorMessage;
  bool _isSubmitting = false;

  // Dữ liệu tạm thời trong bước chờ nhập OTP
  String? _pendingUsername;
  String? _pendingEmail;
  String? _pendingTempToken;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.authenticating || _status == AuthStatus.uninitialized;
  bool get isSubmitting => _isSubmitting;
  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  UserRole get currentRole => _currentRole;
  String? get errorMessage => _errorMessage;

  String? get pendingUsername => _pendingUsername;
  String? get pendingEmail => _pendingEmail;

  AuthProvider() {
    _apiClient.onSessionExpired = () {
      logout(reason: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    };
    initializeAuth();
  }

  /// Khởi tạo và khôi phục trạng thái từ bộ nhớ bảo mật khi mở ứng dụng
  Future<void> initializeAuth() async {
    _status = AuthStatus.uninitialized;
    notifyListeners();

    try {
      final token = await _vault.getAccessToken();
      if (token != null && token.isNotEmpty) {
        _token = token;
        _currentRole = await _vault.getUserRole();
        _currentUser = await _vault.getUserProfile();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// 1. Đăng ký tài khoản: Gọi API POST /api/auth/register
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? studentCode,
    String? phoneNumber,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.register(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      studentCode: studentCode,
      phoneNumber: phoneNumber,
    );

    _isSubmitting = false;

    if (response.success) {
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  /// 2. Đăng nhập bước 1: Gọi API POST /api/auth/login -> Chuẩn bị nhận OTP
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.login(
      username: username,
      password: password,
    );

    _isSubmitting = false;

    if (response.success) {
      final data = response.data;
      _pendingUsername = username;
      _pendingEmail = data?['email']?.toString() ?? username;
      _pendingTempToken = data?['tempToken']?.toString() ?? data?['token']?.toString();
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  /// 3. Xác thực OTP: Gọi API POST /api/auth/verify-otp -> Nhận JWT + Role
  Future<bool> verifyOtp({
    required String otp,
  }) async {
    if (_pendingUsername == null) {
      _errorMessage = 'Không tìm thấy thông tin phiên đăng nhập. Vui lòng đăng nhập lại.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.verifyOtp(
      username: _pendingUsername!,
      otp: otp,
      email: _pendingEmail,
      tempToken: _pendingTempToken,
    );

    _isSubmitting = false;

    if (response.success && response.data != null) {
      final tokenData = response.data!;
      final userRole = UserRole.fromString(tokenData.role);

      await loginSuccess(
        token: tokenData.token,
        role: userRole,
        user: tokenData.user,
        refreshToken: tokenData.refreshToken,
      );

      _pendingUsername = null;
      _pendingEmail = null;
      _pendingTempToken = null;
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  /// Đánh dấu đăng nhập thành công sau khi xác thực OTP thành công
  Future<void> loginSuccess({
    required String token,
    required UserRole role,
    UserModel? user,
    String? refreshToken,
  }) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    _token = token;
    _currentRole = role;
    _currentUser = user;

    await _vault.saveSession(
      token: token,
      role: role,
      user: user,
      refreshToken: refreshToken,
    );

    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Hỗ trợ chuyển đổi nhanh Role để kiểm thử giao diện trong quá trình dev
  Future<void> switchRoleForTesting(UserRole newRole) async {
    _currentRole = newRole;
    await _vault.saveUserRole(newRole);
    notifyListeners();
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> logout({String? reason}) async {
    await _vault.clearSession();
    _token = null;
    _currentUser = null;
    _currentRole = UserRole.unknown;
    _errorMessage = reason;
    _pendingUsername = null;
    _pendingEmail = null;
    _pendingTempToken = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setPendingUser(String username, String email) {
    _pendingUsername = username;
    _pendingEmail = email;
    notifyListeners();
  }
}
