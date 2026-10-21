library;

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/admin_models.dart';

/// Dịch vụ kết nối API cho chức năng Quản trị viên (CRUD Users, Courses, Classes)
/// 100% gọi API thật theo chuẩn Swagger backend ASP.NET Core
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244

class AdminService {
  final ApiClient _client = ApiClient();

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['duLieu'] is List) return data['duLieu'] as List;
      if (data['items'] is List) return data['items'] as List;
      if (data['data'] is List) return data['data'] as List;
    }
    return [];
  }

  int _getRoleId(dynamic role) {
    if (role is int) return role;
    final rStr = role?.toString().toLowerCase() ?? '';
    if (rStr.contains('admin')) return 1;
    if (rStr.contains('giangvien') || rStr.contains('lecturer') || rStr.contains('gv')) return 2;
    return 3; // Sinh viên mặc định
  }

  // ================= USERS CRUD =================
  Future<ApiResponse<List<UserItem>>> getUsers({String? search, String? role}) async {
    final query = <String, dynamic>{
      'Trang': 1,
      'SoLuong': 100,
    };
    if (search != null && search.isNotEmpty) query['TuKhoa'] = search;

    final response = await _client.get<List<UserItem>>(
      AppConfig.endpointUsers,
      queryParameters: query,
      fromData: (data) {
        final list = _extractList(data);
        return list.map((e) => UserItem.fromJson(e as Map<String, dynamic>)).toList();
      },
    );

    return response;
  }

  Future<ApiResponse<UserItem>> createUser(Map<String, dynamic> data) async {
    final payload = {
      'hoTen': (data['fullName'] ?? data['hoTen'] ?? 'Người dùng mới').toString(),
      'email': (data['email'] ?? '').toString().trim().toLowerCase(),
      'tenDangNhap': (data['username'] ?? data['tenDangNhap'] ?? 'user_new').toString().trim(),
      'matKhau': (data['password'] ?? data['matKhau'] ?? '123456').toString(),
      'soDienThoai': data['phoneNumber']?.toString() ?? data['soDienThoai']?.toString(),
      'maSoSinhVien': data['studentCode']?.toString() ?? data['maSoSinhVien']?.toString(),
      'roleId': _getRoleId(data['role']),
    };

    final response = await _client.post<UserItem>(
      AppConfig.endpointUsers,
      data: payload,
      fromData: (res) {
        if (res is Map<String, dynamic>) {
          return UserItem.fromJson(res);
        }
        return UserItem.fromJson(payload);
      },
    );

    return response;
  }

  Future<ApiResponse<UserItem>> updateUser(String id, Map<String, dynamic> data) async {
    final payload = {
      'hoTen': (data['fullName'] ?? data['hoTen'] ?? '').toString(),
      'email': (data['email'] ?? '').toString().trim().toLowerCase(),
      'soDienThoai': data['phoneNumber']?.toString() ?? data['soDienThoai']?.toString(),
      'maSoSinhVien': data['studentCode']?.toString() ?? data['maSoSinhVien']?.toString(),
      'roleId': _getRoleId(data['role']),
      'kichHoat': data['isActive'] == null ? true : data['isActive'] == true,
    };

    final response = await _client.put<UserItem>(
      '${AppConfig.endpointUsers}/$id',
      data: payload,
      fromData: (res) {
        if (res is Map<String, dynamic>) {
          return UserItem.fromJson(res);
        }
        return UserItem.fromJson(payload);
      },
    );

    return response;
  }

  Future<ApiResponse<bool>> deleteUser(String id) async {
    final response = await _client.delete<bool>(
      '${AppConfig.endpointUsers}/$id',
      fromData: (_) => true,
    );
    return response;
  }

  // ================= COURSES CRUD =================
  Future<ApiResponse<List<CourseItem>>> getCourses({String? search}) async {
    final query = <String, dynamic>{
      'Trang': 1,
      'SoLuong': 100,
    };
    if (search != null && search.isNotEmpty) query['TuKhoa'] = search;

    final response = await _client.get<List<CourseItem>>(
      AppConfig.endpointCourses,
      queryParameters: query,
      fromData: (data) {
        final list = _extractList(data);
        return list.map((e) => CourseItem.fromJson(e as Map<String, dynamic>)).toList();
      },
    );

    return response;
  }

  Future<ApiResponse<CourseItem>> createCourse(Map<String, dynamic> data) async {
    final payload = {
      'maMonHoc': (data['courseCode'] ?? data['maMonHoc'] ?? 'IT001').toString(),
      'tenMonHoc': (data['courseName'] ?? data['tenMonHoc'] ?? 'Môn học mới').toString(),
      'soTinChi': int.tryParse(data['credits']?.toString() ?? data['soTinChi']?.toString() ?? '3') ?? 3,
      'moTa': (data['description'] ?? data['moTa'] ?? '').toString(),
      'congKhai': true,
    };

    final response = await _client.post<CourseItem>(
      AppConfig.endpointCourses,
      data: payload,
      fromData: (res) {
        if (res is Map<String, dynamic>) {
          return CourseItem.fromJson(res);
        }
        return CourseItem.fromJson(payload);
      },
    );

    return response;
  }

  Future<ApiResponse<CourseItem>> updateCourse(String id, Map<String, dynamic> data) async {
    final payload = {
      'tenMonHoc': (data['courseName'] ?? data['tenMonHoc'] ?? '').toString(),
      'soTinChi': int.tryParse(data['credits']?.toString() ?? data['soTinChi']?.toString() ?? '3') ?? 3,
      'moTa': (data['description'] ?? data['moTa'] ?? '').toString(),
      'congKhai': true,
    };

    final response = await _client.put<CourseItem>(
      '${AppConfig.endpointCourses}/$id',
      data: payload,
      fromData: (res) {
        if (res is Map<String, dynamic>) {
          return CourseItem.fromJson(res);
        }
        return CourseItem.fromJson(payload);
      },
    );

    return response;
  }

  Future<ApiResponse<bool>> deleteCourse(String id) async {
    final response = await _client.delete<bool>(
      '${AppConfig.endpointCourses}/$id',
      fromData: (_) => true,
    );
    return response;
  }

  // ================= CLASSES CRUD =================
  Future<ApiResponse<List<ClassItem>>> getClasses({String? search}) async {
    final query = <String, dynamic>{
      'Trang': 1,
      'SoLuong': 100,
    };
    if (search != null && search.isNotEmpty) query['TuKhoa'] = search;

    final response = await _client.get<List<ClassItem>>(
      AppConfig.endpointClasses,
      queryParameters: query,
      fromData: (data) {
        final list = _extractList(data);
        return list.map((e) => ClassItem.fromJson(e as Map<String, dynamic>)).toList();
      },
    );

    return response;
  }

  Future<ApiResponse<ClassItem>> createClass(Map<String, dynamic> data) async {
    final payload = {
      'maLopHoc': (data['classCode'] ?? data['maLopHoc'] ?? 'CLASS_01').toString(),
      'tenLopHoc': (data['className'] ?? data['tenLopHoc'] ?? 'Lớp mới').toString(),
      'courseId': int.tryParse(data['courseId']?.toString() ?? '1') ?? 1,
      'giangVienId': int.tryParse(data['lecturerId']?.toString() ?? data['giangVienId']?.toString() ?? '2') ?? 2,
      'namHoc': DateTime.now().year,
      'hocKy': '1',
      'viDo': 10.8505,
      'kinhDo': 106.7718,
      'banKinhChoPhep': 100.0,
    };

    final response = await _client.post<ClassItem>(
      AppConfig.endpointClasses,
      data: payload,
      fromData: (res) {
        if (res is Map<String, dynamic>) {
          return ClassItem.fromJson(res);
        }
        return ClassItem.fromJson(payload);
      },
    );

    return response;
  }

  Future<ApiResponse<ClassItem>> updateClass(String id, Map<String, dynamic> data) async {
    final payload = {
      'tenLopHoc': (data['className'] ?? data['tenLopHoc'] ?? '').toString(),
      'giangVienId': int.tryParse(data['lecturerId']?.toString() ?? data['giangVienId']?.toString() ?? '2') ?? 2,
      'namHoc': DateTime.now().year,
      'hocKy': '1',
      'viDo': 10.8505,
      'kinhDo': 106.7718,
      'banKinhChoPhep': 100.0,
      'dangHoatDong': true,
    };

    final response = await _client.put<ClassItem>(
      '${AppConfig.endpointClasses}/$id',
      data: payload,
      fromData: (res) {
        if (res is Map<String, dynamic>) {
          return ClassItem.fromJson(res);
        }
        return ClassItem.fromJson(payload);
      },
    );

    return response;
  }

  Future<ApiResponse<bool>> deleteClass(String id) async {
    final response = await _client.delete<bool>(
      '${AppConfig.endpointClasses}/$id',
      fromData: (_) => true,
    );
    return response;
  }
}
