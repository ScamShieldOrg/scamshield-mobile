import '../models/api_exception.dart';
import '../models/auth_session.dart';
import '../models/auth_user.dart';
import '../services/auth_api_service.dart';
import '../services/jwt_decoder.dart';
import '../services/session_storage_service.dart';

class AuthRepository {
  AuthRepository({
    AuthApiService? apiService,
    SessionStorageService? storageService,
  }) : _apiService = apiService ?? AuthApiService(),
       _storageService = storageService ?? SecureSessionStorageService();

  final AuthApiService _apiService;
  final SessionStorageService _storageService;

  int _sessionEpoch = 0;
  Future<void> _storageQueue = Future<void>.value();

  Future<AuthSession> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    final trimmedIdentifier = identifier.trim();
    final tokens = await _apiService.login(
      usernameOrPhoneNumber: trimmedIdentifier,
      password: password,
    );

    final user = await _resolveUserProfile(
      accessToken: tokens.accessToken,
      fallbackIdentifier: trimmedIdentifier,
    );

    final session = AuthSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: user,
      rememberMe: rememberMe,
    );

    await _serializeStorage(() async {
      _sessionEpoch++;
      if (rememberMe) {
        await _storageService.saveSession(session);
        await _storageService.saveRememberedIdentifier(trimmedIdentifier);
      } else {
        await _storageService.clearSession();
        await _storageService.saveRememberedIdentifier(null);
      }
    });

    return session;
  }

  Future<AuthSession?> restoreSession() async {
    late int epoch;
    AuthSession? saved;
    await _serializeStorage(() async {
      epoch = _sessionEpoch;
      saved = await _storageService.readSession();
    });
    final candidate = saved;
    if (candidate == null || epoch != _sessionEpoch) {
      return null;
    }

    try {
      final refreshedUser = await _apiService.getCurrentProfile(
        accessToken: candidate.accessToken,
      );
      final updated = candidate.copyWith(user: refreshedUser);
      final persisted = await _saveSessionIfUnchanged(updated, epoch);
      return persisted ? updated : null;
    } catch (error) {
      if (epoch != _sessionEpoch) {
        return null;
      }
      if (!_isAuthRejection(error)) {
        // Transport/transient error: preserve saved session for offline use.
        return candidate;
      }

      final refreshToken = candidate.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearSessionIfUnchanged(epoch);
        return null;
      }

      try {
        final newTokens = await _apiService.refreshToken(
          refreshToken: refreshToken,
        );
        final refreshedUser = await _resolveUserProfile(
          accessToken: newTokens.accessToken,
          fallbackIdentifier: candidate.user.username,
        );
        final updated = candidate.copyWith(
          accessToken: newTokens.accessToken,
          refreshToken: newTokens.refreshToken ?? refreshToken,
          user: refreshedUser,
        );
        final persisted = await _saveSessionIfUnchanged(updated, epoch);
        return persisted ? updated : null;
      } catch (refreshError) {
        if (_isAuthRejection(refreshError)) {
          await _clearSessionIfUnchanged(epoch);
        }
        // On transport failures (statusCode == null) or transient server errors,
        // keep the stored session intact so it can be restored once online.
        return null;
      }
    }
  }

  Future<void> logout(AuthSession? session) async {
    if (session != null) {
      try {
        await _apiService.logout(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
      } catch (_) {
        // Always clear local session even if the server cannot be reached.
      }
    }
    await _serializeStorage(() async {
      _sessionEpoch++;
      await _storageService.clearSession();
    });
  }

  Future<String?> loadRememberedIdentifier() {
    return _storageService.readRememberedIdentifier();
  }

  Future<AuthUser> _resolveUserProfile({
    required String accessToken,
    required String fallbackIdentifier,
  }) async {
    try {
      return await _apiService.getCurrentProfile(accessToken: accessToken);
    } catch (_) {
      final claims = decodeJwtPayload(accessToken);
      if (claims != null) {
        return AuthUser.fromJwtClaims(
          claims,
          fallbackIdentifier: fallbackIdentifier,
        );
      }
      return AuthUser(
        username: fallbackIdentifier,
        role: 'REGISTERED_USER',
      );
    }
  }

  bool _isAuthRejection(Object error) {
    return error is ApiException &&
        (error.statusCode == 401 || error.statusCode == 403);
  }

  Future<bool> _saveSessionIfUnchanged(AuthSession session, int epoch) async {
    var saved = false;
    await _serializeStorage(() async {
      if (epoch != _sessionEpoch) {
        return;
      }
      await _storageService.saveSession(session);
      saved = true;
    });
    return saved;
  }

  Future<void> _clearSessionIfUnchanged(int epoch) async {
    await _serializeStorage(() async {
      if (epoch != _sessionEpoch) {
        return;
      }
      await _storageService.clearSession();
    });
  }

  Future<void> _serializeStorage(Future<void> Function() action) {
    final next = _storageQueue.then((_) => action());
    _storageQueue = next.catchError((_) {});
    return next;
  }
}
