// frontend/lib/features/auth/models/user.dart

class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? fullName;
  final String? level;
  final String? avatarUrl;
  final String? bio;
  final String? school;
  final String? phoneNumber;
  final String? role;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.fullName,
    this.level,
    this.avatarUrl,
    this.bio,
    this.school,
    this.phoneNumber,
    this.role,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('📥 User.fromJson: ${json.keys}');
    
    return User(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      level: json['level'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      school: json['school'] as String?,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'level': level,
      'avatar_url': avatarUrl,
      'bio': bio,
      'school': school,
      'phone_number': phoneNumber,
      'role': role,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $fullName, level: $level)';
  }
}