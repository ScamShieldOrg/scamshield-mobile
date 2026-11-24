import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class ResourceService {
  const ResourceService();

  Future<Map<String, dynamic>> fetch(
    String list,
    Map<String, String> parameters,
  ) async {
    final endpoint = ApiConfig.endpoint('/resources/$list');
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
        if (body is Map<String, dynamic> &&
            body['isSuccess'] == true &&
            body['data'] is Map<String, dynamic>) {
          return body['data'] as Map<String, dynamic>;
        }
      }
      throw const FormatException('Không tải được danh sách tài nguyên.');
    } finally {
      client.close();
    }
  }
}
