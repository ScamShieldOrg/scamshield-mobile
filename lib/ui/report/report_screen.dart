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
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _showPrivacyNotice(context),
                    icon: const Icon(Icons.lock_outline, size: 18),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFE6F2FF),
                      foregroundColor: const Color(0xFF174E8A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    label: const Text(
                      'Bảo vệ thông tin (Zero-PII)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ReportForm(key: _formKey, accessToken: widget.accessToken),
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
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        title: const Text(
          'Bảo vệ thông tin khi báo cáo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PrivacyTip(
              Icons.shield_outlined,
              'Chỉ chia sẻ dữ liệu cần để xác minh lừa đảo.',
            ),
            const _PrivacyTip(
              Icons.visibility_off_outlined,
              'Che tên, ảnh đại diện, địa chỉ và dữ liệu cá nhân không liên quan trong minh chứng.',
            ),
            const _PrivacyTip(
              Icons.lock_outline,
              'Không gửi mật khẩu, mã OTP hoặc ảnh giấy tờ tùy thân.',
            ),
            const _PrivacyTip(
              Icons.fact_check_outlined,
              'Giữ lại số điện thoại, đường link hoặc tài khoản của đối tượng để đối chiếu.',
            ),
            Text(
              'Báo cáo gắn với tài khoản của bạn để theo dõi xử lý. Hãy che dữ liệu nhạy cảm trước khi tải tệp lên.',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(dialogContext).colorScheme.secondaryContainer,
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
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
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
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Không mở được trình duyệt.'),
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          tooltip: 'Sao chép liên kết',
                          onPressed: () async {
                            await Clipboard.setData(
                              const ClipboardData(
                                text:
                                    'https://csrc.nist.gov/pubs/sp/800/122/final',
                              ),
                            );
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép liên kết.'),
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
        actions: [
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE6F2FF),
              foregroundColor: const Color(0xFF174E8A),
              minimumSize: const Size(104, 44),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text(
              'Đóng',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyTip extends StatelessWidget {
  const _PrivacyTip(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
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

Future<bool?> showReportLoginPrompt(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    scrollable: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    icon: Center(
      child: CircleAvatar(
        radius: 26,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        child: const Icon(Icons.verified_user_outlined),
      ),
    ),
    title: const Text(
      'Cần đăng nhập',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Vui lòng đăng nhập để gửi báo cáo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.login_rounded, size: 18),
          label: const Text('Đến trang đăng nhập', textAlign: TextAlign.center),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
      ],
    ),
  ),
);
