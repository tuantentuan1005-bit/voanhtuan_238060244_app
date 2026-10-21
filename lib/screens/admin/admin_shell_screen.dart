library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/admin_models.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

/// Màn hình Quản trị viên (Admin Dashboard Shell) với đầy đủ CRUD
/// CRUD Người dùng • CRUD Môn học • CRUD Lớp học • Cài đặt hệ thống
/// Tác giả: Võ Anh Tuấn - MSSV: 238060244

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Quản Lý Người Dùng',
    'Quản Lý Môn Học',
    'Quản Lý Lớp Học',
    'Cài Đặt Hệ Thống',
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => themeProvider.toggleTheme(!isDark),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          UserManagementTab(),
          CourseManagementTab(),
          ClassManagementTab(),
          AdminSettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts_rounded),
            label: 'Người dùng',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Môn học',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_rounded),
            label: 'Lớp học',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi quyền Quản trị viên?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 1. TAB QUẢN LÝ NGƯỜI DÙNG (USERS CRUD)
// ==========================================
class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final users = admin.users;

    return Scaffold(
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, MSSV, email...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          admin.searchUsers('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => admin.searchUsers(val),
            ),
          ),

          // Role Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildRoleFilterChip(admin, 'all', 'Tất cả (${users.length})'),
                const SizedBox(width: 8),
                _buildRoleFilterChip(admin, 'Student', 'Sinh viên'),
                const SizedBox(width: 8),
                _buildRoleFilterChip(admin, 'Lecturer', 'Giảng viên'),
                const SizedBox(width: 8),
                _buildRoleFilterChip(admin, 'Admin', 'Quản trị'),
              ],
            ),
          ),

          const Divider(height: 16),

          // User List
          Expanded(
            child: admin.isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? _buildEmptyView('Không tìm thấy người dùng nào')
                    : RefreshIndicator(
                        onRefresh: () => admin.fetchUsers(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: users.length,
                          itemBuilder: (ctx, index) {
                            final user = users[index];
                            return _buildUserCard(ctx, user, admin);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context, null),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Thêm người dùng'),
      ),
    );
  }

  Widget _buildRoleFilterChip(AdminProvider admin, String roleKey, String label) {
    final isSelected = admin.userRoleFilter == roleKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => admin.filterUsersByRole(roleKey),
    );
  }

  Widget _buildUserCard(BuildContext context, UserItem user, AdminProvider admin) {
    Color roleColor;
    IconData roleIcon;
    switch (user.role) {
      case UserRole.admin:
        roleColor = Colors.purple;
        roleIcon = Icons.shield_rounded;
        break;
      case UserRole.lecturer:
        roleColor = Colors.teal;
        roleIcon = Icons.school_rounded;
        break;
      case UserRole.student:
      default:
        roleColor = Colors.blue;
        roleIcon = Icons.person_rounded;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: roleColor.withValues(alpha: 0.15),
                  child: Icon(roleIcon, color: roleColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Username: ${user.username}${user.studentCode != null ? ' • MSSV: ${user.studentCode}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    user.role.displayName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    user.email,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ),
                if (user.phoneNumber != null) ...[
                  Icon(Icons.phone_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    user.phoneNumber!,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ],
            ),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showUserDialog(context, user),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Chỉnh sửa'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDeleteUser(context, user, admin),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Xóa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDialog(BuildContext context, UserItem? existingUser) {
    final isEditing = existingUser != null;
    final fullNameController = TextEditingController(text: existingUser?.fullName ?? '');
    final usernameController = TextEditingController(text: existingUser?.username ?? '');
    final emailController = TextEditingController(text: existingUser?.email ?? '');
    final studentCodeController = TextEditingController(text: existingUser?.studentCode ?? '');
    final phoneController = TextEditingController(text: existingUser?.phoneNumber ?? '');
    UserRole selectedRole = existingUser?.role ?? UserRole.student;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Chỉnh Sửa Người Dùng' : 'Thêm Người Dùng Mới'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên *', hintText: 'Nguyễn Văn A'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: usernameController,
                    enabled: !isEditing,
                    decoration: const InputDecoration(labelText: 'Tên đăng nhập *', hintText: 'username'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email *', hintText: 'email@university.edu.vn'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Vai trò'),
                    items: const [
                      DropdownMenuItem(value: UserRole.student, child: Text('Sinh viên')),
                      DropdownMenuItem(value: UserRole.lecturer, child: Text('Giảng viên')),
                      DropdownMenuItem(value: UserRole.admin, child: Text('Quản trị viên')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                  if (selectedRole == UserRole.student) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: studentCodeController,
                      decoration: const InputDecoration(labelText: 'Mã số sinh viên (MSSV)', hintText: '238060244'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại', hintText: '0912345678'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  if (fullNameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đủ họ tên và email')),
                    );
                    return;
                  }
                  final data = {
                    'fullName': fullNameController.text.trim(),
                    'username': usernameController.text.trim(),
                    'email': emailController.text.trim(),
                    'role': selectedRole.rawValue,
                    if (selectedRole == UserRole.student) 'studentCode': studentCodeController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                  };
                  final admin = context.read<AdminProvider>();
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  if (isEditing) {
                    await admin.updateUser(existingUser.id, data);
                  } else {
                    await admin.addUser(data);
                  }
                  messenger.showSnackBar(
                    SnackBar(content: Text(isEditing ? 'Cập nhật thành công' : 'Thêm người dùng thành công')),
                  );
                },
                child: Text(isEditing ? 'Lưu thay đổi' : 'Thêm mới'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, UserItem user, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa người dùng'),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản "${user.fullName}" (${user.username}) không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await admin.deleteUser(user.id);
              messenger.showSnackBar(
                SnackBar(content: Text('Đã xóa "${user.fullName}"')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. TAB QUẢN LÝ MÔN HỌC (COURSES CRUD)
// ==========================================
class CourseManagementTab extends StatefulWidget {
  const CourseManagementTab({super.key});

  @override
  State<CourseManagementTab> createState() => _CourseManagementTabState();
}

class _CourseManagementTabState extends State<CourseManagementTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final courses = admin.courses;

    return Scaffold(
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm môn học theo mã hoặc tên môn...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          admin.searchCourses('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => admin.searchCourses(val),
            ),
          ),

          // Course list
          Expanded(
            child: admin.isLoadingCourses
                ? const Center(child: CircularProgressIndicator())
                : courses.isEmpty
                    ? _buildEmptyView('Chưa có môn học nào')
                    : RefreshIndicator(
                        onRefresh: () => admin.fetchCourses(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: courses.length,
                          itemBuilder: (ctx, index) {
                            final course = courses[index];
                            return _buildCourseCard(ctx, course, admin);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseDialog(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm môn học'),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseItem course, AdminProvider admin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    course.courseCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    course.courseName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${course.credits} Tín chỉ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
            if (course.description != null && course.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                course.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showCourseDialog(context, course),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Sửa'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDeleteCourse(context, course, admin),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Xóa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseDialog(BuildContext context, CourseItem? existingCourse) {
    final isEditing = existingCourse != null;
    final codeController = TextEditingController(text: existingCourse?.courseCode ?? '');
    final nameController = TextEditingController(text: existingCourse?.courseName ?? '');
    final creditsController = TextEditingController(text: '${existingCourse?.credits ?? 3}');
    final descController = TextEditingController(text: existingCourse?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Sửa Môn Học' : 'Thêm Môn Học Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Mã môn học *', hintText: 'Ví dụ: IT302'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên môn học *', hintText: 'Xây dựng ứng dụng di động'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: creditsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tín chỉ *', hintText: '3'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Mô tả tóm tắt', hintText: 'Môn học chuyên ngành...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập mã và tên môn học')),
                );
                return;
              }
              final data = {
                'courseCode': codeController.text.trim(),
                'courseName': nameController.text.trim(),
                'credits': int.tryParse(creditsController.text.trim()) ?? 3,
                'description': descController.text.trim(),
              };
              final admin = context.read<AdminProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              if (isEditing) {
                await admin.updateCourse(existingCourse.id, data);
              } else {
                await admin.addCourse(data);
              }
              messenger.showSnackBar(
                SnackBar(content: Text(isEditing ? 'Cập nhật môn học thành công' : 'Thêm môn học thành công')),
              );
            },
            child: Text(isEditing ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCourse(BuildContext context, CourseItem course, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa môn học'),
        content: Text('Bạn có chắc chắn muốn xóa môn "${course.courseName}" (${course.courseCode})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await admin.deleteCourse(course.id);
              messenger.showSnackBar(
                SnackBar(content: Text('Đã xóa môn "${course.courseName}"')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. TAB QUẢN LÝ LỚP HỌC (CLASSES CRUD)
// ==========================================
class ClassManagementTab extends StatefulWidget {
  const ClassManagementTab({super.key});

  @override
  State<ClassManagementTab> createState() => _ClassManagementTabState();
}

class _ClassManagementTabState extends State<ClassManagementTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final classes = admin.classes;

    return Scaffold(
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm lớp học, môn học, giảng viên...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          admin.searchClasses('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => admin.searchClasses(val),
            ),
          ),

          // Class list
          Expanded(
            child: admin.isLoadingClasses
                ? const Center(child: CircularProgressIndicator())
                : classes.isEmpty
                    ? _buildEmptyView('Chưa có lớp học nào')
                    : RefreshIndicator(
                        onRefresh: () => admin.fetchClasses(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: classes.length,
                          itemBuilder: (ctx, index) {
                            final cls = classes[index];
                            return _buildClassCard(ctx, cls, admin);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClassDialog(context, null),
        icon: const Icon(Icons.add_home_work_rounded),
        label: const Text('Thêm lớp học'),
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, ClassItem cls, AdminProvider admin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    cls.classCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cls.className,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${cls.totalStudents} SV',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.book_outlined, size: 16, color: Colors.teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cls.courseName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_pin_circle_outlined, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'GV: ${cls.lecturerName}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${cls.schedule} • ${cls.room}',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showClassDialog(context, cls),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Sửa'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDeleteClass(context, cls, admin),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Xóa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClassDialog(BuildContext context, ClassItem? existingClass) {
    final isEditing = existingClass != null;
    final codeController = TextEditingController(text: existingClass?.classCode ?? '');
    final nameController = TextEditingController(text: existingClass?.className ?? '');
    final courseNameController = TextEditingController(text: existingClass?.courseName ?? 'Xây dựng ứng dụng di động');
    final lecturerNameController = TextEditingController(text: existingClass?.lecturerName ?? 'ThS. Võ Anh Tuấn');
    final roomController = TextEditingController(text: existingClass?.room ?? 'Phòng B2-302');
    final scheduleController = TextEditingController(text: existingClass?.schedule ?? 'Thứ 4 (Ca 2: 09:30 - 11:30)');
    final totalStudentsController = TextEditingController(text: '${existingClass?.totalStudents ?? 45}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Sửa Lớp Học' : 'Thêm Lớp Học Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Mã lớp *', hintText: '24DTHB1'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên lớp học *', hintText: 'Lớp Lập trình Di động 01'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: courseNameController,
                decoration: const InputDecoration(labelText: 'Môn học tương ứng *', hintText: 'Xây dựng ứng dụng di động'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lecturerNameController,
                decoration: const InputDecoration(labelText: 'Giảng viên phụ trách *', hintText: 'ThS. Võ Anh Tuấn'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: roomController,
                      decoration: const InputDecoration(labelText: 'Phòng học', hintText: 'B2-302'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: totalStudentsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sĩ số', hintText: '45'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: scheduleController,
                decoration: const InputDecoration(labelText: 'Lịch học', hintText: 'Thứ 4 (09:30 - 11:30)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập mã lớp và tên lớp')),
                );
                return;
              }
              final data = {
                'classCode': codeController.text.trim(),
                'className': nameController.text.trim(),
                'courseName': courseNameController.text.trim(),
                'lecturerName': lecturerNameController.text.trim(),
                'room': roomController.text.trim(),
                'schedule': scheduleController.text.trim(),
                'totalStudents': int.tryParse(totalStudentsController.text.trim()) ?? 45,
              };
              final admin = context.read<AdminProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              if (isEditing) {
                await admin.updateClass(existingClass.id, data);
              } else {
                await admin.addClass(data);
              }
              messenger.showSnackBar(
                SnackBar(content: Text(isEditing ? 'Cập nhật lớp học thành công' : 'Thêm lớp học thành công')),
              );
            },
            child: Text(isEditing ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClass(BuildContext context, ClassItem cls, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa lớp học'),
        content: Text('Bạn có chắc chắn muốn xóa lớp "${cls.className}" (${cls.classCode})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await admin.deleteClass(cls.id);
              messenger.showSnackBar(
                SnackBar(content: Text('Đã xóa lớp "${cls.className}"')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. TAB CÀI ĐẶT ADMIN (ADMIN SETTINGS)
// ==========================================
class AdminSettingsTab extends StatelessWidget {
  const AdminSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.shield, color: Colors.white),
            ),
            title: Text(auth.currentUser?.fullName ?? 'Quản trị viên'),
            subtitle: Text('Vai trò: ${auth.currentRole.displayName} • ${auth.currentUser?.username ?? "admin"}'),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('API Base URL (ASP.NET Core)'),
                subtitle: Text(AppConfig.apiBaseUrl),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Tác giả bài thi'),
                subtitle: Text('${AppConfig.studentName} - MSSV: ${AppConfig.studentId}'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                title: const Text('Giao diện tối (Dark Mode)'),
                subtitle: Text(isDark ? 'Đang bật' : 'Đang tắt'),
                value: isDark,
                onChanged: (val) => themeProvider.toggleTheme(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.read<AuthProvider>().logout(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất'),
        ),
      ],
    );
  }
}

Widget _buildEmptyView(String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 54, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}
