import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import '../models/message_model.dart';
import '../models/chatthread.dart';

class ChatRoomDetailPage extends StatefulWidget {
  final ChatThread thread;
  final String token;

  const ChatRoomDetailPage({
    super.key,
    required this.thread,
    required this.token,
  });

  @override
  State<ChatRoomDetailPage> createState() => _ChatRoomDetailPageState();
}

class _ChatRoomDetailPageState extends State<ChatRoomDetailPage> {
  // Color theme - Green theme
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF81C784);
  final Color accentGreen = const Color(0xFF4CAF50);
  final Color darkGreen = const Color(0xFF1B5E20);
  final Color backgroundGreen = const Color(0xFFE8F5E9);
  final Color userMessageBg = const Color(0xFFF5F5F5);
  final Color adminMessageBg = const Color(0xFF4CAF50);

  // Controllers and state
  late TextEditingController _replyController;
  bool _isReplying = false;
  bool _isLoadingMessages = true;
  List<AdminMessage> _allMessages = [];

  // Admin data
  late int _adminId;
  late String _adminName;
  late String _adminEmail;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
    _loadAdminData().then((_) {
      _loadFullConversation();
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  // Di _loadAdminData():
  Future<void> _loadAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _adminId = prefs.getInt('adminId') ?? 0; // ✅ Ini sudah benar

      // Tapi jika adminId null, cek juga String
      if (_adminId == 0) {
        final adminIdString = prefs.getString('adminId');
        if (adminIdString != null) {
          try {
            _adminId = int.parse(adminIdString);
          } catch (e) {
            _adminId = 0;
          }
        }
      }

      _adminName = prefs.getString('adminName') ?? 'Admin';
      _adminEmail = prefs.getString('adminEmail') ?? '';

      print('👤 Admin loaded - ID: $_adminId, Name: $_adminName');

      if (_adminId == 0) {
        print('⚠️ Warning: Admin ID is 0. Check login data.');
      }
    } catch (e) {
      print('❌ Error loading admin data: $e');
      _adminId = 0;
      _adminName = 'Admin';
      _adminEmail = '';
    }
  }

  Future<void> _loadFullConversation() async {
    setState(() => _isLoadingMessages = true);

    try {
      final result = await ApiService.getThreadMessages(
        token: widget.token,
        userId: widget.thread.senderId,
        threadId: widget.thread.threadId,
      );

      print('📦 API Response for thread ${widget.thread.threadId}: $result');

      if (result['success'] == true && result['data'] != null) {
        final messagesData = result['data']['messages'] as List<dynamic>? ?? [];

        print('📨 Found ${messagesData.length} messages');

        // Debug: print semua message
        for (var i = 0; i < messagesData.length; i++) {
          print('Message $i: ${messagesData[i]}');
        }

        final messages = messagesData.map((m) {
          try {
            return AdminMessage.fromJson(m);
          } catch (e) {
            print('❌ Error parsing message: $e, data: $m');
            return AdminMessage(
              id: 0,
              message: 'Error loading message',
              senderId: 0,
              receiverId: widget.thread.senderId,
              timestamp: DateTime.now(),
              isRead: true,
            );
          }
        }).toList();

        setState(() {
          _allMessages = messages;
          _allMessages.sort(
            (a, b) => (a.timestamp ?? DateTime.now()).compareTo(
              b.timestamp ?? DateTime.now(),
            ),
          );
          widget.thread.unreadCount = 0;

          if (_allMessages.isNotEmpty) {
            final lastMessage = _allMessages.last;
            widget.thread.lastMessageTime =
                lastMessage.timestamp ?? DateTime.now();
            widget.thread.lastMessageId = lastMessage.id;
          }

          print('✅ Loaded ${_allMessages.length} messages');
          print(
            '🔍 First message: ${_allMessages.isNotEmpty ? _allMessages.first.message : "No messages"}',
          );
        });

        // Mark as read
        await _markAllAsRead();
      } else {
        print('❌ Failed to load conversation: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
        await _loadRepliesFallback();
      }
    } catch (e) {
      print('❌ Error loading conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading conversation: $e'),
          backgroundColor: Colors.red,
        ),
      );
      await _loadRepliesFallback();
    } finally {
      setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _loadRepliesFallback() async {
    if (widget.thread.lastMessageId == null) return;

    try {
      final replies = await ApiService.getMessageReplies(
        widget.token,
        widget.thread.lastMessageId!,
      );

      setState(() {
        _allMessages.clear();
        if (widget.thread.messages.isNotEmpty) {
          _allMessages.addAll(widget.thread.messages);
        }
        _allMessages.addAll(
          replies.map((r) => AdminMessage.fromJson(r)).toList(),
        );
        _allMessages.sort(
          (a, b) => (a.timestamp ?? DateTime.now()).compareTo(
            b.timestamp ?? DateTime.now(),
          ),
        );
      });
    } catch (e) {
      print('❌ Fallback also failed: $e');
    }
  }

  Future<void> _sendReply() async {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validasi admin ID
    if (_adminId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: Admin not authenticated properly. Please login again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isReplying = true);

      // Create optimistic message with REAL admin ID
      final optimisticMessage = AdminMessage(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        message: replyText,
        senderId: _adminId, // ✅ Gunakan admin ID yang sesungguhnya
        receiverId: widget.thread.senderId,
        isRead: true,
        timestamp: DateTime.now(),
        sender: Sender(id: _adminId, name: _adminName, email: _adminEmail),
      );

      print('📤 Sending message as admin ID: $_adminId');

      // Add optimistic message to UI
      setState(() {
        _allMessages.add(optimisticMessage);
      });

      _replyController.clear();

      // Send to server
      bool success = false;

      // Coba kirim dengan threadId jika ada
      success = await ApiService.sendMessageToThread(
        token: widget.token,
        threadId: widget.thread.threadId,
        message: replyText,
        senderId: _adminId, // ✅ Kirim senderId
      );

      if (success) {
        print('✅ Message sent successfully');

        // Refresh conversation untuk mendapatkan data real dari server
        await _loadFullConversation();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Message sent successfully'),
              ],
            ),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        // Remove optimistic message if failed
        setState(() {
          _allMessages.removeWhere((msg) => msg.id == optimisticMessage.id);
        });

        print('❌ Failed to send message via API');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Failed to send message'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isReplying = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      // Update local state
      setState(() {
        for (var msg in _allMessages.where((m) => !_isAdminMessage(m))) {
          msg.isRead = true;
        }
        widget.thread.unreadCount = 0;
      });

      // Mark on server if we have message IDs
      final unreadMessages = _allMessages
          .where((m) => !_isAdminMessage(m) && !m.isRead)
          .toList();

      for (var msg in unreadMessages) {
        if (msg.id != null) {
          await ApiService.markAdminMessageAsRead(widget.token, msg.id!);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.mark_email_read, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('All messages marked as read'),
            ],
          ),
          backgroundColor: primaryGreen,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  bool _isAdminMessage(AdminMessage msg) {
    // ✅ Gunakan adminId yang sudah diload
    return msg.senderId == _adminId ||
        (msg.sender != null && msg.sender!.id == _adminId) ||
        (_adminEmail.isNotEmpty && msg.sender?.email == _adminEmail) ||
        (msg.sender?.email?.contains('admin') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.thread.unreadCount > 0;

    return Scaffold(
      backgroundColor: backgroundGreen,
      appBar: AppBar(
        title: Text(
          widget.thread.senderName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryGreen,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        actions: [
          if (hasUnread)
            Container(
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(2),
              child: IconButton(
                icon: Icon(Icons.mark_email_read, size: 20),
                onPressed: _markAllAsRead,
                tooltip: 'Mark all as read',
                color: Colors.white,
              ),
            ),
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, size: 22),
              onPressed: _loadFullConversation,
              tooltip: 'Refresh chat',
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // User info card
          Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [lightGreen, accentGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.thread.senderName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.thread.senderName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: darkGreen,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.thread.senderEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Total Messages: ${_allMessages.length}',
                        style: TextStyle(
                          fontSize: 11,
                          color: lightGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Admin ID: $_adminId',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (hasUnread)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.thread.unreadCount} unread',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoadingMessages)
            Container(
              margin: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Loading conversation...',
                    style: TextStyle(
                      color: darkGreen.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: _allMessages.isEmpty && !_isLoadingMessages
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
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
                          child: Icon(
                            Icons.forum_outlined,
                            size: 50,
                            color: lightGreen,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            color: darkGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Send your first message to ${widget.thread.senderName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.all(12),
                    itemCount: _allMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _allMessages[_allMessages.length - 1 - index];
                      return _buildChatBubble(msg);
                    },
                  ),
          ),

          // Reply input section
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            decoration: InputDecoration(
                              hintText: 'Type your reply...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                            ),
                            maxLines: 3,
                            minLines: 1,
                            style: TextStyle(fontSize: 14, color: darkGreen),
                            onSubmitted: (_) {
                              if (!_isReplying) _sendReply();
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.attach_file, color: lightGreen),
                          onPressed: () {
                            // TODO: Implement file attachment
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryGreen, accentGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.4),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _isReplying
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.send, color: Colors.white, size: 22),
                          onPressed: _sendReply,
                          tooltip: 'Send as Admin (ID: $_adminId)',
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(AdminMessage msg) {
    // Gunakan fungsi _isAdminMessage yang sudah diperbaiki
    final isAdmin = _isAdminMessage(msg);

    print(
      '💬 Building bubble - Message: "${msg.message}", SenderId: ${msg.senderId}, IsAdmin: $isAdmin, AdminId: $_adminId',
    );

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAdmin
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isAdmin)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                widget.thread.senderName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          SizedBox(width: 8),

          Flexible(
            child: Column(
              crossAxisAlignment: isAdmin
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isAdmin)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.thread.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdmin ? adminMessageBg : userMessageBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sender name for admin messages
                      if (isAdmin && msg.sender != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            msg.sender?.name ?? 'Admin',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),

                      Text(
                        msg.message ?? '[No message]',
                        style: TextStyle(
                          color: isAdmin ? Colors.white : Colors.black87,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(msg.timestamp ?? DateTime.now()),
                            style: TextStyle(
                              fontSize: 10,
                              color: isAdmin
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(width: 8),
                          if (isAdmin)
                            Icon(
                              Icons.done_all,
                              size: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          if (!isAdmin && msg.isRead)
                            Icon(Icons.done_all, size: 12, color: Colors.blue),
                          if (!isAdmin && !msg.isRead)
                            Icon(Icons.done, size: 12, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 8),

          if (isAdmin)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings,
                size: 16,
                color: darkGreen,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
