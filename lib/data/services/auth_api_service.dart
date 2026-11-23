import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/api_exception.dart';
import '../models/auth_user.dart';

class AuthTokenBundle {
  const AuthTokenBundle({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;
}

class AuthApiService {
  AuthApiService({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl;

  final http.Client _client;
  final String? _baseUrl;
  final Duration timeout;

  Future<AuthTokenBundle> login({
    required String usernameOrPhoneNumber,
    required String password,
  }) async {
    final uri = ApiConfig.resolve('/auth/login', baseUrlOverride: _baseUrl);
    final response = await _send(
      () => _client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'usernameOrPhoneNumber': usernameOrPhoneNumber.trim(),
          'password': password,
        }),
      ),
    );

    final body = _decodeJsonMap(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _mapLoginErrorMessage(response.statusCode, body),
        statusCode: response.statusCode,
      );
    }

    final accessToken = _extractAccessToken(body);
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('Không nhận được mã xác thực từ máy chủ.');
    }

    return AuthTokenBundle(
      accessToken: accessToken,
      refreshToken: extractCookieValue(
        response.headers['set-cookie'],
        'refreshToken',
      ),
    );
  }

  Future<AuthUser> getCurrentProfile({required String accessToken}) async {
    final uri = ApiConfig.resolve('/auth/me', baseUrlOverride: _baseUrl);
    final response = await _send(
      () => _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    final body = _decodeJsonMap(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _mapGeneralErrorMessage(
          response.statusCode,
          body,
          fallback: 'Không thể tải thông tin tài khoản.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Dữ liệu tài khoản trả về không hợp lệ.');
    }
    return AuthUser.fromJson(data);
  }

  Future<AuthTokenBundle> refreshToken({required String refreshToken}) async {
    final uri = ApiConfig.resolve(
      '/auth/refresh-token',
      baseUrlOverride: _baseUrl,
    );
    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'refreshToken=$refreshToken',
        },
        body: '{}',
      ),
    );

    final body = _decodeJsonMap(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _mapGeneralErrorMessage(
          response.statusCode,
          body,
          fallback: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        ),
        statusCode: response.statusCode,
      );
    }

    final accessToken = _extractAccessToken(body);
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('Không thể làm mới phiên đăng nhập.');
    }

    return AuthTokenBundle(
      accessToken: accessToken,
      refreshToken:
          extractCookieValue(response.headers['set-cookie'], 'refreshToken') ??
          refreshToken,
    );
  }

  Future<void> logout({String? accessToken, String? refreshToken}) async {
    final uri = ApiConfig.resolve('/auth/logout', baseUrlOverride: _baseUrl);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
      if (refreshToken != null && refreshToken.isNotEmpty)
        'Cookie': 'refreshToken=$refreshToken',
    };
    await _send(() => _client.post(uri, headers: headers, body: '{}'));
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        'Máy chủ phản hồi quá lâu. Vui lòng kiểm tra kết nối và thử lại.',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc dịch vụ backend.',
      );
    }
  }

  static String? extractCookieValue(String? setCookieHeader, String name) {
    if (setCookieHeader == null || setCookieHeader.isEmpty) {
      return null;
    }
    final pattern = RegExp('(?:^|[,;\\s])${RegExp.escape(name)}=([^;]+)');
    final match = pattern.firstMatch(setCookieHeader);
    final value = match?.group(1)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  static Map<String, dynamic>? _decodeJsonMap(List<int> bodyBytes) {
    if (bodyBytes.isEmpty) {
      return null;
    }
    try {
      final rawBody = utf8.decode(bodyBytes, allowMalformed: true);
      if (rawBody.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(rawBody);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String? _extractAccessToken(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['accessToken'];
      if (nested is String && nested.isNotEmpty) {
        return nested;
      }
    }
    final topLevel = body?['accessToken'];
    return topLevel is String && topLevel.isNotEmpty ? topLevel : null;
  }

  static String _mapLoginErrorMessage(
    int statusCode,
    Map<String, dynamic>? body,
  ) {
    final rawMessage = (body?['message'] as String?)?.trim() ?? '';
    final lower = rawMessage.toLowerCase();

    if (lower.contains('banned') ||
        lower.contains('suspended') ||
        lower.contains('inactive')) {
      return 'Tài khoản của bạn đang bị khóa hoặc tạm ngưng. Vui lòng liên hệ hỗ trợ.';
    }
    if (statusCode == 401 ||
        lower.contains('invalid username') ||
        lower.contains('bad credentials')) {
      return 'Số điện thoại, email hoặc mật khẩu không chính xác.';
    }
    return _mapGeneralErrorMessage(
      statusCode,
      body,
      fallback: 'Đăng nhập thất bại. Vui lòng thử lại.',
    );
  }

  static String _mapGeneralErrorMessage(
    int statusCode,
    Map<String, dynamic>? body, {
    required String fallback,
  }) {
    final rawMessage = (body?['message'] as String?)?.trim();
    if (rawMessage != null && _hasVietnameseDiacritics(rawMessage)) {
      return rawMessage;
    }
    if (statusCode == 400) {
      return 'Thông tin chưa hợp lệ. Vui lòng kiểm tra lại.';
    }
    if (statusCode == 401) {
      return 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.';
    }
    if (statusCode == 403) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }
    if (statusCode == 429) {
      return 'Bạn đã thao tác quá nhiều lần. Vui lòng chờ một lúc rồi thử lại.';
    }
    if (statusCode >= 500) {
      return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
    }
    return fallback;
  }

  static bool _hasVietnameseDiacritics(String value) {
    return RegExp(r'[À-ÖØ-öø-ÿĂăĐđĨĩŨũƠơƯư\u1EA0-\u1EF9]').hasMatch(value);
  }
}
