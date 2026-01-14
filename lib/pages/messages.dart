import 'package:flutter/material.dart';
import '../services/shared.dart';
import '../services/api.dart';
import '../models/chatthread.dart';
import 'chat_room_detail.dart';
import 'package:intl/intl.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  // Modern Color Palette
  final Color primaryColor = const Color(0xFF4361EE); // Modern blue
  final Color secondaryColor = const Color(0xFF3A0CA3); // Dark blue
  final Color accentColor = const Color(0xFF4CC9F0); // Light blue
  final Color successColor = const Color(0xFF06D6A0); // Green
  final Color errorColor = const Color(0xFFEF476F); // Red
  final Color warningColor = const Color(0xFFFFD166); // Yellow
  final Color backgroundColor = const Color(0xFFF8F9FF); // Light background
  final Color cardColor = Colors.white;
  final Color textPrimary = const Color(0xFF2B2D42);
  final Color textSecondary = const Color(0xFF8D99AE);
  final Color borderColor = const Color(0xFFE9ECEF);

  // State
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _token;

  // Threads list
  List<ChatThread> _threads = [];
  int _totalUnread = 0;

  // Filter
  String _filter = 'all'; // 'all', 'unread', 'replied'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    try {
      setState(() => _isLoading = true);

      _token = await SharedService.getToken();
      if (_token == null) {
        throw Exception('Please login again');
      }

      final threads = await ApiService.getAllThreads(_token!);

      final totalUnread = threads.fold(
        0,
        (sum, thread) => sum + thread.unreadCount,
      );

      setState(() {
        _threads = threads;
        _totalUnread = totalUnread;
        _isLoading = false;
        _hasError = false;
      });

      print('✅ Loaded ${_threads.length} threads, $totalUnread unread');
    } catch (e) {
      print('❌ Error loading threads: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load conversations';
        _threads.clear();
        _totalUnread = 0;
      });
    }
  }

  Future<void> _markThreadAsRead(ChatThread thread) async {
    try {
      if (_token == null) return;

      setState(() {
        thread.unreadCount = 0;
        _totalUnread = _threads.fold(0, (sum, t) => sum + t.unreadCount);
      });

      for (var msg in thread.messages.where((m) => !m.isAdmin && !m.isRead)) {
        if (msg.id != null) {
          await ApiService.markAdminMessageAsRead(_token!, msg.id!);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Marked as read'),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error marking thread as read: $e');
    }
  }

  List<ChatThread> get _filteredThreads {
    List<ChatThread> filtered = List.from(_threads);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((thread) {
        return thread.senderName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            thread.senderEmail
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply type filter
    switch (_filter) {
      case 'unread':
        filtered = filtered.where((thread) => thread.unreadCount > 0).toList();
        break;
      case 'replied':
        filtered =
            filtered.where((thread) => thread.messages.any((m) => m.isAdmin)).toList();
        break;
    }

    // Sort by last message time (newest first)
    filtered.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Messages',
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
          if (_totalUnread > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: errorColor,
                shape: BoxShape.circle,
                border: Border.all(color: cardColor, width: 2),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  _totalUnread > 9 ? '9+' : _totalUnread.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, color: primaryColor),
              onPressed: _loadThreads,
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 8),
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
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(color: textSecondary),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: textSecondary),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                style: TextStyle(color: textPrimary),
              ),
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', 'all'),
                  _filterChip('Unread', 'unread'),
                  _filterChip('Replied', 'replied'),
                ],
              ),
            ),
          ),

          // Stats Card
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
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
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.forum_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conversations',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_threads.length} total • $_totalUnread unread',
                          style: TextStyle(
                            fontSize: 16,
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _totalUnread > 0
                          ? errorColor.withOpacity(0.1)
                          : successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _totalUnread > 0
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          size: 14,
                          color: _totalUnread > 0 ? errorColor : successColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _totalUnread > 0 ? '$_totalUnread new' : 'All read',
                          style: TextStyle(
                            fontSize: 12,
                            color: _totalUnread > 0 ? errorColor : successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filter = value);
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text(
              'Loading conversations...',
              style: TextStyle(
                color: textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? 'Unable to load conversations',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadThreads,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return _buildThreadsList();
  }

  Widget _buildThreadsList() {
    final threads = _filteredThreads;

    if (threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _filter == 'unread'
                    ? Icons.mark_email_unread_rounded
                    : _filter == 'replied'
                        ? Icons.reply_rounded
                        : Icons.forum_outlined,
                size: 48,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _filter == 'all'
                  ? 'No conversations yet'
                  : _filter == 'unread'
                      ? 'No unread conversations'
                      : 'No replied conversations',
              style: TextStyle(
                fontSize: 20,
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Messages from users will appear here',
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
            if (_filter != 'all' || _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filter = 'all';
                      _searchQuery = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View All Conversations'),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadThreads,
      color: primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: threads.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final thread = threads[index];
          return _buildThreadCard(thread);
        },
      ),
    );
  }

  Widget _buildThreadCard(ChatThread thread) {
    final hasUnread = thread.unreadCount > 0;
    final hasReplied = thread.messages.any((m) => m.isAdmin);
    final lastMessage = thread.messages.isNotEmpty ? thread.messages.last : null;
    final messageContent = lastMessage?.message ?? 'No messages yet';
    final isAdminReply = lastMessage?.isAdmin == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (_token != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomDetailPage(
                  thread: thread,
                  token: _token!,
                ),
              ),
            );
            await _loadThreads();
          }
        },
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with badge
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        thread.senderName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: errorColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Thread Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.senderName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: errorColor.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              '${thread.unreadCount} new',
                              style: TextStyle(
                                fontSize: 11,
                                color: errorColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      thread.senderEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isAdminReply
                                ? Icons.reply_rounded
                                : Icons.message_rounded,
                            size: 16,
                            color: isAdminReply ? successColor : primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              messageContent,
                              style: TextStyle(
                                fontSize: 13,
                                color: textPrimary,
                                fontStyle: isAdminReply
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeAgo(thread.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (hasReplied)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: successColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.reply_rounded,
                                  size: 12,
                                  color: successColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Replied',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: successColor,
                                    fontWeight: FontWeight.w600,
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
  }

  void _showDeleteDialog(ChatThread thread) {
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
                color: errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: errorColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Conversation?',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete all messages with ${thread.senderName}? This action cannot be undone.',
          style: TextStyle(
            color: textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteThread(thread);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteThread(ChatThread thread) {
    // TODO: Implement API call to delete thread
    setState(() {
      _threads.removeWhere((t) => t.senderId == thread.senderId);
      _totalUnread =
          _threads.fold(0, (sum, t) => sum + t.unreadCount);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Conversation deleted'),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';

    return DateFormat('MMM dd, yyyy').format(date);
  }
}