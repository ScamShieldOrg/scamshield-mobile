import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scamshield_mobile/app/auth_state.dart';
import 'package:scamshield_mobile/app/user_quota_state.dart';
import 'package:scamshield_mobile/core/theme/app_theme.dart';
import 'package:scamshield_mobile/data/models/auth_session.dart';
import 'package:scamshield_mobile/data/models/auth_user.dart';
import 'package:scamshield_mobile/data/repositories/auth_repository.dart';
import 'package:scamshield_mobile/data/repositories/dispute_repository.dart';
import 'package:scamshield_mobile/data/repositories/user_quota_repository.dart';
import 'package:scamshield_mobile/data/services/dispute_api_service.dart';
import 'package:scamshield_mobile/data/services/session_storage_service.dart';
import 'package:scamshield_mobile/data/services/user_quota_api_service.dart';
import 'package:scamshield_mobile/ui/dispute/submit_dispute_screen.dart';
import 'package:scamshield_mobile/ui/dispute/submit_dispute_validation.dart';

Widget _wrapWithAuth({
  AuthUser? user,
  UserQuotaRepository? quotaRepository,
  DisputeRepository? disputeRepository,
  DisputeAttachmentPicker? attachmentPicker,
}) {
  final repository = AuthRepository(
    storageService: InMemorySessionStorageService(),
  );
  final authState = AuthState(authRepository: repository);
  if (user != null) {
    authState.setAuthenticatedSession(
      AuthSession(accessToken: 'test-token', user: user),
    );
  }

  final effectiveQuotaRepository =
      quotaRepository ??
      UserQuotaRepository(
        apiService: UserQuotaApiService(
          baseUrl: 'http://localhost:8080/api',
          client: MockClient((_) async {
            return http.Response(
              jsonEncode({
                'isSuccess': true,
                'message': 'Lấy hạn mức kiểm tra thành công',
                'data': {
                  'userId': 1,
                  'fullName': 'Nguyễn Văn A',
                  'rankName': 'Tân Binh',
                  'limit': 100,
                  'used': 4,
                  'remaining': 96,
                  'resetsAt': '2026-11-25T00:00:00',
                },
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );

  final effectiveDisputeRepository =
      disputeRepository ??
      DisputeRepository(
        apiService: DisputeApiService(
          baseUrl: 'http://localhost:8080/api',
          client: MockClient((request) async {
            if (request.url.path.endsWith('/disputes/me/summary')) {
              return http.Response(
                jsonEncode({
                  'isSuccess': true,
                  'data': {
                    'totalSubmitted': 0,
                    'pending': 0,
                    'inReview': 0,
                    'needsMoreInfo': 0,
                    'approved': 0,
                    'rejected': 0,
                  },
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
            return http.Response('{}', 404);
          }),
        ),
      );

  final quotaState = UserQuotaState(quotaRepository: effectiveQuotaRepository);
  quotaState.syncAccessToken(authState.session?.accessToken);

  return MultiProvider(
    providers: [
      Provider<AuthRepository>.value(value: repository),
      Provider<UserQuotaRepository>.value(value: effectiveQuotaRepository),
      Provider<DisputeRepository>.value(value: effectiveDisputeRepository),
      ChangeNotifierProvider<AuthState>.value(value: authState),
      ChangeNotifierProvider<UserQuotaState>.value(value: quotaState),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: SubmitDisputeScreen(attachmentPicker: attachmentPicker),
    ),
  );
}

void main() {
  const registeredUser = AuthUser(
    id: 1,
    username: 'nguyenvana@gmail.com',
    fullName: 'Nguyễn Văn A',
    email: 'nguyenvana@gmail.com',
    role: 'REGISTERED_USER',
  );

  group('Submit dispute validation', () {
    test('validates indicator values per selected type', () {
      expect(
        validateDisputeIndicatorValue(
          DisputeIndicatorType.phone,
          '091.234.8899',
        ),
        isNull,
      );
      expect(
        validateDisputeIndicatorValue(DisputeIndicatorType.phone, 'abc'),
        isNotNull,
      );
      expect(
        validateDisputeIndicatorValue(
          DisputeIndicatorType.bankAccount,
          '19036888999012',
        ),
        isNull,
      );
      expect(
        validateDisputeIndicatorValue(
          DisputeIndicatorType.url,
          'https://tanphat.vn',
        ),
        isNull,
      );
      expect(
        validateDisputeIndicatorValue(
          DisputeIndicatorType.brandname,
          'TANPHAT',
        ),
        isNull,
      );
    });

    test('validates reason length, attachments, and agreement', () {
      expect(validateDisputeReason('Quá ngắn'), isNotNull);
      expect(
        validateDisputeReason(
          'Đầu số Hotline thuộc sở hữu chính chủ của doanh nghiệp chúng tôi.',
        ),
        isNull,
      );
      expect(validateDisputeAttachments(const []), isNotNull);
      expect(validateDisputeAgreement(false), isNotNull);
      expect(validateDisputeAgreement(true), isNull);
    });

    test('validates picked files for extension, content, and 5MB limit', () {
      final validPdf = validateAndBuildDisputeAttachment(
        id: '1',
        file: PickedDisputeFile(
          fileName: 'gpkd.pdf',
          sizeBytes: 4,
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
      );
      expect(validPdf.error, isNull);
      expect(validPdf.item?.contentType, 'application/pdf');
      expect(validPdf.item?.bytes, hasLength(4));

      final unsupported = validateAndBuildDisputeAttachment(
        id: '2',
        file: PickedDisputeFile(
          fileName: 'script.exe',
          sizeBytes: 4,
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
      );
      expect(unsupported.item, isNull);
      expect(unsupported.error, contains('PDF, JPG, PNG'));

      final oversized = validateAndBuildDisputeAttachment(
        id: '3',
        file: PickedDisputeFile(
          fileName: 'huge.png',
          sizeBytes: maxDisputeAttachmentBytes + 1,
          filePath: '/tmp/huge.png',
        ),
      );
      expect(oversized.item, isNull);
      expect(oversized.error, contains('5 MB'));
    });
  });

  group('SubmitDisputeScreen', () {
    testWidgets('blocks guest users and prompts login', (tester) async {
      await tester.pumpWidget(_wrapWithAuth());
      await tester.pumpAndSettle();

      expect(find.text('Tính năng dành cho Thành viên'), findsOneWidget);
      expect(find.text('Đăng nhập ngay'), findsOneWidget);
      expect(find.text('Biểu Mẫu Khiếu Nại'), findsNothing);
    });

    testWidgets(
      'leaves attachments unchanged on cancel and adds valid picked files',
      (tester) async {
        var callCount = 0;
        Future<List<PickedDisputeFile>?> picker() async {
          callCount++;
          if (callCount == 1) {
            return null;
          }
          return [
            PickedDisputeFile(
              fileName: 'GPKD_Real.pdf',
              sizeBytes: 1024,
              bytes: Uint8List.fromList(List.filled(1024, 65)),
            ),
          ];
        }

        await tester.pumpWidget(
          _wrapWithAuth(user: registeredUser, attachmentPicker: picker),
        );
        await tester.pumpAndSettle();

        expect(find.text('Đã dùng 4/100 lượt hôm nay'), findsOneWidget);
        expect(find.text('GPKD_TanPhatCorp.pdf'), findsNothing);

        await tester.ensureVisible(
          find.byKey(const ValueKey('dispute_upload_box')),
        );
        await tester.tap(find.byKey(const ValueKey('dispute_upload_box')));
        await tester.pumpAndSettle();
        expect(find.text('GPKD_Real.pdf'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('dispute_upload_box')));
        await tester.pumpAndSettle();
        expect(find.text('GPKD_Real.pdf'), findsOneWidget);
      },
    );

    testWidgets(
      'preserves form data on server rejection and confirms only when server accepts',
      (tester) async {
        var shouldAccept = false;
        String? capturedMultipartBody;

        final disputeRepository = DisputeRepository(
          apiService: DisputeApiService(
            baseUrl: 'http://localhost:8080/api',
            client: MockClient.streaming((request, bodyStream) async {
              final rawBody = await bodyStream.bytesToString();
              if (request.url.path.endsWith('/disputes/me/summary')) {
                return http.StreamedResponse(
                  Stream.value(
                    utf8.encode(
                      jsonEncode({
                        'isSuccess': true,
                        'data': {
                          'totalSubmitted': 1,
                          'pending': 1,
                          'inReview': 0,
                          'needsMoreInfo': 0,
                          'approved': 0,
                          'rejected': 0,
                        },
                      }),
                    ),
                  ),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'},
                );
              }

              if (request.method == 'POST' &&
                  request.url.path.endsWith('/disputes')) {
                capturedMultipartBody = rawBody;
                if (!shouldAccept) {
                  return http.StreamedResponse(
                    Stream.value(
                      utf8.encode(
                        jsonEncode({
                          'isSuccess': false,
                          'message':
                              'Không tìm thấy xác thực blacklist còn hiệu lực cho chỉ số này.',
                        }),
                      ),
                    ),
                    400,
                    headers: {
                      'content-type': 'application/json; charset=utf-8',
                    },
                  );
                }
                return http.StreamedResponse(
                  Stream.value(
                    utf8.encode(
                      jsonEncode({
                        'isSuccess': true,
                        'message':
                            'Hồ sơ khiếu nại đã được gửi và đang chờ thẩm định',
                        'data': {
                          'id': 4001,
                          'disputeCode': 'DSP-4001',
                          'status': 'PENDING',
                        },
                      }),
                    ),
                  ),
                  201,
                  headers: {'content-type': 'application/json; charset=utf-8'},
                );
              }

              return http.StreamedResponse(const Stream.empty(), 404);
            }),
          ),
        );

        await tester.pumpWidget(
          _wrapWithAuth(
            user: registeredUser,
            disputeRepository: disputeRepository,
            attachmentPicker: () async => [
              PickedDisputeFile(
                fileName: 'proof.pdf',
                sizeBytes: 16,
                bytes: Uint8List.fromList(utf8.encode('%PDF-1.4 sample!')),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('dispute_indicator_field')),
          '0912348899',
        );
        await tester.enterText(
          find.byKey(const ValueKey('dispute_reason_field')),
          'Đây là đầu số hotline chăm sóc khách hàng chính chủ của doanh nghiệp.',
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('dispute_upload_box')),
        );
        await tester.tap(find.byKey(const ValueKey('dispute_upload_box')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const ValueKey('dispute_agree_checkbox')),
        );
        await tester.tap(find.byKey(const ValueKey('dispute_agree_checkbox')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const ValueKey('dispute_submit_button')),
        );
        await tester.tap(find.byKey(const ValueKey('dispute_submit_button')));
        await tester.pumpAndSettle();

        expect(capturedMultipartBody, contains('"indicatorType":"PHONE"'));
        expect(capturedMultipartBody, contains('proof.pdf'));
        expect(
          find.byKey(const ValueKey('dispute_submit_error_banner')),
          findsOneWidget,
        );
        // Form data must remain intact after server rejection.
        expect(find.text('0912348899'), findsOneWidget);
        expect(find.text('proof.pdf'), findsOneWidget);

        // Retry after server accepts.
        shouldAccept = true;
        await tester.ensureVisible(
          find.byKey(const ValueKey('dispute_submit_button')),
        );
        await tester.tap(find.byKey(const ValueKey('dispute_submit_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('dispute_submit_error_banner')),
          findsNothing,
        );
        expect(find.text('proof.pdf'), findsNothing);
        expect(find.textContaining('#DSP-4001'), findsOneWidget);
      },
    );
  });
}
