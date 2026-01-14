import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/shared.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  // Modern Color Palette sesuai LoginPage
  final Color primaryColor = const Color(0xFF4361EE); // Modern blue
  final Color secondaryColor = const Color(0xFF3A0CA3); // Dark blue
  final Color accentColor = const Color(0xFF4CC9F0); // Light blue
  final Color backgroundColor = const Color(0xFFF8F9FF); // Light background
  final Color surfaceColor = Colors.white;
  final Color textPrimary = const Color(0xFF2B2D42);
  final Color textSecondary = const Color(0xFF8D99AE);
  final Color successColor = const Color(0xFF4CAF50);
  final Color warningColor = const Color(0xFFFF9800);
  final Color errorColor = const Color(0xFFF44336);

  String? _token;
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String searchQuery = '';
  int currentPage = 1;
  int totalPages = 1;
  int totalUsers = 0;
  Timer? _searchTimer;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        currentPage < totalPages &&
        !isLoading) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadMoreUsers() async {
    if (isLoading || currentPage >= totalPages) return;

    setState(() => isLoading = true);

    final nextPage = currentPage + 1;
    final response = await ApiService.getUsers(
      token: _token!,
      page: nextPage,
      perPage: 10,
      search: searchQuery,
    );

    if (response['status'] == true) {
      final data = response['data'] ?? {};
      final newUsers = (data['users'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        users.addAll(newUsers);
        currentPage = nextPage;
        totalPages = data['total_pages'] ?? totalPages;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _initializeData() async {
    _token = await SharedService.getToken();
    if (_token == null) {
      if (mounted) {
        _showSnackBar('Session expired. Please login again.', errorColor);
      }
      return;
    }
    await _loadUsers();
  }

  Future<void> _loadUsers({int page = 1, bool showLoading = true}) async {
    if (_token == null) return;

    if (showLoading) {
      setState(() => isLoading = true);
    }

    try {
      final response = await ApiService.getUsers(
        token: _token!,
        page: page,
        perPage: 10,
        search: searchQuery,
      );

      if (response['status'] == true) {
        final data = response['data'] ?? {};

        setState(() {
          users = (data['users'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          totalPages = data['total_pages'] ?? 1;
          currentPage = data['page'] ?? 1;
          totalUsers = data['total'] ?? 0;
          isLoading = false;
          isRefreshing = false;
        });
      } else {
        _handleError(response['message'] ?? 'Failed to load users');
      }
    } catch (e) {
      _handleError('Error: $e');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      _showSnackBar(message, errorColor);
      setState(() {
        users = [];
        totalUsers = 0;
        totalPages = 1;
        currentPage = 1;
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _toggleUserStatus(int userId, String currentStatus) async {
    if (_token == null) return;

    try {
      final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
      final isActive = newStatus == 'active';

      final response = await ApiService.updateUserStatus(
        token: _token!,
        userId: userId,
        isActive: isActive,
      );

      if (response['status'] == true) {
        setState(() {
          users = users.map((user) {
            if (user['id'] == userId) {
              return {...Map<String, dynamic>.from(user), 'status': newStatus};
            }
            return user;
          }).toList();
        });

        _showSnackBar(
          'User status updated to ${newStatus.toUpperCase()}',
          successColor,
        );
      } else {
        _showSnackBar(
          response['message'] ?? 'Failed to update user status',
          errorColor,
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', errorColor);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _buildUserDetailCard(user),
      ),
    );
  }

  Widget _buildUserDetailCard(Map<String, dynamic> user) {
    final isAdmin = user['role'] == 'admin';
    final isActive = user['status'] == 'active';
    final email = user['email'] ?? '';
    final name = user['name'] ?? 'User';
    final createdAt = user['create_at'] != null
        ? _formatDateTime(user['create_at'])
        : 'Unknown';
    final updatedAt = user['update_at'] != null
        ? _formatDateTime(user['update_at'])
        : 'Never';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isAdmin ? primaryColor : secondaryColor,
                  isAdmin ? accentColor : secondaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAdmin ? 'ADMIN' : 'USER',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isActive
                                      ? Icons.circle
                                      : Icons.circle_outlined,
                                  size: 10,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'ACTIVE' : 'INACTIVE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildDetailItem(
                  icon: Icons.person_outline,
                  label: 'User ID',
                  value: user['id']?.toString() ?? 'N/A',
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  label: 'Joined Date',
                  value: createdAt,
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.update,
                  label: 'Last Updated',
                  value: updatedAt,
                ),
                const SizedBox(height: 32),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _toggleUserStatus(
                          user['id'],
                          user['status'] ?? 'active',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive
                              ? errorColor.withOpacity(0.1)
                              : successColor.withOpacity(0.1),
                          foregroundColor: isActive ? errorColor : successColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isActive ? Icons.block : Icons.check_circle,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive ? 'Deactivate' : 'Activate',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, size: 20, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Close',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final isAdmin = user['role'] == 'admin';
    final isActive = user['status'] == 'active';
    final email = user['email'] ?? '';
    final name = user['name'] ?? 'User ${user['id']}';
    final joinedDate = user['create_at'] != null
        ? _formatDate(user['create_at'])
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isAdmin ? primaryColor.withOpacity(0.2) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserDetails(user),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar with status indicator
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.1),
                            accentColor.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: isAdmin ? primaryColor : accentColor,
                        size: 30,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isActive ? successColor : errorColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Badge Row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ADMIN',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Email
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 8),

                      // Status + Date Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? successColor.withOpacity(0.1)
                                  : errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isActive ? Icons.circle : Icons.circle_outlined,
                                  size: 10,
                                  color: isActive ? successColor : errorColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? successColor : errorColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Joined Date
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 13,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                joinedDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Switch
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: isActive,
                    onChanged: (value) => _toggleUserStatus(
                      user['id'],
                      user['status'] ?? 'active',
                    ),
                    activeThumbColor: Colors.white,
                    inactiveThumbColor: Colors.white,
                    activeTrackColor: successColor.withOpacity(0.5),
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return successColor;
                        }
                        return errorColor;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => searchQuery = value);
            _searchTimer?.cancel();
            _searchTimer = Timer(const Duration(milliseconds: 500), () {
              _loadUsers(page: 1);
            });
          },
          decoration: InputDecoration(
            hintText: 'Search users by name or email...',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            prefixIcon: Icon(Icons.search, color: primaryColor, size: 22),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => searchQuery = '');
                      _loadUsers(page: 1);
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          style: TextStyle(color: textPrimary, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final activeCount = users.where((u) => u['status'] == 'active').length;
    final adminCount = users.where((u) => u['role'] == 'admin').length;
    final inactiveCount = totalUsers - activeCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.08),
              accentColor.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              'Total Users',
              totalUsers.toString(),
              Icons.people_outline,
              primaryColor,
            ),
            _buildStatItem(
              'Active',
              activeCount.toString(),
              Icons.check_circle_outline,
              successColor,
            ),
            _buildStatItem(
              'Inactive',
              inactiveCount.toString(),
              Icons.pause_circle_outline,
              warningColor,
            ),
            _buildStatItem(
              'Admins',
              adminCount.toString(),
              Icons.admin_panel_settings_outlined,
              secondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
          const SizedBox(height: 20),
          Text(
            'Loading users...',
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 70,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              searchQuery.isEmpty ? 'No Users Found' : 'No Results Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              searchQuery.isEmpty
                  ? 'There are no users in the system yet.'
                  : 'No users found for "$searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            if (searchQuery.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => searchQuery = '');
                  _loadUsers(page: 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.clear_all, size: 20),
                label: const Text('Clear Search'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return RefreshIndicator(
      color: primaryColor,
      backgroundColor: backgroundColor,
      displacement: 40,
      onRefresh: () => _loadUsers(page: 1, showLoading: false),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 100,
        ),
        itemCount: users.length + (currentPage < totalPages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == users.length && currentPage < totalPages) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            );
          }
          return _buildUserCard(users[index], index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, size: 24),
            onPressed: _token != null ? _showAddUserDialog : null,
            tooltip: 'Add New User',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: () {
              setState(() => isRefreshing = true);
              _loadUsers(page: 1);
            },
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (isRefreshing)
            LinearProgressIndicator(
              color: primaryColor,
              backgroundColor: primaryColor.withOpacity(0.1),
              minHeight: 2,
            ),
          _buildSearchBar(),
          _buildStatsCard(),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading && users.isEmpty
                ? _buildLoadingIndicator()
                : users.isEmpty
                    ? _buildEmptyState()
                    : _buildUserList(),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _roleController = TextEditingController(text: 'user');
    final _statusController = TextEditingController(text: 'active');

    bool _isLoading = false;
    String? _errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.person_add, color: primaryColor),
                  const SizedBox(width: 12),
                  const Text('Add New User'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: errorColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: errorColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: errorColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: textSecondary),
                          prefixIcon: Icon(Icons.person, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        style: TextStyle(color: textPrimary),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(color: textSecondary),
                          prefixIcon: Icon(Icons.email, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        style: TextStyle(color: textPrimary),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: textSecondary),
                          prefixIcon: Icon(Icons.lock, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        style: TextStyle(color: textPrimary),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Role Dropdown
                      DropdownButtonFormField<String>(
                        value: _roleController.text,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          labelStyle: TextStyle(color: textSecondary),
                          prefixIcon: Icon(Icons.work, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        style: TextStyle(color: textPrimary),
                        items: ['user', 'admin']
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _roleController.text = value ?? 'user';
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        value: _statusController.text,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: TextStyle(color: textSecondary),
                          prefixIcon: Icon(Icons.toggle_on, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        style: TextStyle(color: textPrimary),
                        items: ['active', 'inactive']
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _statusController.text = value ?? 'active';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });

                            try {
                              final Map<String, dynamic> userData = {
                                'name': _nameController.text.trim(),
                                'email': _emailController.text.trim(),
                                'password': _passwordController.text,
                                'role': _roleController.text,
                                'status': _statusController.text,
                              };

                              final response = await ApiService.createUser(
                                token: _token!,
                                userData: userData,
                              );

                              if (response['status'] == true) {
                                if (mounted) {
                                  Navigator.pop(context);
                                  _showSnackBar(
                                    response['message'] ??
                                        'User created successfully',
                                    successColor,
                                  );
                                  _loadUsers(page: 1);
                                }
                              } else {
                                setState(() {
                                  _errorMessage =
                                      response['message'] ??
                                          'Failed to create user';
                                  _isLoading = false;
                                });
                              }
                            } catch (e) {
                              setState(() {
                                _errorMessage = 'Error: ${e.toString()}';
                                _isLoading = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create User'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}