import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/shared.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final Color darkGreen = const Color(0xFF456028);
  final Color mediumGreen = const Color(0xFF94A65E);
  final Color lightGreen = const Color(0xFFDDDDA1);
  final Color creamBackground = const Color(0xFFF8F9FA);
  final Color accentBlue = const Color(0xFF5A86AD);

  static const String baseUrl = 'http://localhost:5000/api';
  String? _token;

  List<dynamic> users = [];
  bool isLoading = true;
  String searchQuery = '';
  int currentPage = 1;
  int totalPages = 1;
  int totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _token = await SharedService.getToken();
    await _loadUsers();
  }

  Future<void> _loadUsers({int page = 1}) async {
    if (_token == null) return;

    setState(() => isLoading = true);

    try {
      String url = '$baseUrl/admin/users?page=$page&per_page=10';
      if (searchQuery.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(searchQuery)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            users = data['data']['users'];
            totalPages = data['data']['total_pages'];
            currentPage = data['data']['page'];
            totalUsers = data['data']['total'];
            isLoading = false;
          });
        }
      } else {
        // Fallback dummy data
        _useDummyData();
      }
    } catch (e) {
      print('Error loading users: $e');
      _useDummyData();
    }
  }

  void _useDummyData() {
    setState(() {
      users = [
        {
          'id': 1,
          'name': 'Admin',
          'email': 'admin@hydrogrow.com',
          'role': 'admin',
          'created_at': '2024-01-01T00:00:00.000Z',
          'last_login': '2024-01-15T10:30:00.000Z',
        },
        {
          'id': 2,
          'name': 'User 1',
          'email': 'user1@example.com',
          'role': 'user',
          'created_at': '2024-01-10T00:00:00.000Z',
          'last_login': '2024-01-14T15:45:00.000Z',
        },
        {
          'id': 3,
          'name': 'User 2',
          'email': 'user2@example.com',
          'role': 'user',
          'created_at': '2024-01-12T00:00:00.000Z',
          'last_login': '2024-01-13T09:20:00.000Z',
        },
      ];
      totalUsers = users.length;
      totalPages = 1;
      currentPage = 1;
      isLoading = false;
    });
  }

  Future<void> _toggleUserStatus(int userId, bool currentStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'is_active': !currentStatus}),
      );

      if (response.statusCode == 200) {
        await _loadUsers(page: currentPage);
      }
    } catch (e) {
      print('Error toggling user status: $e');
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['name'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Email', user['email'] ?? 'N/A'),
              _detailRow('Role', user['role'] ?? 'user'),
              _detailRow(
                'Status',
                user['is_active'] ?? true ? 'Active' : 'Inactive',
              ),
              if (user['created_at'] != null)
                _detailRow('Joined', _formatDate(user['created_at'])),
              if (user['last_login'] != null)
                _detailRow('Last Login', _formatDate(user['last_login'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, color: darkGreen),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() => searchQuery = value);
                  _loadUsers();
                },
                decoration: InputDecoration(
                  hintText: 'Search users by name or email...',
                  prefixIcon: Icon(Icons.search, color: mediumGreen),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Stats Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    darkGreen.withValues(alpha: 0.1),
                    mediumGreen.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mediumGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Total Users', totalUsers.toString(), Icons.people),
                  _statItem(
                    'Active',
                    users
                        .where((u) => u['is_active'] ?? true)
                        .length
                        .toString(),
                    Icons.check_circle,
                  ),
                  _statItem(
                    'Admins',
                    users.where((u) => u['role'] == 'admin').length.toString(),
                    Icons.admin_panel_settings,
                  ),
                ],
              ),
            ),
          ),

          // Users List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: () {
                                setState(() => searchQuery = '');
                                _loadUsers();
                              },
                              child: const Text('Clear search'),
                            ),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadUsers(page: currentPage),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isAdmin = user['role'] == 'admin';
                        final isActive = user['is_active'] ?? true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: isAdmin
                                  ? darkGreen.withValues(alpha: 0.3)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? darkGreen.withValues(alpha: 0.1)
                                    : accentBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAdmin
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                                color: isAdmin ? darkGreen : accentBlue,
                              ),
                            ),
                            title: Text(
                              user['name'] ?? 'User ${user['id']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: darkGreen,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['email'] ?? ''),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? darkGreen.withValues(alpha: 0.1)
                                            : accentBlue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isAdmin ? 'Admin' : 'User',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isAdmin
                                              ? darkGreen
                                              : accentBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isActive
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.info_outline,
                                    color: mediumGreen,
                                  ),
                                  onPressed: () => _showUserDetails(user),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isActive
                                        ? Icons.toggle_on
                                        : Icons.toggle_off,
                                    color: isActive
                                        ? Colors.green
                                        : Colors.grey,
                                    size: 30,
                                  ),
                                  onPressed: () =>
                                      _toggleUserStatus(user['id'], isActive),
                                ),
                              ],
                            ),
                            onTap: () => _showUserDetails(user),
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // Pagination
          if (totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: currentPage > 1 ? darkGreen : Colors.grey,
                    ),
                    onPressed: currentPage > 1
                        ? () => _loadUsers(page: currentPage - 1)
                        : null,
                  ),
                  Text(
                    'Page $currentPage of $totalPages',
                    style: TextStyle(color: darkGreen),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: currentPage < totalPages ? darkGreen : Colors.grey,
                    ),
                    onPressed: currentPage < totalPages
                        ? () => _loadUsers(page: currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new user functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add user functionality coming soon')),
          );
        },
        backgroundColor: darkGreen,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: darkGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: darkGreen, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: darkGreen,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
