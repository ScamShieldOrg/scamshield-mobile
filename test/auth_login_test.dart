import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_mobile/app/app.dart';
import 'package:scamshield_mobile/app/auth_state.dart';
import 'package:scamshield_mobile/core/theme/app_theme.dart';
import 'package:scamshield_mobile/data/models/api_exception.dart';
import 'package:scamshield_mobile/data/models/auth_session.dart';
import 'package:scamshield_mobile/data/models/auth_user.dart';
import 'package:scamshield_mobile/data/repositories/auth_repository.dart';
import 'package:scamshield_mobile/data/services/auth_api_service.dart';
import 'package:scamshield_mobile/data/services/session_storage_service.dart';
import 'package:scamshield_mobile/ui/shared/scam_shield_brand_badge.dart';

String _buildFakeJwt(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return '$header.$body.signature';
}

void main() {
  group('AuthApiService & AuthRepository', () {
    test('logs in, extracts refresh cookie, and fetches user profile', () async {
      final token = _buildFakeJwt({
        'id': 1,
        'sub': 'nguyenvana@gmail.com',
        'email': 'nguyenvana@gmail.com',
        'role': 'REGISTERED_USER',
      });

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['usernameOrPhoneNumber'], 'nguyenvana@gmail.com');
          expect(body['password'], '123456');
          return http.Response(
            jsonEncode({
              'isSuccess': true,
              'message': 'Login successful',
              'data': {'accessToken': token},
            }),
            200,
            headers: {
              'content-type': 'application/json',
              'set-cookie':
                  'refreshToken=rt_sample_123; Path=/; HttpOnly; SameSite=Lax',
            },
          );
        }

        if (request.url.path.endsWith('/auth/me')) {
          expect(request.headers['Authorization'], 'Bearer $token');
          return http.Response(
            jsonEncode({
              'isSuccess': true,
              'message': 'User profile retrieved successfully',
              'data': {
                'id': 1,
                'username': 'nguyenvana@gmail.com',
                'fullName': 'Nguyễn Văn A',
                'email': 'nguyenvana@gmail.com',
                'phoneNumber': '0987654321',
                'isPhoneVerified': true,
                'role': 'REGISTERED_USER',
                'status': 'ACTIVE',
                'reputationPoints': 0,
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response('Not Found', 404);
      });

      final storage = InMemorySessionStorageService();
      final repository = AuthRepository(
        apiService: AuthApiService(
          client: client,
          baseUrl: 'http://localhost:8080/api',
        ),
        storageService: storage,
      );

      final session = await repository.login(
        identifier: 'nguyenvana@gmail.com',
        password: '123456',
        rememberMe: true,
      );

      expect(session.accessToken, token);
      expect(session.refreshToken, 'rt_sample_123');
      expect(session.user.fullName, 'Nguyễn Văn A');
      expect(session.user.role, 'REGISTERED_USER');
      expect((await storage.readSession())?.accessToken, token);
      expect(await storage.readRememberedIdentifier(), 'nguyenvana@gmail.com');
    });

    test('maps 401 bad credentials to Vietnamese ApiException', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'isSuccess': false,
            'message': 'Invalid username/phone number or password',
            'data': null,
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(
        client: client,
        baseUrl: 'http://localhost:8080/api',
      );

      expect(
        () => service.login(
          usernameOrPhoneNumber: 'nguyenvana@gmail.com',
          password: 'wrongpassword',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('không chính xác'),
          ),
        ),
      );
    });
  });

  group('LoginScreen flow', () {
    testWidgets('navigates from Home to Login and signs in successfully', (
      tester,
    ) async {
      final token = _buildFakeJwt({
        'id': 1,
        'sub': 'nguyenvana@gmail.com',
        'email': 'nguyenvana@gmail.com',
        'role': 'REGISTERED_USER',
      });

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({
              'isSuccess': true,
              'message': 'Login successful',
              'data': {'accessToken': token},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/auth/me')) {
          return http.Response(
            jsonEncode({
              'isSuccess': true,
              'data': {
                'id': 1,
                'username': 'nguyenvana@gmail.com',
                'fullName': 'Nguyễn Văn A',
                'email': 'nguyenvana@gmail.com',
                'phoneNumber': '0987654321',
                'role': 'REGISTERED_USER',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 200);
      });

      final repository = AuthRepository(
        apiService: AuthApiService(
          client: client,
          baseUrl: 'http://localhost:8080/api',
        ),
        storageService: InMemorySessionStorageService(),
      );

      await tester.pumpWidget(
        ScamShieldApp(
          authRepository: repository,
          restoreSessionOnStart: false,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home_login_action')));
      await tester.pumpAndSettle();

      expect(find.text('Ghi nhớ đăng nhập'), findsOneWidget);
      expect(find.text('Cổng Giám Sát An Toàn Số'), findsNothing);
      expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('login_identifier_field')),
        'nguyenvana@gmail.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login_password_field')),
        '123456',
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('login_submit_button')),
      );
      await tester.tap(find.byKey(const ValueKey('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Xin chào, Nguyễn Văn A'), findsOneWidget);
    });

    testWidgets('shows inline error banner when login API returns 401', (
      tester,
    ) async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'isSuccess': false,
            'message': 'Invalid username/phone number or password',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = AuthRepository(
        apiService: AuthApiService(
          client: client,
          baseUrl: 'http://localhost:8080/api',
        ),
        storageService: InMemorySessionStorageService(),
      );

      await tester.pumpWidget(
        ScamShieldApp(
          authRepository: repository,
          restoreSessionOnStart: false,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home_login_action')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('login_identifier_field')),
        'nguyenvana@gmail.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login_password_field')),
        'wrong123',
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('login_submit_button')),
      );
      await tester.tap(find.byKey(const ValueKey('login_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Số điện thoại, email hoặc mật khẩu không chính xác.'),
        findsOneWidget,
      );
    });
  });

  group('Session restoration, cookies, and brand badge regressions', () {
    test('extractCookieValue stops at comma and semicolon', () {
      expect(
        AuthApiService.extractCookieValue(
          'refreshToken=rt_123; Path=/; HttpOnly',
          'refreshToken',
        ),
        'rt_123',
      );
      expect(
        AuthApiService.extractCookieValue(
          'refreshToken=rt_456, otherCookie=abc; Path=/',
          'refreshToken',
        ),
        'rt_456',
      );
    });

    test(
      'restoreSession clears stored session on 401 when no refresh token exists',
      () async {
        final storage = InMemorySessionStorageService();
        await storage.saveSession(
          const AuthSession(
            accessToken: 'expired-token',
            user: AuthUser(username: 'user@test.vn', role: 'REGISTERED_USER'),
            rememberMe: true,
          ),
        );

        final repository = AuthRepository(
          apiService: AuthApiService(
            baseUrl: 'http://localhost:8080/api',
            client: MockClient((_) async => http.Response('{}', 401)),
          ),
          storageService: storage,
        );

        final restored = await repository.restoreSession();
        expect(restored, isNull);
        expect(await storage.readSession(), isNull);
      },
    );

    test(
      'restoreSession keeps stored session on refresh transport failure and clears on refresh 401',
      () async {
        const savedSession = AuthSession(
          accessToken: 'expired-token',
          refreshToken: 'rt_keep_me',
          user: AuthUser(username: 'user@test.vn', role: 'REGISTERED_USER'),
          rememberMe: true,
        );

        final offlineStorage = InMemorySessionStorageService();
        await offlineStorage.saveSession(savedSession);

        final offlineRepo = AuthRepository(
          apiService: AuthApiService(
            baseUrl: 'http://localhost:8080/api',
            client: MockClient((request) async {
              if (request.url.path.endsWith('/auth/me')) {
                return http.Response('{}', 401);
              }
              throw http.ClientException('Network down');
            }),
          ),
          storageService: offlineStorage,
        );

        expect(await offlineRepo.restoreSession(), isNull);
        expect(
          (await offlineStorage.readSession())?.refreshToken,
          'rt_keep_me',
        );

        final rejectedStorage = InMemorySessionStorageService();
        await rejectedStorage.saveSession(savedSession);

        final rejectedRepo = AuthRepository(
          apiService: AuthApiService(
            baseUrl: 'http://localhost:8080/api',
            client: MockClient((_) async => http.Response('{}', 401)),
          ),
          storageService: rejectedStorage,
        );

        expect(await rejectedRepo.restoreSession(), isNull);
        expect(await rejectedStorage.readSession(), isNull);
      },
    );

    test(
      'restoreSession preserves offline session when /auth/me hits a transport failure',
      () async {
        const savedSession = AuthSession(
          accessToken: 'saved-token',
          user: AuthUser(username: 'user@test.vn', role: 'REGISTERED_USER'),
          rememberMe: true,
        );
        final storage = InMemorySessionStorageService();
        await storage.saveSession(savedSession);

        final repository = AuthRepository(
          apiService: AuthApiService(
            baseUrl: 'http://localhost:8080/api',
            client: MockClient((_) async {
              throw http.ClientException('Offline');
            }),
          ),
          storageService: storage,
        );

        final restored = await repository.restoreSession();
        expect(restored?.accessToken, 'saved-token');
        expect((await storage.readSession())?.accessToken, 'saved-token');
      },
    );

    test(
      'in-flight restoreSession and initialize do not overwrite a session saved by login',
      () async {
        final restoreGate = Completer<void>();
        final storage = InMemorySessionStorageService();
        await storage.saveSession(
          const AuthSession(
            accessToken: 'old-token',
            user: AuthUser(username: 'old@test.vn', role: 'REGISTERED_USER'),
            rememberMe: true,
          ),
        );

        final newToken = _buildFakeJwt({
          'id': 2,
          'sub': 'new@test.vn',
          'email': 'new@test.vn',
          'role': 'REGISTERED_USER',
        });

        final repository = AuthRepository(
          apiService: AuthApiService(
            baseUrl: 'http://localhost:8080/api',
            client: MockClient((request) async {
              if (request.url.path.endsWith('/auth/login')) {
                return http.Response(
                  jsonEncode({
                    'isSuccess': true,
                    'data': {'accessToken': newToken},
                  }),
                  200,
                  headers: {'content-type': 'application/json'},
                );
              }
              if (request.headers['Authorization'] == 'Bearer old-token') {
                await restoreGate.future;
                return http.Response(
                  jsonEncode({
                    'isSuccess': true,
                    'data': {
                      'id': 1,
                      'username': 'old@test.vn',
                      'fullName': 'Old User',
                      'role': 'REGISTERED_USER',
                    },
                  }),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'},
                );
              }
              return http.Response(
                jsonEncode({
                  'isSuccess': true,
                  'data': {
                    'id': 2,
                    'username': 'new@test.vn',
                    'fullName': 'New User',
                    'role': 'REGISTERED_USER',
                  },
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }),
          ),
          storageService: storage,
        );

        final authState = AuthState(authRepository: repository);
        final initFuture = authState.initialize();

        final loggedIn = await repository.login(
          identifier: 'new@test.vn',
          password: 'password123',
          rememberMe: true,
        );
        authState.setAuthenticatedSession(loggedIn);

        restoreGate.complete();
        await initFuture;

        expect(authState.session?.accessToken, newToken);
        expect(authState.user?.fullName, 'New User');
        expect((await storage.readSession())?.accessToken, newToken);
      },
    );

    testWidgets(
      'ScamShieldBrandBadge uses mutedInk subtitle on light surface and white on dark surface',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ScamShieldBrandBadge(darkSurface: false, showSubtitle: true),
                  ScamShieldBrandBadge(darkSurface: true, showSubtitle: true),
                ],
              ),
            ),
          ),
        );

        final subtitles = tester
            .widgetList<Text>(find.text('AI THREAT VERIFICATION • VIETNAM'))
            .toList();
        expect(subtitles, hasLength(2));
        expect(subtitles[0].style?.color, AppTheme.mutedInk);
        expect(
          subtitles[1].style?.color,
          Colors.white.withValues(alpha: 0.68),
        );
      },
    );
  });
}
