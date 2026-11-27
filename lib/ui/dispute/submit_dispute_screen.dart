import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../app/user_quota_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/api_exception.dart';
import '../../data/repositories/dispute_repository.dart';
import '../auth/login_screen.dart';
import '../shared/ai_quota_banner.dart';
import '../shared/guest_menu.dart';
import '../shared/scamshield_header.dart';
import '../shared/scamshield_navigation.dart';
import 'dispute_tracking_screen.dart';
import 'submit_dispute_validation.dart';

typedef DisputeAttachmentPicker = Future<List<PickedDisputeFile>?> Function();

class SubmitDisputeScreen extends StatefulWidget {
  const SubmitDisputeScreen({super.key, this.attachmentPicker});

  /// Optional override for selecting PDF/image attachments (defaults to [FilePicker]).
  final DisputeAttachmentPicker? attachmentPicker;

  @override
  State<SubmitDisputeScreen> createState() => _SubmitDisputeScreenState();
}

class _SubmitDisputeScreenState extends State<SubmitDisputeScreen> {
  static const _activeBlue = Color(0xFF2563EB);
  static const _softBlue = Color(0xFFEFF6FF);
  static const _tabTrack = Color(0xFFEEF2FA);
  static const _requiredBg = Color(0xFFFEE2E2);

  final _formKey = GlobalKey<FormState>();
  final _indicatorController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _isSubmitting = false;
  int _submissionAttempt = 0;
  int? _submittedDisputeCount;
  DisputeIndicatorType _indicatorType = DisputeIndicatorType.phone;
  DisputeLegalRelationship _legalRelationship =
      DisputeLegalRelationship.legalRepresentative;
  bool _agreedToTerms = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  String? _attachmentsError;
  String? _agreementError;
  String? _submitError;
  int _attachmentSequence = 0;

