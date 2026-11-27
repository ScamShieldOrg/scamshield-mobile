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

  /// Base URL of the ScamShield Core REST API (including `/api`).
  ///
  /// Override at runtime with:
  /// `flutter run --dart-define=API_BASE_URL=http://<host>:8080/api`
  static String get baseUrl {
    if (_configuredBase.trim().isNotEmpty) {
      return _normalizeBaseUrl(_configuredBase);
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static Uri resolve(String path, {String? baseUrlOverride}) {
    final base = _normalizeBaseUrl(baseUrlOverride ?? baseUrl);
    var cleanPath = path.startsWith('/') ? path : '/$path';
    if (base.endsWith('/api') && cleanPath.startsWith('/api/')) {
      cleanPath = cleanPath.substring(4);
    }
    return Uri.parse('$base$cleanPath');
  }

  static String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
