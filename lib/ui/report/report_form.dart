import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/report_service.dart';
import 'evidence_image_editor.dart';
import 'evidence_image_redaction.dart';
import 'report_evidence_tile.dart';
import 'report_target_validation.dart';

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
  const ReportForm({
    super.key,
    required this.accessToken,
    this.onShowPrivacyNotice,
  });

  final String accessToken;
  final VoidCallback? onShowPrivacyNotice;

  @override
  ReportFormState createState() => ReportFormState();
}

class ReportFormState extends State<ReportForm>
    with AutomaticKeepAliveClientMixin<ReportForm> {
  final _service = ReportService();
  final _identifier = TextEditingController();
  final _identifierFocus = FocusNode();
  bool _identifierTouched = false;
  Timer? _identifierDebounce;
  bool _attemptedSubmit = false;
  final _description = TextEditingController();
  final _files = <({ReportEvidence evidence, bool redacted})>[];
  List<ReportOption> _regions = [];
  List<ReportOption> _categories = const [];
  bool _loadingRegions = true;
  String? _regionsError;
  bool _loadingCategories = false;
  String? _categoriesError;
  int _categoryRequest = 0;
  String? _region;
  String? _category;
  bool _busy = false;
  _ReportTarget? _target;
  bool _confirmed = false;

  @override
  bool get wantKeepAlive => true;

  bool get hasDraft =>
      _identifier.text.isNotEmpty ||
      _description.text.isNotEmpty ||
      _files.isNotEmpty ||
      _target != null ||
      _region != null ||
      _category != null ||
      _confirmed;

  @override
  void initState() {
    super.initState();
    _identifierFocus.addListener(() {
      if (!_identifierFocus.hasFocus && _target != _ReportTarget.phone) {
        setState(() => _identifierTouched = true);
      }
    });
    _loadRegions();
    _loadCategories();
  }

  @override
  void didUpdateWidget(covariant ReportForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accessToken != widget.accessToken) _loadCategories();
  }

  Future<void> _loadCategories() async {
    final token = widget.accessToken;
    final request = ++_categoryRequest;
    setState(() {
      _category = null;
      _categories = const [];
      _categoriesError = null;
      _loadingCategories = true;
    });

    try {
      final categories = await _service.categories(token);
      if (!mounted || request != _categoryRequest) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
        if (categories.isEmpty) {
          _categoriesError = 'Chưa có danh mục thủ đoạn.';
        }
      });
    } on Exception {
      if (!mounted || request != _categoryRequest) return;
      setState(() {
        _loadingCategories = false;
        _categoriesError = 'Không tải được danh mục thủ đoạn.';
      });
    }
  }

  Future<void> _loadRegions() async {
    try {
      final regions = await _service.regions();
      if (mounted) {
        setState(() {
          _regions = regions;
          _regionsError = regions.isEmpty
              ? 'Máy chủ chưa trả về danh sách tỉnh/thành.'
              : null;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _regionsError = 'Không tải được danh sách tỉnh/thành.';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingRegions = false);
    }
  }

  @override
  void dispose() {
    _identifierDebounce?.cancel();
    _identifier.dispose();
    _identifierFocus.dispose();
    _description.dispose();
    super.dispose();
  }

  void _message(String message) {
    final displayMessage = message.replaceAllMapped(
      RegExp(r'#?\bRPT-0*([0-9]+)\b', caseSensitive: false),
      (match) => match[1]!,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(displayMessage)));
  }

  final _targetStepKey = GlobalKey();
  bool _showTargetError = false;

  void _guideToTarget() {
    setState(() => _showTargetError = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stepContext = _targetStepKey.currentContext;
      if (stepContext == null || _target != null) return;
      Scrollable.ensureVisible(
        stepContext,
        duration: const Duration(milliseconds: 350),
        alignment: 0.08,
        curve: Curves.easeOut,
      );
    });
  }

  Widget _requireTarget(Widget input) {
    if (_target != null) return input;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _guideToTarget,
      child: ExcludeFocus(child: AbsorbPointer(child: input)),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on FormatException catch (error) {
      if (mounted) _message(error.message);
    } on PlatformException catch (error) {
      if (mounted) _message(error.message ?? 'Không thể đọc tệp minh chứng.');
    } on Exception {
      if (mounted) {
        _message(
          'Không thể hoàn thành yêu cầu. Vui lòng kiểm tra kết nối hoặc thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectRegion() async {
    var query = '';
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final matches = _regions
              .where(
                (option) =>
                    ' ${_regionSearchKey(option.name)}'.contains(' $query'),
              )
              .toList();
          final colors = Theme.of(context).colorScheme;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            constraints: const BoxConstraints(maxWidth: 390, maxHeight: 400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Chọn tỉnh/thành',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm tỉnh/thành',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: colors.secondaryContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setDialogState(
                      () => query = _regionSearchKey(value.trim()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: matches.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              'Không tìm thấy tỉnh/thành.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            primary: false,
                            shrinkWrap: true,
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final option = matches[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                selectedTileColor: colors.secondaryContainer,
                                title: Text(option.name),
                                selected: option.code == _region,
                                trailing: option.code == _region
                                    ? const Icon(Icons.check_circle_outline)
                                    : null,
                                onTap: () =>
                                    Navigator.pop(dialogContext, option.code),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (mounted && selected != null) setState(() => _region = selected);
  }

  Future<void> _pickEvidence() => _run(() async {
    final file = await const MethodChannel(
      'scamshield/report_evidence',
    ).invokeMapMethod<String, Object>('pick');
    if (!mounted || file == null) return;
    final name = file['name'] as String;
    final bytes = file['bytes'] as Uint8List;
    if (bytes.isEmpty ||
        bytes.length > maxReportEvidenceBytes ||
        !RegExp(r'\.(png|jpe?g|pdf)$', caseSensitive: false).hasMatch(name)) {
      _message('Chọn tệp PNG, JPG hoặc PDF không quá 5 MB.');
      return;
    }
    setState(
      () => _files.add((evidence: (name: name, bytes: bytes), redacted: false)),
    );
  });

  Future<void> _editEvidence(int index) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final file = _files[index].evidence;
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => EvidenceImageEditor(name: file.name, bytes: file.bytes),
      ),
    );
    if (!mounted || bytes == null) return;
    final name = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '.png');
    setState(
      () => _files[index] = (
        evidence: (name: name, bytes: bytes),
        redacted: true,
      ),
    );
  }

  Future<void> _submit() async {
    final token = widget.accessToken;
    final target = _target;
    final region = _region;
    final category = _category;
    final identifier = _identifier.text.trim();
    final description = _description.text.trim();
    if (!_validateIdentifierBeforeSubmit()) return;
    if (target == null ||
        region == null ||
        category == null ||
        identifier.isEmpty ||
        description.isEmpty ||
        !_confirmed ||
        _files.isEmpty) {
      _message(
        'Vui lòng điền đủ thông tin, chọn tệp minh chứng và xác nhận báo cáo.',
      );
      return;
    }
    await _run(() async {
      final code = await _service.submit(
        token,
        {
          'threatType': switch (target) {
            _ReportTarget.phone => 'PHONE',
            _ReportTarget.website => 'URL',
            _ReportTarget.bank => 'BANK_ACCOUNT',
          },
          'targetIdentifier': identifier,
          'regionCode': region,
          'category': category,
          'description': description,
          'isConfirmed': true,
        },
        [for (final file in _files) file.evidence],
      );
      if (!mounted) return;
      _identifier.clear();
      _description.clear();
      setState(() {
        _files.clear();
        _identifierTouched = false;
        _identifierDebounce = null;
        _attemptedSubmit = false;
        _target = null;
        _confirmed = false;
        _region = null;
        _category = null;
      });
      _message('Đã gửi báo cáo $code. Vui lòng theo dõi kết quả kiểm duyệt.');
    });
  }

  String? get _identifierWarning => reportTargetTypeWarning(
    _target == null ? null : ReportTargetType.values.byName(_target!.name),
    _identifier.text,
  );

  bool _validateIdentifierBeforeSubmit() {
    _identifierDebounce?.cancel();
    setState(() => _attemptedSubmit = true);
    return _identifierError == null;
  }

  String? get _identifierError {
    if (_target == _ReportTarget.phone &&
        (_identifierDebounce?.isActive ?? false)) {
      return null;
    }
    if (_target == null) return null;
    if (_attemptedSubmit && _identifier.text.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại, URL hoặc tài khoản cần báo cáo.';
    }
    return _identifierTouched ||
            _attemptedSubmit ||
            (_target == _ReportTarget.phone && _identifierDebounce != null)
        ? _identifierWarning
        : null;
  }

  void _submitPressed() {
    if (_target == null) {
      _guideToTarget();
      return;
    }
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                KeyedSubtree(
                  key: _targetStepKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _StepTitle(1, 'Loại đối tượng báo cáo *'),
                      if (_target == null && _showTargetError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Vui lòng chọn loại đối tượng báo cáo.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.error),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                RadioGroup<_ReportTarget>(
                  groupValue: _target,
                  onChanged: (value) => setState(() {
                    _target = value;
                    _showTargetError = false;
                  }),
                  child: Column(
                    children: [
                      for (final target in _ReportTarget.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: RadioListTile<_ReportTarget>(
                            value: target,
                            enabled: !_busy,
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
                _requireTarget(
                  TextFormField(
                    controller: _identifier,
                    enabled: _target != null,
                    inputFormatters: _target == _ReportTarget.phone
                        ? [reportPhoneInputFormatter]
                        : null,
                    focusNode: _identifierFocus,
                    onChanged: (_) {
                      _identifierDebounce?.cancel();
                      if (_target == _ReportTarget.phone) {
                        setState(() {
                          _identifierDebounce = Timer(
                            const Duration(seconds: 1),
                            () {
                              if (mounted) setState(() {});
                            },
                          );
                        });
                        return;
                      }
                      if (_identifierTouched || _attemptedSubmit) {
                        setState(() {});
                      }
                    },
                    readOnly: _busy,
                    keyboardType: _target?.keyboard,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: _decoration(
                      context,
                      hintMaxLines: 1,
                      hint: _target?.hint ?? 'Nhập đối tượng bị báo cáo',
                      icon: _target?.icon ?? Icons.shield_outlined,
                    ).copyWith(errorText: _identifierError, errorMaxLines: 4),
                  ),
                ),
                const SizedBox(height: 12),
                const _RequiredLabel('Tỉnh/thành của bạn'),
                if (_loadingRegions) const LinearProgressIndicator(),
                _requireTarget(
                  TextFormField(
                    key: ValueKey(('region', _region)),
                    initialValue: _regions
                        .where((option) => option.code == _region)
                        .firstOrNull
                        ?.name,
                    enabled: !_busy && _regions.isNotEmpty,
                    readOnly: true,
                    onTap: _selectRegion,
                    decoration:
                        _decoration(
                          context,
                          hint: 'Chọn tỉnh/thành',
                          hintMaxLines: 1,
                          icon: Icons.location_on_outlined,
                        ).copyWith(
                          errorText: _regionsError,
                          errorMaxLines: 2,
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                const _RequiredLabel('Danh mục thủ đoạn'),
                _requireTarget(
                  DropdownButtonFormField<String>(
                    key: ValueKey(('category', _category)),
                    initialValue: _category,
                    isExpanded: true,
                    items: [
                      for (final option in _categories)
                        DropdownMenuItem(
                          value: option.code,
                          child: Text(
                            option.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _busy || _categories.isEmpty
                        ? null
                        : (value) => setState(() => _category = value),
                    decoration: _decoration(
                      context,
                      icon: Icons.category_outlined,
                    ).copyWith(errorText: _categoriesError, errorMaxLines: 2),
                    hint: Text(
                      _loadingCategories
                          ? 'Đang tải danh mục…'
                          : 'Chọn thủ đoạn',
                      style: _hintStyle(context),
                    ),
                  ),
                ),
                if (_categoriesError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _loadCategories,
                      child: const Text('Thử lại'),
                    ),
                  ),
                const SizedBox(height: 12),
                const _RequiredLabel('Mô tả ngắn gọn hành vi'),
                _requireTarget(
                  TextFormField(
                    controller: _description,
                    readOnly: _busy,
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
                ),
                const SizedBox(height: 12),
                const _RequiredLabel(
                  'Tệp minh chứng (Ảnh chụp đoạn chat, biên lai)',
                ),
                _requireTarget(
                  OutlinedButton.icon(
                    onPressed: _busy || _files.length >= 5
                        ? null
                        : _pickEvidence,
                    icon: const Icon(Icons.attach_file),
                    label: Text('Chọn tệp minh chứng'),
                  ),
                ),
                for (var index = 0; index < _files.length; index++)
                  ReportEvidenceTile(
                    file: _files[index].evidence,
                    redacted: _files[index].redacted,
                    onEdit: _busy ? null : () => _editEvidence(index),
                    onRemove: _busy
                        ? null
                        : () => setState(() => _files.removeAt(index)),
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
                  onLearnMore: widget.onShowPrivacyNotice,
                  content: const TextSpan(
                    text:
                        'Che thông tin cá nhân không liên quan trên ảnh đính kèm. Với PDF, hãy che thông tin trước khi chọn tệp.',
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
                _requireTarget(
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
                    onChanged: _busy
                        ? null
                        : (value) =>
                              setState(() => _confirmed = value ?? false),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _submitPressed,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    disabledBackgroundColor: const Color(0xFFE1E9F7),
                    disabledForegroundColor: const Color(0xFF465B7D),
                  ),
                  icon: const Icon(Icons.send_outlined),
                  label: Text(_busy ? 'Đang xử lý...' : 'Gửi báo cáo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _regionSearchKey(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
    .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
    .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
    .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
    .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
    .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
    .replaceAll('đ', 'd')
    .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
    .replaceAll(RegExp(r'\s+'), ' ');

const _labelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);

TextStyle _hintStyle(BuildContext context) {
  final theme = Theme.of(context);
  return (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: theme.colorScheme.onSurfaceVariant,
  );
}

InputDecoration _decoration(
  BuildContext context, {
  String? hint,
  IconData? icon,
  int hintMaxLines = 2,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: _hintStyle(context),
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
    this.onLearnMore,
  });

  final IconData icon;
  final Color color;
  final TextSpan content;
  final Color? background;
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    final notice = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (onLearnMore case final learnMore?) ...[
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: learnMore,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Bảo vệ thông tin Zero-PII'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ],
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
