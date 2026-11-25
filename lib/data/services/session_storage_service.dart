import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session.dart';

abstract class SessionStorageService {
  Future<void> saveSession(AuthSession session);
  Future<AuthSession?> readSession();
  Future<void> clearSession();
  Future<void> saveRememberedIdentifier(String? identifier);
  Future<String?> readRememberedIdentifier();
}

class SecureSessionStorageService implements SessionStorageService {
  SecureSessionStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'scamshield_auth_session';
  static const _identifierKey = 'scamshield_remembered_identifier';

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveSession(AuthSession session) async {
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  @override
  Future<AuthSession?> readSession() async {
    try {
      final raw = await _storage.read(key: _sessionKey);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final session = AuthSession.fromJson(decoded);
      if (session.accessToken.isEmpty) {
        return null;
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }

  @override
  Future<void> saveRememberedIdentifier(String? identifier) async {
    final trimmed = identifier?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await _storage.delete(key: _identifierKey);
      return;
    }
    await _storage.write(key: _identifierKey, value: trimmed);
  }

  @override
  Future<String?> readRememberedIdentifier() async {
    try {
      return await _storage.read(key: _identifierKey);
    } catch (_) {
      return null;
    }
  }
}

class InMemorySessionStorageService implements SessionStorageService {
  AuthSession? _session;
  String? _identifier;

  @override
  Future<void> saveSession(AuthSession session) async {
    _session = session;
  }

  @override
  Future<AuthSession?> readSession() async => _session;

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<void> saveRememberedIdentifier(String? identifier) async {
    final trimmed = identifier?.trim();
    _identifier = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  Future<String?> readRememberedIdentifier() async => _identifier;
}
