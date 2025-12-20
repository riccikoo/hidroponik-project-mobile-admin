class User {
  final String? id;
  final String name;
  final String email;
  final String? token;
  final String? role;
  final String? status;
  final String? password; // 🔑 Untuk kebutuhan login/register
  final String? createdAt; // Sesuai database: created_at
  final String? updatedAt; // Sesuai database: updated_at

  User({
    this.id,
    required this.name,
    required this.email,
    this.token,
    this.role,
    this.status,
    this.password,
    this.createdAt,
    this.updatedAt,
  });

  // --- fromJson: Reads data from the API response ---
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      password: json['password']?.toString(),
      createdAt: json['created_at']?.toString(), // ❗ Perhatikan underscore
      updatedAt: json['updated_at']?.toString(), // ❗ Perhatikan underscore
    );
  }

  // --- toJson: Converts the model back to a Map for saving/sending ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      'role': role,
      'status': status,
      'password': password,
      'created_at': createdAt, // ❗ Gunakan underscore untuk konsisten dengan BE
      'updated_at': updatedAt,
    };
  }
}
