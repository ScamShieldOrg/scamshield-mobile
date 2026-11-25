import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/api_config.dart';
import '../../ui/dispute/submit_dispute_validation.dart';
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

  Future<DisputeSubmissionResult> submitDispute({
    required String accessToken,
    required DisputeIndicatorType indicatorType,
    required String indicatorValue,
    required DisputeLegalRelationship legalRelationship,
    required String reason,
    required bool agreeTerms,
    required List<DisputeAttachmentItem> attachments,
  }) async {
    final uri = ApiConfig.resolve('/disputes', baseUrlOverride: _baseUrl);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $accessToken';

    final payload = jsonEncode({
      'indicatorType': indicatorType.apiValue,
      'indicatorValue': indicatorValue.trim(),
      'legalRelationship': legalRelationship.apiValue,
      'reason': reason.trim(),
      'agreeTerms': agreeTerms,
    });
    request.files.add(
      http.MultipartFile.fromString(
        'request',
        payload,
        contentType: MediaType('application', 'json'),
      ),
    );

    for (final attachment in attachments) {
      final mediaType = MediaType.parse(attachment.contentType);
      if (attachment.bytes != null && attachment.bytes!.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            attachment.bytes!,
            filename: attachment.fileName,
            contentType: mediaType,
          ),
        );
      } else if (attachment.filePath != null &&
          attachment.filePath!.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            attachment.filePath!,
            filename: attachment.fileName,
            contentType: mediaType,
          ),
        );
      } else {
        throw ApiException(
          'Không thể đọc tệp "${attachment.fileName}". Vui lòng chọn lại.',
        );
      }
    }

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        'Máy chủ phản hồi quá lâu. Vui lòng kiểm tra kết nối và thử lại.',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng và thử lại.',
      );
    }

    final body = _decodeJsonMap(response.bodyBytes);
    final isAccepted =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body?['isSuccess'] == true;
    if (!isAccepted) {
      throw ApiException(
        _errorMessage(
          body,
          fallback: 'Không thể gửi hồ sơ khiếu nại. Vui lòng thử lại.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Phản hồi xác nhận hồ sơ không hợp lệ.');
    }
    final serverMessage = (body?['message'] as String?)?.trim();
    return DisputeSubmissionResult.fromJson(
      data,
      message: (serverMessage != null && serverMessage.isNotEmpty)
          ? serverMessage
          : 'Hồ sơ khiếu nại đã được gửi và đang chờ thẩm định.',
    );
  }

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
    final data = body?['data'];
    if (data is Map<String, dynamic>) {
      for (final value in data.values) {
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    final message = (body?['message'] as String?)?.trim();
    return (message != null && message.isNotEmpty) ? message : fallback;
  }
}
