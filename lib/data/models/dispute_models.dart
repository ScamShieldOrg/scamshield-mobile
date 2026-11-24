enum DisputeRecordStatus {
  pending,
  inReview,
  needsMoreInfo,
  approved,
  rejected,
  unknown;

  static DisputeRecordStatus fromApi(String? raw) {
    return switch (raw?.trim().toUpperCase()) {
      'PENDING' => DisputeRecordStatus.pending,
      'IN_REVIEW' => DisputeRecordStatus.inReview,
      'NEEDS_MORE_INFO' => DisputeRecordStatus.needsMoreInfo,
      'APPROVED' => DisputeRecordStatus.approved,
      'REJECTED' => DisputeRecordStatus.rejected,
      _ => DisputeRecordStatus.unknown,
    };
  }
}

enum DisputeFilterTab {
  all,
  inProgress,
  resolved;

  List<String>? get apiStatuses => switch (this) {
    DisputeFilterTab.all => null,
    DisputeFilterTab.inProgress => const [
      'PENDING',
      'IN_REVIEW',
      'NEEDS_MORE_INFO',
    ],
    DisputeFilterTab.resolved => const ['APPROVED'],
  };
}

class DisputeIndicatorInfo {
  const DisputeIndicatorInfo({
    required this.type,
    required this.displayValue,
    this.id,
    this.blacklistStatus,
  });

  final int? id;
  final String type;
  final String displayValue;
  final String? blacklistStatus;

  String get fieldLabel => switch (type.toUpperCase()) {
    'PHONE' => 'SĐT Phúc khảo:',
    'URL' => 'Tên miền phúc khảo:',
    'BANK_ACCOUNT' => 'STK Ngân hàng:',
    'BRANDNAME' => 'Brandname phúc khảo:',
    _ => 'Chỉ số phúc khảo:',
  };

  factory DisputeIndicatorInfo.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return DisputeIndicatorInfo(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId'),
      type: (json['type'] as String?)?.trim() ?? '',
      displayValue: (json['displayValue'] as String?)?.trim() ?? '',
      blacklistStatus: (json['blacklistStatus'] as String?)?.trim(),
    );
  }
}

class DisputeEvidenceItem {
  const DisputeEvidenceItem({
    required this.id,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    this.description,
    this.verificationStatus,
  });

  final int? id;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final String? description;
  final String? verificationStatus;

  factory DisputeEvidenceItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawSize = json['fileSize'];
    return DisputeEvidenceItem(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId'),
      fileName: (json['fileName'] as String?)?.trim(),
      fileUrl: (json['fileUrl'] as String?)?.trim(),
      fileSize: rawSize is num ? rawSize.toInt() : int.tryParse('$rawSize'),
      description: (json['description'] as String?)?.trim(),
      verificationStatus: (json['verificationStatus'] as String?)?.trim(),
    );
  }
}

class DisputeRecord {
  const DisputeRecord({
    required this.id,
    required this.disputeCode,
    required this.status,
    required this.priority,
    required this.reason,
    required this.evidenceCount,
    required this.attachments,
    this.legalRelationship,
    this.progressMessage,
    this.estimatedResolutionAt,
    this.supplementReason,
    this.supplementDeadline,
    this.resolutionReason,
    this.resolutionDocumentUrl,
    this.createdAt,
    this.resolvedAt,
    this.indicator,
  });

  final int id;
  final String disputeCode;
  final DisputeRecordStatus status;
  final String priority;
  final String reason;
  final String? legalRelationship;
  final String? progressMessage;
  final DateTime? estimatedResolutionAt;
  final String? supplementReason;
  final DateTime? supplementDeadline;
  final String? resolutionReason;
  final String? resolutionDocumentUrl;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final DisputeIndicatorInfo? indicator;
  final int evidenceCount;
  final List<DisputeEvidenceItem> attachments;

  bool get isHighPriority => priority.toUpperCase() == 'HIGH';

  String get displayCode =>
      disputeCode.startsWith('#') ? disputeCode : '#$disputeCode';

