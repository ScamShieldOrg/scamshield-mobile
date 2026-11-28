import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class ApiConfig {
  static const _configuredBase = String.fromEnvironment('API_BASE_URL');
  static const _androidDebugBase = 'http://10.0.2.2:8080/api';
  static String _assetBase = '';

  static Future<void> load() async {
    final contents = await rootBundle.loadString('.env');
    final entry = RegExp(r'^ *API_BASE_URL *=([^\r\n]*)', multiLine: true);
    _assetBase = entry.firstMatch(contents)?.group(1)?.trim() ?? '';
  }

  static Uri endpoint(String path) => resolve(path);

  /// Base URL of the ScamShield Core REST API (including `/api`).
  ///
  /// Set in `.env` or override with `--dart-define=API_BASE_URL=...`.
  static String get baseUrl => _validatedBase().toString();

  static Uri resolve(String path, {String? baseUrlOverride}) {
    final base = _validatedBase(baseUrlOverride);
    final request = Uri.parse(path.startsWith('/') ? path : '/$path');
    var cleanPath = request.path;
    if (base.path.endsWith('/api') &&
        (cleanPath == '/api' || cleanPath.startsWith('/api/'))) {
      cleanPath = cleanPath.substring(4);
    }
    return base.replace(
      path: '${base.path}$cleanPath',
      query: request.hasQuery ? request.query : null,
      fragment: request.hasFragment ? request.fragment : null,
    );
  }

  static Uri _validatedBase([String? override]) {
    final define = _configuredBase.trim();
    final configured = define.isEmpty ? _assetBase : define;
    final address =
        override?.trim() ??
        (configured.isEmpty && kDebugMode ? _developmentBase : configured);
    final base = Uri.tryParse(address);
    if (base == null ||
        (base.scheme != 'http' && base.scheme != 'https') ||
        base.host.isEmpty) {
      throw const FormatException(
        'Chưa cấu hình API_BASE_URL hợp lệ cho ứng dụng.',
      );
    }
    return base.replace(path: base.path.replaceFirst(RegExp(r'/+$'), ''));
  }

  static String get _developmentBase =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? _androidDebugBase
      : 'http://localhost:8080/api';
}
