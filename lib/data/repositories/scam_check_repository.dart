import 'package:flutter/services.dart';

import '../services/scam_check_service.dart';

class ScamCheckRepository {
  final _service = ScamCheckService();
  static const _storage = MethodChannel('scamshield/guest_session');
  String? _token;

  Future<ScamCheckQuota> refreshQuota() async {
    final previous = _token ?? await _storage.invokeMethod<String>('read');
    final token = await _service.restoreSession(previous);
    _token = token;
    if (previous != token) await _storage.invokeMethod<void>('write', token);
    return _service.quota(token);
  }

  Future<ScamCheckQuota> currentQuota() => _service.quota(_token!);

  Future<ScamCheckResult> analyze(String type, String content) =>
      _service.analyze(_token!, type, content);
}
