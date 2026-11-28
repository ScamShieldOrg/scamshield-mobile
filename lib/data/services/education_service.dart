import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class EducationService {
  const EducationService();

  Future<Map<String, dynamic>> fetchHub({String? categoryCode}) async {
    final endpoint = ApiConfig.endpoint('/education-hub');
    final uri = categoryCode == null
        ? endpoint
        : endpoint.replace(
            queryParameters: {
              ...endpoint.queryParameters,
              'categoryCode': categoryCode,
            },
          );
    final client = http.Client();
    try {
      final response = await client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw const FormatException('Không tải được cẩm nang an toàn.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic> &&
          decoded['isSuccess'] == true &&
          decoded['data'] is Map<String, dynamic>) {
        return decoded['data'] as Map<String, dynamic>;
      }
      throw const FormatException('Dữ liệu cẩm nang an toàn không hợp lệ.');
    } finally {
      client.close();
    }
  }
}
