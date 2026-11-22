import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../shared/guest_menu.dart';
import '../shared/scamshield_header.dart';
import '../shared/scamshield_navigation.dart';
import 'report_form.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, this.onSignOut, this.onLightModeChanged});

  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onLightModeChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScamShieldHeader(),
      endDrawer: GuestMenu(
        onSignOut: onSignOut,
        onLightModeChanged: onLightModeChanged,
      ),
      bottomNavigationBar: ScamShieldNavigation(
        selected: ScamShieldTab.report,
        onSignOut: onSignOut,
        onLightModeChanged: onLightModeChanged,
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
                const ReportForm(),
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
        title: const Text(
          'Bảo vệ thông tin khi báo cáo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        scrollable: true,
        content: const Text(
          'Chỉ chia sẻ dữ liệu cần thiết để xác minh hành vi lừa đảo.\n\n'
          '• Che tên, ảnh đại diện, địa chỉ và thông tin cá nhân không liên quan trong minh chứng.\n'
          '• Không gửi mật khẩu, mã OTP hoặc ảnh giấy tờ tùy thân.\n'
          '• Giữ lại số điện thoại, đường link hoặc tài khoản của đối tượng bị báo cáo để đối chiếu.\n\n'
          'Báo cáo gắn với tài khoản của bạn để theo dõi xử lý. Hãy che dữ liệu nhạy cảm trước khi tải tệp lên.',
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
