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
  bool _isInitializing = false;
  bool _isSigningOut = false;
  int _sessionGeneration = 0;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  AuthUser? get user => _session?.user;
  bool get isAuthenticated => _session != null;
  bool get isBusy => _isInitializing || _isSigningOut;

  Future<void> initialize() async {
    if (_status != AuthStatus.initial || _isInitializing) {
      return;
    }
    final generation = _sessionGeneration;
    _isInitializing = true;
    notifyListeners();
    try {
      final restored = await _authRepository.restoreSession();
      if (generation != _sessionGeneration) {
        return;
      }
      _session = restored;
      _status = restored != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } catch (_) {
      if (generation != _sessionGeneration) {
        return;
      }
      _session = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void setAuthenticatedSession(AuthSession session) {
    _sessionGeneration++;
    _session = session;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_isSigningOut) {
      return;
    }
    final current = _session;
    _sessionGeneration++;
    _isSigningOut = true;
    notifyListeners();
    try {
      await _authRepository.logout(current);
    } finally {
      _session = null;
      _status = AuthStatus.unauthenticated;
      _isSigningOut = false;
      notifyListeners();
    }
  }
}
