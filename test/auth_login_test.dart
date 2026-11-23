import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_mobile/app/app.dart';
import 'package:scamshield_mobile/data/models/api_exception.dart';
import 'package:scamshield_mobile/data/repositories/auth_repository.dart';
import 'package:scamshield_mobile/data/services/auth_api_service.dart';
import 'package:scamshield_mobile/data/services/session_storage_service.dart';

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
}
