import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../../data/models/auth_models.dart';

/// Lớp quản lý lưu trữ an toàn JWT Token và thông tin xác thực
/// Sử dụng FlutterSecureStorage (Keystore trên Android / Keychain trên iOS)
/// Tác giả: Võ Anh Tuấn - 238060244

class SecureVault {
  static final SecureVault _instance = SecureVault._internal();
  factory SecureVault() => _instance;
  SecureVault._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Lưu Access Token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: StorageKeys.accessToken, value: token);
  }

  /// Lấy Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: StorageKeys.accessToken);
  }

  /// Lưu Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: StorageKeys.refreshToken, value: token);
  }

  /// Lấy Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: StorageKeys.refreshToken);
  }

  /// Lưu vai trò người dùng (Admin, Lecturer, Student)
  Future<void> saveUserRole(UserRole role) async {
    await _storage.write(key: StorageKeys.userRole, value: role.rawValue);
  }

  /// Lấy vai trò người dùng đã lưu
  Future<UserRole> getUserRole() async {
    final raw = await _storage.read(key: StorageKeys.userRole);
    return UserRole.fromString(raw);
  }

  /// Lưu thông tin người dùng
  Future<void> saveUserProfile(UserModel user) async {
    final rawJson = jsonEncode(user.toJson());
    await _storage.write(key: StorageKeys.userProfile, value: rawJson);
  }

  /// Đọc thông tin người dùng
  Future<UserModel?> getUserProfile() async {
    final rawJson = await _storage.read(key: StorageKeys.userProfile);
    if (rawJson == null || rawJson.isEmpty) return null;
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Lưu toàn bộ phiên đăng nhập
  Future<void> saveSession({
    required String token,
    required UserRole role,
    UserModel? user,
    String? refreshToken,
  }) async {
    await saveAccessToken(token);
    await saveUserRole(role);
    if (user != null) {
      await saveUserProfile(user);
    }
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
  }

  /// Xóa toàn bộ dữ liệu phiên khi đăng xuất
  Future<void> clearSession() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.userProfile);
    await _storage.delete(key: StorageKeys.userRole);
  }

  /// Kiểm tra xem có token hợp lệ lưu trên máy hay không
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
