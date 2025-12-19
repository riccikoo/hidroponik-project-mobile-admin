import 'package:flutter/material.dart';
import '../services/shared.dart';
import '../services/api.dart';
import '../models/message_model.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final Color darkGreen = const Color(0xFF456028);
  final Color mediumGreen = const Color(0xFF94A65E);
  final Color lightGreen = const Color(0xFFDDDDA1);

  List<AdminMessage> _messages = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _token;
  String _filter = 'all'; // 'all', 'unread', 'read'
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      _token = await SharedService.getToken();
      if (_token == null || _token!.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Load messages
      final messages = await ApiService.getAdminMessages(_token!);

      // Calculate unread count from messages
      final unreadCount = messages.where((msg) => !msg.isRead).length;

      setState(() {
        _messages = messages;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load messages: ${e.toString()}';
        _messages = [];
        _unreadCount = 0;
      });
    }
  }

  Future<void> _markAsRead(int messageId) async {
    try {
      if (_token != null) {
        final success = await ApiService.markAdminMessageAsRead(
          _token!,
          messageId,
        );
        if (success) {
          // Update local message state
          setState(() {
            final index = _messages.indexWhere((msg) => msg.id == messageId);
            if (index != -1) {
              _messages[index] = _messages[index].copyWith(isRead: true);
              // Update unread count
              _unreadCount = _messages.where((msg) => !msg.isRead).length;
            }
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message marked as read'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error marking as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark message as read'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    try {
      if (_token != null) {
        final success = await ApiService.deleteAdminMessage(_token!, messageId);
        if (success) {
          // Remove message from local list
          final removedMessage = _messages.firstWhere(
            (msg) => msg.id == messageId,
            orElse: () => AdminMessage(),
          );

          setState(() {
            _messages.removeWhere((msg) => msg.id == messageId);
            // Update unread count if the message was unread
            if (!removedMessage.isRead) {
              _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
            }
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<AdminMessage> get _filteredMessages {
    switch (_filter) {
      case 'unread':
        return _messages.where((msg) => !msg.isRead).toList();
      case 'read':
        return _messages.where((msg) => msg.isRead).toList();
      default:
        return _messages;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Messages', style: TextStyle(color: Colors.white)),
            if (_unreadCount > 0) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
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
        backgroundColor: darkGreen,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // Filter dropdown
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _filter = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inbox, color: darkGreen),
                    SizedBox(width: 8),
                    Text('All Messages'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'unread',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Unread Only'),
                    if (_unreadCount > 0) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_unreadCount',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Read Only'),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.filter_list, color: Colors.white),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadMessages();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(darkGreen),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Failed to Load Messages',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMessages,
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildMessageList();
  }

  Widget _buildMessageList() {
    if (_filteredMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              _filter == 'all'
                  ? 'No messages yet'
                  : _filter == 'unread'
                  ? 'No unread messages'
                  : 'No read messages',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All messages from users will appear here',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      color: darkGreen,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredMessages.length,
        itemBuilder: (context, index) {
          final message = _filteredMessages[index];
          final isUnread = !message.isRead;

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            color: isUnread ? Colors.blue.shade50 : null,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUnread ? Colors.blue.shade100 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnread ? Icons.mark_email_unread : Icons.mark_email_read,
                  color: isUnread ? Colors.blue : Colors.grey,
                  size: 20,
                ),
              ),
              title: Text(
                message.message ?? 'No Message',
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  color: isUnread ? darkGreen : Colors.grey.shade700,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          message.sender?.name ?? 'Unknown User',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          message.sender?.email ?? 'No Email',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        _formatDate(message.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Spacer(),
                      if (isUnread)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'UNREAD',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'read' && isUnread) {
                    _markAsRead(message.id!);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(message);
                  }
                },
                itemBuilder: (context) => [
                  if (isUnread)
                    PopupMenuItem(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Mark as Read'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                icon: Icon(Icons.more_vert, color: Colors.grey),
              ),
              onTap: () {
                _showMessageDetail(message);
              },
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(AdminMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message.id!);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMessageDetail(AdminMessage message) {
    final isUnread = !message.isRead;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.message, color: darkGreen),
                SizedBox(width: 8),
                Text('Message Detail'),
                if (isUnread) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    color: Colors.grey.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message Content',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            message.message ?? 'No message content',
                            style: TextStyle(fontSize: 16, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(height: 1),
                  SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.person,
                    title: 'From',
                    value: message.sender?.name ?? 'Unknown User',
                  ),
                  SizedBox(height: 8),
                  _buildDetailItem(
                    icon: Icons.email,
                    title: 'Email',
                    value: message.sender?.email ?? 'No Email',
                  ),
                  SizedBox(height: 8),
                  _buildDetailItem(
                    icon: Icons.calendar_today,
                    title: 'Date',
                    value: _formatDate(message.timestamp),
                  ),
                  SizedBox(height: 8),
                  _buildDetailItem(
                    icon: Icons.circle,
                    title: 'Status',
                    value: isUnread ? 'Unread' : 'Read',
                    valueColor: isUnread ? Colors.orange : Colors.green,
                  ),
                  SizedBox(height: 8),
                  _buildDetailItem(
                    icon: Icons.info_outline,
                    title: 'Message ID',
                    value: message.id?.toString() ?? 'N/A',
                  ),
                ],
              ),
            ),
            actions: [
              if (isUnread)
                ElevatedButton.icon(
                  onPressed: () {
                    _markAsRead(message.id!);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Message marked as read'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: Icon(Icons.check_circle),
                  label: Text('Mark as Read'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
