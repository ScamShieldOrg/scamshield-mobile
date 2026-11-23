import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

typedef ScamCheckQuota = ({int remaining, int limit});
typedef ScamCheckResult = ({
  String verdict,
  String? explanation,
  String? guidance,
  List<String> urgencyKeywords,
  String? technicalExplanation,
  num? confidence,
  num? riskScore,
  String? scamType,
  List<String> recommendations,
});

class ScamCheckApiException implements Exception {
  const ScamCheckApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;
}

class ScamCheckService {
  Future<String> restoreSession(String? token) async {
    final data = await _request(
      '/guest/sessions',
      body: {'sessionToken': token},
    );
    final sessionToken = data['sessionToken'];
    if (sessionToken is String && sessionToken.isNotEmpty) return sessionToken;
    throw const ScamCheckApiException('Máy chủ chưa cấp phiên khách.');
  }

  Future<ScamCheckQuota> quota(String token) async {
    final data = await _request('/guest/quota', token: token);
    final remaining = data['remaining'];
    final limit = data['limit'];
    if (remaining is int &&
        limit is int &&
        remaining >= 0 &&
        remaining <= limit) {
      return (remaining: remaining, limit: limit);
    }
    throw const ScamCheckApiException('Máy chủ trả về hạn mức không hợp lệ.');
  }

  Future<ScamCheckResult> analyze(
    String token,
    String type,
    String content,
  ) async {
    final data = await _request(
      '/scam-checks',
      token: token,
      body: {'inputType': type, 'content': content},
      timeout: const Duration(seconds: 90),
    );
    final ai = data['aiDetails'];
    final aiVerdict = ai is Map ? ai['verdict'] : null;
    final verdict =
        (aiVerdict is Map ? aiVerdict['riskLevel'] : null) ?? data['verdict'];
    if (verdict is! String || verdict.isEmpty) {
      throw const ScamCheckApiException(
        'Máy chủ chưa trả về kết quả kiểm tra.',
      );
    }
    final summary = aiVerdict is Map ? aiVerdict['summary'] : null;
    final explanation = summary ?? data['explanation'];
    final guidance = data['safetyGuidance'];
    final features = ai is Map
        ? ai['deterministicFeatures'] ?? ai['deterministic_features']
        : null;
    final urgency = features is Map ? features['urgency_indicators'] : null;
    final keywords = urgency is Map ? urgency['matched_keywords'] : null;
    final List<String> urgencyKeywords =
        type == 'MESSAGE' && keywords is List<Object?>
        ? keywords
              .whereType<String>()
              .map((word) => word.trim())
              .where((word) => word.isNotEmpty)
              .toSet()
              .toList()
        : const <String>[];
    final confidence =
        (aiVerdict is Map ? aiVerdict['confidence'] : null) ??
        data['confidence'];
    final technicalExplanation = data['explanation'];
    final score = aiVerdict is Map ? aiVerdict['riskScore'] : null;
    final scamType = aiVerdict is Map ? aiVerdict['scamType'] : null;
    final recommendations = ai is Map ? ai['recommendations'] : null;
    return (
      verdict: verdict,
      explanation: explanation is String ? explanation : null,
      guidance: guidance is String ? guidance : null,
      urgencyKeywords: urgencyKeywords,
      technicalExplanation: technicalExplanation is String
          ? technicalExplanation
          : null,
      confidence: confidence is num && confidence >= 0 && confidence <= 1
          ? confidence
          : null,
      riskScore:
          verdict.toUpperCase() != 'UNKNOWN' &&
              score is num &&
              score >= 0 &&
              score <= 100
          ? score
          : null,
      scamType: scamType is String && scamType.trim().isNotEmpty
          ? scamType.trim()
          : null,
      recommendations: recommendations is List<Object?>
          ? recommendations
                .whereType<String>()
                .map((step) => step.trim())
                .where((step) => step.isNotEmpty)
                .toSet()
                .toList()
          : const <String>[],
    );
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String? token,
    Map<String, Object?>? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final client = http.Client();
    try {
      final uri = ApiConfig.endpoint(path);
      final headers = {
        'Accept': 'application/json',
        if (token != null) 'X-Guest-Session': token,
        if (body != null) 'Content-Type': 'application/json',
      };
      final response =
          await (body == null
                  ? client.get(uri, headers: headers)
                  : client.post(uri, headers: headers, body: jsonEncode(body)))
              .timeout(timeout);
      final status = response.statusCode;
      if (status == 429) {
        throw ScamCheckApiException(
          'Bạn đã hết lượt kiểm tra hôm nay.',
          status,
        );
      }
      if (status == 401) {
        throw ScamCheckApiException(
          'Phiên khách đã hết hạn. Vui lòng cập nhật số lượt rồi thử lại.',
          status,
        );
      }
      final envelope = jsonDecode(utf8.decode(response.bodyBytes));
      if (envelope is Map<String, dynamic>) {
        final data = envelope['data'];
        if (status >= 200 &&
            status < 300 &&
            envelope['isSuccess'] == true &&
            data is Map<String, dynamic>) {
          return data;
        }
        final message = envelope['message'];
        if (message is String && message.isNotEmpty) {
          throw ScamCheckApiException(message, status);
        }
      }
      throw ScamCheckApiException('Chưa thể xử lý yêu cầu kiểm tra.', status);
    } on TimeoutException {
      throw const ScamCheckApiException(
        'Máy chủ phản hồi quá lâu. Hãy kiểm tra số lượt trước khi thử lại.',
      );
    } on http.ClientException {
      throw const ScamCheckApiException(
        'Không kết nối được máy chủ. Vui lòng thử lại.',
      );
    } on FormatException catch (error) {
      throw ScamCheckApiException(error.message);
    } finally {
      client.close();
    }
  }
}
