import 'package:flutter/services.dart';

import '../home/scam_check_validation.dart';

String formatReportPhoneInput(String value) {
  final phone = normalizeScamCheckPhone(value);
  if (RegExp(r'^0[0-9]{0,9}$').hasMatch(phone)) {
    return _groupPhone(phone, [4, 7]);
  }
  if (RegExp(r'^\+84[0-9]{0,9}$').hasMatch(phone)) {
    return _groupPhone(phone, [3, 6, 9]);
  }
  if (RegExp(r'^1[89]00[0-9]{4,6}$').hasMatch(phone)) {
    final middle = (phone.length + 1) ~/ 2;
    return '${phone.substring(0, middle)} ${phone.substring(middle)}';
  }
  if (RegExp(r'^1[89]00[0-9]*$').hasMatch(phone)) {
    return _groupPhone(phone, [4]);
  }
  return value;
}

String _groupPhone(String phone, List<int> breaks) {
  final result = StringBuffer();
  for (var index = 0; index < phone.length; index++) {
    if (breaks.contains(index)) result.write(' ');
    result.write(phone[index]);
  }
  return result.toString();
}

enum ReportTargetType {
  phone('Số điện thoại / Hotline'),
  website('Website / Đường dẫn'),
  bank('Tài khoản ngân hàng');

  const ReportTargetType(this.label);
  final String label;
}

bool matchesReportTarget(ReportTargetType type, String value) {
  if (value.length > 10000) return false;
  switch (type) {
    case ReportTargetType.phone:
      var phone = normalizeScamCheckPhone(value);
      if (phone.startsWith('0084')) phone = '+84${phone.substring(4)}';
      if (phone.startsWith('+84')) {
        phone = '0${phone.substring(3)}';
      } else if (phone.startsWith('84') && phone.length >= 11) {
        phone = '0${phone.substring(2)}';
      }
      return RegExp(r'^(?:0[0-9]{9}|1[89]00[0-9]{4,7})$').hasMatch(phone);
    case ReportTargetType.website:
      final url = parseScamCheckLink(value);
      if (url == null || url.authority.contains('@')) return false;
      if (RegExp(r'\p{L}', unicode: true).hasMatch(url.host)) return true;
      final parts = url.host.split('.');
      return parts.length == 4 &&
          parts.every(
            (part) =>
                RegExp(r'^[0-9]{1,3}$').hasMatch(part) &&
                int.parse(part) <= 255,
          );
    case ReportTargetType.bank:
      return RegExp(
        r'^[0-9]{6,30}$',
      ).hasMatch(value.replaceAll(RegExp(r'[\s.-]'), ''));
  }
}

String? reportTargetTypeWarning(ReportTargetType? selected, String input) {
  final value = input.trim();
  if (selected == null ||
      value.isEmpty ||
      matchesReportTarget(selected, value)) {
    return null;
  }
  if (selected == ReportTargetType.phone) {
    final phone = normalizeScamCheckPhone(value);
    final expectedLength = switch (phone) {
      _ when RegExp(r'^\+84[0-9]*$').hasMatch(phone) => 12,
      _ when RegExp(r'^0084[0-9]*$').hasMatch(phone) => 13,
      _ when RegExp(r'^84[0-9]*$').hasMatch(phone) => 11,
      _ when RegExp(r'^0[0-9]*$').hasMatch(phone) => 10,
      _ when RegExp(r'^1[89]00[0-9]*$').hasMatch(phone) => 8,
      _ => null,
    };
    if (expectedLength != null && phone.length < expectedLength) {
      return 'Còn thiếu ${expectedLength - phone.length} chữ số.';
    }
    if (expectedLength != null) {
      return 'Số điện thoại chưa đúng định dạng.';
    }
  }

  final candidates = ReportTargetType.values
      .where((type) => type != selected && matchesReportTarget(type, value))
      .map((type) => type.label)
      .join(' hoặc ');
  if (candidates.isEmpty) return null;
  return 'Dữ liệu đã nhập có thể thuộc loại $candidates. '
      'Vui lòng kiểm tra lại loại đối tượng báo cáo.';
}

final reportPhoneInputFormatter = TextInputFormatter.withFunction((
  oldValue,
  newValue,
) {
  if (!newValue.composing.isCollapsed) return newValue;

  int countDigits(String text) => RegExp(r'[0-9]').allMatches(text).length;
  final phone = newValue.text.replaceAll(RegExp(r'[\s.()-]'), '');
  final limit = switch (phone) {
    _ when phone.startsWith('+84') => 11,
    _ when phone.startsWith('0084') => 13,
    _ when phone.startsWith('84') => 11,
    _ when phone.startsWith('0') => 10,
    _ => null,
  };
  final digits = countDigits(phone);
  if (limit != null && digits > limit && digits >= countDigits(oldValue.text)) {
    return oldValue;
  }
  final formatted = formatReportPhoneInput(newValue.text);
  if (formatted == newValue.text || !newValue.selection.isValid) {
    return newValue;
  }

  int mapOffset(int offset) {
    final precedingDigits = countDigits(newValue.text.substring(0, offset));
    var position = formatted.startsWith('+') && offset > 0 ? 1 : 0;
    var seen = 0;
    while (position < formatted.length && seen < precedingDigits) {
      seen += countDigits(formatted[position]);
      position++;
    }
    return position;
  }

  return TextEditingValue(
    text: formatted,
    selection: newValue.selection.copyWith(
      baseOffset: mapOffset(newValue.selection.baseOffset),
      extentOffset: mapOffset(newValue.selection.extentOffset),
    ),
  );
});
