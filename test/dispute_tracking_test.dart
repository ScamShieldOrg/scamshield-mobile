import 'dart:async';
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
import 'package:scamshield_mobile/data/models/dispute_models.dart';
import 'package:scamshield_mobile/data/repositories/auth_repository.dart';
import 'package:scamshield_mobile/data/repositories/dispute_repository.dart';
import 'package:scamshield_mobile/data/repositories/user_quota_repository.dart';
import 'package:scamshield_mobile/data/services/dispute_api_service.dart';
import 'package:scamshield_mobile/data/services/session_storage_service.dart';
import 'package:scamshield_mobile/data/services/user_quota_api_service.dart';
import 'package:scamshield_mobile/ui/dispute/dispute_tracking_screen.dart';
import 'package:scamshield_mobile/ui/dispute/dispute_tracking_viewmodel.dart';

Widget _wrapTrackingScreen({AuthUser? user, http.Client? disputeClient}) {
  final authRepository = AuthRepository(
    storageService: InMemorySessionStorageService(),
  );
  final authState = AuthState(authRepository: authRepository);
  if (user != null) {
    authState.setAuthenticatedSession(
      AuthSession(accessToken: 'test-token', user: user),
    );
  }

  final quotaRepository = UserQuotaRepository(
    apiService: UserQuotaApiService(
      baseUrl: 'http://localhost:8080/api',
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'isSuccess': true,
            'data': {
              'userId': 1,
              'fullName': 'Nguyễn Văn A',
              'rankName': 'Tân Binh',
              'limit': 100,
              'used': 6,
              'remaining': 94,
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    ),
  );

  final effectiveDisputeClient =
      disputeClient ??
      MockClient((request) async {
        if (request.url.path.endsWith('/disputes/me/summary')) {
          return http.Response(
            jsonEncode({
              'isSuccess': true,
              'data': {
                'totalSubmitted': 3,
                'pending': 0,
                'inReview': 1,
                'needsMoreInfo': 1,
                'approved': 1,
                'rejected': 0,
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        final statusFilter = request.url.queryParameters['status'];
        final allItems = [
          {
            'id': 3091,
            'disputeCode': 'DSP-3091',
            'status': 'IN_REVIEW',
            'priority': 'HIGH',
            'reason': 'Hotline chính chủ của doanh nghiệp.',
            'progressMessage':
                'Hệ thống đã tạm hạ 70% trọng số cảnh báo khi người dùng nhận cuộc gọi.',
            'estimatedResolutionAt': '2026-11-25T17:00:00',
            'createdAt': '2026-11-24T08:30:00',
            'indicator': {
              'id': 11,
              'type': 'PHONE',
              'displayValue': '091.234.8899',
              'blacklistStatus': 'ACTIVE',
            },
            'evidenceCount': 2,
            'attachments': [
              {'id': 1, 'fileName': 'GPKD Tân Phát'},
              {'id': 2, 'fileName': 'HĐ VNPT'},
            ],
          },
          {
            'id': 2814,
            'disputeCode': 'DSP-2814',
            'status': 'APPROVED',
            'priority': 'NORMAL',
            'reason': 'Tên miền bị giả mạo.',
            'resolutionReason':
                'Xác nhận tên miền bị đối tượng mạo danh chiếm quyền DNS tạm thời.',
            'resolutionDocumentUrl': 'https://files.example/qd-2814.pdf',
            'createdAt': '2026-10-12T09:00:00',
            'resolvedAt': '2026-10-15T10:00:00',
            'indicator': {
              'id': 12,
              'type': 'URL',
              'displayValue': 'techcorp-vietnam.vn',
              'blacklistStatus': 'RETRACTED',
            },
            'evidenceCount': 1,
            'attachments': const [],
          },
          {
            'id': 2105,
            'disputeCode': 'DSP-2105',
            'status': 'NEEDS_MORE_INFO',
            'priority': 'NORMAL',
            'reason': 'STK kinh doanh hợp lệ.',
            'supplementReason':
                'Vui lòng tải lên sao kê ngân hàng có mộc đỏ 30 ngày gần nhất.',
            'supplementDeadline': '2026-11-26T14:00:00',
            'createdAt': '2026-09-02T09:00:00',
            'indicator': {
              'id': 13,
              'type': 'BANK_ACCOUNT',
              'displayValue': 'Techcombank • 1902.9999.xxxx',
              'blacklistStatus': 'ACTIVE',
            },
            'evidenceCount': 1,
            'attachments': const [],
          },
        ];

        final filtered = statusFilter == 'APPROVED'
            ? allItems.where((e) => e['status'] == 'APPROVED').toList()
            : statusFilter != null
            ? allItems.where((e) => e['status'] != 'APPROVED').toList()
            : allItems;

        return http.Response(
          jsonEncode({
            'isSuccess': true,
            'data': {
              'data': filtered,
              'currentPage': 0,
              'totalItems': filtered.length,
              'totalPages': 1,
              'pageSize': 20,
              'hasNext': false,
              'hasPrevious': false,
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

  final disputeRepository = DisputeRepository(
    apiService: DisputeApiService(
      baseUrl: 'http://localhost:8080/api',
      client: effectiveDisputeClient,
    ),
  );
  final quotaState = UserQuotaState(quotaRepository: quotaRepository);
  quotaState.syncAccessToken(authState.session?.accessToken);

  return MultiProvider(
    providers: [
      Provider<AuthRepository>.value(value: authRepository),
      Provider<UserQuotaRepository>.value(value: quotaRepository),
      Provider<DisputeRepository>.value(value: disputeRepository),
      ChangeNotifierProvider<AuthState>.value(value: authState),
      ChangeNotifierProvider<UserQuotaState>.value(value: quotaState),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const DisputeTrackingScreen(),
    ),
  );
}

void main() {
  group('Dispute models formatting', () {
    test('formats dates and supplement remaining time cleanly', () {
      final now = DateTime(2026, 11, 24, 14, 0);
      expect(formatDisputeDate(DateTime(2024, 10, 15)), '15/10/2024');
      expect(
        formatDisputeSubmittedAt(DateTime(2026, 11, 24, 8, 30), now: now),
        'Nộp lúc 08:30 hôm nay',
      );
      expect(
        formatSupplementRemaining(DateTime(2026, 11, 26, 14, 0), now: now),
        'Còn 02 ngày',
      );
      expect(
        formatSupplementRemaining(DateTime(2026, 11, 23, 14, 0), now: now),
        'Đã quá hạn',
      );
    });
  });

  group('DisputeTrackingScreen', () {
    testWidgets('blocks guest users and prompts login', (tester) async {
      await tester.pumpWidget(_wrapTrackingScreen());
      await tester.pumpAndSettle();

      expect(find.text('Tính năng dành cho Thành viên'), findsOneWidget);
      expect(find.text('Đăng nhập ngay'), findsOneWidget);
    });

    testWidgets(
      'renders real disputes, filters cleanly, opens sidebar, and switches to submit screen',
      (tester) async {
        const registeredUser = AuthUser(
          id: 1,
          username: 'nguyenvana@gmail.com',
          fullName: 'Nguyễn Văn A',
          email: 'nguyenvana@gmail.com',
          role: 'REGISTERED_USER',
        );

        await tester.pumpWidget(_wrapTrackingScreen(user: registeredUser));
        await tester.pumpAndSettle();

        expect(find.text('Đã dùng 6/100 lượt hôm nay'), findsOneWidget);
        expect(find.text('Tiến Trình Đơn (3)'), findsOneWidget);
        expect(find.text('Tất cả (3)'), findsOneWidget);
        expect(find.text('Đang xử lý (2)'), findsOneWidget);
        expect(find.text('Đã gỡ (1)'), findsOneWidget);

        expect(find.text('#DSP-3091'), findsOneWidget);
        expect(find.text('#DSP-2814'), findsOneWidget);
        expect(find.text('#DSP-2105'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('dispute_filter_resolved')));
        await tester.pumpAndSettle();

        expect(find.text('#DSP-2814'), findsOneWidget);
        expect(find.text('#DSP-3091'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('user_menu_button')));
        await tester.pumpAndSettle();
        expect(find.text('Đăng xuất an toàn'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const ValueKey('tracking_create_new_dispute_button')),
        );
        await tester.tap(
          find.byKey(const ValueKey('tracking_create_new_dispute_button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Biểu Mẫu Khiếu Nại'), findsOneWidget);
      },
    );
  });

  group('DisputeTrackingViewModel state transitions', () {
    test(
      'selectFilter invalidates previous filter items/page and exposes error on failure',
      () async {
        final repository = DisputeRepository(
          apiService: DisputeApiService(
            baseUrl: 'http://localhost:8080/api',
            client: MockClient((request) async {
              if (request.url.path.endsWith('/disputes/me/summary')) {
                return http.Response(
                  jsonEncode({
                    'isSuccess': true,
                    'data': {
                      'totalSubmitted': 2,
                      'pending': 1,
                      'inReview': 0,
                      'needsMoreInfo': 0,
                      'approved': 1,
                      'rejected': 0,
                    },
                  }),
                  200,
                );
              }
              if (request.url.queryParameters['status'] == 'APPROVED') {
                return http.Response(
                  jsonEncode({'isSuccess': false, 'message': 'Lỗi máy chủ'}),
                  500,
                  headers: {'content-type': 'application/json; charset=utf-8'},
                );
              }
              return http.Response(
                jsonEncode({
                  'isSuccess': true,
                  'data': {
                    'data': [
                      {
                        'id': 1,
                        'disputeCode': 'DSP-1',
                        'status': 'PENDING',
                        'priority': 'NORMAL',
                        'reason': 'test',
                        'evidenceCount': 0,
                        'attachments': const [],
                      },
                    ],
                    'currentPage': 0,
                    'totalItems': 2,
                    'hasNext': true,
                  },
                }),
                200,
              );
            }),
          ),
        );

        final viewModel = DisputeTrackingViewModel(
          disputeRepository: repository,
        );
        await viewModel.loadAll(accessToken: 'token');
        expect(viewModel.items, hasLength(1));
        expect(viewModel.hasNext, isTrue);

        await viewModel.selectFilter(
          filter: DisputeFilterTab.resolved,
          accessToken: 'token',
        );
        expect(viewModel.items, isEmpty);
        expect(viewModel.hasNext, isFalse);
        expect(viewModel.errorMessage, 'Lỗi máy chủ');
        viewModel.dispose();
      },
    );

    test(
      'loadAll and selectFilter reset _isLoadingMore while a pagination request is in flight',
      () async {
        final page1Gate = Completer<void>();
        var page1Requests = 0;

        final repository = DisputeRepository(
          apiService: DisputeApiService(
            baseUrl: 'http://localhost:8080/api',
            client: MockClient((request) async {
              if (request.url.path.endsWith('/disputes/me/summary')) {
                return http.Response(
                  jsonEncode({
                    'isSuccess': true,
                    'data': {
                      'totalSubmitted': 2,
                      'pending': 2,
                      'inReview': 0,
                      'needsMoreInfo': 0,
                      'approved': 0,
                      'rejected': 0,
                    },
                  }),
                  200,
                );
              }
              final page = request.url.queryParameters['page'];
              if (page == '1') {
                page1Requests++;
                if (page1Requests == 1) {
                  await page1Gate.future;
                }
                return http.Response(
                  jsonEncode({
                    'isSuccess': true,
                    'data': {
                      'data': [
                        {
                          'id': 2,
                          'disputeCode': 'DSP-2',
                          'status': 'PENDING',
                          'priority': 'NORMAL',
                          'reason': 'page 1',
                          'evidenceCount': 0,
                          'attachments': const [],
                        },
                      ],
                      'currentPage': 1,
                      'totalItems': 2,
                      'hasNext': false,
                    },
                  }),
                  200,
                );
              }
              return http.Response(
                jsonEncode({
                  'isSuccess': true,
                  'data': {
                    'data': [
                      {
                        'id': 1,
                        'disputeCode': 'DSP-1',
                        'status': 'PENDING',
                        'priority': 'NORMAL',
                        'reason': 'page 0',
                        'evidenceCount': 0,
                        'attachments': const [],
                      },
                    ],
                    'currentPage': 0,
                    'totalItems': 2,
                    'hasNext': true,
                  },
                }),
                200,
              );
            }),
          ),
        );

        final viewModel = DisputeTrackingViewModel(
          disputeRepository: repository,
        );
        await viewModel.loadAll(accessToken: 'token');

        final staleLoadMore = viewModel.loadMore(accessToken: 'token');
        expect(viewModel.isLoadingMore, isTrue);

        await viewModel.selectFilter(
          filter: DisputeFilterTab.inProgress,
          accessToken: 'token',
        );
        expect(viewModel.isLoadingMore, isFalse);

        // Stale loadMore finishing should not break subsequent pagination.
        page1Gate.complete();
        await staleLoadMore;

        await viewModel.loadMore(accessToken: 'token');
        expect(viewModel.items, hasLength(2));
        expect(viewModel.isLoadingMore, isFalse);
        viewModel.dispose();
      },
    );
  });
}
