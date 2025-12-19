class UserMessage {
  final int id;
  final String message;
  final DateTime timestamp;

  UserMessage({
    required this.id,
    required this.message,
    required this.timestamp,
  });

  factory UserMessage.fromJson(Map<String, dynamic> json) {
    return UserMessage(
      id: json['id'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
