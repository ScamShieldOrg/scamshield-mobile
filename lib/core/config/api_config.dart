import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const _configuredBase = String.fromEnvironment('API_BASE_URL');
  static const _androidDebugBase = 'http://10.0.2.2:8080/api';

  static Uri endpoint(String path) {
    final address =
        _configuredBase.isEmpty &&
            kDebugMode &&
            !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android
        ? _androidDebugBase
        : _configuredBase;
    final base = Uri.tryParse(address);
    if (base == null ||
        !['http', 'https'].contains(base.scheme) ||
        base.host.isEmpty) {
      throw const FormatException('Chưa cấu hình API_BASE_URL cho ứng dụng.');
    }
    return base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/$'), '')}$path',
    );
  }
}
