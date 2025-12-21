import 'message_model.dart';

class ChatThread {
  final String threadId;
  final String senderName;
  final String senderEmail;
  final int senderId;
  final List<AdminMessage> messages; // Gunakan AdminMessage langsung
  int unreadCount;
  DateTime lastMessageTime;
  int? lastMessageId;

  ChatThread({
    required this.threadId,
    required this.senderName,
    required this.senderEmail,
    required this.senderId,
    required this.messages,
    this.unreadCount = 0,
    required this.lastMessageTime,
    this.lastMessageId,
  });

  // Helper untuk cek apakah ada reply dari admin
  bool get hasAdminReply {
    return messages.any((msg) => msg.isAdmin); // ✅ Gunakan getter isAdmin
  }
}
