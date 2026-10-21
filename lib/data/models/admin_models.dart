library;

import '../../core/constants/app_constants.dart';

/// Các mô hình dữ liệu cho chức năng Quản trị (Admin CRUD)
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244

class UserItem {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final UserRole role;
  final String? studentCode;
  final String? phoneNumber;
  final bool isActive;
  final DateTime? createdAt;

  UserItem({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.studentCode,
    this.phoneNumber,
    this.isActive = true,
    this.createdAt,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
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
      isActive: json['isActive'] != null
          ? json['isActive'] == true
          : (json['kichHoat'] == null ? true : json['kichHoat'] == true),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['ngayTao'] != null ? DateTime.tryParse(json['ngayTao'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role.rawValue,
      if (studentCode != null) 'studentCode': studentCode,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'isActive': isActive,
    };
  }

  UserItem copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    UserRole? role,
    String? studentCode,
    String? phoneNumber,
    bool? isActive,
  }) {
    return UserItem(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      studentCode: studentCode ?? this.studentCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

class CourseItem {
  final String id;
  final String courseCode;
  final String courseName;
  final int credits;
  final String? description;

  CourseItem({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.credits,
    this.description,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      id: (json['id'] ?? json['courseId'] ?? '').toString(),
      courseCode: (json['courseCode'] ?? json['maMonHoc'] ?? json['code'] ?? '').toString(),
      courseName: (json['courseName'] ?? json['tenMonHoc'] ?? json['name'] ?? '').toString(),
      credits: int.tryParse((json['credits'] ?? json['soTinChi'] ?? '3').toString()) ?? 3,
      description: (json['description'] ?? json['moTa'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseCode': courseCode,
      'courseName': courseName,
      'credits': credits,
      if (description != null) 'description': description,
    };
  }

  CourseItem copyWith({
    String? id,
    String? courseCode,
    String? courseName,
    int? credits,
    String? description,
  }) {
    return CourseItem(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      credits: credits ?? this.credits,
      description: description ?? this.description,
    );
  }
}

class ClassItem {
  final String id;
  final String classCode;
  final String className;
  final String? courseId;
  final String courseName;
  final String? lecturerId;
  final String lecturerName;
  final String room;
  final String schedule;
  final int totalStudents;

  ClassItem({
    required this.id,
    required this.classCode,
    required this.className,
    this.courseId,
    required this.courseName,
    this.lecturerId,
    required this.lecturerName,
    required this.room,
    required this.schedule,
    this.totalStudents = 45,
  });

  factory ClassItem.fromJson(Map<String, dynamic> json) {
    // Xử lý nested object monHoc và giangVien từ backend ASP.NET Core
    String resolvedCourseName = 'Môn học chuyên ngành';
    String? resolvedCourseId = json['courseId']?.toString();
    if (json['monHoc'] is Map<String, dynamic>) {
      resolvedCourseName = (json['monHoc']['tenMonHoc'] ?? json['monHoc']['courseName'] ?? resolvedCourseName).toString();
      resolvedCourseId ??= json['monHoc']['courseId']?.toString();
    } else if (json['courseName'] != null) {
      resolvedCourseName = json['courseName'].toString();
    }

    String resolvedLecturerName = 'ThS. Nguyễn Văn Hùng';
    String? resolvedLecturerId = json['lecturerId']?.toString() ?? json['giangVienId']?.toString();
    if (json['giangVien'] is Map<String, dynamic>) {
      resolvedLecturerName = (json['giangVien']['hoTen'] ?? json['giangVien']['fullName'] ?? resolvedLecturerName).toString();
      resolvedLecturerId ??= json['giangVien']['userId']?.toString();
    } else if (json['lecturerName'] != null) {
      resolvedLecturerName = json['lecturerName'].toString();
    }

    return ClassItem(
      id: (json['id'] ?? json['classId'] ?? '').toString(),
      classCode: (json['classCode'] ?? json['maLopHoc'] ?? json['code'] ?? '').toString(),
      className: (json['className'] ?? json['tenLopHoc'] ?? json['name'] ?? '').toString(),
      courseId: resolvedCourseId,
      courseName: resolvedCourseName,
      lecturerId: resolvedLecturerId,
      lecturerName: resolvedLecturerName,
      room: (json['room'] ?? json['phongHoc'] ?? 'Phòng A1-201').toString(),
      schedule: (json['schedule'] ?? 'Học kỳ ${json['hocKy'] ?? 1} (${json['namHoc'] ?? 2026})').toString(),
      totalStudents: int.tryParse((json['totalStudents'] ?? '45').toString()) ?? 45,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classCode': classCode,
      'className': className,
      if (courseId != null) 'courseId': courseId,
      'courseName': courseName,
      if (lecturerId != null) 'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'room': room,
      'schedule': schedule,
      'totalStudents': totalStudents,
    };
  }

  ClassItem copyWith({
    String? id,
    String? classCode,
    String? className,
    String? courseId,
    String? courseName,
    String? lecturerId,
    String? lecturerName,
    String? room,
    String? schedule,
    int? totalStudents,
  }) {
    return ClassItem(
      id: id ?? this.id,
      classCode: classCode ?? this.classCode,
      className: className ?? this.className,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      lecturerId: lecturerId ?? this.lecturerId,
      lecturerName: lecturerName ?? this.lecturerName,
      room: room ?? this.room,
      schedule: schedule ?? this.schedule,
      totalStudents: totalStudents ?? this.totalStudents,
    );
  }
}
