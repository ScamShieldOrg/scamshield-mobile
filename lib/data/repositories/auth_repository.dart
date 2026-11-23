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

    if (rememberMe) {
      await _storageService.saveSession(session);
      await _storageService.saveRememberedIdentifier(trimmedIdentifier);
    } else {
      await _storageService.clearSession();
      await _storageService.saveRememberedIdentifier(null);
    }

    return session;
  }

  Future<AuthSession?> restoreSession() async {
    final saved = await _storageService.readSession();
    if (saved == null) {
      return null;
    }

    try {
      final refreshedUser = await _apiService.getCurrentProfile(
        accessToken: saved.accessToken,
      );
      final updated = saved.copyWith(user: refreshedUser);
      await _storageService.saveSession(updated);
      return updated;
    } catch (_) {
      final refreshToken = saved.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        return saved;
      }
      try {
        final newTokens = await _apiService.refreshToken(
          refreshToken: refreshToken,
        );
        final refreshedUser = await _resolveUserProfile(
          accessToken: newTokens.accessToken,
          fallbackIdentifier: saved.user.username,
        );
        final updated = saved.copyWith(
          accessToken: newTokens.accessToken,
          refreshToken: newTokens.refreshToken ?? refreshToken,
          user: refreshedUser,
        );
        await _storageService.saveSession(updated);
        return updated;
      } catch (_) {
        await _storageService.clearSession();
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
    await _storageService.clearSession();
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
}
