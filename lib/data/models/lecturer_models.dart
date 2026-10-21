/// Models dữ liệu cho Giảng viên (Lecturer)
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244
library;

/// Buổi học (Session)
class SessionItem {
  final String id;
  final String classId;
  final String className;
  final String courseCode;
  final String courseName;
  final String date; // DD/MM/YYYY
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String status; // 'scheduled' | 'open' | 'closed'
  final String? attendanceCode;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;

  const SessionItem({
    required this.id,
    required this.classId,
    required this.className,
    required this.courseCode,
    required this.courseName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.attendanceCode,
    this.totalStudents = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
  });

  factory SessionItem.fromJson(Map<String, dynamic> json) {
    final id = (json['sessionId'] ?? json['id'] ?? '').toString();
    final tieuDe = (json['tieuDe'] ?? json['className'] ?? 'Buổi học').toString();

    String resolvedClassName = tieuDe;
    String resolvedCourseName = (json['courseName'] ?? 'Lập trình di động').toString();
    String resolvedCourseCode = (json['courseCode'] ?? 'LTDD').toString();
    String resolvedClassId = (json['classId'] ?? '').toString();

    if (json['lopHoc'] is Map<String, dynamic>) {
      final lop = json['lopHoc'] as Map<String, dynamic>;
      resolvedClassName = (lop['tenLopHoc'] ?? resolvedClassName).toString();
      resolvedCourseName = (lop['monHoc'] ?? resolvedCourseName).toString();
      resolvedClassId = (lop['classId'] ?? resolvedClassId).toString();
    }

    String dateStr = json['date']?.toString() ?? '';
    String startStr = json['startTime']?.toString() ?? '07:30';
    String endStr = json['endTime']?.toString() ?? '09:30';

    if (json['thoiGianBatDau'] != null) {
      final dt = DateTime.tryParse(json['thoiGianBatDau'].toString())?.toLocal();
      if (dt != null) {
        dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        startStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
    if (json['thoiGianKetThuc'] != null) {
      final dtEnd = DateTime.tryParse(json['thoiGianKetThuc'].toString())?.toLocal();
      if (dtEnd != null) {
        endStr = '${dtEnd.hour.toString().padLeft(2, '0')}:${dtEnd.minute.toString().padLeft(2, '0')}';
      }
    }

    String statusStr = 'scheduled';
    if (json['dangMoDiemDanh'] == true) {
      statusStr = 'open';
    } else if (json['status'] != null) {
      statusStr = json['status'].toString();
    } else if (json['dangMoDiemDanh'] == false) {
      statusStr = 'closed';
    }

    return SessionItem(
      id: id,
      classId: resolvedClassId,
      className: resolvedClassName,
      courseCode: resolvedCourseCode,
      courseName: resolvedCourseName,
      date: dateStr,
      startTime: startStr,
      endTime: endStr,
      status: statusStr,
      attendanceCode: json['qrToken']?.toString() ?? json['attendanceCode']?.toString(),
      totalStudents: (json['tongDiemDanh'] ?? json['totalStudents'] as num?)?.toInt() ?? 0,
      presentCount: (json['coMat'] ?? json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['vangMat'] ?? json['absentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['treGio'] ?? json['lateCount'] as num?)?.toInt() ?? 0,
    );
  }

  SessionItem copyWith({
    String? id,
    String? classId,
    String? className,
    String? courseCode,
    String? courseName,
    String? date,
    String? startTime,
    String? endTime,
    String? status,
    String? attendanceCode,
    int? totalStudents,
    int? presentCount,
    int? absentCount,
    int? lateCount,
  }) =>
      SessionItem(
        id: id ?? this.id,
        classId: classId ?? this.classId,
        className: className ?? this.className,
        courseCode: courseCode ?? this.courseCode,
        courseName: courseName ?? this.courseName,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        status: status ?? this.status,
        attendanceCode: attendanceCode ?? this.attendanceCode,
        totalStudents: totalStudents ?? this.totalStudents,
        presentCount: presentCount ?? this.presentCount,
        absentCount: absentCount ?? this.absentCount,
        lateCount: lateCount ?? this.lateCount,
      );

  /// Tỉ lệ % có mặt
  double get attendanceRate =>
      totalStudents == 0 ? 0 : (presentCount / totalStudents) * 100;

  /// Nhãn trạng thái buổi học
  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Đang mở';
      case 'closed':
        return 'Đã kết thúc';
      default:
        return 'Chờ mở';
    }
  }
}

/// Bản ghi điểm danh một sinh viên trong buổi học
class AttendanceRecord {
  final String studentId;
  final String studentName;
  final String studentCode; // Mã sinh viên
  final String status; // 'present' | 'absent' | 'late'
  final String? timestamp; // Thời gian điểm danh
  final String? method; // 'qr' | 'gps' | 'face' | 'manual'
  final String? note;

  const AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.status,
    this.timestamp,
    this.method,
    this.note,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    String st = (json['trangThai'] ?? json['status'] ?? 'absent').toString();
    if (st == 'CóMặt') {
      st = 'present';
    } else if (st == 'TrễGiờ') {
      st = 'late';
    } else if (st == 'VắngMặt') {
      st = 'absent';
    }

    String sName = 'Sinh viên';
    String sCode = '';
    String sId = (json['attendanceId'] ?? json['studentId'] ?? '').toString();

    if (json['sinhVien'] is Map<String, dynamic>) {
      final sv = json['sinhVien'] as Map<String, dynamic>;
      sName = (sv['hoTen'] ?? sName).toString();
      sCode = (sv['maSoSinhVien'] ?? '').toString();
      sId = (sv['userId'] ?? sId).toString();
    } else {
      sName = (json['studentName'] ?? sName).toString();
      sCode = (json['studentCode'] ?? '').toString();
    }

    String? timeStr = json['thoiGianDiemDanh']?.toString() ?? json['timestamp']?.toString();
    if (timeStr != null && timeStr.contains('T')) {
      final dt = DateTime.tryParse(timeStr)?.toLocal();
      if (dt != null) {
        timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return AttendanceRecord(
      studentId: sId,
      studentName: sName,
      studentCode: sCode,
      status: st,
      timestamp: timeStr,
      method: (json['thietBiDaDung'] != null ? 'qr' : (json['method'] ?? 'qr')).toString(),
      note: json['note']?.toString(),
    );
  }

  AttendanceRecord copyWith({String? status, String? note, String? method}) =>
      AttendanceRecord(
        studentId: studentId,
        studentName: studentName,
        studentCode: studentCode,
        status: status ?? this.status,
        timestamp: timestamp,
        method: method ?? this.method,
        note: note ?? this.note,
      );

  /// Nhãn trạng thái điểm danh
  String get statusLabel {
    switch (status) {
      case 'present':
        return 'Có mặt';
      case 'late':
        return 'Đi muộn';
      default:
        return 'Vắng mặt';
    }
  }
}

/// Dữ liệu QR Điểm danh động
class QrPayload {
  final String sessionId;
  final String lecturerId;
  final int timestamp; // Unix seconds
  final String signature; // Chữ ký bảo mật

  const QrPayload({
    required this.sessionId,
    required this.lecturerId,
    required this.timestamp,
    required this.signature,
  });

  String toQrString() =>
      'ATT:$sessionId:$lecturerId:$timestamp:$signature';
}
