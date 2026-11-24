import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/api_exception.dart';
import '../models/user_scam_check_quota.dart';

class UserQuotaApiService {
  UserQuotaApiService({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl;

  final http.Client _client;
  final String? _baseUrl;
  final Duration timeout;

  Future<UserScamCheckQuota> getMyQuota({required String accessToken}) async {
    final uri = ApiConfig.resolve(
      '/users/me/scam-check-quota',
      baseUrlOverride: _baseUrl,
    );

    final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException('Hết thời gian tải hạn mức tra cứu.');
    } catch (_) {
      throw const ApiException('Không thể kết nối đến máy chủ.');
    }

    final body = _decodeJsonMap(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final serverMsg = (body?['message'] as String?)?.trim();
      throw ApiException(
        (serverMsg != null && serverMsg.isNotEmpty)
            ? serverMsg
            : 'Không thể tải hạn mức tra cứu AI.',
        statusCode: response.statusCode,
      );
    }

    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Dữ liệu hạn mức trả về không hợp lệ.');
    }

    return UserScamCheckQuota.fromJson(data);
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
}
