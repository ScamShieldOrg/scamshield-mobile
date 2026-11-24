import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import 'scam_check_validation.dart';

enum _CheckType {
  message(
    'Tin nhắn',
    Icons.chat_bubble_outline,
    'Nhập hoặc dán nội dung tin nhắn đáng ngờ…',
  ),
  url('Đường dẫn', Icons.link, 'https://example.com'),
  phone('Số điện thoại', Icons.phone_outlined, 'Nhập số điện thoại đáng ngờ…');

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
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _CheckType _type = _CheckType.message;
  String? _summary;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Hãy nhập nội dung cần kiểm tra.';
    }
    return switch (_type) {
      _CheckType.url when parseScamCheckLink(input) == null =>
        'Nhập địa chỉ web hợp lệ, ví dụ example.com.',
      _CheckType.phone when !isScamCheckPhone(input) =>
        'Nhập số điện thoại hoặc đầu số hợp lệ.',
      _ => null,
    };
  }

  void _check() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final input = _controller.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _summary = switch (_type) {
        _CheckType.message => 'Nội dung đã nhập: ${input.runes.length} ký tự.',
        _CheckType.url => 'Tên miền: ${parseScamCheckLink(input)!.host}',
        _CheckType.phone => 'Số đã nhập: ${normalizeScamCheckPhone(input)}',
      };
    });
  }

  Future<void> _paste() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) {
      return;
    }
    final value = clipboard?.text?.trim();
    if (value == null || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa sao chép nội dung.')),
      );
      return;
    }
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() => _summary = null);
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _summary;

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
                        if (selected) {
                          setState(() {
                            _type = type;
                            _summary = null;
                          });
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Text(
                'Nội dung khả nghi cần phân tích',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: ValueKey(_type),
                controller: _controller,
                minLines: _type == _CheckType.message ? 3 : 1,
                maxLines: _type == _CheckType.message ? 5 : 1,
                keyboardType: switch (_type) {
                  _CheckType.message => TextInputType.multiline,
                  _CheckType.url => TextInputType.url,
                  _CheckType.phone => TextInputType.phone,
                },
                autocorrect: false,
                onChanged: (_) {
                  if (_summary != null) {
                    setState(() => _summary = null);
                  }
                },
                validator: _validate,
                decoration: InputDecoration(
                  hintText: _type.hint,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  TextButton.icon(
                    onPressed: _paste,
                    icon: const Icon(Icons.content_paste_outlined, size: 18),
                    label: const Text('Dán nhanh'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _formKey.currentState?.reset();
                      _controller.clear();
                      setState(() => _summary = null);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Xóa nội dung'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: _check,
                icon: const Icon(Icons.bolt),
                label: const Text('Kiểm tra đầu vào'),
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
