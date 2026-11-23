class AuthUser {
  const AuthUser({
    required this.username,
    required this.role,
    this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.isPhoneVerified = false,
    this.status,
    this.reputationPoints,
  });

  final int? id;
  final String username;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final bool isPhoneVerified;
  final String role;
  final String? status;
  final int? reputationPoints;

  String get displayName {
    final trimmedName = fullName?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      return trimmedName;
    }
    final trimmedEmail = email?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
      return trimmedEmail;
    }
    final trimmedPhone = phoneNumber?.trim();
    if (trimmedPhone != null && trimmedPhone.isNotEmpty) {
      return trimmedPhone;
    }
    return username;
  }

  String get roleLabel => switch (role.toUpperCase()) {
    'ADMINISTRATOR' => 'Quản trị viên',
    'MODERATOR' => 'Kiểm duyệt viên',
    'BUSINESS_PARTNER' => 'Đối tác doanh nghiệp',
    'REGISTERED_USER' => 'Thành viên',
    _ => 'Khách',
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawPoints = json['reputationPoints'];
    return AuthUser(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId'),
      username: (json['username'] as String?)?.trim() ?? '',
      fullName: (json['fullName'] as String?)?.trim(),
      email: (json['email'] as String?)?.trim(),
      phoneNumber: (json['phoneNumber'] as String?)?.trim(),
      isPhoneVerified: json['isPhoneVerified'] == true,
      role: (json['role'] as String?)?.trim() ?? 'REGISTERED_USER',
      status: (json['status'] as String?)?.trim(),
      reputationPoints: rawPoints is num
          ? rawPoints.toInt()
          : int.tryParse('$rawPoints'),
    );
  }

  factory AuthUser.fromJwtClaims(
    Map<String, dynamic> claims, {
    String fallbackIdentifier = '',
  }) {
    final rawId = claims['id'];
    final email = (claims['email'] as String?)?.trim();
    final sub = (claims['sub'] as String?)?.trim();
    final role = (claims['role'] as String?)?.trim();
    return AuthUser(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId'),
      username: (sub != null && sub.isNotEmpty)
          ? sub
          : (email != null && email.isNotEmpty)
          ? email
          : fallbackIdentifier,
      email: email,
      role: (role != null && role.isNotEmpty) ? role : 'REGISTERED_USER',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'isPhoneVerified': isPhoneVerified,
    'role': role,
    'status': status,
    'reputationPoints': reputationPoints,
  };
}
