final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _digitsOnlyPattern = RegExp(r'^\d+$');
final _startsWithDigitPattern = RegExp(r'^\d');

String? validateLoginIdentifier(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Vui lòng nhập số điện thoại hoặc email.';
  }

  if (trimmed.contains('@')) {
    return _emailPattern.hasMatch(trimmed)
        ? null
        : 'Email không hợp lệ. Vui lòng nhập đúng định dạng (ví dụ: email@domain.vn).';
  }

  if (_digitsOnlyPattern.hasMatch(trimmed)) {
    return trimmed.length == 10
        ? null
        : 'Số điện thoại phải gồm đúng 10 chữ số (hiện có ${trimmed.length} số).';
  }

  if (_startsWithDigitPattern.hasMatch(trimmed)) {
    return 'Số điện thoại chỉ được chứa các chữ số và phải gồm đúng 10 số.';
  }

  return 'Vui lòng nhập email hợp lệ (có chứa @) hoặc số điện thoại 10 chữ số.';
}

String? validateLoginPassword(String? value) {
  final input = value ?? '';
  if (input.isEmpty) {
    return 'Vui lòng nhập mật khẩu.';
  }
  return input.length >= 6
      ? null
      : 'Mật khẩu phải có ít nhất 6 ký tự (hiện có ${input.length} ký tự).';
}