  String get attachmentsSummary {
    final names = attachments
        .map((e) => e.fileName)
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      return evidenceCount > 0
          ? '$evidenceCount tệp đính kèm'
          : 'Chưa có tệp đính kèm';
    }
    if (names.length <= 2) {
      return names.join(' & ');
    }
    return '${names.first} (+${names.length - 1} tệp)';
  }

  factory DisputeRecord.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0;
    final rawCode = (json['disputeCode'] as String?)?.trim();
    final rawEvidenceCount = json['evidenceCount'];
    final indicatorJson = json['indicator'];
    final rawAttachments = json['attachments'];

    return DisputeRecord(
      id: id,
      disputeCode: (rawCode != null && rawCode.isNotEmpty)
          ? rawCode
          : 'DSP-$id',
      status: DisputeRecordStatus.fromApi(json['status'] as String?),
      priority: (json['priority'] as String?)?.trim() ?? 'NORMAL',
      reason: (json['reason'] as String?)?.trim() ?? '',
      legalRelationship: (json['legalRelationship'] as String?)?.trim(),
      progressMessage: (json['progressMessage'] as String?)?.trim(),
      estimatedResolutionAt: _parseDateTime(json['estimatedResolutionAt']),
      supplementReason: (json['supplementReason'] as String?)?.trim(),
      supplementDeadline: _parseDateTime(json['supplementDeadline']),
      resolutionReason: (json['resolutionReason'] as String?)?.trim(),
      resolutionDocumentUrl: (json['resolutionDocumentUrl'] as String?)?.trim(),
      createdAt: _parseDateTime(json['createdAt']),
      resolvedAt: _parseDateTime(json['resolvedAt']),
      indicator: indicatorJson is Map<String, dynamic>
          ? DisputeIndicatorInfo.fromJson(indicatorJson)
          : null,
      evidenceCount: rawEvidenceCount is num
          ? rawEvidenceCount.toInt()
          : int.tryParse('$rawEvidenceCount') ?? 0,
      attachments: rawAttachments is List
          ? rawAttachments
                .whereType<Map<String, dynamic>>()
                .map(DisputeEvidenceItem.fromJson)
                .toList()
          : const [],
    );
  }
}

class DisputeSummary {
  const DisputeSummary({
    required this.totalSubmitted,
    required this.pending,
    required this.inReview,
    required this.needsMoreInfo,
    required this.approved,
    required this.rejected,
  });

  final int totalSubmitted;
  final int pending;
  final int inReview;
  final int needsMoreInfo;
  final int approved;
  final int rejected;

  int get inProgressTotal => pending + inReview + needsMoreInfo;

  factory DisputeSummary.fromJson(Map<String, dynamic> json) {
    return DisputeSummary(
      totalSubmitted: _asInt(json['totalSubmitted']),
      pending: _asInt(json['pending']),
      inReview: _asInt(json['inReview']),
      needsMoreInfo: _asInt(json['needsMoreInfo']),
      approved: _asInt(json['approved']),
      rejected: _asInt(json['rejected']),
    );
  }
}

class DisputePageResult {
  const DisputePageResult({
    required this.items,
    required this.currentPage,
    required this.totalItems,
    required this.hasNext,
  });

  final List<DisputeRecord> items;
  final int currentPage;
  final int totalItems;
  final bool hasNext;

  factory DisputePageResult.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return DisputePageResult(
      items: rawData is List
          ? rawData
                .whereType<Map<String, dynamic>>()
                .map(DisputeRecord.fromJson)
                .toList()
          : const [],
      currentPage: _asInt(json['currentPage']),
      totalItems: _asInt(json['totalItems']),
      hasNext: json['hasNext'] == true,
    );
  }
}

int _asInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? 0;
}

DateTime? _parseDateTime(Object? raw) {
  if (raw is! String || raw.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw.trim());
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String formatDisputeDate(DateTime? dateTime) {
  if (dateTime == null) {
    return '--/--/----';
  }
  return '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/${dateTime.year}';
}

String formatDisputeSubmittedAt(DateTime? dateTime, {DateTime? now}) {
  if (dateTime == null) {
    return 'Chưa có thời gian nộp';
  }
  final reference = now ?? DateTime.now();
  final timeText = '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  final isSameDay =
      dateTime.year == reference.year &&
      dateTime.month == reference.month &&
      dateTime.day == reference.day;
  if (isSameDay) {
    return 'Nộp lúc $timeText hôm nay';
  }
  return 'Nộp lúc $timeText ngày ${formatDisputeDate(dateTime)}';
}

String formatEstimatedResolution(DateTime? dateTime, {DateTime? now}) {
  if (dateTime == null) {
    return '';
  }
  final reference = now ?? DateTime.now();
  final tomorrow = reference.add(const Duration(days: 1));
  final timeText = '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  if (dateTime.year == reference.year &&
      dateTime.month == reference.month &&
      dateTime.day == reference.day) {
    return 'Ước tính có kết luận trước $timeText hôm nay';
  }
  if (dateTime.year == tomorrow.year &&
      dateTime.month == tomorrow.month &&
      dateTime.day == tomorrow.day) {
    return 'Ước tính có kết luận trước $timeText ngày mai';
  }
  return 'Ước tính có kết luận trước $timeText ${formatDisputeDate(dateTime)}';
}

String formatSupplementRemaining(DateTime? deadline, {DateTime? now}) {
  if (deadline == null) {
    return 'Cần bổ sung sớm';
  }
  final diff = deadline.difference(now ?? DateTime.now());
  if (diff.isNegative) {
    return 'Đã quá hạn';
  }
  if (diff.inHours < 24) {
    final hours = diff.inHours <= 0 ? 1 : diff.inHours;
    return 'Còn $hours giờ';
  }
  final days = (diff.inHours / 24).ceil();
  return 'Còn ${_twoDigits(days)} ngày';
}
