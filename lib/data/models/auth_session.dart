import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    this.refreshToken,
    this.rememberMe = false,
  });

  final String accessToken;
  final String? refreshToken;
  final AuthUser user;
  final bool rememberMe;

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    AuthUser? user,
    bool? rememberMe,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'];
    if (userMap is! Map<String, dynamic>) {
      throw const FormatException('Thiếu thông tin người dùng trong phiên.');
    }
    return AuthSession(
      accessToken: (json['accessToken'] as String?) ?? '',
      refreshToken: json['refreshToken'] as String?,
      user: AuthUser.fromJson(userMap),
      rememberMe: json['rememberMe'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'user': user.toJson(),
    'rememberMe': rememberMe,
  };
}
