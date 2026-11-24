import 'dart:convert';

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
import 'package:scamshield_mobile/data/repositories/user_quota_repository.dart';
import 'package:scamshield_mobile/data/services/session_storage_service.dart';
import 'package:scamshield_mobile/data/services/user_quota_api_service.dart';
import 'package:scamshield_mobile/ui/dispute/submit_dispute_screen.dart';
import 'package:scamshield_mobile/ui/dispute/submit_dispute_validation.dart';

Widget _wrapWithAuth({
  AuthUser? user,
  UserQuotaRepository? quotaRepository,
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

  final quotaState = UserQuotaState(quotaRepository: effectiveQuotaRepository);
  quotaState.syncAccessToken(authState.session?.accessToken);

  return MultiProvider(
    providers: [
      Provider<AuthRepository>.value(value: repository),
      Provider<UserQuotaRepository>.value(value: effectiveQuotaRepository),
      ChangeNotifierProvider<AuthState>.value(value: authState),
      ChangeNotifierProvider<UserQuotaState>.value(value: quotaState),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const SubmitDisputeScreen(),
    ),
  );
}

void main() {
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
      'shows real AI quota, starts with no mock files, and displays uploaded file cards',
      (tester) async {
        const registeredUser = AuthUser(
          id: 1,
          username: 'nguyenvana@gmail.com',
          fullName: 'Nguyễn Văn A',
          email: 'nguyenvana@gmail.com',
          role: 'REGISTERED_USER',
        );

        await tester.pumpWidget(_wrapWithAuth(user: registeredUser));
        await tester.pumpAndSettle();

        expect(find.text('Hạn mức tra cứu AI'), findsOneWidget);
        expect(find.text('Đã dùng 4/100 lượt hôm nay'), findsOneWidget);
        expect(find.text('Đã dùng 18/50 lượt hôm nay'), findsNothing);
        expect(find.text('GPKD_TanPhatCorp.pdf'), findsNothing);
        expect(find.text('HopDong_VNPT_0912348899.pdf'), findsNothing);

        await tester.ensureVisible(
          find.byKey(const ValueKey('dispute_upload_box')),
        );
        await tester.tap(find.byKey(const ValueKey('dispute_upload_box')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Chọn tệp PDF (ĐKKD / Hợp đồng)'));
        await tester.pumpAndSettle();

        expect(find.text('GiayPhepKinhDoanh_1.pdf'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('user_menu_button')));
        await tester.pumpAndSettle();

        expect(find.text('Khiếu Nại Chỉ Số'), findsOneWidget);
        expect(find.text('Đăng xuất an toàn'), findsOneWidget);
      },
    );
  });
}
