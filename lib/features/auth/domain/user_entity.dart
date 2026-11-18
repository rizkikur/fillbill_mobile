class UserEntity {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final String tier;
  final bool isVerified;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.tier,
    required this.isVerified,
    this.createdAt,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    String tierName = 'end_user';
    if (json['tier'] is Map) {
      tierName = (json['tier'] as Map)['name']?.toString() ?? 'end_user';
    } else if (json['tier'] != null) {
      tierName = json['tier'].toString();
    }

    return UserEntity(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'user',
      tier: tierName,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'tier': tier,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class AuthTokenResult {
  final String token;
  final String tokenType;
  final UserEntity user;

  const AuthTokenResult({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory AuthTokenResult.fromJson(Map<String, dynamic> json) {
    return AuthTokenResult(
      token: json['token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      user: UserEntity.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

