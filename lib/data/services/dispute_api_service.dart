import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/api_exception.dart';
import '../models/dispute_models.dart';

class DisputeApiService {
  DisputeApiService({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl;

  final http.Client _client;
  final String? _baseUrl;
  final Duration timeout;

  Future<DisputePageResult> getMyDisputes({
    required String accessToken,
    List<String>? statuses,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, String>{
      'page': '$page',
      'size': '$size',
      if (statuses != null && statuses.isNotEmpty)
        'status': statuses.join(','),
    };
    final baseUri = ApiConfig.resolve('/disputes/me', baseUrlOverride: _baseUrl);
    final uri = baseUri.replace(queryParameters: queryParams);

    final response = await _get(uri, accessToken);
    final body = _decodeJsonMap(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(
          body,
          fallback: 'Không thể tải danh sách hồ sơ khiếu nại.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Dữ liệu danh sách khiếu nại không hợp lệ.');
    }
    return DisputePageResult.fromJson(data);
  }

  Future<DisputeSummary> getMySummary({required String accessToken}) async {
    final uri = ApiConfig.resolve(
      '/disputes/me/summary',
      baseUrlOverride: _baseUrl,
    );
    final response = await _get(uri, accessToken);
    final body = _decodeJsonMap(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(body, fallback: 'Không thể tải thống kê khiếu nại.'),
        statusCode: response.statusCode,
      );
    }

    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Dữ liệu thống kê khiếu nại không hợp lệ.');
    }
    return DisputeSummary.fromJson(data);
  }

  Future<http.Response> _get(Uri uri, String accessToken) async {
    try {
      return await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        'Máy chủ phản hồi quá lâu. Vui lòng thử lại sau.',
      );
    } catch (_) {
      throw const ApiException(
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.',
      );
    }
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

  static String _errorMessage(
    Map<String, dynamic>? body, {
    required String fallback,
  }) {
    final message = (body?['message'] as String?)?.trim();
    return (message != null && message.isNotEmpty) ? message : fallback;
  }
}
