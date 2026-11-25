import 'dart:convert';

Map<String, dynamic>? decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2 || parts[1].isEmpty) {
      return null;
    }
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final jsonMap = jsonDecode(decoded);
    return jsonMap is Map<String, dynamic> ? jsonMap : null;
  } catch (_) {
    return null;
  }
}
