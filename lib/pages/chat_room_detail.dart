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
  // Modern Color Palette
  final Color primaryColor = const Color(0xFF4361EE); // Modern blue
  final Color secondaryColor = const Color(0xFF3A0CA3); // Dark blue
  final Color accentColor = const Color(0xFF4CC9F0); // Light blue
  final Color successColor = const Color(0xFF06D6A0); // Green
  final Color errorColor = const Color(0xFFEF476F); // Red
  final Color backgroundColor = const Color(0xFFF8F9FF); // Light background
  final Color cardColor = Colors.white;
  final Color textPrimary = const Color(0xFF2B2D42);
  final Color textSecondary = const Color(0xFF8D99AE);
  final Color borderColor = const Color(0xFFE9ECEF);
  final Color userMessageColor = const Color(0xFFE3F2FD); // Light blue
  final Color adminMessageColor = const Color(0xFF4361EE); // Primary blue

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

  Future<void> _loadAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _adminId = prefs.getInt('adminId') ?? 0;

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

        for (var i = 0; i < messagesData.length; i++) {
          print('Message $i: ${messagesData[i]}');
        }

        final List<AdminMessage> messages = messagesData
            .whereType<AdminMessage>()
            .toList();

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

        await _markAllAsRead();
      } else {
        print('❌ Failed to load conversation: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: ${result['message']}'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadRepliesFallback();
      }
    } catch (e) {
      print('❌ Error loading conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading conversation: $e'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
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
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_adminId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin not authenticated'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() => _isReplying = true);

      // Optimistic message
      final optimisticMessage = AdminMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        message: replyText,
        senderId: _adminId,
        receiverId: widget.thread.senderId,
        isRead: true,
        timestamp: DateTime.now(),
        sender: Sender(id: _adminId, name: _adminName, email: _adminEmail),
      );

      setState(() {
        _allMessages.add(optimisticMessage);
      });

      _replyController.clear();

      int? _getLastUserMessageId() {
        final userMessages = _allMessages
            .where((m) => !_isAdminMessage(m))
            .toList();

        if (userMessages.isEmpty) return null;

        userMessages.sort(
          (a, b) => (b.timestamp ?? DateTime.now()).compareTo(
            a.timestamp ?? DateTime.now(),
          ),
        );

        return userMessages.first.id;
      }

      final lastUserMessageId = _getLastUserMessageId();

      if (lastUserMessageId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot reply: no user message found'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      print('📤 Replying to USER message ID: $lastUserMessageId');

      final success = await ApiService.sendReply(
        token: widget.token,
        messageId: lastUserMessageId,
        content: replyText,
      );

      if (!success) {
        setState(() {
          _allMessages.removeWhere((m) => m.id == optimisticMessage.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reply'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await _loadFullConversation();
    } catch (e) {
      print('❌ Reply error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isReplying = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      setState(() {
        for (var msg in _allMessages.where((m) => !_isAdminMessage(m))) {
          msg.isRead = true;
        }
        widget.thread.unreadCount = 0;
      });

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
          backgroundColor: successColor,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  bool _isAdminMessage(AdminMessage msg) {
    return msg.senderId == _adminId ||
        (msg.sender != null && msg.sender!.id == _adminId) ||
        (_adminEmail.isNotEmpty && msg.sender?.email == _adminEmail) ||
        (msg.sender?.email?.contains('admin') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.thread.unreadCount > 0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.thread.senderName,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              'Online',
              style: TextStyle(
                color: successColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, color: primaryColor),
              onPressed: _loadFullConversation,
              tooltip: 'Refresh chat',
            ),
          ),
          SizedBox(width: 8),
          if (hasUnread)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.mark_email_read, color: errorColor),
                onPressed: _markAllAsRead,
                tooltip: 'Mark all as read',
              ),
            ),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // User info card
          Container(
            margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: EdgeInsets.all(16),
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
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.thread.senderName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.thread.senderName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.thread.senderEmail,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Messages: ${_allMessages.length}',
                              style: TextStyle(
                                fontSize: 11,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          if (hasUnread)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${widget.thread.unreadCount} unread',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: errorColor,
                                  fontWeight: FontWeight.w600,
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
          ),

          // Loading indicator
          if (_isLoadingMessages)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading conversation...',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Chat messages
          if (!_isLoadingMessages)
            Expanded(
              child: _allMessages.isEmpty
                  ? Center(
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
                              Icons.forum_outlined,
                              size: 48,
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Start a conversation',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Send your first message to ${widget.thread.senderName}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.all(16),
                      itemCount: _allMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _allMessages[_allMessages.length - 1 - index];
                        return _buildChatBubble(msg);
                      },
                    ),
            ),

          // Reply input section
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(top: BorderSide(color: borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
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
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                              maxLines: 3,
                              minLines: 1,
                              style: TextStyle(
                                fontSize: 14,
                                color: textPrimary,
                              ),
                              onSubmitted: (_) {
                                if (!_isReplying) _sendReply();
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.attach_file_rounded,
                              color: primaryColor,
                            ),
                            onPressed: () {
                              // TODO: Implement file attachment
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
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
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
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
                            icon: Icon(Icons.send_rounded, color: Colors.white),
                            onPressed: _sendReply,
                            tooltip: 'Send message',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(AdminMessage msg) {
    final isAdmin = _isAdminMessage(msg);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAdmin
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isAdmin)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.thread.senderName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
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
                    padding: EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      widget.thread.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAdmin ? adminMessageColor : userMessageColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: isAdmin ? Radius.circular(20) : Radius.circular(4),
                      bottomRight: isAdmin ? Radius.circular(4) : Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAdmin && msg.sender != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            msg.sender?.name ?? 'Admin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      Text(
                        msg.message ?? '[No message]',
                        style: TextStyle(
                          color: isAdmin ? Colors.white : textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(msg.timestamp ?? DateTime.now()),
                            style: TextStyle(
                              fontSize: 11,
                              color: isAdmin
                                  ? Colors.white.withOpacity(0.8)
                                  : textSecondary,
                            ),
                          ),
                          SizedBox(width: 8),
                          if (isAdmin)
                            Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          if (!isAdmin && msg.isRead)
                            Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: primaryColor,
                            ),
                          if (!isAdmin && !msg.isRead)
                            Icon(
                              Icons.done_rounded,
                              size: 14,
                              color: textSecondary,
                            ),
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 16,
                  color: primaryColor,
                ),
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