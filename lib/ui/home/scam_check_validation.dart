Uri? parseScamCheckLink(String input) {
  if (RegExp(r'\s').hasMatch(input)) {
    return null;
  }
  final hasScheme = RegExp(
    r'^[a-z][a-z0-9+.-]*://',
    caseSensitive: false,
  ).hasMatch(input);
  final link = Uri.tryParse(hasScheme ? input : 'https://$input');
  if (link == null ||
      (link.scheme != 'https' && link.scheme != 'http') ||
      !link.host.contains('.') ||
      link.host.startsWith('.') ||
      link.host.endsWith('.') ||
      link.host.contains('..') ||
      link.userInfo.isNotEmpty) {
    return null;
  }
  return link;
}

String normalizeScamCheckPhone(String input) =>
    input.replaceAll(RegExp(r'[\s().-]'), '');

bool isScamCheckPhone(String input) =>
    RegExp(r'^\+?[0-9]{3,15}$').hasMatch(normalizeScamCheckPhone(input));
