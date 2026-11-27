import 'dart:typed_data';

import '../home/scam_check_validation.dart';

enum DisputeIndicatorType {
  phone('Số điện thoại', '091.234.8899', 'PHONE'),
  bankAccount('STK Ngân hàng', 'Ví dụ: 19036888999012', 'BANK_ACCOUNT'),
  url('Website / Link', 'Ví dụ: https://domain.vn', 'URL'),
  brandname('Brandname', 'Ví dụ: TANPHAT_CSKH', 'BRANDNAME');

  const DisputeIndicatorType(this.label, this.hint, this.apiValue);

  final String label;
  final String hint;
  final String apiValue;
}

enum DisputeLegalRelationship {
  legalRepresentative('Đại diện pháp lý doanh nghiệp', 'LEGAL_REPRESENTATIVE'),
  owner('Chủ sở hữu cá nhân / chính chủ', 'OWNER'),
  authorizedRepresentative(
    'Người được ủy quyền hợp pháp',
    'AUTHORIZED_REPRESENTATIVE',
  );

  const DisputeLegalRelationship(this.label, this.apiValue);

  final String label;
  final String apiValue;
}

class PickedDisputeFile {
  const PickedDisputeFile({
    required this.fileName,
    required this.sizeBytes,
    this.bytes,
    this.filePath,
  });

  final String fileName;
  final int sizeBytes;
  final Uint8List? bytes;
  final String? filePath;
}

class DisputeAttachmentItem {
  const DisputeAttachmentItem({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    required this.sizeLabel,
    required this.note,
    required this.contentType,
    this.bytes,
    this.filePath,
  });

  final String id;
  final String fileName;
  final int sizeBytes;
  final String sizeLabel;
  final String note;
  final String contentType;
  final Uint8List? bytes;
  final String? filePath;
}

const int maxDisputeReasonLength = 1000;
const int maxDisputeAttachmentCount = 10;
const int maxDisputeAttachmentBytes = 5 * 1024 * 1024;
const Set<String> allowedDisputeFileExtensions = {'pdf', 'jpg', 'jpeg', 'png'};

String formatDisputeAttachmentSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).round()} KB';
  }
  return '$bytes B';
}

({DisputeAttachmentItem? item, String? error})
validateAndBuildDisputeAttachment({
  required String id,
  required PickedDisputeFile file,
}) {
  final fileName = file.fileName.trim();
  if (fileName.isEmpty) {
    return (item: null, error: 'Tên tệp không hợp lệ.');
  }

  final dotIndex = fileName.lastIndexOf('.');
  final extension = dotIndex > 0 && dotIndex < fileName.length - 1
      ? fileName.substring(dotIndex + 1).toLowerCase()
      : '';
  if (!allowedDisputeFileExtensions.contains(extension)) {
    return (
      item: null,
      error: 'Tệp "$fileName" không được hỗ trợ. Chỉ chấp nhận PDF, JPG, PNG.',
    );
  }

  final hasBytes = file.bytes != null && file.bytes!.isNotEmpty;
  final hasPath = file.filePath != null && file.filePath!.trim().isNotEmpty;
  if (!hasBytes && !hasPath) {
    return (
      item: null,
      error: 'Không thể đọc nội dung tệp "$fileName". Vui lòng chọn lại.',
    );
  }

  final effectiveSize = hasBytes ? file.bytes!.length : file.sizeBytes;
  if (effectiveSize <= 0) {
    return (item: null, error: 'Tệp "$fileName" bị rỗng.');
  }
  if (effectiveSize > maxDisputeAttachmentBytes) {
    return (
      item: null,
      error: 'Tệp "$fileName" vượt quá giới hạn 5 MB mỗi tệp.',
    );
  }

  final (contentType, note) = switch (extension) {
    'pdf' => ('application/pdf', 'Tài liệu PDF xác minh'),
    'png' => ('image/png', 'Ảnh PNG xác minh'),
    _ => ('image/jpeg', 'Ảnh JPG xác minh'),
  };

  return (
    item: DisputeAttachmentItem(
      id: id,
      fileName: fileName,
      sizeBytes: effectiveSize,
      sizeLabel: formatDisputeAttachmentSize(effectiveSize),
      note: note,
      contentType: contentType,
      bytes: file.bytes,
      filePath: file.filePath?.trim(),
    ),
    error: null,
  );
}

String? validateDisputeIndicatorValue(
  DisputeIndicatorType type,
  String? value,
) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) {
    return 'Vui lòng nhập chỉ số bị gắn nhầm.';
  }
  if (input.length > 255) {
    return 'Chỉ số cần khiếu nại tối đa 255 ký tự.';
  }

  return switch (type) {
    DisputeIndicatorType.phone when !isScamCheckPhone(input) =>
      'Nhập số điện thoại hoặc đầu số hợp lệ.',
    DisputeIndicatorType.bankAccount
        when !RegExp(r'^[A-Za-z0-9\s.-]{6,34}$').hasMatch(input) =>
      'Nhập số tài khoản ngân hàng hợp lệ (từ 6 đến 34 ký tự).',
    DisputeIndicatorType.url when parseScamCheckLink(input) == null =>
      'Nhập địa chỉ website hợp lệ, ví dụ domain.vn.',
    DisputeIndicatorType.brandname when input.length < 2 =>
      'Tên Brandname phải có ít nhất 2 ký tự.',
    _ => null,
  };
}

String? validateDisputeReason(String? value) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) {
    return 'Vui lòng nhập lý do khiếu nại và giải trình.';
  }
  if (input.length < 20) {
    return 'Giải trình cần tối thiểu 20 ký tự để phục vụ thẩm định.';
  }
  if (input.length > maxDisputeReasonLength) {
    return 'Lý do khiếu nại tối đa $maxDisputeReasonLength ký tự.';
  }
  return null;
}

String? validateDisputeAttachments(List<DisputeAttachmentItem> attachments) {
  if (attachments.isEmpty) {
    return 'Vui lòng đính kèm ít nhất 1 tài liệu xác minh chính chủ.';
  }
  if (attachments.length > maxDisputeAttachmentCount) {
    return 'Mỗi hồ sơ chỉ được đính kèm tối đa $maxDisputeAttachmentCount tệp.';
  }
  return null;
}

String? validateDisputeAgreement(bool agreed) {
  return agreed
      ? null
      : 'Bạn cần xác nhận cam đoan thông tin trước khi gửi đơn.';
}
