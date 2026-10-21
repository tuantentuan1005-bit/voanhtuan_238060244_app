library;

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/lecturer_models.dart';

/// Dịch vụ gọi API cho Giảng viên (Lecturer)
/// 100% kết nối API thật ASP.NET Core theo chuẩn Swagger
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244

class LecturerService {
  final ApiClient _api;
  LecturerService(this._api);

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['duLieu'] is List) return data['duLieu'] as List;
      if (data['items'] is List) return data['items'] as List;
      if (data['data'] is List) return data['data'] as List;
    }
    return [];
  }

  // ─────────────────────────────────────────
  // API METHODS
  // ─────────────────────────────────────────

  /// Lấy danh sách buổi học của giảng viên: GET /api/sessions
  Future<ApiResponse<List<SessionItem>>> getSessions(String? lecturerId) async {
    final query = <String, dynamic>{
      'Trang': 1,
      'SoLuong': 100,
    };

    final resp = await _api.get<List<SessionItem>>(
      AppConfig.endpointSessions,
      queryParameters: query,
      fromData: (data) {
        final list = _extractList(data);
        return list
            .map((e) => SessionItem.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );

    return resp;
  }

  /// Tạo buổi học mới: POST /api/sessions
  Future<ApiResponse<SessionItem>> createSession({
    required String classId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    // Chuyển đổi định dạng ngày giờ sang ISO 8601
    final parts = date.split('/');
    int day = DateTime.now().day;
    int month = DateTime.now().month;
    int year = DateTime.now().year;
    if (parts.length == 3) {
      day = int.tryParse(parts[0]) ?? day;
      month = int.tryParse(parts[1]) ?? month;
      year = int.tryParse(parts[2]) ?? year;
    }

    final startParts = startTime.split(':');
    final startH = startParts.isNotEmpty ? (int.tryParse(startParts[0]) ?? 7) : 7;
    final startM = startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 30) : 30;

    final endParts = endTime.split(':');
    final endH = endParts.isNotEmpty ? (int.tryParse(endParts[0]) ?? 9) : 9;
    final endM = endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 30) : 30;

    final startDt = DateTime(year, month, day, startH, startM);
    final endDt = DateTime(year, month, day, endH, endM);

    final payload = {
      'tieuDe': 'Buổi học ngày $date ($startTime - $endTime)',
      'classId': int.tryParse(classId) ?? 1,
      'thoiGianBatDau': startDt.toIso8601String(),
      'thoiGianKetThuc': endDt.toIso8601String(),
    };

    final resp = await _api.post<SessionItem>(
      AppConfig.endpointSessions,
      data: payload,
      fromData: (data) {
        if (data is Map<String, dynamic>) {
          return SessionItem.fromJson(data);
        }
        return SessionItem(
          id: 's_${DateTime.now().millisecondsSinceEpoch}',
          classId: classId,
          className: 'Lớp học',
          courseCode: 'LTDD',
          courseName: 'Lập trình di động',
          date: date,
          startTime: startTime,
          endTime: endTime,
          status: 'scheduled',
        );
      },
    );

    return resp;
  }

  /// Mở buổi điểm danh: POST /api/sessions/{id}/open-attendance
  Future<ApiResponse<Map<String, dynamic>>> openAttendance(String sessionId) async {
    final resp = await _api.post<Map<String, dynamic>>(
      AppConfig.endpointOpenAttendance(sessionId),
      fromData: (data) {
        if (data is Map<String, dynamic>) return data;
        return {'raw': data};
      },
    );
    return resp;
  }

  /// Đóng buổi điểm danh: POST /api/sessions/{id}/close-attendance
  Future<ApiResponse<bool>> closeAttendance(String sessionId) async {
    final resp = await _api.post<bool>(
      AppConfig.endpointCloseAttendance(sessionId),
      fromData: (_) => true,
    );
    return resp;
  }

  /// Lấy mã QR hiện tại của buổi học: GET /api/sessions/{id}/current-qr
  Future<ApiResponse<Map<String, dynamic>>> getCurrentQr(String sessionId) async {
    final resp = await _api.get<Map<String, dynamic>>(
      AppConfig.endpointCurrentQr(sessionId),
      fromData: (data) {
        if (data is Map<String, dynamic>) return data;
        return {'raw': data};
      },
    );
    return resp;
  }

  /// Lấy danh sách điểm danh của 1 buổi học: GET /api/attendances?sessionId={id}
  Future<ApiResponse<List<AttendanceRecord>>> getAttendance(String sessionId) async {
    final query = <String, dynamic>{
      'sessionId': int.tryParse(sessionId) ?? sessionId,
      'Trang': 1,
      'SoLuong': 100,
    };

    final resp = await _api.get<List<AttendanceRecord>>(
      AppConfig.endpointAttendances,
      queryParameters: query,
      fromData: (data) {
        final list = _extractList(data);
        return list
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );

    return resp;
  }

  /// Cập nhật trạng thái điểm danh thủ công: PUT /api/attendances/{id}
  Future<ApiResponse<bool>> updateAttendanceStatus({
    required String attendanceId,
    required String status,
    String? note,
  }) async {
    String trangThaiBackend = 'CóMặt';
    if (status == 'late') {
      trangThaiBackend = 'TrễGiờ';
    } else if (status == 'absent') {
      trangThaiBackend = 'VắngMặt';
    }

    final resp = await _api.put<bool>(
      '${AppConfig.endpointAttendances}/$attendanceId',
      data: {'trangThai': trangThaiBackend},
      fromData: (_) => true,
    );
    return resp;
  }
}
