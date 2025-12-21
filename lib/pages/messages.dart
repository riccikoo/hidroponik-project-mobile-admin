import 'package:flutter/material.dart';
import '../services/shared.dart';
import '../services/api.dart';
import '../models/chatthread.dart';
import 'chat_room_detail.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  // Color theme - Green theme konsisten
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF81C784);
  final Color accentGreen = const Color(0xFF4CAF50);
  final Color darkGreen = const Color(0xFF1B5E20);
  final Color backgroundGreen = const Color(0xFFE8F5E9);

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

      // Gunakan endpoint baru getAllThreads
      final threads = await ApiService.getAllThreads(_token!);

      // Hitung total unread
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

      // Update local state
      setState(() {
        thread.unreadCount = 0;
        _totalUnread = _threads.fold(0, (sum, t) => sum + t.unreadCount);
      });

      // Mark all messages in this thread as read
      for (var msg in thread.messages.where((m) => !m.isAdmin && !m.isRead)) {
        if (msg.id != null) {
          await ApiService.markAdminMessageAsRead(_token!, msg.id!);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Marked as read'),
            ],
          ),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error marking thread as read: $e');
    }
  }

  List<ChatThread> get _filteredThreads {
    // Sort by last message time (newest first)
    final sortedThreads = List<ChatThread>.from(_threads)
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    return sortedThreads.where((thread) {
      switch (_filter) {
        case 'unread':
          return thread.unreadCount > 0;
        case 'replied':
          return thread.messages.any((m) => m.isAdmin);
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGreen,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.forum, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text(
              'Conversations',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            if (_totalUnread > 0) ...[
              SizedBox(width: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_totalUnread',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: primaryGreen,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        actions: _buildAppBarActions(),
      ),
      body: _buildBody(),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      // Filter button
      Container(
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: PopupMenuButton<String>(
          onSelected: (value) => setState(() => _filter = value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'all',
              child: Row(
                children: [
                  Icon(Icons.all_inbox, color: darkGreen, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'All Conversations',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: darkGreen,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'unread',
              child: Row(
                children: [
                  Icon(Icons.mark_email_unread, color: Colors.blue, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Unread',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  if (_totalUnread > 0) ...[
                    SizedBox(width: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_totalUnread',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuItem(
              value: 'replied',
              child: Row(
                children: [
                  Icon(Icons.reply, color: Colors.green, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Replied',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          icon: Icon(Icons.filter_list, color: Colors.white, size: 24),
        ),
      ),
      // Refresh button
      Container(
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: IconButton(
          icon: Icon(Icons.refresh, size: 24),
          onPressed: _loadThreads,
          tooltip: 'Refresh',
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Loading conversations...',
              style: TextStyle(
                color: darkGreen.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait a moment',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.error_outline, size: 40, color: Colors.red),
              ),
              SizedBox(height: 20),
              Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _errorMessage ?? 'Unable to load conversations',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: _loadThreads,
                icon: Icon(Icons.refresh, size: 20),
                label: Text('Try Again', style: TextStyle(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(
                _filter == 'unread'
                    ? Icons.mark_email_unread_outlined
                    : _filter == 'replied'
                    ? Icons.reply_outlined
                    : Icons.forum_outlined,
                size: 50,
                color: lightGreen,
              ),
            ),
            SizedBox(height: 25),
            Text(
              _filter == 'all'
                  ? 'No conversations yet'
                  : _filter == 'unread'
                  ? 'No unread conversations'
                  : 'No replied conversations',
              style: TextStyle(
                fontSize: 20,
                color: darkGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Messages from users will appear here',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            SizedBox(height: 25),
            if (_filter != 'all')
              ElevatedButton.icon(
                onPressed: () => setState(() => _filter = 'all'),
                icon: Icon(Icons.all_inbox, size: 18),
                label: Text('View All Conversations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadThreads,
      color: primaryGreen,
      displacement: 40,
      child: ListView.separated(
        padding: EdgeInsets.all(12),
        itemCount: threads.length,
        separatorBuilder: (context, index) => SizedBox(height: 8),
        itemBuilder: (context, index) {
          final thread = threads[index];
          return _buildThreadCard(thread); // Panggil method yang benar
        },
      ),
    );
  }

  Widget _buildThreadCard(ChatThread thread) {
    final hasUnread = thread.unreadCount > 0;
    final hasReplied = thread.messages.any((m) => m.isAdmin); // ✅ Di sini
    final lastMessage = thread.messages.isNotEmpty
        ? thread.messages.last
        : null;
    final messageContent =
        lastMessage?.message ?? 'No messages yet'; // ✅ Di sini

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4),
      elevation: hasUnread ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () async {
          if (_token != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChatRoomDetailPage(thread: thread, token: _token!),
              ),
            );

            // Refresh if needed
            if (result == true) {
              await _loadThreads();
            }
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: hasUnread
                ? LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasUnread
                        ? [Colors.blue.shade300, Colors.blue.shade500]
                        : [lightGreen, accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (hasUnread ? Colors.blue : primaryGreen)
                          .withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    thread.senderName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),

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
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: hasUnread
                                  ? Colors.blue.shade800
                                  : darkGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red, Colors.orange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${thread.unreadCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      thread.senderEmail,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.message,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              messageContent.length > 50
                                  ? '${messageContent.substring(0, 50)}...'
                                  : messageContent,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontStyle: lastMessage?.isAdmin == true
                                    ? FontStyle.italic
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatTimeAgo(thread.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Spacer(),
                        if (hasReplied)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.reply,
                                  size: 12,
                                  color: Colors.green.shade700,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Replied',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
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

              // Action Menu
              SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'mark_read' && hasUnread) {
                    await _markThreadAsRead(thread);
                  } else if (value == 'delete') {
                    _showDeleteDialog(thread);
                  }
                },
                itemBuilder: (context) => [
                  if (hasUnread)
                    PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(
                            Icons.mark_email_read,
                            size: 18,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Mark as Read',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
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
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text(
              'Delete Conversation?',
              style: TextStyle(color: darkGreen, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Delete all messages with ${thread.senderName}? This action cannot be undone.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteThread(thread);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteThread(ChatThread thread) {
    // TODO: Implement API call to delete thread
    setState(() {
      _threads.removeWhere((t) => t.senderId == thread.senderId);
      _totalUnread = _threads.fold(0, (sum, t) => sum + t.unreadCount);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Conversation deleted'),
          ],
        ),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

    return '${date.day}/${date.month}/${date.year}';
  }
}
