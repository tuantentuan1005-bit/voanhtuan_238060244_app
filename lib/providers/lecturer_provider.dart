/// Provider quản lý state cho Giảng viên (Lecturer)
/// 100% gọi API thật ASP.NET Core, không dùng dữ liệu giả
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../data/models/lecturer_models.dart';
import '../data/services/lecturer_service.dart';

enum LecturerLoadState { idle, loading, loaded, error }

class LecturerProvider extends ChangeNotifier {
  late final LecturerService _service;
  bool _isOfflineMode = false;

  LecturerProvider() {
    _service = LecturerService(ApiClient());
    _sessions = [];
    _sessionState = LecturerLoadState.idle;
  }

  bool get isOfflineMode => _isOfflineMode;

  // ─── State buổi học ───────────────────────────────
  LecturerLoadState _sessionState = LecturerLoadState.idle;
  List<SessionItem> _sessions = [];
  String _sessionError = '';
  String _sessionFilter = 'all'; // all | open | closed | scheduled

  LecturerLoadState get sessionState => _sessionState;
  List<SessionItem> get sessions => _sessions;
  String get sessionError => _sessionError;
  String get sessionFilter => _sessionFilter;

  List<SessionItem> get filteredSessions {
    if (_sessionFilter == 'all') return _sessions;
    return _sessions.where((s) => s.status == _sessionFilter).toList();
  }

  // ─── State điểm danh ──────────────────────────────
  LecturerLoadState _attendanceState = LecturerLoadState.idle;
  List<AttendanceRecord> _attendanceRecords = [];
  String _attendanceError = '';
  SessionItem? _selectedSession;

  LecturerLoadState get attendanceState => _attendanceState;
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
  String get attendanceError => _attendanceError;
  SessionItem? get selectedSession => _selectedSession;

  // ─── State QR ─────────────────────────────────────
  QrPayload? _currentQr;
  String? _currentQrString;
  int _qrSecondsLeft = 30;
  Timer? _qrTimer;
  String? _activeQrSessionId;

  QrPayload? get currentQr => _currentQr;
  String? get currentQrString => _currentQrString;
  int get qrSecondsLeft => _qrSecondsLeft;
  String? get activeQrSessionId => _activeQrSessionId;

  // ─────────────────────────────────────────────────────
  // BUỔI HỌC
  // ─────────────────────────────────────────────────────

  Future<void> loadSessions(String? lecturerId) async {
    _sessionState = LecturerLoadState.loading;
    _sessionError = '';
    notifyListeners();

    final resp = await _service.getSessions(lecturerId);
    if (resp.success && resp.data != null) {
      _sessions = resp.data!;
      _sessionState = LecturerLoadState.loaded;
      _isOfflineMode = false;
    } else {
      _sessionError = resp.message;
      _sessions = [];
      _sessionState = LecturerLoadState.error;
    }
    notifyListeners();
  }

  void setSessionFilter(String filter) {
    _sessionFilter = filter;
    notifyListeners();
  }

  Future<bool> createSession({
    required String classId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final resp = await _service.createSession(
      classId: classId,
      date: date,
      startTime: startTime,
      endTime: endTime,
    );
    if (resp.success && resp.data != null) {
      _sessions.insert(0, resp.data!);
      notifyListeners();
      return true;
    }
    _sessionError = resp.message;
    notifyListeners();
    return false;
  }

  Future<bool> toggleSession(String sessionId, String newStatus) async {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx == -1) return false;

    if (newStatus == 'open') {
      final res = await _service.openAttendance(sessionId);
      if (res.success) {
        final token = res.data?['qrToken']?.toString();
        _sessions[idx] = _sessions[idx].copyWith(status: 'open', attendanceCode: token);
        notifyListeners();
        return true;
      }
    } else {
      final res = await _service.closeAttendance(sessionId);
      if (res.success) {
        _sessions[idx] = _sessions[idx].copyWith(status: 'closed');
        if (_activeQrSessionId == sessionId) {
          stopQr();
        }
        notifyListeners();
        return true;
      }
    }

    return false;
  }

  // ─────────────────────────────────────────────────────
  // SỔ ĐIỂM DANH
  // ─────────────────────────────────────────────────────

  Future<void> loadAttendance(SessionItem session) async {
    _selectedSession = session;
    _attendanceState = LecturerLoadState.loading;
    _attendanceError = '';
    notifyListeners();

    final resp = await _service.getAttendance(session.id);
    if (resp.success && resp.data != null) {
      _attendanceRecords = resp.data!;
      _attendanceState = LecturerLoadState.loaded;
    } else {
      _attendanceError = resp.message;
      _attendanceRecords = [];
      _attendanceState = LecturerLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> updateRecord(
      String studentId, String newStatus, String? note) async {
    if (_selectedSession == null) return false;

    final idx = _attendanceRecords.indexWhere((r) => r.studentId == studentId);
    if (idx != -1) {
      _attendanceRecords[idx] =
          _attendanceRecords[idx].copyWith(status: newStatus, note: note, method: 'manual');
      notifyListeners();
    }

    final resp = await _service.updateAttendanceStatus(
      attendanceId: studentId,
      status: newStatus,
      note: note,
    );

    if (resp.success) {
      final present = _attendanceRecords.where((r) => r.status == 'present').length;
      final absent = _attendanceRecords.where((r) => r.status == 'absent').length;
      final late = _attendanceRecords.where((r) => r.status == 'late').length;
      final sIdx = _sessions.indexWhere((s) => s.id == _selectedSession!.id);
      if (sIdx != -1) {
        _sessions[sIdx] = _sessions[sIdx].copyWith(
          presentCount: present,
          absentCount: absent,
          lateCount: late,
        );
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─────────────────────────────────────────────────────
  // QR ĐỘNG (đồng bộ thật với backend mỗi 30 giây)
  // ─────────────────────────────────────────────────────

  Future<void> startQr(String sessionId, String lecturerId) async {
    _activeQrSessionId = sessionId;
    await _fetchQrFromBackend(sessionId, lecturerId);

    _qrTimer?.cancel();
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      _qrSecondsLeft--;
      if (_qrSecondsLeft <= 0) {
        await _fetchQrFromBackend(sessionId, lecturerId);
        _qrSecondsLeft = 30;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchQrFromBackend(String sessionId, String lecturerId) async {
    final res = await _service.getCurrentQr(sessionId);
    if (res.success && res.data != null) {
      final token = res.data!['qrToken']?.toString() ?? '';
      _currentQrString = token;
      _currentQr = QrPayload(
        sessionId: sessionId,
        lecturerId: lecturerId,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        signature: token,
      );
    } else {
      // Nếu ca chưa mở thì gọi mở
      final openRes = await _service.openAttendance(sessionId);
      if (openRes.success && openRes.data != null) {
        final token = openRes.data!['qrToken']?.toString() ?? '';
        _currentQrString = token;
        _currentQr = QrPayload(
          sessionId: sessionId,
          lecturerId: lecturerId,
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          signature: token,
        );
      }
    }
    notifyListeners();
  }

  void stopQr() {
    _qrTimer?.cancel();
    _qrTimer = null;
    _currentQr = null;
    _currentQrString = null;
    _activeQrSessionId = null;
    _qrSecondsLeft = 30;
    notifyListeners();
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    super.dispose();
  }
}
