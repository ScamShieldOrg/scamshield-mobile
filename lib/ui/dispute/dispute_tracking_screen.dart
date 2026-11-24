import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../app/user_quota_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/dispute_models.dart';
import '../../data/repositories/dispute_repository.dart';
import '../auth/login_screen.dart';
import '../shared/ai_quota_banner.dart';
import '../shared/user_app_bar.dart';
import '../shared/user_bottom_nav.dart';
import '../shared/user_sidebar_drawer.dart';
import 'dispute_tracking_viewmodel.dart';
import 'submit_dispute_screen.dart';

class DisputeTrackingScreen extends StatefulWidget {
  const DisputeTrackingScreen({super.key});

  @override
  State<DisputeTrackingScreen> createState() => _DisputeTrackingScreenState();
}

class _DisputeTrackingScreenState extends State<DisputeTrackingScreen> {
  static const _activeBlue = Color(0xFF2563EB);
  static const _softBlue = Color(0xFFEFF6FF);
  static const _skyBadgeBg = Color(0xFFE0F2FE);
  static const _skyBadgeFg = Color(0xFF0369A1);
  static const _periwinkleBg = Color(0xFFE8EEFF);
  static const _tabTrack = Color(0xFFEEF2FA);
  static const _softRedBg = Color(0xFFFEE2E2);
  static const _topBarBlue = Color(0xFFBFDBFE);
  static const _topBarSky = Color(0xFFBAE6FD);
  static const _topBarRed = Color(0xFFFECACA);

  late final DisputeTrackingViewModel _viewModel;
  bool _isLightMode = true;
  String? _loadedAccessToken;

