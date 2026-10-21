/// Models dữ liệu cho phân hệ Sinh viên (Student)
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244
library;

/// Lịch sử điểm danh của sinh viên theo từng buổi học
class AttendanceHistoryItem {
  final String id;
  final String sessionId;
  final String courseCode;
  final String courseName;
  final String className;
  final String date; // DD/MM/YYYY
  final String time; // HH:mm
  final String status; // 'present' | 'late' | 'absent'
  final String method; // 'qr' | 'face' | 'manual'
  final String room;
  final double? distanceMeters;
  final bool faceVerified;
  final String? note;

  const AttendanceHistoryItem({
    required this.id,
    required this.sessionId,
    required this.courseCode,
    required this.courseName,
    required this.className,
    required this.date,
    required this.time,
    required this.status,
    required this.method,
    required this.room,
    this.distanceMeters,
    this.faceVerified = false,
    this.note,
  });

  factory AttendanceHistoryItem.fromJson(Map<String, dynamic> json) {
    String cName = 'Lập trình ứng dụng di động';
    String clsName = 'Lớp chuyên ngành';
    String cCode = (json['courseCode'] ?? 'LTDD').toString();
    String sId = (json['sessionId'] ?? '').toString();

    if (json['buoiHoc'] is Map<String, dynamic>) {
      final bh = json['buoiHoc'] as Map<String, dynamic>;
      cName = (bh['monHoc'] ?? cName).toString();
      clsName = (bh['lopHoc'] ?? bh['tieuDe'] ?? clsName).toString();
      sId = (bh['sessionId'] ?? sId).toString();
    } else {
      cName = (json['courseName'] ?? cName).toString();
      clsName = (json['className'] ?? clsName).toString();
    }

    String st = (json['trangThai'] ?? json['status'] ?? 'present').toString();
    if (st == 'CóMặt') {
      st = 'present';
    } else if (st == 'TrễGiờ') {
      st = 'late';
    } else if (st == 'VắngMặt') {
      st = 'absent';
    }

    String dateStr = json['date']?.toString() ?? '';
    String timeStr = json['time']?.toString() ?? '07:15';

    final tStr = json['thoiGianDiemDanh']?.toString();
    if (tStr != null && tStr.contains('T')) {
      final dt = DateTime.tryParse(tStr)?.toLocal();
      if (dt != null) {
        dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return AttendanceHistoryItem(
      id: (json['attendanceId'] ?? json['id'] ?? '').toString(),
      sessionId: sId,
      courseCode: cCode,
      courseName: cName,
      className: clsName,
      date: dateStr.isNotEmpty ? dateStr : '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      time: timeStr,
      status: st,
      method: (json['method'] ?? 'qr').toString(),
      room: (json['room'] ?? json['phongHoc'] ?? 'Phòng Lab 5 (A1-102)').toString(),
      distanceMeters: (json['khoangCach'] as num?)?.toDouble() ?? (json['distanceMeters'] as num?)?.toDouble(),
      faceVerified: json['duongDanAnh'] != null || json['faceVerified'] == true,
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'courseCode': courseCode,
        'courseName': courseName,
        'className': className,
        'date': date,
        'time': time,
        'status': status,
        'method': method,
        'room': room,
        'distanceMeters': distanceMeters,
        'faceVerified': faceVerified,
        'note': note,
      };

  String get statusLabel {
    switch (status) {
      case 'present':
        return 'Có mặt';
      case 'late':
        return 'Đi muộn';
      case 'absent':
        return 'Vắng mặt';
      default:
        return 'Chưa xác định';
    }
  }

  String get methodLabel {
    switch (method) {
      case 'qr':
        return 'Quét QR';
      case 'face':
        return 'Khuôn mặt';
      case 'manual':
        return 'Giảng viên duyệt';
      default:
        return 'Tự động';
    }
  }
}

/// Thống kê chuyên cần theo từng môn học của sinh viên
class CourseAttendanceSummary {
  final String courseCode;
  final String courseName;
  final int totalSessions;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int maxAllowedAbsence;

  const CourseAttendanceSummary({
    required this.courseCode,
    required this.courseName,
    required this.totalSessions,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    this.maxAllowedAbsence = 3,
  });

  factory CourseAttendanceSummary.fromJson(Map<String, dynamic> json) {
    final total = (json['tongSoBuoi'] as num?)?.toInt() ?? (json['totalSessions'] as num?)?.toInt() ?? 12;
    final absent = (json['soBuoiVang'] as num?)?.toInt() ?? (json['absentCount'] as num?)?.toInt() ?? 0;
    final late = (json['soBuoiTre'] as num?)?.toInt() ?? (json['lateCount'] as num?)?.toInt() ?? 0;
    final present = (json['soBuoiCoMat'] as num?)?.toInt() ?? (json['presentCount'] as num?)?.toInt() ?? (total - absent - late);

    return CourseAttendanceSummary(
      courseCode: (json['maMonHoc'] ?? json['courseCode'] ?? 'MH').toString(),
      courseName: (json['monHoc'] ?? json['tenMonHoc'] ?? json['courseName'] ?? 'Môn học').toString(),
      totalSessions: total,
      presentCount: present < 0 ? 0 : present,
      lateCount: late,
      absentCount: absent,
      maxAllowedAbsence: (json['maxAllowedAbsence'] as num?)?.toInt() ?? (total * 0.2).round(),
    );
  }

  /// Tỷ lệ vắng mặt (%) = (Số buổi vắng / Tổng số buổi) * 100
  double get absenceRate =>
      totalSessions == 0 ? 0.0 : (absentCount / totalSessions) * 100;

  /// Tỷ lệ có mặt (%)
  double get attendanceRate =>
      totalSessions == 0 ? 0.0 : ((presentCount + lateCount) / totalSessions) * 100;

  /// Đã chạm ngưỡng nguy cơ cấm thi (>= 20%)
  bool get isAtRisk => absenceRate >= 20.0;

  /// Đã bị cấm thi (vắng quá mức cho phép)
  bool get isBarredFromExam => absentCount > maxAllowedAbsence;

  /// Số buổi vắng còn lại trước khi bị cấm thi
  int get remainingAllowedAbsence {
    final rem = maxAllowedAbsence - absentCount;
    return rem < 0 ? 0 : rem;
  }
}

/// Kết quả sau khi thực hiện điểm danh
class CheckInResult {
  final bool success;
  final String message;
  final String? sessionId;
  final String? courseName;
  final String? className;
  final String? checkInTime;
  final double? distanceMeters;
  final bool faceVerified;
  final String method;

  const CheckInResult({
    required this.success,
    required this.message,
    this.sessionId,
    this.courseName,
    this.className,
    this.checkInTime,
    this.distanceMeters,
    this.faceVerified = false,
    this.method = 'qr',
  });
}
