import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../shared/guest_menu.dart';
import '../shared/scamshield_header.dart';
import '../shared/scamshield_navigation.dart';
import 'report_form.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.accessToken,
    this.onSignOut,
    this.onLightModeChanged,
  });

  final String accessToken;
  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onLightModeChanged;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<ReportFormState>();

  Future<bool> _confirmTabChange() async {
    if (_formKey.currentState?.hasDraft != true) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bỏ báo cáo đang soạn?'),
            content: const Text(
              'Nội dung đã nhập và tệp đính kèm sẽ bị mất khi chuyển mục.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ở lại'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Bỏ báo cáo'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScamShieldHeader(),
      endDrawer: GuestMenu(onSignOut: widget.onSignOut),
      bottomNavigationBar: ScamShieldNavigation(
        selected: ScamShieldTab.report,
        onSignOut: widget.onSignOut,
        onLightModeChanged: widget.onLightModeChanged,
        confirmTabChange: _confirmTabChange,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const _ReportHero(),
                const SizedBox(height: 18),
                ReportForm(
                  key: _formKey,
                  accessToken: widget.accessToken,
                  onShowPrivacyNotice: () => _showPrivacyNotice(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacyNotice(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        constraints: const BoxConstraints(maxWidth: 440),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 12),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bảo vệ thông tin khi báo cáo',
                      style: Theme.of(dialogContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PrivacyTip(
                      Icons.shield_outlined,
                      'Chỉ chia sẻ thông tin cần thiết',
                      'Báo cáo gắn với tài khoản để bạn theo dõi kết quả xử lý.',
                    ),
                    const _PrivacyTip(
                      Icons.visibility_off_outlined,
                      'Che dữ liệu cá nhân',
                      'Che tên, ảnh đại diện, địa chỉ và dữ liệu cá nhân không liên quan trong minh chứng.',
                    ),
                    const _PrivacyTip(
                      Icons.lock_outline,
                      'Giữ kín thông tin xác thực',
                      'Không gửi mật khẩu, mã OTP hoặc ảnh giấy tờ tùy thân.',
                    ),
                    const _PrivacyTip(
                      Icons.fact_check_outlined,
                      'Giữ lại dấu hiệu để đối chiếu',
                      'Giữ lại số điện thoại, đường link hoặc tài khoản của đối tượng để đối chiếu.',
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          dialogContext,
                        ).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nguồn tham khảo · NIST SP 800-122',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const Text(
                              'Hướng dẫn bảo vệ thông tin nhận dạng cá nhân (PII)',
                              style: TextStyle(fontSize: 12),
                            ),
                            Wrap(
                              spacing: 4,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Mở tài liệu NIST'),
                                  onPressed: () async {
                                    var opened = false;
                                    try {
                                      opened =
                                          await const MethodChannel(
                                            'scamshield/privacy_reference',
                                          ).invokeMethod<bool>('open') ??
                                          false;
                                    } on PlatformException {
                                      opened = false;
                                    } on MissingPluginException {
                                      opened = false;
                                    }
                                    if (!opened && dialogContext.mounted) {
                                      ScaffoldMessenger.of(
                                        dialogContext,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Không mở được trình duyệt.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy_outlined,
                                    size: 18,
                                  ),
                                  tooltip: 'Sao chép liên kết',
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      const ClipboardData(
                                        text:
                                            'https://csrc.nist.gov/pubs/sp/800/122/final',
                                      ),
                                    );
                                    if (dialogContext.mounted) {
                                      ScaffoldMessenger.of(
                                        dialogContext,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Đã sao chép liên kết.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyTip extends StatelessWidget {
  const _PrivacyTip(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colors.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.45,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportHero extends StatelessWidget {
  const _ReportHero();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.navy, Color(0xFF194984)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x223BAEFF),
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: Padding(
                padding: EdgeInsets.all(11),
                child: Icon(
                  Icons.shield_outlined,
                  color: AppTheme.shieldBlue,
                  size: 26,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Báo Cáo Đối Tượng Lừa Đảo',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Chung tay làm sạch không gian mạng.',
              style: TextStyle(color: Color(0xFFD8E8FF)),
            ),
          ],
        ),
      ),
    );
  }
}
