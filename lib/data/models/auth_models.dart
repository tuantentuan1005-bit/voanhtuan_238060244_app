import '../../core/constants/app_constants.dart';

/// Mô hình dữ liệu người dùng và phiên đăng nhập
/// Tác giả: Võ Anh Tuấn - 238060244

class UserModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final UserRole role;
  final String? studentCode;
  final String? phoneNumber;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.studentCode,
    this.phoneNumber,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      username: (json['username'] ?? json['tenDangNhap'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ??
          json['hoTen'] ??
          json['name'] ??
          json['username'] ??
          json['tenDangNhap'] ??
          'Người dùng').toString(),
      role: UserRole.fromString((json['role'] ?? json['vaiTro'])?.toString()),
      studentCode: (json['studentCode'] ?? json['maSoSinhVien'])?.toString(),
      phoneNumber: (json['phoneNumber'] ?? json['soDienThoai'])?.toString(),
      avatarUrl: (json['avatarUrl'] ?? json['duongDanAnh'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role.rawValue,
      'studentCode': studentCode,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
    };
  }
}

class AuthTokenData {
  final String token;
  final String? refreshToken;
  final String role;
  final UserModel? user;

  const AuthTokenData({
    required this.token,
    this.refreshToken,
    required this.role,
    this.user,
  });

  factory AuthTokenData.fromJson(Map<String, dynamic> json) {
    // Backend trả về 'token', 'accessToken', hoặc 'jwt'
    final token = (json['token'] ?? json['accessToken'] ?? json['jwt'] ?? '').toString();
    final refreshToken = json['refreshToken']?.toString();
    final role = (json['role'] ?? json['vaiTro'] ?? json['userRole'] ?? '').toString();

    UserModel? user;
    final userMap = json['user'] ?? json['nguoiDung'] ?? json['userInfo'];
    if (userMap != null && userMap is Map<String, dynamic>) {
      user = UserModel.fromJson(userMap);
    } else {
      user = UserModel(
        id: (json['userId'] ?? json['id'] ?? '').toString(),
        username: (json['username'] ?? json['tenDangNhap'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        fullName: (json['fullName'] ?? json['hoTen'] ?? '').toString(),
        role: UserRole.fromString(role),
      );
    }

    return AuthTokenData(
      token: token,
      refreshToken: refreshToken,
      role: role,
      user: user,
    );
  }
}
