// buat file baru: pages/messages.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/shared.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final Color darkGreen = const Color(0xFF456028);
  final Color mediumGreen = const Color(0xFF94A65E);
  final Color lightGreen = const Color(0xFFDDDDA1);

  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _token;
  String _filter = 'all'; // 'all', 'unread', 'read'

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      _token = await SharedService.getToken();

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/user/messages'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages = data['messages'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int messageId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/messages/$messageId/read'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Refresh messages
        await _loadMessages();
      }
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/messages/$messageId'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        // Refresh messages
        await _loadMessages();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  List<dynamic> get _filteredMessages {
    switch (_filter) {
      case 'unread':
        return _messages.where((msg) => msg['read'] == false).toList();
      case 'read':
        return _messages.where((msg) => msg['read'] == true).toList();
      default:
        return _messages;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Messages'),
        backgroundColor: darkGreen,
        actions: [
          // Filter dropdown
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _filter = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All Messages')),
              PopupMenuItem(value: 'unread', child: Text('Unread Only')),
              PopupMenuItem(value: 'read', child: Text('Read Only')),
            ],
            icon: Icon(Icons.filter_list),
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadMessages),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: darkGreen))
          : _buildMessageList(),
    );
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
              'No messages found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            SizedBox(height: 8),
            Text(
              _filter == 'all'
                  ? 'All messages will appear here'
                  : 'No ${_filter} messages',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredMessages.length,
      itemBuilder: (context, index) {
        final message = _filteredMessages[index];
        final isUnread = message['read'] == false;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          color: isUnread ? Colors.blue.withValues(alpha: 0.05) : null,
          elevation: 1,
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnread
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnread ? Icons.mark_email_unread : Icons.mark_email_read,
                color: isUnread ? Colors.blue : Colors.grey,
              ),
            ),
            title: Text(
              message['subject'] ?? 'No Subject',
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                color: isUnread ? darkGreen : Colors.grey.shade700,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  message['message']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      message['user_name']?.toString() ?? 'Unknown User',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Spacer(),
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(message['timestamp']),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'read' && isUnread) {
                  _markAsRead(message['id']);
                } else if (value == 'delete') {
                  _deleteMessage(message['id']);
                }
              },
              itemBuilder: (context) => [
                if (isUnread)
                  PopupMenuItem(value: 'read', child: Text('Mark as Read')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            onTap: () {
              // Show message detail
              _showMessageDetail(message);
            },
          ),
        );
      },
    );
  }

  void _showMessageDetail(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message['subject'] ?? 'Message Detail'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message['message']?.toString() ?? '',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text(
                'From: ${message['user_name'] ?? 'Unknown User'}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                'Date: ${_formatDate(message['timestamp'])}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (message['read'] == false) SizedBox(height: 4),
              if (message['read'] == false)
                Text(
                  'Status: Unread',
                  style: TextStyle(fontSize: 14, color: Colors.orange),
                ),
            ],
          ),
        ),
        actions: [
          if (message['read'] == false)
            TextButton(
              onPressed: () {
                _markAsRead(message['id']);
                Navigator.pop(context);
              },
              child: Text('Mark as Read'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      final date = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return timestamp.toString();
    }
  }
}