  @override
  void initState() {
    super.initState();
    final repository = context.read<DisputeRepository?>() ?? DisputeRepository();
    _viewModel = DisputeTrackingViewModel(disputeRepository: repository);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncAndLoad();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _syncAndLoad() {
    final authState = context.read<AuthState?>();
    final user = authState?.user;
    final token = authState?.session?.accessToken;
    final isRegisteredUser =
        user != null && user.role.toUpperCase() == 'REGISTERED_USER';
    if (!isRegisteredUser || token == null || token.isEmpty) {
      return;
    }

    final quotaState = context.read<UserQuotaState?>();
    if (quotaState != null && !quotaState.isLoading) {
      quotaState.refresh();
    }

    if (_loadedAccessToken != token) {
      _loadedAccessToken = token;
      _viewModel.loadAll(accessToken: token);
    }
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSubmitDispute() {
    Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const SubmitDisputeScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _handleSignOut(AuthState authState) async {
    await authState.signOut();
    if (!mounted) {
      return;
    }
    _showNotice('Đã đăng xuất an toàn.');
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _handleSidebarNavigation(UserSidebarDestination destination) {
    if (destination == UserSidebarDestination.dispute) {
      return;
    }
    if (destination == UserSidebarDestination.scamCheck) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
      return;
    }
    _showNotice('Mục "${destination.title}" trên di động đang được phát triển.');
  }

  void _handleBottomNavTap(UserBottomNavTab tab) {
    if (tab == UserBottomNavTab.check) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
      return;
    }
    final label = switch (tab) {
      UserBottomNavTab.check => 'Kiểm tra',
      UserBottomNavTab.history => 'Lịch sử',
      UserBottomNavTab.report => 'Gửi báo cáo mới',
      UserBottomNavTab.news => 'Tin tức & Thông báo',
      UserBottomNavTab.account => 'Tài khoản',
    };
    _showNotice('Tính năng "$label" trên di động đang được phát triển.');
  }

  void _openDisputeDetailSheet(DisputeRecord item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chi tiết hồ sơ ${item.displayCode}',
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                if (item.indicator != null) ...[
                  Text(
                    '${item.indicator!.fieldLabel} ${item.indicator!.displayValue}',
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  formatDisputeSubmittedAt(item.createdAt),
                  style: const TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 12.5,
                    color: AppTheme.mutedInk,
                  ),
                ),
                if (item.reason.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Nội dung giải trình',
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.reason,
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13.5,
                      color: AppTheme.mutedInk,
                      height: 1.45,
                    ),
                  ),
                ],
                if (item.progressMessage != null &&
                    item.progressMessage!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Trạng thái xử lý gần nhất',
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.progressMessage!,
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13.5,
                      color: AppTheme.ink,
                      height: 1.45,
                    ),
                  ),
                ],
                if (item.resolutionReason != null &&
                    item.resolutionReason!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Kết luận thẩm định',
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.resolutionReason!,
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13.5,
                      color: AppTheme.ink,
                      height: 1.45,
                    ),
                  ),
                ],
                if (item.attachments.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Tệp minh chứng (${item.attachments.length})',
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final att in item.attachments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 16,
                            color: AppTheme.mutedInk,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              att.fileName?.isNotEmpty == true
                                  ? att.fileName!
                                  : 'Tài liệu #${att.id ?? ''}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'sans-serif',
                                fontSize: 13,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final pageTheme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: 'sans-serif'),
    );
    final authState = context.watch<AuthState?>();
    final user = authState?.user;
    final accessToken = authState?.session?.accessToken;
    final isRegisteredUser =
        user != null && user.role.toUpperCase() == 'REGISTERED_USER';

    if (isRegisteredUser &&
        accessToken != null &&
        accessToken.isNotEmpty &&
        _loadedAccessToken != accessToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncAndLoad();
        }
      });
    }

    return ChangeNotifierProvider<DisputeTrackingViewModel>.value(
      value: _viewModel,
      child: Theme(
        data: pageTheme,
        child: Scaffold(
          backgroundColor: AppTheme.page,
          drawer: isRegisteredUser
              ? UserSidebarDrawer(
                  activeDestination: UserSidebarDestination.dispute,
                  unreadNotificationCount: 3,
                  isLightMode: _isLightMode,
                  onLightModeChanged: (value) {
                    setState(() => _isLightMode = value);
                  },
                  onSelectDestination: _handleSidebarNavigation,
                  onSignOut: authState != null
                      ? () => _handleSignOut(authState)
                      : null,
                )
              : null,
          appBar: isRegisteredUser
              ? UserAppBar(
                  user: user,
                  unreadNotificationCount: 3,
                  onNotificationsTap: () => _showNotice(
                    'Mục "Thông Báo" trên di động đang được phát triển.',
                  ),
                )
              : AppBar(
                  title: const Text(
                    'Khiếu Nại & Gỡ Nhãn Sai',
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
          body: SafeArea(
            top: false,
            child: isRegisteredUser
                ? _buildTrackingBody(accessToken ?? '')
                : _buildAccessRestrictedBody(user != null),
          ),
          bottomNavigationBar: isRegisteredUser
              ? UserBottomNav(
                  activeTab: null,
                  hasNewsDot: true,
                  onSelectTab: _handleBottomNavTap,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildAccessRestrictedBody(bool isSignedInOtherRole) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _softBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.gavel_outlined,
                        color: AppTheme.navy,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tính năng dành cho Thành viên',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSignedInOtherRole
                        ? 'Tài khoản hiện tại không thuộc nhóm Thành viên đã đăng ký (Registered User) nên không thể theo dõi đơn khiếu nại.'
                        : 'Vui lòng đăng nhập bằng tài khoản Thành viên đã đăng ký để theo dõi tiến trình hồ sơ khiếu nại.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13.5,
                      color: AppTheme.mutedInk,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!isSignedInOtherRole)
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppTheme.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đăng nhập ngay',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        foregroundColor: AppTheme.ink,
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Quay lại',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingBody(String accessToken) {
    return Consumer<DisputeTrackingViewModel>(
      builder: (context, viewModel, _) {
        final summary = viewModel.summary;
        final totalCount = summary?.totalSubmitted ?? viewModel.items.length;
        final inProgressCount = summary?.inProgressTotal ?? 0;
        final resolvedCount = summary?.approved ?? 0;

        return RefreshIndicator(
          color: AppTheme.navy,
          onRefresh: () async {
            if (accessToken.isNotEmpty) {
              await Future.wait([
                viewModel.loadAll(accessToken: accessToken),
                if (context.read<UserQuotaState?>() case final quotaState?)
                  quotaState.refresh(),
              ]);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AiQuotaBanner(),
                    const SizedBox(height: 18),
                    const Text(
                      'Khiếu Nại & Gỡ Nhãn Sai',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSegmentedTabs(totalCount),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill(
                            key: const ValueKey('dispute_filter_all'),
                            label: 'Tất cả ($totalCount)',
                            selected:
                                viewModel.activeFilter == DisputeFilterTab.all,
                            onTap: () => viewModel.selectFilter(
                              filter: DisputeFilterTab.all,
                              accessToken: accessToken,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterPill(
                            key: const ValueKey('dispute_filter_in_progress'),
                            label: 'Đang xử lý ($inProgressCount)',
                            selected:
                                viewModel.activeFilter ==
                                DisputeFilterTab.inProgress,
                            onTap: () => viewModel.selectFilter(
                              filter: DisputeFilterTab.inProgress,
                              accessToken: accessToken,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterPill(
                            key: const ValueKey('dispute_filter_resolved'),
                            label: 'Đã gỡ ($resolvedCount)',
                            selected:
                                viewModel.activeFilter ==
                                DisputeFilterTab.resolved,
                            onTap: () => viewModel.selectFilter(
                              filter: DisputeFilterTab.resolved,
                              accessToken: accessToken,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (viewModel.isLoading && viewModel.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.navy,
                          ),
                        ),
                      )
                    else if (viewModel.errorMessage != null &&
                        viewModel.items.isEmpty)
                      _buildErrorCard(viewModel.errorMessage!, accessToken)
                    else if (viewModel.items.isEmpty)
                      _buildEmptyCard(viewModel.activeFilter)
                    else ...[
                      for (final item in viewModel.items) ...[
                        _buildDisputeCard(item),
                        const SizedBox(height: 14),
                      ],
                      if (viewModel.hasNext) ...[
                        OutlinedButton(
                          onPressed: viewModel.isLoadingMore
                              ? null
                              : () => viewModel.loadMore(
                                  accessToken: accessToken,
                                ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: AppTheme.navy,
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: viewModel.isLoadingMore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.navy,
                                  ),
                                )
                              : const Text(
                                  'Tải thêm hồ sơ',
                                  style: TextStyle(
                                    fontFamily: 'sans-serif',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                    const SizedBox(height: 6),
                    _buildCreateNewCtaCard(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentedTabs(int totalCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _tabTrack,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              key: const ValueKey('tracking_tab_submit'),
              onTap: _openSubmitDispute,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  'Nộp Đơn Phản Chứng',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedInk,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              key: const ValueKey('tracking_tab_progress'),
              padding: const EdgeInsets.symmetric(
                vertical: 11,
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.navy.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Tiến Trình Đơn ($totalCount)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppTheme.navy : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: AppTheme.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppTheme.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisputeCard(DisputeRecord item) {
    final topAccentColor = switch (item.status) {
      DisputeRecordStatus.approved => _topBarSky,
      DisputeRecordStatus.needsMoreInfo ||
      DisputeRecordStatus.rejected => _topBarRed,
      _ => _topBarBlue,
    };

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: topAccentColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: switch (item.status) {
              DisputeRecordStatus.approved => _buildApprovedCardContent(item),
              DisputeRecordStatus.needsMoreInfo =>
                _buildNeedsMoreInfoCardContent(item),
              DisputeRecordStatus.rejected => _buildRejectedCardContent(item),
              _ => _buildInProgressCardContent(item),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressCardContent(DisputeRecord item) {
    final statusLabel = item.status == DisputeRecordStatus.pending
        ? 'Chờ Thẩm Định'
        : 'Đang Xử Lý';
    final estimatedText = formatEstimatedResolution(item.estimatedResolutionAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    item.displayCode,
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  if (item.isHighPriority)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.muted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Ưu tiên cao',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _periwinkleBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _activeBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _activeBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formatDisputeSubmittedAt(item.createdAt),
          style: const TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 12,
            color: AppTheme.mutedInk,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.page,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (item.indicator != null)
                _buildInfoRow(
                  item.indicator!.fieldLabel,
                  item.indicator!.displayValue,
                ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hồ sơ đính kèm:',
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 12.5,
                      color: AppTheme.mutedInk,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.attach_file_rounded,
                          size: 14,
                          color: AppTheme.mutedInk,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            item.attachmentsSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.progressMessage != null &&
                  item.progressMessage!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.manage_search_rounded,
                          size: 17,
                          color: AppTheme.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.progressMessage!,
                          style: const TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (estimatedText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppTheme.blue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        estimatedText,
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _openDisputeDetailSheet(item),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  backgroundColor: _tabTrack,
                  foregroundColor: AppTheme.ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text(
                  'Xem log đối soát',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showNotice(
                  'Bổ sung chứng cứ cho ${item.displayCode} đang được phát triển.',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  backgroundColor: AppTheme.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text(
                  'Bổ sung chứng cứ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApprovedCardContent(DisputeRecord item) {
    final summaryNote = item.resolutionReason?.isNotEmpty == true
        ? item.resolutionReason!
        : (item.progressMessage ?? 'Đã hoàn tất thẩm định và giải tỏa nhãn.');
    final hasDocument =
        item.resolutionDocumentUrl != null &&
        item.resolutionDocumentUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              item.displayCode,
              style: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.verified_outlined,
              size: 18,
              color: AppTheme.blue,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _skyBadgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 14,
                    color: _skyBadgeFg,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Đã Gỡ Blacklist',
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _skyBadgeFg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Hoàn tất ngày ${formatDisputeDate(item.resolvedAt ?? item.createdAt)}',
          style: const TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 12,
            color: AppTheme.mutedInk,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.page,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (item.indicator != null)
                _buildInfoRow(
                  item.indicator!.fieldLabel,
                  item.indicator!.displayValue,
                ),
              if (hasDocument) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Biên bản thẩm định:',
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 12.5,
                        color: AppTheme.mutedInk,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '#QĐ-${item.id}/SCS-A05',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  summaryNote,
                  style: const TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: hasDocument
              ? () => _showNotice(
                  'Đang chuẩn bị biên bản giải tỏa cho ${item.displayCode}.',
                )
              : () => _openDisputeDetailSheet(item),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            backgroundColor: _periwinkleBg,
            foregroundColor: AppTheme.navy,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(
            hasDocument ? Icons.download_rounded : Icons.visibility_outlined,
            size: 17,
          ),
          label: Text(
            hasDocument
                ? 'Tải biên bản giải tỏa chính thức (.PDF)'
                : 'Xem chi tiết kết quả giải tỏa',
            style: const TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNeedsMoreInfoCardContent(DisputeRecord item) {
    final remainingText = formatSupplementRemaining(item.supplementDeadline);
    final quote = item.supplementReason?.isNotEmpty == true
        ? item.supplementReason!
        : (item.progressMessage ??
              'Vui lòng bổ sung thêm tài liệu xác minh chính chủ.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.displayCode,
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _softRedBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          remainingText,
                          style: const TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDisputeSubmittedAt(item.createdAt),
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 12,
                      color: AppTheme.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _softRedBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: AppTheme.error,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Cần Bổ Sung\nMinh Chứng',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.error,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.page,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (item.indicator != null)
                _buildInfoRow(
                  item.indicator!.fieldLabel,
                  item.indicator!.displayValue,
                ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.errorBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yêu cầu từ kiểm duyệt viên A05:',
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedInk,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '“$quote”',
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.error,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Thời hạn hoàn thiện:',
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 12.5,
                      color: AppTheme.mutedInk,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    remainingText,
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _showNotice(
            'Cập nhật chứng cứ cho ${item.displayCode} đang được phát triển.',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            backgroundColor: AppTheme.navy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.photo_camera_outlined, size: 17),
          label: const Text(
            'Cập nhật chứng cứ ngay',
            style: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedCardContent(DisputeRecord item) {
    final reason = item.resolutionReason?.isNotEmpty == true
        ? item.resolutionReason!
        : (item.progressMessage ?? 'Hồ sơ khiếu nại chưa được chấp nhận.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              item.displayCode,
              style: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _softRedBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel_outlined, size: 14, color: AppTheme.error),
                  SizedBox(width: 5),
                  Text(
                    'Từ Chối',
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Hoàn tất ngày ${formatDisputeDate(item.resolvedAt ?? item.createdAt)}',
          style: const TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 12,
            color: AppTheme.mutedInk,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.page,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (item.indicator != null)
                _buildInfoRow(
                  item.indicator!.fieldLabel,
                  item.indicator!.displayValue,
                ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  reason,
                  style: const TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 12.5,
                    color: AppTheme.ink,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _openDisputeDetailSheet(item),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            backgroundColor: _tabTrack,
            foregroundColor: AppTheme.ink,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.description_outlined, size: 16),
          label: const Text(
            'Xem chi tiết kết luận',
            style: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 12.5,
            color: AppTheme.mutedInk,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message, String accessToken) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.errorBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 32),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _viewModel.loadAll(accessToken: accessToken),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(DisputeFilterTab filter) {
    final description = switch (filter) {
      DisputeFilterTab.inProgress =>
        'Hiện chưa có hồ sơ khiếu nại nào đang xử lý.',
      DisputeFilterTab.resolved =>
        'Hiện chưa có hồ sơ nào đã được gỡ nhãn blacklist.',
      DisputeFilterTab.all =>
        'Bạn chưa gửi hồ sơ khiếu nại nào. Nếu có chỉ số bị gắn nhãn nhầm, hãy tạo đơn khiếu nại mới.',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 34,
              color: AppTheme.mutedInk,
            ),
            const SizedBox(height: 10),
            const Text(
              'Chưa có hồ sơ khiếu nại',
              style: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 13,
                color: AppTheme.mutedInk,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateNewCtaCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppTheme.shieldBlue,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cần gỡ nhầm hotline hoặc website?',
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const ValueKey('tracking_create_new_dispute_button'),
            onPressed: _openSubmitDispute,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text(
              'Tạo Đơn Khiếu Nại Mới',
              style: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
