import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class ResourceService {
  const ResourceService();

  Future<Map<String, dynamic>> fetch(
    String list,
    Map<String, String> parameters,
  ) async {
    final data = await _fetch('/resources/$list', parameters);
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Không tải được danh sách tài nguyên.');
  }

  Future<List<String>> fetchPublicEvidence(int id) async {
    final data = await _fetch('/resources/blacklist/$id/images', const {});
    if (data is! List) {
      throw const FormatException('Không tải được ảnh minh chứng.');
    }
    return data.whereType<String>().where((link) {
      final uri = Uri.tryParse(link);
      return uri != null &&
          uri.host.isNotEmpty &&
          (uri.scheme == 'https' || uri.scheme == 'http');
    }).toList();
  }

  Future<Object?> _fetch(String path, Map<String, String> parameters) async {
    final endpoint = ApiConfig.endpoint(path);
    final client = http.Client();
    try {
      final response = await client
          .get(
            endpoint.replace(
              queryParameters: {...endpoint.queryParameters, ...parameters},
            ),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map<String, dynamic> && body['isSuccess'] == true) {
          return body['data'];
        }
      }
      throw const FormatException('Không tải được danh sách tài nguyên.');
    } finally {
      client.close();
    }
  }
}
