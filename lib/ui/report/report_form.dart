import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum _ReportTarget {
  phone(
    'Số điện thoại / Hotline',
    'Nhập số điện thoại kẻ lừa đảo...',
    Icons.phone_outlined,
    TextInputType.phone,
  ),
  website(
    'Website / Link giả',
    'Nhập URL website giả mạo...',
    Icons.language,
    TextInputType.url,
  ),
  bank(
    'Tài khoản ngân hàng (STK)',
    'Nhập số tài khoản ngân hàng...',
    Icons.account_balance_outlined,
    TextInputType.number,
  );

  const _ReportTarget(this.label, this.hint, this.icon, this.keyboard);

  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
}

class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  _ReportTarget? _target;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fieldFill = colors.brightness == Brightness.dark
        ? colors.surfaceContainerHigh
        : const Color(0xFFF5F7FD);
    final panelFill = colors.brightness == Brightness.dark
        ? colors.secondaryContainer
        : const Color(0xFFE9F2FF);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: panelFill,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: Color(0xFF174E8A),
                    foregroundColor: Colors.white,
                    child: Icon(Icons.assignment_outlined, size: 17),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Biểu Mẫu Tiếp Nhận Báo Cáo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _StepTitle(1, 'Loại đối tượng báo cáo *'),
                const SizedBox(height: 8),
                RadioGroup<_ReportTarget>(
                  groupValue: _target,
                  onChanged: (value) => setState(() => _target = value),
                  child: Column(
                    children: [
                      for (final target in _ReportTarget.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: RadioListTile<_ReportTarget>(
                            value: target,
                            title: Text(target.label, style: _labelStyle),
                            controlAffinity: ListTileControlAffinity.leading,
                            secondary: Icon(
                              target.icon,
                              size: 16,
                              color: colors.primary,
                            ),
                            subtitle: Text(
                              switch (target) {
                                _ReportTarget.phone => 'Cuộc gọi, SMS đe dọa',
                                _ReportTarget.website =>
                                  'Trang mạo danh, phishing',
                                _ReportTarget.bank => 'STK thụ hưởng nhận tiền',
                              },
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            contentPadding: const EdgeInsetsDirectional.only(
                              end: 14,
                            ),
                            activeColor: AppTheme.blue,
                            tileColor: target == _target
                                ? panelFill
                                : fieldFill,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: target == _target
                                    ? AppTheme.blue
                                    : AppTheme.border,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                const _StepTitle(2, 'Thông tin & Bằng chứng'),
                const SizedBox(height: 12),
                const _RequiredLabel('Đối tượng bị báo cáo'),
                TextFormField(
                  keyboardType: _target?.keyboard,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: _decoration(
                    context,
                    hintMaxLines: 1,
                    hint:
                        _target?.hint ??
                        'Nhập số điện thoại, URL hoặc tài khoản cần báo cáo...',
                    icon: _target?.icon ?? Icons.shield_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                const _RequiredLabel('Tỉnh/thành của bạn'),
                TextFormField(
                  enabled: false,
                  decoration: _decoration(
                    context,
                    hint: 'Nhập tên để tìm và chọn tỉnh/thành',
                    icon: Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                const _RequiredLabel('Danh mục thủ đoạn'),
                TextFormField(
                  enabled: false,
                  decoration: _decoration(
                    context,
                    hint: 'Chọn thủ đoạn',
                    icon: Icons.category_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                const _RequiredLabel('Mô tả ngắn gọn hành vi'),
                TextFormField(
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 2000,
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => Text(
                        '$currentLength/$maxLength ký tự',
                        style: _labelStyle,
                      ),
                  decoration: _decoration(
                    context,
                    hint:
                        'Mô tả chi tiết kịch bản, lời nói hoặc bằng chứng lừa đảo...',
                  ),
                ),
                const SizedBox(height: 12),
                const _RequiredLabel(
                  'Tệp minh chứng (Ảnh chụp đoạn chat, biên lai)',
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.attach_file),
                  label: Text('Chọn tệp minh chứng'),
                ),
                const SizedBox(height: 6),
                _ReportNotice(
                  icon: Icons.info_outline,
                  color: colors.onSurfaceVariant,
                  content: const TextSpan(
                    text: 'PNG, JPG hoặc PDF · Tối đa 5 tệp, 5 MB mỗi tệp',
                  ),
                ),
                const SizedBox(height: 8),
                _ReportNotice(
                  icon: Icons.lock_outline,
                  color: colors.primary,
                  background: panelFill,
                  content: const TextSpan(
                    text:
                        'Hãy che thông tin cá nhân không liên quan trước khi tải tệp lên.',
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const _StepTitle(3, 'Xác nhận & Gửi'),
                const SizedBox(height: 12),
                _ReportNotice(
                  icon: Icons.verified_user_outlined,
                  color: colors.primary,
                  background: panelFill,
                  content: TextSpan(
                    text:
                        'Báo cáo sẽ được kiểm duyệt độc lập trước khi cảnh báo cộng đồng.',
                  ),
                ),
                const SizedBox(height: 10),
                _ReportNotice(
                  icon: Icons.workspace_premium_outlined,
                  color: Color(0xFF995B00),
                  content: TextSpan(
                    children: [
                      TextSpan(text: 'Báo cáo được xác thực giúp bạn nhận '),
                      TextSpan(text: '50 điểm uy tín', style: _labelStyle),
                      TextSpan(text: ' và nâng thứ hạng.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  tileColor: fieldFill,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    'Tôi xác nhận thông tin cung cấp là trung thực.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _confirmed,
                  onChanged: (value) =>
                      setState(() => _confirmed = value ?? false),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    disabledBackgroundColor: const Color(0xFFE1E9F7),
                    disabledForegroundColor: const Color(0xFF465B7D),
                  ),
                  icon: const Icon(Icons.send_outlined),
                  label: Text('Gửi báo cáo'),
                ),
                Text(
                  'Tính năng gửi báo cáo đang được chuẩn bị.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _labelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);

InputDecoration _decoration(
  BuildContext context, {
  String? hint,
  IconData? icon,
  int hintMaxLines = 2,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 13,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    hintMaxLines: hintMaxLines,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : const Color(0xFFF5F7FD),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: _fieldBorder,
    disabledBorder: _fieldBorder,
  );
}

final _fieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: const BorderSide(color: AppTheme.border),
);

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: label,
          style: _labelStyle,
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFBA1A1A)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportNotice extends StatelessWidget {
  const _ReportNotice({
    required this.icon,
    required this.color,
    required this.content,
    this.background,
  });

  final IconData icon;
  final Color color;
  final TextSpan content;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final notice = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            content,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
    final fill = background;
    if (fill == null) return notice;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(padding: const EdgeInsets.all(10), child: notice),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.step, this.title);

  final int step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: const Color(0xFF174E8A),
          child: Text(
            '$step',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: _labelStyle)),
      ],
    );
  }
}
