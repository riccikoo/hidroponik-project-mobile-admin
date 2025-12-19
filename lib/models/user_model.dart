class User {
  final String? id;
  final String name;
  final String email;
  final String? token;
  // 🔑 Fields added to match the Python model
  final String? role;
  final String? status;
  final String? timestamp; // Use String to hold the formatted date/time

  User({
    this.id,
    required this.name,
    required this.email,
    this.token,
    // 🔑 Required in constructor
    this.role,
    this.status,
    this.timestamp,
  });

  // --- fromJson: Reads data from the API response ---
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
      // 🔑 Reading the new fields from JSON
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      timestamp: json['timestamp']
          ?.toString(), // Use the correct spelling 'timestamp'
    );
  }

  // --- toJson: Converts the model back to a Map for saving/sending ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      // 🔑 Including the new fields in the JSON map
      'role': role,
      'status': status,
      'timestamp': timestamp, // Use the correct spelling 'timestamp'
    };
  }
}
