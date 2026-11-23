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

bool isScamCheckPhone(String input) {
  var phone = normalizeScamCheckPhone(input);
  if (phone.startsWith('+84')) {
    phone = '0${phone.substring(3)}';
  } else if (phone.startsWith('84') && phone.length >= 11) {
    phone = '0${phone.substring(2)}';
  }
  return RegExp(r'^(?:0[1-9]\d{7,9}|1[89]00\d{4,7})$').hasMatch(phone);
}

String normalizeScamCheckBankAccount(String input) =>
    input.replaceAll(RegExp(r'[\s.-]'), '');

bool isScamCheckBankAccount(String input) =>
    RegExp(r'^\d{6,30}$').hasMatch(normalizeScamCheckBankAccount(input));

final _messageLinks = RegExp(
  r'''https?://[^\s<>"']+|www\.[^\s<>"']+|(?<![\w@.])(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+'''
  r'(?:com|net|org|info|biz|vn|io|co|me|to|cc|tv|xyz|top|vip|shop|online|site|'
  r'club|app|link|live|store|asia|tk|ml|ga|cf|gq|icu|cyou|bond|sbs|click|fun|'
  r'pro|win|bet|best|life|world|today|news|space|website|tech|dev|ly|gl|gd|in|'
  r'''us|uk|cn|ru)\b(?:/[^\s<>"']*)?''',
);

({int links, int phones}) countScamCheckIndicators(String input) => (
  links: _messageLinks
      .allMatches(input)
      .map((match) => match[0])
      .toSet()
      .length,
  phones: RegExp(r'(0\d{9,10}|\+84\d{9,10})').allMatches(input).length,
);
