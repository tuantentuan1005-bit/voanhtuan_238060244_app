library;

import 'package:flutter/material.dart';
import '../data/models/admin_models.dart';
import '../data/services/admin_service.dart';

/// Provider quản lý trạng thái phân hệ Quản trị viên (Admin CRUD)
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  // Users State
  List<UserItem> _users = [];
  bool _isLoadingUsers = false;
  String _userSearchQuery = '';
  String _userRoleFilter = 'all';

  // Courses State
  List<CourseItem> _courses = [];
  bool _isLoadingCourses = false;
  String _courseSearchQuery = '';

  // Classes State
  List<ClassItem> _classes = [];
  bool _isLoadingClasses = false;
  String _classSearchQuery = '';

  String? _errorMessage;
  String? _successMessage;
  bool _isOfflineMode = false;

  // Getters
  List<UserItem> get users => _users;
  bool get isLoadingUsers => _isLoadingUsers;
  String get userSearchQuery => _userSearchQuery;
  String get userRoleFilter => _userRoleFilter;

  List<CourseItem> get courses => _courses;
  bool get isLoadingCourses => _isLoadingCourses;
  String get courseSearchQuery => _courseSearchQuery;

  List<ClassItem> get classes => _classes;
  bool get isLoadingClasses => _isLoadingClasses;
  String get classSearchQuery => _classSearchQuery;

  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isOfflineMode => _isOfflineMode;

  AdminProvider() {
    loadAll();
  }

  void loadAll() {
    fetchUsers();
    fetchCourses();
    fetchClasses();
  }

  // ================= USERS CRUD =================
  Future<void> fetchUsers() async {
    _isLoadingUsers = true;
    notifyListeners();

    final res = await _service.getUsers(
      search: _userSearchQuery,
      role: _userRoleFilter,
    );

    _isLoadingUsers = false;
    if (res.isOfflineFallback) {
      _isOfflineMode = true;
    }
    if (res.success && res.data != null) {
      _users = res.data!;
    } else {
      _errorMessage = res.message;
    }
    notifyListeners();
  }

  void searchUsers(String query) {
    _userSearchQuery = query;
    fetchUsers();
  }

  void filterUsersByRole(String role) {
    _userRoleFilter = role;
    fetchUsers();
  }

  Future<bool> addUser(Map<String, dynamic> data) async {
    final res = await _service.createUser(data);
    if (res.success) {
      _successMessage = res.message;
      await fetchUsers();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _service.updateUser(id, data);
    if (res.success) {
      _successMessage = res.message;
      await fetchUsers();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    final res = await _service.deleteUser(id);
    if (res.success) {
      _successMessage = res.message;
      await fetchUsers();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  // ================= COURSES CRUD =================
  Future<void> fetchCourses() async {
    _isLoadingCourses = true;
    notifyListeners();

    final res = await _service.getCourses(search: _courseSearchQuery);
    _isLoadingCourses = false;
    if (res.isOfflineFallback) {
      _isOfflineMode = true;
    }
    if (res.success && res.data != null) {
      _courses = res.data!;
    } else {
      _errorMessage = res.message;
    }
    notifyListeners();
  }

  void searchCourses(String query) {
    _courseSearchQuery = query;
    fetchCourses();
  }

  Future<bool> addCourse(Map<String, dynamic> data) async {
    final res = await _service.createCourse(data);
    if (res.success) {
      _successMessage = res.message;
      await fetchCourses();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCourse(String id, Map<String, dynamic> data) async {
    final res = await _service.updateCourse(id, data);
    if (res.success) {
      _successMessage = res.message;
      await fetchCourses();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCourse(String id) async {
    final res = await _service.deleteCourse(id);
    if (res.success) {
      _successMessage = res.message;
      await fetchCourses();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  // ================= CLASSES CRUD =================
  Future<void> fetchClasses() async {
    _isLoadingClasses = true;
    notifyListeners();

    final res = await _service.getClasses(search: _classSearchQuery);
    _isLoadingClasses = false;
    if (res.isOfflineFallback) {
      _isOfflineMode = true;
    }
    if (res.success && res.data != null) {
      _classes = res.data!;
    } else {
      _errorMessage = res.message;
    }
    notifyListeners();
  }

  void searchClasses(String query) {
    _classSearchQuery = query;
    fetchClasses();
  }

  Future<bool> addClass(Map<String, dynamic> data) async {
    final res = await _service.createClass(data);
    if (res.success) {
      _successMessage = res.message;
      await fetchClasses();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClass(String id, Map<String, dynamic> data) async {
    final res = await _service.updateClass(id, data);
    if (res.success) {
      _successMessage = res.message;
      await fetchClasses();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClass(String id) async {
    final res = await _service.deleteClass(id);
    if (res.success) {
      _successMessage = res.message;
      await fetchClasses();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  void clearNotification() {
    _errorMessage = null;
    _successMessage = null;
  }
}
