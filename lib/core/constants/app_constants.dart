library;

/// Các hằng số phân quyền và khóa lưu trữ bảo mật
/// Tác giả: Võ Anh Tuấn - 238060244

enum UserRole {
  admin,
  lecturer,
  student,
  unknown;

  static UserRole fromString(String? roleStr) {
    if (roleStr == null) return UserRole.unknown;
    final normalized = roleStr.trim().toLowerCase();
    if (normalized == 'admin' || normalized == 'quantri') {
      return UserRole.admin;
    }
    if (normalized == 'lecturer' ||
        normalized == 'giangvien' ||
        normalized == 'teacher') {
      return UserRole.lecturer;
    }
    if (normalized == 'student' ||
        normalized == 'sinhvien') {
      return UserRole.student;
    }
    return UserRole.unknown;
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.lecturer:
        return 'Giảng viên';
      case UserRole.student:
        return 'Sinh viên';
      case UserRole.unknown:
        return 'Người dùng';
    }
  }

  String get rawValue {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.lecturer:
        return 'Lecturer';
      case UserRole.student:
        return 'Student';
      case UserRole.unknown:
        return '';
    }
  }
}

class StorageKeys {
  StorageKeys._();
  static const String accessToken = 'vat_auth_token_key';
  static const String refreshToken = 'vat_refresh_token_key';
  static const String userProfile = 'vat_user_profile_key';
  static const String userRole = 'vat_user_role_key';
  static const String appThemeMode = 'vat_theme_mode_key';
}
