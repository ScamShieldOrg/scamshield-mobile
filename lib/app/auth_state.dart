import 'package:flutter/foundation.dart';

import '../data/models/auth_session.dart';
import '../data/models/auth_user.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState extends ChangeNotifier {
  AuthState({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.initial;
  AuthSession? _session;
  bool _isBusy = false;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  AuthUser? get user => _session?.user;
  bool get isAuthenticated => _session != null;
  bool get isBusy => _isBusy;

  Future<void> initialize() async {
    if (_status != AuthStatus.initial) {
      return;
    }
    _isBusy = true;
    notifyListeners();
    try {
      final restored = await _authRepository.restoreSession();
      _session = restored;
      _status = restored != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } catch (_) {
      _session = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void setAuthenticatedSession(AuthSession session) {
    _session = session;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_isBusy) {
      return;
    }
    final current = _session;
    _isBusy = true;
    notifyListeners();
    try {
      await _authRepository.logout(current);
    } finally {
      _session = null;
      _status = AuthStatus.unauthenticated;
      _isBusy = false;
      notifyListeners();
    }
  }
}
