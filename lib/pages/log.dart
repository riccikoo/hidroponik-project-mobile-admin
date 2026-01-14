import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/shared.dart';
import 'package:intl/intl.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  // Modern Color Palette
  final Color primaryColor = const Color(0xFF4361EE); // Modern blue
  final Color secondaryColor = const Color(0xFF3A0CA3); // Dark blue
  final Color accentColor = const Color(0xFF4CC9F0); // Light blue
  final Color successColor = const Color(0xFF06D6A0); // Green
  final Color warningColor = const Color(0xFFFFD166); // Yellow
  final Color errorColor = const Color(0xFFEF476F); // Red
  final Color backgroundColor = const Color(0xFFF8F9FF); // Light background
  final Color cardColor = Colors.white;
  final Color textPrimary = const Color(0xFF2B2D42);
  final Color textSecondary = const Color(0xFF8D99AE);
  final Color borderColor = const Color(0xFFE9ECEF);

  static const String baseUrl =
      'https://uncollapsable-overfly-blaine.ngrok-free.dev/api';
  String? _token;

  List<dynamic> logs = [];
  bool isLoading = true;
  String selectedFilter = 'all'; // all, info, warning, error
  DateTime? selectedDate;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _token = await SharedService.getToken();
    await _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/logs'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            logs = data['data'];
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading logs: $e');
    }

    // Fallback dummy data
    _useDummyData();
  }

  void _useDummyData() {
    setState(() {
      logs = [
        {
          'id': 1,
          'level': 'INFO',
          'message': 'Admin dashboard accessed',
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 5))
              .toIso8601String(),
          'user': 'admin',
          'source': 'dashboard',
        },
        {
          'id': 2,
          'level': 'INFO',
          'message': 'Sensor data updated successfully',
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 10))
              .toIso8601String(),
          'source': 'sensor',
          'details': 'Temperature: 25.5°C, Humidity: 65%',
        },
        {
          'id': 3,
          'level': 'WARNING',
          'message': 'High temperature detected',
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 15))
              .toIso8601String(),
          'source': 'dht_temp',
          'details': 'Temperature reached 32.5°C',
        },
        {
          'id': 4,
          'level': 'INFO',
          'message': 'System backup completed',
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 30))
              .toIso8601String(),
          'source': 'system',
          'details': 'Backup size: 15.2 MB',
        },
        {
          'id': 5,
          'level': 'ERROR',
          'message': 'Database connection timeout',
          'timestamp': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
          'source': 'database',
          'details': 'Retrying connection...',
        },
        {
          'id': 6,
          'level': 'INFO',
          'message': 'User login successful',
          'timestamp': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
          'user': 'admin',
          'source': 'auth',
        },
        {
          'id': 7,
          'level': 'WARNING',
          'message': 'Low water level detected',
          'timestamp': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
          'source': 'ultrasonic',
          'details': 'Water level: 15%',
        },
        {
          'id': 8,
          'level': 'ERROR',
          'message': 'Sensor calibration failed',
          'timestamp': DateTime.now()
              .subtract(const Duration(hours: 4))
              .toIso8601String(),
          'source': 'sensor',
          'details': 'PH sensor requires recalibration',
        },
        {
          'id': 9,
          'level': 'INFO',
          'message': 'System maintenance completed',
          'timestamp': DateTime.now()
              .subtract(const Duration(hours: 5))
              .toIso8601String(),
          'source': 'system',
          'details': 'All systems running optimally',
        },
      ];
      isLoading = false;
    });
  }

  List<dynamic> get filteredLogs {
    List<dynamic> filtered = List.from(logs);

    if (selectedFilter != 'all') {
      filtered = filtered
          .where(
            (log) => log['level'].toLowerCase() == selectedFilter.toLowerCase(),
          )
          .toList();
    }

    if (selectedDate != null) {
      filtered = filtered.where((log) {
        final logDate = DateTime.parse(log['timestamp']);
        return logDate.year == selectedDate!.year &&
            logDate.month == selectedDate!.month &&
            logDate.day == selectedDate!.day;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((log) {
        return log['message'].toString().toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            log['source'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
            log['level'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                );
      }).toList();
    }

    // Sort by timestamp (newest first)
    filtered.sort((a, b) {
      return DateTime.parse(b['timestamp']).compareTo(
        DateTime.parse(a['timestamp']),
      );
    });

    return filtered;
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return errorColor;
      case 'WARNING':
        return warningColor;
      case 'INFO':
        return primaryColor;
      default:
        return textSecondary;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Icons.error_outline_rounded;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'INFO':
        return Icons.info_outline_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  String _formatDateTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return DateFormat('MMM dd, HH:mm').format(date);
      }
    } catch (e) {
      return timestamp;
    }
  }

  void _showLogDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getLevelColor(log['level']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getLevelIcon(log['level']),
                color: _getLevelColor(log['level']),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Log Details',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Level', log['level'], _getLevelColor(log['level'])),
              _detailRow('Message', log['message']),
              _detailRow('Timestamp', _formatDateTime(log['timestamp'])),
              if (log['source'] != null) _detailRow('Source', log['source']),
              if (log['user'] != null) _detailRow('User', log['user']),
              if (log['details'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Details',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log['details'],
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: textSecondary,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      selectedFilter = 'all';
      selectedDate = null;
      searchQuery = '';
    });
  }

  void _exportLogs() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export functionality coming soon',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelCounts = {
      'all': logs.length,
      'info': logs.where((log) => log['level'] == 'INFO').length,
      'warning': logs.where((log) => log['level'] == 'WARNING').length,
      'error': logs.where((log) => log['level'] == 'ERROR').length,
    };

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Activity Logs',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download_rounded, color: primaryColor),
            onPressed: _exportLogs,
            tooltip: 'Export logs',
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: _loadLogs,
            tooltip: 'Refresh logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: cardColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  hintStyle: TextStyle(color: textSecondary),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: textSecondary),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: textSecondary),
                          onPressed: () {
                            setState(() => searchQuery = '');
                          },
                        )
                      : null,
                ),
                style: TextStyle(color: textPrimary),
              ),
            ),
          ),

          // Filters Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Column(
              children: [
                // Level Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', 'all', levelCounts['all']!),
                      _filterChip('Info', 'info', levelCounts['info']!),
                      _filterChip(
                        'Warning',
                        'warning',
                        levelCounts['warning']!,
                      ),
                      _filterChip('Error', 'error', levelCounts['error']!),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Date Filter
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                selectedDate != null
                                    ? DateFormat('MMM dd, yyyy').format(selectedDate!)
                                    : 'Filter by date',
                                style: TextStyle(
                                  color: selectedDate != null
                                      ? textPrimary
                                      : textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              if (selectedDate != null)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedDate = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: errorColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: errorColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (selectedFilter != 'all' || selectedDate != null || searchQuery.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.clear_all_rounded, color: errorColor),
                          onPressed: _clearFilters,
                          tooltip: 'Clear all filters',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Total Logs',
                    logs.length.toString(),
                    Icons.list_alt_rounded,
                    primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Today',
                    logs.where((log) {
                      final logDate = DateTime.parse(log['timestamp']);
                      final today = DateTime.now();
                      return logDate.year == today.year &&
                          logDate.month == today.month &&
                          logDate.day == today.day;
                    }).length.toString(),
                    Icons.today_rounded,
                    accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Errors',
                    levelCounts['error']!.toString(),
                    Icons.error_outline_rounded,
                    errorColor,
                  ),
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          'Loading activity logs...',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 80,
                              color: textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No logs found',
                              style: TextStyle(
                                fontSize: 18,
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or search',
                              style: TextStyle(
                                color: textSecondary,
                              ),
                            ),
                            if (selectedFilter != 'all' ||
                                selectedDate != null ||
                                searchQuery.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: ElevatedButton(
                                  onPressed: _clearFilters,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Clear all filters'),
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        color: primaryColor,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredLogs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            final levelColor = _getLevelColor(log['level']);

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showLogDetails(log),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: levelColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _getLevelIcon(log['level']),
                                            color: levelColor,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log['message'],
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        levelColor.withOpacity(
                                                            0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    log['level'],
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: levelColor,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                if (log['source'] != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: primaryColor
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      log['source'],
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: primaryColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                const Spacer(),
                                                Text(
                                                  _formatDateTime(
                                                      log['timestamp']),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count) {
    final isSelected = selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : primaryColor,
                ),
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => selectedFilter = value);
        },
        backgroundColor: backgroundColor,
        selectedColor: primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? primaryColor : borderColor,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}