import 'dart:convert';

import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/api_config.dart';

typedef ReportOption = ({String code, String name});
typedef ReportEvidence = ({String name, Uint8List bytes});

class ReportService {
  Map<String, dynamic> _body(http.Response response) {
    if (response.statusCode == 401) {
      throw const FormatException(
        'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.',
      );
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Máy chủ trả về dữ liệu không hợp lệ.');
    }
    if (response.statusCode >= 400 ||
        (data['isSuccess'] ?? data['success']) == false) {
      throw FormatException(data['message']?.toString() ?? 'Yêu cầu thất bại.');
    }
    return data;
  }

  Future<List<ReportOption>> categories(String token) async {
    final response = await http
        .get(
          ApiConfig.endpoint('/user/reports/categories'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));
    return _options(_body(response)['data']);
  }

  Future<List<ReportOption>> regions() async {
    final response = await http
        .get(ApiConfig.endpoint('/dashboard/filters'))
        .timeout(const Duration(seconds: 20));
    return _options(_body(response)['data']?['regions']);
  }

  List<ReportOption> _options(dynamic data) {
    if (data is! List) {
      throw const FormatException('Không tải được danh sách lựa chọn.');
    }
    return [
      for (final item in data)
        (code: item['code'].toString(), name: item['name'] as String),
    ];
  }

  Future<String> submit(
    String token,
    Map<String, Object> payload,
    List<ReportEvidence> evidence,
  ) async {
    final request =
        http.MultipartRequest('POST', ApiConfig.endpoint('/reports'))
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile.fromString(
              'request',
              jsonEncode(payload),
              contentType: MediaType('application', 'json'),
            ),
          );
    for (final file in evidence) {
      final extension = file.name.split('.').last.toLowerCase();
      final mime = switch (extension) {
        'pdf' => MediaType('application', 'pdf'),
        'png' => MediaType('image', 'png'),
        _ => MediaType('image', 'jpeg'),
      };
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          file.bytes,
          filename: file.name,
          contentType: mime,
        ),
      );
    }
    final client = http.Client();
    try {
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(minutes: 2));
      final body = _body(response);
      final data = body['data'];
      if (body['isSuccess'] != true || data is! Map || data['id'] is! num) {
        throw const FormatException('Chưa nhận được xác nhận lưu báo cáo.');
      }
      return data['reportCode']?.toString() ?? '#RPT-${data['id']}';
    } finally {
      client.close();
    }
  }
}
