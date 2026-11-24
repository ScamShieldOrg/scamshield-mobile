enum ResourceList {
  warnings('Nguồn nguy hiểm', 'blacklist'),
  verified('Nguồn an toàn', 'whitelist');

  const ResourceList(this.label, this.path);
  final String label;
  final String path;
}

enum ResourceType {
  all('Tất cả', null),
  phone('Số điện thoại', 'PHONE'),
  website('Website / Tên miền', 'URL'),
  bank('Tài khoản ngân hàng', 'BANK_ACCOUNT'),
  sms('SMS', 'SMS');

  const ResourceType(this.label, this.code);
  final String label;
  final String? code;
}

enum ResourceSort {
  newest('Mới cập nhật'),
  name('Theo tên'),
  reports('Nhiều cảnh báo');

  const ResourceSort(this.label);
  final String label;
}

class ResourceEntry {
  ResourceEntry.fromJson(Map<String, dynamic> json, ResourceList list)
    : title =
          (json[list == ResourceList.warnings ? 'title' : 'name'] as String?) ??
          '',
      type = json['resourceType'] as String?,
      warningCategory = _text(json['categoryName']),
      warningCategoryDescription = _text(json['categoryDescription']),
      description = json['description'] as String?,
      warnings = (json['warningCount'] as num?)?.toInt() ?? 0,
      date = DateTime.tryParse(
        (json['updatedAt'] ?? json['confirmedAt'] ?? json['verifiedAt'] ?? '')
            .toString(),
      ),
      details = {
        'Tên thương hiệu': _text(json['brandName']),
        'Mã số thuế': _text(json['taxId']),
        'Người đại diện': _text(json['legalRepresentative']),
        'Lý do xác thực': _text(json['verificationReason']),
        'Hotline chính thức': _text(json['officialHotlines']),
        'Website chính thức': _text(json['officialDomains']),
        'Thông tin đã xác thực': _verifiedValues(json['verifiedIndicators']),
      };

  final String title;
  final String? type;
  final String warningCategory;
  final String warningCategoryDescription;
  final String? description;
  final int warnings;
  final DateTime? date;
  final Map<String, String> details;

  String get displayTitle {
    if (type?.toUpperCase() != ResourceType.phone.code) return title;
    final phone = title.replaceAll(RegExp(r'[\s.-]'), '');
    if (!RegExp(
      r'^(?:\+84\d{9,10}|0\d{9,10}|(?:1800|1900)\d{4,6})$',
    ).hasMatch(phone)) {
      return title;
    }

    if (phone.startsWith('1800') || phone.startsWith('1900')) {
      return '${phone.substring(0, 4)} ${phone.substring(4)}';
    }
    if (phone.startsWith('+84')) {
      final local = phone.substring(3);
      final prefixLength = local.length == 9 ? 3 : 2;
      const lastGroupStart = 6;
      return '+84 ${local.substring(0, prefixLength)} '
          '${local.substring(prefixLength, lastGroupStart)} '
          '${local.substring(lastGroupStart)}';
    }
    if (phone.length == 11) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 7)} '
          '${phone.substring(7)}';
    }
    return '${phone.substring(0, 4)} ${phone.substring(4, 7)} '
        '${phone.substring(7)}';
  }

  String get blacklistReason {
    final reason = description?.trim();
    if (reason == null ||
        reason.isEmpty ||
        reason == 'ScamShield confirmed this resource as unsafe.') {
      return 'ScamShield đã xác nhận tài nguyên này không an toàn.';
    }
    return reason;
  }

  String get typeLabel {
    for (final item in ResourceType.values.skip(1)) {
      if (item.code == type?.toUpperCase()) return item.label;
    }
    return 'Tài nguyên';
  }

  static String _verifiedValues(Object? value) {
    if (value is! List) return '';
    return value
        .whereType<Map<String, dynamic>>()
        .map((item) => _text(item['value']))
        .where((item) => item.isNotEmpty)
        .toSet()
        .join('\n');
  }

  static String _text(Object? value) => switch (value) {
    String text => text.trim(),
    List values => values.whereType<String>().join('\n'),
    _ => '',
  };
}

typedef ResourcePage = ({List<ResourceEntry> entries, int total, bool hasNext});
