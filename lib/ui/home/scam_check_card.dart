import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../report/report_target_validation.dart';
import 'scam_check_validation.dart';

enum _CheckType {
  message(
    'Tin nhắn',
    Icons.chat_bubble_outline,
    'Nhập hoặc dán nội dung tin nhắn đáng ngờ…',
  ),
  url('Đường dẫn', Icons.link, 'https://example.com'),
  phone(
    'Số điện thoại',
    Icons.phone_outlined,
    'Ví dụ: 0912 345 678 hoặc 1900 1234',
  ),
  bank('Số tài khoản', Icons.account_balance_outlined, 'Ví dụ: 0123 456 789');

  const _CheckType(this.label, this.icon, this.hint);

  final String label;
  final IconData icon;
  final String hint;
}

class ScamCheckCard extends StatefulWidget {
  const ScamCheckCard({super.key});

  @override
  State<ScamCheckCard> createState() => _ScamCheckCardState();
}

class _ScamCheckCardState extends State<ScamCheckCard> {
  static const _messageLimit = 2000;

  final _drafts = {
    for (final type in _CheckType.values) type: TextEditingController(),
  };
  TextEditingController get _controller => _drafts[_type]!;
  final _formKey = GlobalKey<FormState>();
  _CheckType _type = _CheckType.message;
  String? _summary;
  Timer? _validationTimer;
  String? _inputError;

  ReportTargetType? get _reportType => switch (_type) {
    _CheckType.message => null,
    _CheckType.url => ReportTargetType.website,
    _CheckType.phone => ReportTargetType.phone,
    _CheckType.bank => ReportTargetType.bank,
  };

  @override
  void dispose() {
    _validationTimer?.cancel();
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  String? _validate(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Hãy nhập nội dung cần kiểm tra.';
    }
    if (_type != _CheckType.message && input.length > 10000) {
      return 'Nội dung không được vượt quá 10.000 ký tự.';
    }
    final type = _reportType;
    if (type == null || matchesReportTarget(type, input)) return null;
    if (type == ReportTargetType.website) {
      return 'Đường dẫn không hợp lệ. Ví dụ: https://example.com';
    }
    final warning = reportTargetTypeWarning(type, input);
    if (warning != null) {
      return warning.split('. ').first + (warning.contains('. ') ? '.' : '');
    }
    return switch (_type) {
      _CheckType.bank => 'Số tài khoản phải có từ 6 đến 30 chữ số.',
      _CheckType.phone => 'Nhập số điện thoại hoặc đầu số hợp lệ.',
      _ => null,
    };
  }

  void _inputChanged() {
    _validationTimer?.cancel();
    _formKey.currentState?.clearError();
    final input = _controller.text.trim();
    final shouldValidate = _reportType != null && input.isNotEmpty;
    final debounce = _type == _CheckType.phone || _type == _CheckType.url;
    setState(() {
      _summary = null;
      _inputError = shouldValidate && !debounce ? _validate(input) : null;
    });
    if (shouldValidate && debounce) {
      _validationTimer = Timer(
        const Duration(seconds: 1),
        () => setState(() => _inputError = _validate(_controller.text)),
      );
    }
  }

  void _check() {
    _validationTimer?.cancel();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final input = _controller.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _summary = switch (_type) {
        _CheckType.bank =>
          'Số tài khoản: ${normalizeScamCheckBankAccount(input)}',
        _CheckType.message => 'Định dạng tin nhắn hợp lệ.',
        _CheckType.url => 'Tên miền: ${parseScamCheckLink(input)!.host}',
        _CheckType.phone => 'Số đã nhập: ${normalizeScamCheckPhone(input)}',
      };
    });
  }

  Future<void> _paste() async {
    final type = _type;
    final draft = _controller;
    final previous = draft.value;
    ClipboardData? clipboard;
    try {
      clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    } on PlatformException {
      if (mounted && _type == type) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không đọc được bộ nhớ tạm. Hãy dán trực tiếp vào ô nhập.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted || _type != type || draft.value != previous) {
      return;
    }
    final value = clipboard?.text?.trim();
    if (value == null || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa sao chép nội dung.')),
      );
      return;
    }
    final pasted = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    final next = switch (type) {
      _CheckType.phone => reportPhoneInputFormatter.formatEditUpdate(
        previous,
        pasted,
      ),
      _CheckType.message => LengthLimitingTextInputFormatter.truncate(
        pasted,
        _messageLimit,
      ),
      _ => pasted,
    };
    if (next == previous) {
      final error = _validate(value);
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    _controller.value = next;
    _inputChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _summary;
    final colors = theme.colorScheme;
    final input = _controller.text;
    final indicators = _type == _CheckType.message
        ? countScamCheckIndicators(input)
        : null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 7,
                runSpacing: 4,
                children: [
                  for (final type in _CheckType.values)
                    ChoiceChip(
                      label: Text(type.label),
                      avatar: Icon(
                        type.icon,
                        size: 17,
                        color: _type == type
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      selectedColor: AppTheme.blue,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelStyle: TextStyle(
                        color: _type == type
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                      selected: _type == type,
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected && _type != type) {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _type = type;
                          });
                          _inputChanged();
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(_type.icon, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _type == _CheckType.message
                          ? 'Nội dung khả nghi cần phân tích'
                          : _type.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: ValueKey(_type),
                controller: _controller,
                minLines: _type == _CheckType.message ? 4 : 1,
                maxLines: _type == _CheckType.message ? 5 : 1,
                keyboardType: switch (_type) {
                  _CheckType.message => TextInputType.multiline,
                  _CheckType.url => TextInputType.url,
                  _CheckType.phone => TextInputType.phone,
                  _CheckType.bank => TextInputType.number,
                },
                autocorrect: false,
                maxLength: _type == _CheckType.message ? _messageLimit : null,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                inputFormatters: _type == _CheckType.phone
                    ? [reportPhoneInputFormatter]
                    : null,
                onChanged: (_) => _inputChanged(),
                forceErrorText: _inputError,
                validator: _validate,
                decoration: InputDecoration(
                  hintText: _type.hint,
                  errorMaxLines: 3,
                  counterText: '',
                  filled: true,
                  fillColor: theme.brightness == Brightness.light
                      ? AppTheme.page
                      : colors.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              if (indicators != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${input.characters.length}/$_messageLimit ký tự · '
                  '${indicators.links} liên kết · ${indicators.phones} số điện thoại',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (_type == _CheckType.bank) ...[
                const SizedBox(height: 8),
                Text(
                  '${input.characters.length} ký tự',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const Divider(height: 24),
              Wrap(
                spacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: _paste,
                    icon: const Icon(Icons.content_paste_outlined, size: 18),
                    label: const Text('Dán nhanh'),
                  ),
                  TextButton.icon(
                    onPressed: input.isEmpty
                        ? null
                        : () {
                            _controller.clear();
                            _inputChanged();
                          },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Xóa nội dung'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: input.trim().isEmpty ? null : _check,
                icon: const Icon(Icons.bolt),
                label: const Text('Kiểm tra định dạng'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppTheme.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  summary == null
                      ? 'Chế độ kiểm tra đầu vào. Phân tích rủi ro cần kết nối máy chủ.'
                      : '$summary\nChưa có kết quả đánh giá rủi ro.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
