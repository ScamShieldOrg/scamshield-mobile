import 'package:flutter/foundation.dart';

import '../../app/auth_state.dart';
import '../../data/models/api_exception.dart';
import '../../data/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({
    required AuthRepository authRepository,
    required AuthState authState,
  }) : _authRepository = authRepository,
       _authState = authState;

  final AuthRepository _authRepository;
  final AuthState _authState;

  bool _isSubmitting = false;
  bool _rememberMe = true;
  String? _errorMessage;
  bool _disposed = false;

  bool get isSubmitting => _isSubmitting;
  bool get rememberMe => _rememberMe;
  String? get errorMessage => _errorMessage;

  Future<String?> loadRememberedIdentifier() {
    return _authRepository.loadRememberedIdentifier();
  }

  void setRememberMe(bool value) {
    if (_rememberMe == value) {
      return;
    }
    _rememberMe = value;
    _safeNotify();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    _safeNotify();
  }

  Future<bool> submit({
    required String identifier,
    required String password,
  }) async {
    if (_isSubmitting) {
      return false;
    }
    _isSubmitting = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final session = await _authRepository.login(
        identifier: identifier,
        password: password,
        rememberMe: _rememberMe,
      );
      _authState.setAuthenticatedSession(session);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';
      return false;
    } finally {
      _isSubmitting = false;
      _safeNotify();
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