  final List<DisputeAttachmentItem> _attachments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final quotaState = context.read<UserQuotaState?>();
      if (quotaState != null && !quotaState.isLoading) {
        quotaState.refresh();
      }
      _loadDisputeCount();
    });
  }

  Future<void> _loadDisputeCount() async {
    final authState = context.read<AuthState?>();
    final token = authState?.session?.accessToken;
    if (token == null || token.isEmpty) {
      return;
    }
    final repository = context.read<DisputeRepository?>();
    if (repository == null) {
      return;
    }
    try {
      final summary = await repository.fetchMySummary(accessToken: token);
      if (mounted) {
        setState(() => _submittedDisputeCount = summary.totalSubmitted);
      }
    } catch (_) {
      // Keep count omitted when summary endpoint is unavailable.
    }
  }

  void _openDisputeTracking() {
    Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const DisputeTrackingScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

  Future<List<PickedDisputeFile>?> _defaultPickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedDisputeFileExtensions.toList(growable: false),
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    return [
      for (final file in result.files)
        PickedDisputeFile(
          fileName: file.name,
          sizeBytes: file.size,
          bytes: file.bytes,
          filePath: file.path,
        ),
    ];
  }

  Future<void> _openAttachmentPicker() async {
    if (_isSubmitting) {
      return;
    }
    if (_attachments.length >= maxDisputeAttachmentCount) {
      _showNotice(
        'Mỗi hồ sơ chỉ được đính kèm tối đa $maxDisputeAttachmentCount tệp.',
      );
      return;
    }

    final submissionAttempt = _submissionAttempt;
    List<PickedDisputeFile>? picked;
    try {
      final picker = widget.attachmentPicker ?? _defaultPickFiles;
      picked = await picker();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showNotice('Không thể mở trình chọn tệp. Vui lòng thử lại.');
      return;
    }

    if (!mounted ||
        submissionAttempt != _submissionAttempt ||
        picked == null ||
        picked.isEmpty) {
      return;
    }

    final validItems = <DisputeAttachmentItem>[];
    String? firstError;
    final remainingSlots = maxDisputeAttachmentCount - _attachments.length;

    for (final file in picked) {
      if (validItems.length >= remainingSlots) {
        firstError ??=
            'Mỗi hồ sơ chỉ được đính kèm tối đa $maxDisputeAttachmentCount tệp.';
        break;
      }
      final validated = validateAndBuildDisputeAttachment(
        id: 'att_${++_attachmentSequence}',
        file: file,
      );
      if (validated.item != null) {
        validItems.add(validated.item!);
      } else {
        firstError ??= validated.error;
      }
    }

    if (validItems.isNotEmpty) {
      setState(() {
        _attachments.addAll(validItems);
        _attachmentsError = firstError;
        _submitError = null;
      });
    } else if (firstError != null) {
      setState(() {
        _attachmentsError = firstError;
      });
    }

    if (firstError != null) {
      _showNotice(firstError);
    }
  }

  void _removeAttachment(String id) {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _attachments.removeWhere((item) => item.id == id);
      if (_autovalidateMode != AutovalidateMode.disabled) {
        _attachmentsError = validateDisputeAttachments(_attachments);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) {
      return;
    }

    final formValid = _formKey.currentState?.validate() ?? false;
    final attachmentsErr = validateDisputeAttachments(_attachments);
    final agreementErr = validateDisputeAgreement(_agreedToTerms);

    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
      _attachmentsError = attachmentsErr;
      _agreementError = agreementErr;
      _submitError = null;
    });

    if (!formValid || attachmentsErr != null || agreementErr != null) {
      _showNotice('Vui lòng kiểm tra lại các thông tin bắt buộc.');
      return;
    }

    final authState = context.read<AuthState?>();
    final accessToken = authState?.session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _showNotice('Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _submissionAttempt++;
      _submitError = null;
    });

    try {
      final repository =
          context.read<DisputeRepository?>() ?? DisputeRepository();
      final result = await repository.submitDispute(
        accessToken: accessToken,
        indicatorType: _indicatorType,
        indicatorValue: _indicatorController.text,
        legalRelationship: _legalRelationship,
        reason: _reasonController.text,
        agreeTerms: _agreedToTerms,
        attachments: List<DisputeAttachmentItem>.unmodifiable(_attachments),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _submitError = null;
        _autovalidateMode = AutovalidateMode.disabled;
        _indicatorController.clear();
        _reasonController.clear();
        _attachments.clear();
        _agreedToTerms = false;
        _attachmentsError = null;
        _agreementError = null;
        _submittedDisputeCount = (_submittedDisputeCount ?? 0) + 1;
      });
      _formKey.currentState?.reset();
      _showNotice('${result.message} (${result.displayCode})');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _submitError = error.message;
      });
      _showNotice(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      const message = 'Không thể gửi hồ sơ khiếu nại. Vui lòng thử lại.';
      setState(() {
        _isSubmitting = false;
        _submitError = message;
      });
      _showNotice(message);
    }
  }

  void _handleSaveDraft() {
    FocusScope.of(context).unfocus();
    _showNotice('Đã lưu bản nháp cục bộ trên màn hình hiện tại.');
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final pageTheme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: 'sans-serif'),
    );
    final authState = context.watch<AuthState?>();
    final user = authState?.user;
    final isRegisteredUser =
        user != null && user.role.toUpperCase() == 'REGISTERED_USER';

    return Theme(
      data: pageTheme,
      child: Scaffold(
        backgroundColor: AppTheme.page,
        appBar: const ScamShieldHeader(),
        endDrawer: GuestMenu(
          user: user,
          onLogin: () => Navigator.of(
            context,
          ).push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen())),
          onSignOut: authState != null && user != null
              ? () => _handleSignOut(authState)
              : null,
        ),
        body: SafeArea(
          top: false,
          child: isRegisteredUser
              ? _buildRegisteredUserBody()
              : _buildAccessRestrictedBody(user != null),
        ),
        bottomNavigationBar: ScamShieldNavigation(
          selected: ScamShieldTab.appeal,
          onSignOut: authState != null && user != null
              ? () => _handleSignOut(authState)
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
                        ? 'Tài khoản hiện tại không thuộc nhóm Thành viên đã đăng ký (Registered User) nên không thể gửi đơn khiếu nại.'
                        : 'Vui lòng đăng nhập bằng tài khoản Thành viên đã đăng ký để gửi đơn khiếu nại và gỡ nhãn sai.',
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

  Widget _buildRegisteredUserBody() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AiQuotaBanner(),
              const SizedBox(height: 20),
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
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Hỗ trợ xác minh chính chủ và giải tỏa các số điện thoại, tên miền hoặc số tài khoản bị gắn nhãn nhầm qua quy trình chuẩn A05.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 13.5,
                    color: AppTheme.mutedInk,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildSegmentedTabs(),
              const SizedBox(height: 16),
              ExcludeFocus(
                excluding: _isSubmitting,
                child: AbsorbPointer(
                  absorbing: _isSubmitting,
                  child: _buildDisputeFormCard(),
                ),
              ),
              const SizedBox(height: 14),
              _buildImportantNotesCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    final trackingLabel = _submittedDisputeCount != null
        ? 'Tiến Trình Đơn ($_submittedDisputeCount)'
        : 'Tiến Trình Đơn';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _tabTrack,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              key: const ValueKey('dispute_tab_submit'),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
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
              child: const Text(
                'Nộp đơn phản chứng',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              key: const ValueKey('dispute_tab_progress'),
              onTap: _openDisputeTracking,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
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
                        trackingLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeFormCard() {
    final reasonLength = _reasonController.text.characters.length;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _softBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: _activeBlue,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Biểu Mẫu Khiếu Nại',
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _requiredBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '* Bắt buộc',
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildRequiredLabel('1. Chọn loại chỉ số khiếu nại'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildIndicatorOption(DisputeIndicatorType.phone),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildIndicatorOption(
                      DisputeIndicatorType.bankAccount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildIndicatorOption(DisputeIndicatorType.url),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildIndicatorOption(
                      DisputeIndicatorType.brandname,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildRequiredLabel('2. Chỉ số bị gắn nhầm'),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('dispute_indicator_field'),
                controller: _indicatorController,
                keyboardType: switch (_indicatorType) {
                  DisputeIndicatorType.phone => TextInputType.phone,
                  DisputeIndicatorType.url => TextInputType.url,
                  _ => TextInputType.text,
                },
                textInputAction: TextInputAction.next,
                autocorrect: false,
                style: const TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
                validator: (value) =>
                    validateDisputeIndicatorValue(_indicatorType, value),
                decoration: _inputDecoration(
                  hintText: _indicatorType.hint,
                  prefixIcon: Icons.search_rounded,
                ),
              ),
              const SizedBox(height: 18),
              _buildRequiredLabel('3. Quan hệ pháp lý với đối tượng'),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: _inputDecoration(hintText: '').copyWith(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DisputeLegalRelationship>(
                    key: const ValueKey('dispute_relationship_dropdown'),
                    value: _legalRelationship,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.mutedInk,
                    ),
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                    items: [
                      for (final rel in DisputeLegalRelationship.values)
                        DropdownMenuItem(
                          value: rel,
                          child: Text(
                            rel.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _legalRelationship = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildRequiredLabel(
                      '4. Lý do khiếu nại & giải trình',
                    ),
                  ),
                  Text(
                    '$reasonLength/$maxDisputeReasonLength ký tự',
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 11.5,
                      color: AppTheme.mutedInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('dispute_reason_field'),
                controller: _reasonController,
                minLines: 4,
                maxLines: 6,
                maxLength: maxDisputeReasonLength,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      required maxLength,
                    }) => null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 14,
                  color: AppTheme.ink,
                  height: 1.45,
                ),
                onChanged: (_) => setState(() {}),
                validator: validateDisputeReason,
                decoration: _inputDecoration(
                  hintText:
                      'Mô tả nguồn gốc sở hữu và lý do chỉ số bị gắn nhãn nhầm (tối thiểu 20 ký tự)...',
                ),
              ),
              const SizedBox(height: 18),
              _buildRequiredLabel('5. Tài liệu xác minh chính chủ'),
              const SizedBox(height: 8),
              Material(
                color: AppTheme.page,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: const ValueKey('dispute_upload_box'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openAttachmentPicker,
                  child: CustomPaint(
                    painter: _DashedRRectPainter(
                      color: _attachmentsError != null
                          ? AppTheme.error
                          : AppTheme.border,
                      radius: 14,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: _softBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: _activeBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Chạm để tải tệp hoặc chụp trực tiếp',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '(ĐKKD, Hợp đồng mạng viễn thông, CCCD che số • PDF/JPG/PNG ≤5MB)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 11.5,
                              color: AppTheme.mutedInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_attachmentsError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _attachmentsError!,
                  style: const TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 12,
                    color: AppTheme.error,
                  ),
                ),
              ],
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final file in _attachments)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.page,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 20,
                          color: AppTheme.mutedInk,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'sans-serif',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${file.sizeLabel} • ${file.note}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'sans-serif',
                                  fontSize: 11.5,
                                  color: AppTheme.mutedInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(
                              side: BorderSide(color: AppTheme.border),
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _removeAttachment(file.id),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: AppTheme.mutedInk,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        key: const ValueKey('dispute_agree_checkbox'),
                        value: _agreedToTerms,
                        activeColor: _activeBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                            if (_agreedToTerms) {
                              _agreementError = null;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                          if (_agreedToTerms) {
                            _agreementError = null;
                          }
                        });
                      },
                      child: const Text(
                        'Tôi cam đoan thông tin khai báo hoàn toàn chính xác và chịu hoàn toàn trách nhiệm trước pháp luật.',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 12.5,
                          color: AppTheme.mutedInk,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_agreementError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _agreementError!,
                  style: const TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 12,
                    color: AppTheme.error,
                  ),
                ),
              ],
              if (_submitError != null) ...[
                const SizedBox(height: 12),
                Container(
                  key: const ValueKey('dispute_submit_error_banner'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.errorBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.error_outline,
                          size: 18,
                          color: AppTheme.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _submitError!,
                          style: const TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey('dispute_submit_button'),
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppTheme.navy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.navy.withValues(
                    alpha: 0.72,
                  ),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.rocket_launch_outlined,
                        size: 18,
                        color: AppTheme.shieldBlue,
                      ),
                label: Text(
                  _isSubmitting
                      ? 'Đang gửi hồ sơ...'
                      : 'Gửi Đơn Khiếu Nại Thẩm Định',
                  style: const TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('dispute_draft_button'),
                onPressed: _isSubmitting ? null : _handleSaveDraft,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.ink,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.save_outlined,
                  size: 18,
                  color: AppTheme.mutedInk,
                ),
                label: const Text(
                  'Lưu bản nháp',
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorOption(DisputeIndicatorType type) {
    final selected = _indicatorType == type;
    return Material(
      color: selected ? _softBlue : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('dispute_type_${type.name}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _indicatorType = type);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _activeBlue : AppTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _activeBlue : Colors.transparent,
                  border: Border.all(
                    color: selected ? _activeBlue : AppTheme.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? _activeBlue : AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportantNotesCard() {
    const notes = [
      'Chỉ áp dụng cho chỉ số đang bị gắn nhãn cảnh báo (ACTIVE) trên hệ thống ScamShield.',
      'Định dạng tệp hỗ trợ: PDF, JPG, PNG; mỗi hồ sơ tối đa 10 tệp minh chứng chính chủ.',
      'Vui lòng che bớt các thông tin cá nhân không cần thiết trên CCCD/hợp đồng theo chuẩn Zero-PII.',
      'Thông tin giả mạo có thể dẫn tới việc từ chối hồ sơ và hạn chế quyền gửi khiếu nại.',
    ];

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: _activeBlue,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        title: const Text(
          'Lưu Ý Quan Trọng',
          style: TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        children: [
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•  ',
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontWeight: FontWeight.w800,
                      color: _activeBlue,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 13,
                        color: AppTheme.mutedInk,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequiredLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: AppTheme.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppTheme.mutedInk.withValues(alpha: 0.72),
      ),
      errorStyle: const TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 12,
        color: AppTheme.error,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 19, color: AppTheme.mutedInk)
          : null,
      filled: true,
      fillColor: AppTheme.page,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _activeBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
