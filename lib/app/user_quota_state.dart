import 'package:flutter/foundation.dart';

import '../data/models/api_exception.dart';
import '../data/models/user_scam_check_quota.dart';
import '../data/repositories/user_quota_repository.dart';

class UserQuotaState extends ChangeNotifier {
  UserQuotaState({required UserQuotaRepository quotaRepository})
    : _quotaRepository = quotaRepository;

  final UserQuotaRepository _quotaRepository;

  String? _accessToken;
  UserScamCheckQuota? _quota;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  UserScamCheckQuota? get quota => _quota;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void syncAccessToken(String? accessToken) {
    final normalized = (accessToken != null && accessToken.isNotEmpty)
        ? accessToken
        : null;
    if (_accessToken == normalized) {
      return;
    }
    _accessToken = normalized;
    Future.microtask(() => _handleTokenChange(normalized));
  }

  Future<void> refresh() async {
    final token = _accessToken;
    if (token == null || _isLoading) {
      return;
    }
    await _loadQuota(token);
  }

  Future<void> _handleTokenChange(String? token) async {
    if (_disposed || token != _accessToken) {
      return;
    }
    if (token == null) {
      _quota = null;
      _errorMessage = null;
      _isLoading = false;
      _safeNotify();
      return;
    }
    await _loadQuota(token);
  }

  Future<void> _loadQuota(String token) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final result = await _quotaRepository.fetchMyQuota(accessToken: token);
      if (_disposed || token != _accessToken) {
        return;
      }
      _quota = result;
    } on ApiException catch (error) {
      if (_disposed || token != _accessToken) {
        return;
      }
      _errorMessage = error.message;
    } catch (_) {
      if (_disposed || token != _accessToken) {
        return;
      }
      _errorMessage = 'Không thể tải hạn mức tra cứu AI.';
    } finally {
      if (!_disposed && token == _accessToken) {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
